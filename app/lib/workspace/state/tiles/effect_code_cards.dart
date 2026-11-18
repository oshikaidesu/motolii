// The code of one card of a layer, as the engine and the disk know it: which file a card's code is, its title, whether the
// file is the user's own copy and no other card's, and the copy made when a shelf's file is first edited. The Code tab's cell
// (workspace/shelf/effect_code.dart) shows it.
import 'package:motolii/bridge/engine_paths.dart' show motoliiOwn;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/script_files.dart' show linesOf, textOf;
import 'package:motolii/storage/shelf_disk.dart'
    show copyFile, makeFolder, writeText;
import 'package:motolii/workspace/state/document/expression_engine.dart'
    show supportedIn;
import 'package:motolii/workspace/state/media/shelf_items.dart'
    show shelfCopyImages;
import 'package:motolii/workspace/state/tiles/tile_review.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// Drawn code, or an expression (a .js with each(), document/scripts/expressions.h).
final _code = RegExp(r'\.(wgsl|fs|js)$');

/// The file of the card [title] on layer [thing] and the layer property that names it: the Script card's one file, or the
/// effect file of the layer's [fx] entries. Null when the card has no code.
/// The Script card has one file. Any other card is matched to a file of the layer's effects by its parameter [names],
/// not by the title alone, because two cards can share a title.
/// An effect's parameters, and those of an expression applied again ("repeater~2.js"), are named after the file
/// (`js_<stem>_<param>`, document/scripts/scripts.h doc_script_of), so the file is the one whose name they all begin with.
/// An expression's own parameters are `js_<param>`, so the file is the .js whose header declares them all.
/// If two files fit, the one whose title matches the card wins, then the longer name.
/// A card with no parameters of its own (the engine still gives it a card, doc_cards_of) is matched by title alone.
({String word, String slot})? codeOfCard(
  WorkspaceController ws,
  int thing,
  String title,
  List<String> names,
) {
  final m = ws.inside!;
  if (title == 'Script') {
    final script = m.word(thing, 'script');
    return script.endsWith('.js') ? (word: script, slot: 'script') : null;
  }
  final word = codeFileOf(m.word(thing, 'fx'), title, names);
  return word == null ? null : (word: word, slot: 'fx');
}

/// The file in a layer's [fx] that the card belongs to, or null if there is none or it is not code.
String? codeFileOf(String fx, String title, List<String> names) {
  (String, int)? best;
  for (final w in WorkspaceController.fxFiles(fx)) {
    if (!_code.hasMatch(w)) continue;
    final file = codeSource(w),
        stem = TileReview.knobStem(w),
        titled = codeTitleOf(w) == title;
    // A three.js effect is run as a scene once saved (doc_three_saved).
    if (w.endsWith('.js') && _three(file)) continue;
    // A card's own parameters begin with js_. The first card with code on a layer also shows values of the layer
    // itself (How many copies), which no file declares, so those do not decide.
    final own = [
      for (final n in names)
        if (n.startsWith('js_')) n,
    ];
    if (own.isEmpty) {
      if (titled) return w;
      continue;
    }
    final fits = w.endsWith('.js') && file == w
        ? own.every({for (final k in _knobs(_head(file))) 'js_$k'}.contains)
        : own.every((n) => n.startsWith('js_${stem}_'));
    if (!fits) continue;
    final score = (titled ? 1000 : 0) + stem.length;
    if (best == null || score > best.$2) best = (w, score);
  }
  return best?.$1;
}

/// The card title for an effect file, named as the engine does (document/cards.h doc_fx_title).
/// An effect applied again ("Glow~2.fs") gets its original's title and its number.
/// An ISF effect gets its file name (isf.cpp titles the WGSL it generates that way).
/// Any other file gets the name in its first line ("// Repeater: …"), else its file name with each _ as a space
/// and the first letter capitalised.
String codeTitleOf(String w) {
  final file = codeSource(w),
      stem = w.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '');
  if (file != w) {
    return '${codeTitleOf(file)} ${stem.substring(stem.lastIndexOf('~') + 1)}';
  }
  if (w.endsWith('.fs')) return stem;
  var first = '';
  try {
    first = linesOf(file).firstOrNull ?? '';
  } catch (_) {}
  if (first.startsWith('// ') && first.contains(':')) {
    return first.substring(3, first.indexOf(':'));
  }
  final t = stem.replaceAll('_', ' ');
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

/// The file to read for an effect [w]. An effect applied again ("Glow~2.fs") reads its original's file (fx_source, isf.h).
String codeSource(String w) => existsFile(w)
    ? w
    : w.replaceFirstMapped(RegExp(r'~[0-9]+(\.[^./]+)$'), (x) => x[1]!);

/// Whether the file [word] of the layer [thing] belongs to that card alone: one of the user's own copies, used by
/// no other card on any layer.
bool codeAlone(WorkspaceController ws, int thing, String word, String slot) {
  final m = ws.inside!, file = codeSource(word);
  if (!file.startsWith('$motoliiOwn/programs/$slot/')) return false;
  for (final t in m.layers) {
    for (final w in WorkspaceController.fxFiles(m.word(t, slot))) {
      if (!(t == thing && w == word) && codeSource(w) == file) return false;
    }
  }
  return true;
}

/// Gives the card's file [word] a copy of its own, as its first edit does: the file and the ones the engine reads
/// beside it go to `programs/<slot>/<stamp>/`, and the layer's slot names the copy. Returns the copy as the slot
/// names it, the copied file, and the engine's ticket for reading it.
(String, String, int) codeCopyOwn(
  WorkspaceController ws,
  int thing,
  String word,
  String slot,
) {
  final m = ws.inside!, file = codeSource(word);
  final dir =
          '$motoliiOwn/programs/$slot/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      to = '$dir/${file.split('/').last}',
      said = '$dir/${word.split('/').last}';
  makeFolder(dir);
  codeBeside(file, word, dir);
  copyFile(file, to);
  // Joined the way doc_fx_join does. An entry keeps the ID in front of its file, which its values are kept under.
  final fx = [
    for (final e in WorkspaceController.fxEntries(m.word(thing, slot)))
      WorkspaceController.fxFile(e) == word
          ? '${e.substring(0, e.length - word.length)}$said'
          : e,
  ].join(' ');
  m.later('say', layer: thing, name: slot, word: fx);
  return (said, to, m.later('code', word: to));
}

/// Whether the card of the code [word] takes a name of the user's: its title is the name in the code's first line
/// (doc_fx_title). An ISF's title is its file's name and an effect put on again has its original's, so those do not.
bool codeNamedInText(String word, String slot) =>
    slot == 'fx' && !word.endsWith('.fs') && codeSource(word) == word;

/// [text] with the card's name in its first line ("// Repeater: what it does") changed to [name]. Code that has no
/// such line gets one. The file keeps its name, so its values and keys, which are named after the file, stay.
String codeRenamed(String text, String name) {
  final end = text.indexOf('\n'),
      first = end < 0 ? text : text.substring(0, end);
  if (first.startsWith('// ') &&
      !first.startsWith('// --') &&
      first.contains(':')) {
    return '// $name${text.substring(first.indexOf(':'))}';
  }
  return '// $name:\n$text';
}

/// Why [name] cannot be the name of a card beside the cards [taken], or '' if it can.
String codeNameRefused(String name, Iterable<String> taken) {
  final n = name.trim();
  if (n.isEmpty) return 'A card needs a name';
  if (n.contains(':') || n.contains('\n') || n.startsWith('--')) {
    return 'A name has no colon and does not begin with --';
  }
  return taken.contains(n) ? 'Another card of this layer is named $n' : '';
}

/// Names the card of the code [word] of layer [thing] [name], by writing it in the code's first line as a change of
/// the code is written: to the layer's own copy, made first if the file is the shelf's or another card's too.
void codeRename(
  WorkspaceController ws,
  int thing,
  String word,
  String slot,
  String name,
  void Function(bool done, String why) told,
) {
  final file = codeSource(word), text = codeRenamed(textOf(file), name.trim());
  if (codeAlone(ws, thing, word, slot)) {
    writeText(file, text);
    return codeWritten(ws, file, told);
  }
  final (_, to, read) = codeCopyOwn(ws, thing, word, slot);
  ws.after(read, (_, _) {
    writeText(to, text);
    codeWritten(ws, to, told);
  });
}

/// Copies the files the engine reads beside [from] to the copy's folder [dir].
void codeBeside(String from, String word, String dir) {
  final home = from.substring(0, from.lastIndexOf('/'));
  if (from.endsWith('.fs')) {
    final vs = from.replaceFirst(RegExp(r'\.fs$'), '.vs');
    if (existsFile(vs)) copyFile(vs, '$dir/${vs.split('/').last}');
  }
  final first = '$home/first.tsv', name = word.split('/').last;
  if (existsFile(first)) {
    final lines = [
      for (final l in linesOf(first))
        if (l.split('\t').first == name) l,
    ];
    if (lines.isNotEmpty) {
      writeText('$dir/first.tsv', '${lines.join('\n')}\n');
    }
  }
  shelfCopyImages(from, dir);
}

/// The view keys the Code tab keeps: the titles of the cells that are folded, and the card last asked for with a count,
/// so that asking for the same card again is heard.
const codeFolded = 'code.folded', codeAsked = 'code.asked';

/// Opens the Code tab on the card [title]: its cell is unfolded and scrolled into sight.
void showCodeCell(WorkspaceController ws, String title) {
  ws.setView(
    codeFolded,
    {...ws.viewOf(codeFolded, const <String>{})}..remove(title),
  );
  ws.setView(codeAsked, (
    title,
    (ws.viewOf<(String, int)?>(codeAsked, null)?.$2 ?? 0) + 1,
  ));
  ws.front('Code');
}

/// The expression prompts the running expression in [file] supports, asked of the engine (null when it is not a script).
Future<Map<String, String>?> codeSupport(WorkspaceController ws, String file) =>
    supportedIn(ws, file);

/// Tells [told] what the engine said of the code [file] it was written as (the last one it accepted stays shown if not),
/// then reads the workspace again.
void codeWritten(
  WorkspaceController ws,
  String file,
  void Function(bool done, String why) told,
) => ws.after(ws.inside!.later('code', word: file), (done, why) {
  told(done, why);
  ws.reread();
});

List<String> _head(String file) {
  try {
    return [
      for (final l in linesOf(
        file,
      ).takeWhile((l) => l.startsWith('//') || l.trim().isEmpty))
        if (l.startsWith('//')) l,
    ];
  } catch (_) {
    return const [];
  }
}

/// The parameter names declared in [head], such as "// --track@StepX:Step X,…" (script_knobs).
List<String> _knobs(List<String> head) => [
  for (final l in head)
    if ((l.indexOf('--'), l.indexOf('@'), l.indexOf(':'))
        case (final d, final a, final c)
        when d >= 0 && d < a && a < c && c > a + 1)
      l.substring(a + 1, c),
];

bool _three(String file) {
  // Same test as three_isf.cpp three_is: a .js containing a fragmentShader.
  try {
    return textOf(file).contains('fragmentShader');
  } catch (_) {
    return false;
  }
}
