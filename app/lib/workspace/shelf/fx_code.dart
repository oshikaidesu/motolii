// An effect's code on its card, under its knobs, as the Script card's is (slot: 'script'): a .wgsl's, an ISF .fs's, an
// expression's (a .js with each() among its fx: document/expressions.h). What is typed is this thing's effect alone. The shelf's file is never written over: the first typing copies it to a folder of its own in the maker's
// programs (programs/fx/<stamp>/) under the same file name, and this thing's fx says the copy in its place. The same
// name keeps what hangs on it: its values' names (js_<stem>_<knob>, doc_screen_knob), its card's title (doc_fx_title),
// so its eye, place and values stay. Beside it go what the engine reads from the file's folder: an ISF's .vs (isf.cpp),
// its line of first.tsv (script_first), the images its head names (--image@, screen_fx.h).
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../skin/tokens.dart';
import '../dock/dock_program.dart' show ProgramCode;
import 'effect_tiles.dart' show EffectTiles;
import 'shelf_add.dart';
import '../state/state.dart';

class FxCode extends StatefulWidget {
  const FxCode(this.ws, this.thing, this.word, {this.slot = 'fx', this.shelf = true, super.key});
  final Ws ws;
  final int thing;
  final String word; // (as the thing's slot says it)
  final String slot; // ('fx': the effects; 'script': the Script card's one file) the thing's word that says the file, and the programs/ folder of its copies
  final bool shelf; // (Add to shelf under it: an effect's, not a script's)
  @override
  State<FxCode> createState() => _FxCodeState();

  static final _code = RegExp(r'\.(wgsl|fs|js)$'); // (drawn code, and an expression: a .js with each(), document/expressions.h)

  /// The code of a thing's effect card (null: not one of its code effects), by its values, not its title alone: two
  /// cards may share one (ThorVG's Tint is called Duotone, as an ISF file may be). An effect's values, and an expression
  /// put on again's ("repeater~2.js"), are named by its file (`js_<stem>_<knob>`, document/scripts.h doc_script_of): the
  /// file whose name they all begin with. An expression's first are its knobs' own (`js_<knob>`): the .js whose head
  /// says them all. Of two that fit, the one the card's title is, else the longer name. A card of no values (an effect
  /// with no knobs: the engine gives it a card all the same, doc_cards_of) by its title alone.
  static FxCode? of(Ws ws, int thing, String title, List<String> names) {
    final word = fileOf(ws.inside!.word(thing, 'fx'), title, names);
    return word == null ? null : FxCode(ws, thing, word, key: ValueKey('fx-code-$thing-$title'));
  }

  /// The word of a thing's fx ([fx]) that a card is of (null: none, or not code).
  static String? fileOf(String fx, String title, List<String> names) {
    (String, int)? best;
    for (final w in Ws.fxFiles(fx)) {
      if (!_code.hasMatch(w)) continue;
      final file = source(w), stem = EffectTiles.knobStem(w), titled = titleOf(w) == title;
      if (w.endsWith('.js') && _three(file)) continue; // (a three.js effect: saved, it is run as a scene, doc_three_saved)
      if (names.isEmpty) {
        if (titled) return w;
        continue;
      }
      final fits = w.endsWith('.js') && file == w
          ? names.every({for (final k in _knobs(_head(file))) 'js_$k'}.contains)
          : names.every((n) => n.startsWith('js_${stem}_'));
      if (!fits) continue;
      final score = (titled ? 1000 : 0) + stem.length;
      if (best == null || score > best.$2) best = (w, score);
    }
    return best?.$1;
  }

  /// Its card's title, as the engine names an effect file's (document/cards.h doc_fx_title): one put on again ("Glow~2.fs")
  /// its original's and its number; an ISF's its file's name (isf.cpp heads the WGSL it makes so); another's the name
  /// its first line says ("// Repeater: …"), else its file's name, a space for each _, its first letter large.
  static String titleOf(String w) {
    final file = source(w), stem = w.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '');
    if (file != w) return '${titleOf(file)} ${stem.substring(stem.lastIndexOf('~') + 1)}';
    if (w.endsWith('.fs')) return stem;
    var first = '';
    try {
      first = File(file).readAsLinesSync().firstOrNull ?? '';
    } catch (_) {}
    if (first.startsWith('// ') && first.contains(':')) return first.substring(3, first.indexOf(':'));
    final t = stem.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  /// Its head: the lines before its code (script.cpp script_knobs reads its knobs there).
  static List<String> _head(String file) {
    try {
      return [
        for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//') || l.trim().isEmpty))
          if (l.startsWith('//')) l,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The knobs its head says, by name: "// --track@StepX:Step X,…" (script_knobs).
  static List<String> _knobs(List<String> head) => [
    for (final l in head)
      if ((l.indexOf('--'), l.indexOf('@'), l.indexOf(':')) case (final d, final a, final c) when d >= 0 && d < a && a < c && c > a + 1) l.substring(a + 1, c),
  ];

  static bool _three(String file) {
    // (three_isf.cpp three_is: a .js with a fragmentShader)
    try {
      return File(file).readAsStringSync().contains('fragmentShader');
    } catch (_) {
      return false;
    }
  }

  /// The file read for an effect word: an effect put on again ("Glow~2.fs") reads its original's (fx_source, isf.h).
  static String source(String w) => File(w).existsSync() ? w : w.replaceFirstMapped(RegExp(r'~[0-9]+(\.[^./]+)$'), (x) => x[1]!);
}

class _FxCodeState extends State<FxCode> {
  String? _mine; // (the copy said, until the inside has it as the thing's)
  String _why = ''; // (why its code as it is now is not taken, said on its card; '' it is)
  bool _making = false; // (its copy made once as it was, before what is typed is written over it)
  String? _typed; // (typed meanwhile)
  String? _adding; // (the name being written to add it to the shelf by)
  String _added = ''; // (what came of the last Add to shelf: why not, or where it went)
  bool _addedOk = false;

  String get _own => '${EffectTiles.own}/programs/${widget.slot}/';

  /// Whether the file is this thing's card's alone: one of its own copies, said by no other card of any thing.
  bool _alone(String word) {
    final m = widget.ws.inside!, file = FxCode.source(word);
    if (!file.startsWith(_own)) return false;
    for (final t in m.layers) {
      for (final w in Ws.fxFiles(m.word(t, widget.slot))) {
        if (!(t == widget.thing && w == word) && FxCode.source(w) == file) return false;
      }
    }
    return true;
  }

  // (the copy is first made as the file it is of and taken so, then written over with what is typed: a half typed
  //  effect or expression stays drawn as it last was taken, which a copy never taken has not: isf.cpp, doc_script_of)
  void _write(String text) {
    if (_making) {
      _typed = text;
      return;
    }
    final ws = widget.ws, m = ws.inside!, word = _mine ?? widget.word, file = FxCode.source(word);
    if (_alone(word)) {
      File(file).writeAsStringSync(text);
      return _saved(file);
    }
    final dir = '$_own${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}', to = '$dir/${file.split('/').last}', said = '$dir/${word.split('/').last}';
    Directory(dir).createSync(recursive: true);
    _beside(file, word, dir);
    File(file).copySync(to);
    _mine = said;
    _making = true;
    _typed = text;
    final fx = [for (final w in Ws.fxFiles(m.word(widget.thing, widget.slot))) w == word ? said : w].join(' '); // (as doc_fx_join says it)
    m.later('say', layer: widget.thing, name: widget.slot, word: fx);
    ws.after(m.later('code', word: to), (_, _) {
      _making = false;
      File(to).writeAsStringSync(_typed!);
      _typed = null;
      _saved(to);
    });
  }

  void _saved(String file) => widget.ws.after(widget.ws.inside!.later('code', word: file), (done, why) {
    if (mounted) setState(() => _why = done ? '' : why.trim());
    widget.ws.reread();
  });

  /// What the engine reads beside the file, copied beside the copy.
  static void _beside(String from, String word, String dir) {
    final home = from.substring(0, from.lastIndexOf('/'));
    if (from.endsWith('.fs')) {
      final vs = File(from.replaceFirst(RegExp(r'\.fs$'), '.vs'));
      if (vs.existsSync()) vs.copySync('$dir/${vs.path.split('/').last}');
    }
    final first = File('$home/first.tsv'), name = word.split('/').last;
    if (first.existsSync()) {
      final lines = [
        for (final l in first.readAsLinesSync())
          if (l.split('\t').first == name) l,
      ];
      if (lines.isNotEmpty) File('$dir/first.tsv').writeAsStringSync('${lines.join('\n')}\n');
    }
    for (final l in File(from).readAsLinesSync()) {
      final image = RegExp(r'^//.*--image@[^:]*:(.+)$').firstMatch(l)?[1]?.trim();
      if (image == null || image.startsWith('/') || !File('$home/$image').existsSync()) continue;
      File('$dir/$image').parent.createSync(recursive: true);
      File('$home/$image').copySync('$dir/$image');
    }
  }

  // (its code as the card has it, under the name written: an effect on the Effects shelf, an expression in Create's
  //  Copies, shelf_add.dart; written in place of its title, as Finder's Rename)
  void _add(String? name) {
    setState(() => _adding = null);
    if (name == null) return;
    final word = _mine ?? widget.word, file = FxCode.source(word), expression = shelfIsExpression(file);
    final why = _why.isNotEmpty
        ? 'It does not compile: fix it first'
        : shelfAdd(widget.ws, file, _typed ?? File(file).readAsStringSync(), name, shelfTaken(widget.ws, expression: expression));
    setState(() {
      _addedOk = why.isEmpty;
      _added = why.isEmpty ? 'Added to ${expression ? 'Create, Copies' : 'Effects'} as ${name.trim()}' : why;
    });
  }

  Widget _shelf() {
    if (_adding case final name?) return SizedBox(height: Shape.s(18), child: ShelfNameField(name, _add, small: false));
    return Row(
      children: [
        NakedButton(
          onPressed: () => setState(() {
            _adding = FxCode.titleOf(_mine ?? widget.word);
            _added = '';
          }),
          enableFeedback: false,
          child: Text('Add to shelf', style: T.label(Grey.g76)),
        ),
        if (_added.isNotEmpty) ...[
          SizedBox(width: Shape.s(8)),
          Expanded(
            child: Text(_added, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(_addedOk ? Grey.g56 : Role.error)),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mine == widget.word) _mine = null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_why.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Shape.s(4)),
            child: Text('Does not compile; the last that did is shown. $_why', maxLines: 4, overflow: TextOverflow.ellipsis, style: T.label(Role.error)),
          ),
        Expanded(child: ProgramCode(FxCode.source(_mine ?? widget.word), _write, keep: _making)),
        if (widget.shelf)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: _shelf(),
          ),
      ],
    );
  }
}
