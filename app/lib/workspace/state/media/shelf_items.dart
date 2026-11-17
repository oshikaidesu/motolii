// Adding an effect or expression from a layer to the shelf under a name the user chooses ("Add to shelf" on the
// card's code, effect_code.dart), and renaming one added that way from its tile's menu.
// What is added belongs to the user: it goes in their own folder (motoliiOwn), never in the library's (engine/).
// An effect (.fs, .wgsl) goes in effects/, where the Effects shelf reads the user's effects (doc_folders).
// An expression (a .js with each()) goes in expressions/, the Expression group's folder. The engine also reads it
// as a motion, but Create shows it only once, as the user's (dock_make_expressions.dart).
// Nothing is overwritten: a name already on the shelf, or an existing file of that name, is refused.
// A rename writes the name beside the file (<file>.name, as pasted code does: CodeFile.rename in dock/create/code_file.dart).
// The file stays where it is, so documents that use it still find it.
import 'package:motolii/storage/host_platform.dart' show isRooted;
import 'package:motolii/bridge/engine_paths.dart'
    show motoliiOwn, motoliiShelves;
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/folder_entries.dart' show folderThere;
import 'package:motolii/storage/folder_files.dart' show filesIn;
import 'package:motolii/storage/script_files.dart' show linesOf, filesUnder;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_shelves.dart';

String get _ownEffects => '$motoliiOwn/effects';
String get _ownExpressions => '$motoliiOwn/expressions';

/// A .js with each(), or a pen's CSS, which moves a text's letters (engine/community/css).
bool shelfIsExpression(String file) =>
    file.endsWith('.js') || file.endsWith('.css');

/// The display name written beside a file the user added, or null if there is none or the file is not theirs.
String? shelfNamed(String file) {
  if (!shelfAdded(file)) return null;
  return shelfSidecarText(file)?.trim();
}

/// Whether the user added the file to a shelf. Library files were not, so they cannot be renamed.
bool shelfAdded(String file) =>
    file.startsWith('$_ownEffects/') || file.startsWith('$_ownExpressions/');

/// The path of the file that holds the name the user gave [file] (beside it, with the extension changed to .name).
String shelfSidecarPath(String file) =>
    '${file.substring(0, file.lastIndexOf('.'))}.name';

/// The name kept beside [file], or null when there is none.
String? shelfSidecarText(String file) {
  final p = shelfSidecarPath(file);
  return existsFile(p) ? readTextNow(p) : null;
}

/// Writes [text] as the name kept beside [file].
void shelfSidecarWrite(String file, String text) =>
    writeText(shelfSidecarPath(file), text);

/// The items of a shelf that the search text [query] finds, as their ids, best first. The engine does the matching
/// (Motolii.find); items scoring below [least] are left out.
List<String> nearShelfItems(
  WorkspaceController ws,
  String query,
  Iterable<(String, String, String)> items, {
  double least = 0,
}) => ws.inside?.find(query, items, least: least) ?? const [];

/// Removes the name kept beside [file], if there is one.
void shelfSidecarDelete(String file) {
  final p = shelfSidecarPath(file);
  if (existsFile(p)) deleteFile(p);
}

/// The expressions the user added as (name, file), sorted by name.
/// The name is the one written beside the file, else the one in its header, else the file name.
List<(String, String)> shelfExpressions() {
  final dir = _ownExpressions;
  return [
    for (final f in filesIn(dir).where(shelfIsExpression))
      (
        shelfNamed(f) ??
            _headName(f) ??
            f.split('/').last.replaceFirst(RegExp(r'\.js$'), ''),
        f,
      ),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

/// The name in the file's first line ("// Repeater: …"), or null if there is none.
String? _headName(String file) {
  try {
    final first = linesOf(file).firstOrNull ?? '';
    return first.startsWith('// ') && first.contains(':')
        ? first.substring(3, first.indexOf(':'))
        : null;
  } catch (_) {
    return null;
  }
}

/// The names on the Effects shelf already: the library's and the user's, and the names the layer's own effects and
/// presets are known by. None when no project is open.
Set<String> shelfTakenNames(WorkspaceController ws) {
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
  if (name.startsWith('.') || RegExp(r'[/\\:~\t\n]').hasMatch(name)) {
    return 'A name without / \\ : ~ or a leading dot';
  }
  if (taken.any((t) => t.toLowerCase() == name.toLowerCase())) {
    return '"$name" is already on the shelf';
  }
  return '';
}

/// Adds [code] (the card's current code, read from [from]) to its shelf as [name].
/// Returns why it could not be added, or '' on success. [taken] holds the names already on that shelf, from the library and the user.
String shelfAdd(
  WorkspaceController ws,
  String from,
  String code,
  String name,
  Iterable<String> taken,
) {
  name = name.trim();
  if (_whyNot(name, taken) case final why when why.isNotEmpty) return why;
  final ext = from.substring(from.lastIndexOf('.')),
      expression = shelfIsExpression(from);
  final dir = expression ? _ownExpressions : _ownEffects,
      file = '$dir/$name$ext';
  // A user's file of the same name takes precedence over the library's (doc_folder_files), but neither is overwritten.
  // The library groups effects by what they do (blur/, color/…), so search it recursively.
  final library = '$motoliiShelves/effects';
  if (existsFile(file) ||
      (!expression &&
          folderThere(library) &&
          filesUnder(
            library,
            recursive: true,
          ).any((p) => p.endsWith('/$name$ext')))) {
    return '"$name$ext" is already there';
  }
  makeFolder(dir);
  // The card title and shelf name: an ISF takes its file name (isf.cpp), anything else its first line (doc_fx_title).
  if (ext != '.fs') {
    final lines = code.split('\n'), first = lines.first;
    final head =
        first.startsWith('// ') &&
        first.contains(':') &&
        !first.startsWith('// --');
    code = head
        ? [
            '// $name${first.substring(first.indexOf(':'))}',
            ...lines.skip(1),
          ].join('\n')
        : '// $name:\n$code';
  }
  writeText(file, code);
  _beside(from, name + ext, dir);
  ws.inside?.forgetFolders();
  ws.reread();
  return '';
}

/// Copies the images the header of the effect file [from] names (`--image@name:path`) from beside it to [dir], keeping their folders.
/// A path that starts with / or is not there is left; with [overwrite] false a file already in [dir] is kept.
void shelfCopyImages(String from, String dir, {bool overwrite = true}) {
  final home = from.substring(0, from.lastIndexOf('/'));
  for (final l in linesOf(from)) {
    final image = RegExp(r'^//.*--image@[^:]*:(.+)$').firstMatch(l)?[1]?.trim();
    if (image == null ||
        isRooted(image) ||
        !existsFile('$home/$image') ||
        (!overwrite && existsFile('$dir/$image'))) {
      continue;
    }
    makeFolderOf('$dir/$image');
    copyFile('$home/$image', '$dir/$image');
  }
}

/// Copies the files the engine reads beside an effect's file (see codeBeside in effect_code_cards.dart).
/// That is an ISF's .vs, its lines of first.tsv (under the new name, appended to the folder's), and the images its
/// header names (copied only where none exists, so nothing is overwritten).
void _beside(String from, String to, String dir) {
  final home = from.substring(0, from.lastIndexOf('/')),
      name = from
          .split('/')
          .last
          .replaceFirst(RegExp(r'~[0-9]+(?=\.[^.]+$)'), '');
  final stem = to.substring(0, to.lastIndexOf('.'));
  if (from.endsWith('.fs')) {
    final vs = from.replaceFirst(RegExp(r'\.fs$'), '.vs');
    if (existsFile(vs) && !existsFile('$dir/$stem.vs')) {
      copyFile(vs, '$dir/$stem.vs');
    }
  }
  final first = '$home/first.tsv';
  if (existsFile(first)) {
    final lines = [
      for (final l in linesOf(first))
        if (l.split('\t').first == name)
          [to, ...l.split('\t').skip(1)].join('\t'),
    ];
    if (lines.isNotEmpty) {
      appendText('$dir/first.tsv', '${lines.join('\n')}\n');
    }
  }
  shelfCopyImages(from, dir, overwrite: false);
}

/// Renames a file the user added to [to] by writing the name beside it. Returns why it failed, or '' on success.
/// [taken] holds the shelf's names except this file's own.
String shelfRename(
  WorkspaceController ws,
  String file,
  String to,
  Iterable<String> taken,
) {
  to = to.trim();
  if (!shelfAdded(file)) return 'Only what you added can be renamed';
  if (_whyNot(to, taken) case final why when why.isNotEmpty) return why;
  shelfSidecarWrite(file, to);
  ws.inside?.forgetFolders();
  ws.reread();
  return '';
}
