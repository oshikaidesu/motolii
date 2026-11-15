// What a folder on the disk holds, as the panels read it: the entries they keep, whether a folder is there, and the
// home folder. Panels import this instead of dart:io.
import 'dart:io';

String? get homeFolderEnv => Platform.environment['HOME'];

/// The entries of [folder] that [make] keeps, in the order the disk lists them. [make] is given each entry, and a way to
/// read its size when it needs one. A folder that cannot be read has no entries.
Future<List<T>> entriesKept<T>(
  String folder,
  Future<T?> Function(
    ({String path, bool folder, bool file}) e,
    Future<int> Function() size,
  )
  make,
) async {
  try {
    final out = <T>[];
    for (final e in await Directory(folder).list().toList()) {
      final kept = await make((
        path: e.path,
        folder: e is Directory,
        file: e is File,
      ), () async => (await e.stat()).size);
      if (kept != null) out.add(kept);
    }
    return out;
  } on FileSystemException {
    return [];
  }
}

bool folderThere(String folder) => Directory(folder).existsSync();

List<String> filesInNow(String folder) => [
  for (final e in Directory(folder).listSync())
    if (e is File) e.path,
];

String folderOfFile(String path) => File(path).parent.path;
