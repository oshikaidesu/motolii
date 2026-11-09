// A thing's effect or expression added to the shelf under a name of the maker's (Add to shelf, on its card's code:
// fx_code.dart), and one added so renamed by its tile's menu. What is added is the maker's: in their own folder
// (EffectTiles.own), never the library's (engine/). An effect (.fs, .wgsl) goes in effects/, where the Effects shelf
// reads the maker's effects (doc_folders); an expression (.js with each()) in expressions/, which no shelf of the inside
// reads: not programs/ (the Program shelf's), not effects/ or animators/ (they read a .js as an effect, a motion), so
// Create lists it in its Copies (dock_make_3.dart). Nothing is written over: a name the shelf has, or a file there of
// that name, is refused. A rename writes the name beside the file (<file>.name, as the Program shelf's: dock_program.dart
// Program.rename): the file stays where it is, so the documents that use it still find it.
import 'dart:io';

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../motolii.dart' show motoliiDir;
import '../sets/foundations/text_hand.dart';
import '../tokens.dart';
import 'dock_make.dart' show createNames;
import 'effect_tiles.dart' show EffectTiles;
import 'ws.dart';

String get _ownEffects => '${EffectTiles.own}/effects';
String get _ownExpressions => '${EffectTiles.own}/expressions';

bool shelfIsExpression(String file) => file.endsWith('.js');

/// The name written beside one the maker added (null: none, or not theirs).
String? shelfNamed(String file) {
  if (!shelfAdded(file)) return null;
  final f = _sidecar(file);
  return f.existsSync() ? f.readAsStringSync().trim() : null;
}

/// Whether the file is one the maker added to a shelf (a library file is not: it has no Rename).
bool shelfAdded(String file) => file.startsWith('$_ownEffects/') || file.startsWith('$_ownExpressions/');

File _sidecar(String file) => File('${file.substring(0, file.lastIndexOf('.'))}.name');

/// The expressions the maker added, by name (the one written beside it, else its head's, else its file's): name and file.
List<(String, String)> shelfExpressions() {
  final dir = Directory(_ownExpressions);
  if (!dir.existsSync()) return const [];
  return [
    for (final f in dir.listSync().whereType<File>().map((f) => f.path).where(shelfIsExpression))
      (shelfNamed(f) ?? _headName(f) ?? f.split('/').last.replaceFirst(RegExp(r'\.js$'), ''), f),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

/// The name its first line says ("// Repeater: …"; null none).
String? _headName(String file) {
  try {
    final first = File(file).readAsLinesSync().firstOrNull ?? '';
    return first.startsWith('// ') && first.contains(':') ? first.substring(3, first.indexOf(':')) : null;
  } catch (_) {
    return null;
  }
}

/// The names on the shelf an effect ([expression]: an expression) is added to, the library's and the maker's: the Effects
/// shelf's (dock_effects.dart), else Create's (dock_make.dart).
Set<String> shelfTaken(Ws ws, {required bool expression}) {
  if (expression) return createNames(ws);
  final m = ws.inside;
  if (m == null) return const {};
  return {'Empty', for (final l in [m.thingEffects, m.looks, m.animators]) ...l.map((e) => e.$1), for (final (n, f) in m.effects) shelfNamed(f) ?? n};
}

/// Why a name cannot be one on a shelf whose names are [taken] ('' it can): it is a file's name too.
String _whyNot(String name, Iterable<String> taken) {
  if (name.isEmpty) return 'Give it a name';
  if (name.startsWith('.') || RegExp(r'[/\\:~\t\n]').hasMatch(name)) return 'A name without / \\ : ~ or a leading dot';
  if (taken.any((t) => t.toLowerCase() == name.toLowerCase())) return '"$name" is already on the shelf';
  return '';
}

/// [code] (the card's code as it is, read from [from]) added to its shelf as [name]; why it is not ('' it is).
/// [taken]: the names on that shelf, the library's and the maker's.
String shelfAdd(Ws ws, String from, String code, String name, Iterable<String> taken) {
  name = name.trim();
  if (_whyNot(name, taken) case final why when why.isNotEmpty) return why;
  final ext = from.substring(from.lastIndexOf('.')), expression = shelfIsExpression(from);
  final dir = expression ? _ownExpressions : _ownEffects, file = '$dir/$name$ext';
  // (the maker's file of a name stands over the library's (doc_folder_files): neither is written over)
  for (final f in [file, if (!expression) '$motoliiDir/effects/$name$ext']) {
    if (File(f).existsSync()) return '"$name$ext" is already there';
  }
  Directory(dir).createSync(recursive: true);
  // (its card's title and its shelf name: an ISF's its file's (isf.cpp), another's its first line's (doc_fx_title))
  if (ext != '.fs') {
    final lines = code.split('\n'), first = lines.first;
    final head = first.startsWith('// ') && first.contains(':') && !first.startsWith('// --');
    code = head ? ['// $name${first.substring(first.indexOf(':'))}', ...lines.skip(1)].join('\n') : '// $name:\n$code';
  }
  File(file).writeAsStringSync(code);
  _beside(from, name + ext, dir);
  ws.inside?.forgetFolders();
  ws.reread();
  return '';
}

/// What the engine reads beside an effect's file (fx_code.dart _beside): an ISF's .vs, its lines of first.tsv (under its
/// new name, added to the folder's), the images its head names (copied where none is: none is written over).
void _beside(String from, String to, String dir) {
  final home = from.substring(0, from.lastIndexOf('/')), name = from.split('/').last.replaceFirst(RegExp(r'~[0-9]+(?=\.[^.]+$)'), '');
  final stem = to.substring(0, to.lastIndexOf('.'));
  if (from.endsWith('.fs')) {
    final vs = File(from.replaceFirst(RegExp(r'\.fs$'), '.vs'));
    if (vs.existsSync() && !File('$dir/$stem.vs').existsSync()) vs.copySync('$dir/$stem.vs');
  }
  final first = File('$home/first.tsv');
  if (first.existsSync()) {
    final lines = [for (final l in first.readAsLinesSync()) if (l.split('\t').first == name) [to, ...l.split('\t').skip(1)].join('\t')];
    if (lines.isNotEmpty) File('$dir/first.tsv').writeAsStringSync('${lines.join('\n')}\n', mode: FileMode.append);
  }
  for (final l in File(from).readAsLinesSync()) {
    final image = RegExp(r'^//.*--image@[^:]*:(.+)$').firstMatch(l)?[1]?.trim();
    if (image == null || image.startsWith('/') || !File('$home/$image').existsSync() || File('$dir/$image').existsSync()) continue;
    File('$dir/$image').parent.createSync(recursive: true);
    File('$home/$image').copySync('$dir/$image');
  }
}

/// One the maker added renamed [to] (its name written beside it); why not ('' it is). [taken]: the shelf's names but its own.
String shelfRename(Ws ws, String file, String to, Iterable<String> taken) {
  to = to.trim();
  if (!shelfAdded(file)) return 'Only what you added can be renamed';
  if (_whyNot(to, taken) case final why when why.isNotEmpty) return why;
  _sidecar(file).writeAsStringSync(to);
  ws.inside?.forgetFolders();
  ws.reread();
  return '';
}

/// A name written in place, as Finder's: Return or leaving it says it, Escape lets it be ([done] null).
class ShelfNameField extends StatefulWidget {
  const ShelfNameField(this.name, this.done, {super.key, this.small = true});
  final String name;
  final void Function(String? name) done;
  final bool small;   // (a tile's name; else a card's)
  @override
  State<ShelfNameField> createState() => _ShelfNameFieldState();
}

class _ShelfNameFieldState extends State<ShelfNameField> {
  late final _words = TextEditingController(text: widget.name)..selection = TextSelection(baseOffset: 0, extentOffset: widget.name.length);
  late final FocusNode _focus = FocusNode()..addListener(() => _focus.hasFocus ? null : _say(_words.text));
  bool _said = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _say(String? name) {
    if (_said) return;
    _said = true;
    widget.done(name);
  }

  @override
  void dispose() {
    _words.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _say(null)},
    child: Container(
      color: Grey.g91,
      padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
      alignment: Alignment.centerLeft,
      child: TextHand(field: (k) => EditableText(key: k, rendererIgnoresPointer: true,
        controller: _words,
        focusNode: _focus,
        style: widget.small ? T.micro(Grey.g13) : T.name(Grey.g13),
        cursorColor: Grey.g13,
        backgroundCursorColor: Grey.g38,
        selectionColor: Grey.g63,
        maxLines: 1,
        onSubmitted: (_) => _say(_words.text),
      )),
    ),
  );
}
