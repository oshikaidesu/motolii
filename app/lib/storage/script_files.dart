// Files the Create and Effects shelves read and write beside their items: the code a user pasted, the names given to
// the user's files, and the create scripts' folders. Panels import this instead of dart:io.
import 'dart:io';
import 'dart:typed_data';

/// Resolves [target] relative to [baseFile]'s folder (when not absolute) and
/// returns its raw bytes, or null when missing or unreadable.
Uint8List? readRelativeBytes(String baseFile, String target) {
  final trimmed = target.trim();
  if (trimmed.isEmpty) return null;
  try {
    final f = trimmed.startsWith('/')
        ? File(trimmed)
        : (baseFile.isNotEmpty
              ? File('${File(baseFile).parent.path}/$trimmed')
              : File(trimmed));
    if (!f.existsSync()) return null;
    return f.readAsBytesSync();
  } catch (_) {
    return null;
  }
}

/// The paths of the files under [folder], down into its subfolders when [recursive]. None when there is no such folder.
List<String> filesUnder(String folder, {bool recursive = false}) {
  final d = Directory(folder);
  if (!d.existsSync()) return const [];
  return [
    for (final f in d.listSync(recursive: recursive).whereType<File>()) f.path,
  ];
}

/// The lines of the text file at [path].
List<String> linesOf(String path) => File(path).readAsLinesSync();

/// The text of the file at [path].
String textOf(String path) => File(path).readAsStringSync();

/// When the file at [path] was last written.
DateTime writtenAt(String path) => File(path).lastModifiedSync();

/// The folder two levels above [path] (the folder that holds the folder of a file).
String folderTwoUp(String path) => File(path).parent.parent.path;

/// The name the user gave a file, kept beside it in [sidecar], or null when there is none.
String? sidecarText(File sidecar) =>
    sidecar.existsSync() ? sidecar.readAsStringSync() : null;

/// Writes [text] as the name kept in [sidecar].
void writeSidecar(File sidecar, String text) => sidecar.writeAsStringSync(text);

/// Removes the name kept in [sidecar], if there is one.
void deleteSidecar(File sidecar) {
  if (sidecar.existsSync()) sidecar.deleteSync();
}
