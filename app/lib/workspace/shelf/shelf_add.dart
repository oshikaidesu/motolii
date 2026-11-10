// Adding an effect or expression from a layer to the shelf under a name the user chooses ("Add to shelf" on the
// card's code, effect_code.dart), and renaming one added that way from its tile's menu.
// What is added belongs to the user: it goes in their own folder (EffectTiles.own), never in the library's (engine/).
// An effect (.fs, .wgsl) goes in effects/, where the Effects shelf reads the user's effects (doc_folders).
// An expression (a .js with each()) goes in expressions/, the Expression group's folder. The engine also reads it
// as a motion, but Create shows it only once, as the user's (dock_make_expressions.dart).
// Nothing is overwritten: a name already on the shelf, or an existing file of that name, is refused.
// A rename writes the name beside the file (<file>.name, as the Program shelf does: Program.rename in dock_program.dart).
// The file stays where it is, so documents that use it still find it.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/dock/dock_make_create.dart' show createNames;
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_shelves.dart';

String get _ownEffects => '${EffectTiles.own}/effects';
String get _ownExpressions => '${EffectTiles.own}/expressions';

bool shelfIsExpression(String file) => file.endsWith('.js');

/// The display name written beside a file the user added, or null if there is none or the file is not theirs.
String? shelfNamed(String file) {
  if (!shelfAdded(file)) return null;
  final f = shelfSidecar(file);
  return f.existsSync() ? f.readAsStringSync().trim() : null;
}

/// Whether the user added the file to a shelf. Library files were not, so they cannot be renamed.
bool shelfAdded(String file) => file.startsWith('$_ownEffects/') || file.startsWith('$_ownExpressions/');

File shelfSidecar(String file) => File('${file.substring(0, file.lastIndexOf('.'))}.name');

/// The expressions the user added as (name, file), sorted by name.
/// The name is the one written beside the file, else the one in its header, else the file name.
List<(String, String)> shelfExpressions() {
  final dir = Directory(_ownExpressions);
  if (!dir.existsSync()) return const [];
  return [
    for (final f in dir.listSync().whereType<File>().map((f) => f.path).where(shelfIsExpression))
      (shelfNamed(f) ?? _headName(f) ?? f.split('/').last.replaceFirst(RegExp(r'\.js$'), ''), f),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

/// The name in the file's first line ("// Repeater: …"), or null if there is none.
String? _headName(String file) {
  try {
    final first = File(file).readAsLinesSync().firstOrNull ?? '';
    return first.startsWith('// ') && first.contains(':') ? first.substring(3, first.indexOf(':')) : null;
  } catch (_) {
    return null;
  }
}

/// The names already on the shelf that a new item goes to, from the library and the user.
/// An effect goes to the Effects shelf (dock_effects.dart); an expression ([expression]) goes to Create (dock_make.dart).
Set<String> shelfTaken(WorkspaceController ws, {required bool expression}) {
  if (expression) return createNames(ws);
  final m = ws.inside;
  if (m == null) return const {};
  return {
    'Empty',
    for (final l in [m.layerEffects, m.presets]) ...l.map((e) => e.$1),
    for (final (n, f) in m.effects) shelfNamed(f) ?? n,
  };
}

/// Why [name] cannot be used on a shelf whose names are [taken], or '' if it can. The name is also a file name.
String _whyNot(String name, Iterable<String> taken) {
  if (name.isEmpty) return 'Give it a name';
  if (name.startsWith('.') || RegExp(r'[/\\:~\t\n]').hasMatch(name)) return 'A name without / \\ : ~ or a leading dot';
  if (taken.any((t) => t.toLowerCase() == name.toLowerCase())) return '"$name" is already on the shelf';
  return '';
}

/// Adds [code] (the card's current code, read from [from]) to its shelf as [name].
/// Returns why it could not be added, or '' on success. [taken] holds the names already on that shelf, from the library and the user.
String shelfAdd(WorkspaceController ws, String from, String code, String name, Iterable<String> taken) {
  name = name.trim();
  if (_whyNot(name, taken) case final why when why.isNotEmpty) return why;
  final ext = from.substring(from.lastIndexOf('.')), expression = shelfIsExpression(from);
  final dir = expression ? _ownExpressions : _ownEffects, file = '$dir/$name$ext';
  // A user's file of the same name takes precedence over the library's (doc_folder_files), but neither is overwritten.
  // The library groups effects by what they do (blur/, color/…), so search it recursively.
  final library = Directory('$motoliiShelves/effects');
  if (File(file).existsSync() || (!expression && library.existsSync() && library.listSync(recursive: true).any((e) => e.path.endsWith('/$name$ext')))) {
    return '"$name$ext" is already there';
  }
  Directory(dir).createSync(recursive: true);
  // The card title and shelf name: an ISF takes its file name (isf.cpp), anything else its first line (doc_fx_title).
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

/// Copies the files the engine reads beside an effect's file (see _beside in effect_code.dart).
/// That is an ISF's .vs, its lines of first.tsv (under the new name, appended to the folder's), and the images its
/// header names (copied only where none exists, so nothing is overwritten).
void _beside(String from, String to, String dir) {
  final home = from.substring(0, from.lastIndexOf('/')), name = from.split('/').last.replaceFirst(RegExp(r'~[0-9]+(?=\.[^.]+$)'), '');
  final stem = to.substring(0, to.lastIndexOf('.'));
  if (from.endsWith('.fs')) {
    final vs = File(from.replaceFirst(RegExp(r'\.fs$'), '.vs'));
    if (vs.existsSync() && !File('$dir/$stem.vs').existsSync()) vs.copySync('$dir/$stem.vs');
  }
  final first = File('$home/first.tsv');
  if (first.existsSync()) {
    final lines = [
      for (final l in first.readAsLinesSync())
        if (l.split('\t').first == name) [to, ...l.split('\t').skip(1)].join('\t'),
    ];
    if (lines.isNotEmpty) File('$dir/first.tsv').writeAsStringSync('${lines.join('\n')}\n', mode: FileMode.append);
  }
  for (final l in File(from).readAsLinesSync()) {
    final image = RegExp(r'^//.*--image@[^:]*:(.+)$').firstMatch(l)?[1]?.trim();
    if (image == null || image.startsWith('/') || !File('$home/$image').existsSync() || File('$dir/$image').existsSync()) continue;
    File('$dir/$image').parent.createSync(recursive: true);
    File('$home/$image').copySync('$dir/$image');
  }
}

/// Renames a file the user added to [to] by writing the name beside it. Returns why it failed, or '' on success.
/// [taken] holds the shelf's names except this file's own.
String shelfRename(WorkspaceController ws, String file, String to, Iterable<String> taken) {
  to = to.trim();
  if (!shelfAdded(file)) return 'Only what you added can be renamed';
  if (_whyNot(to, taken) case final why when why.isNotEmpty) return why;
  shelfSidecar(file).writeAsStringSync(to);
  ws.inside?.forgetFolders();
  ws.reread();
  return '';
}

/// A name edited in place, as in Finder. Return or leaving the field commits it; Escape cancels and calls [done] with null.
class ShelfNameField extends StatelessWidget {
  const ShelfNameField(this.name, this.done, {super.key, this.small = true});
  final String name;
  final void Function(String? name) done;

  /// Whether it edits a tile's name (true) or a card's (false).
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    color: Grey.g91,
    padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
    alignment: Alignment.centerLeft,
    child: TypedField(
      text: name,
      take: true,
      escapes: true,
      style: small ? TextStyles.micro(Grey.g13) : TextStyles.name(Grey.g13),
      cursor: Grey.g13,
      selection: Grey.g63,
      onDone: done,
    ),
  );
}
