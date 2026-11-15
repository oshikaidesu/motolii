// The files in a folder on disk, for panels that list what a shelf or an agent left there.
import 'dart:io';

/// The paths of the files directly in [folder] (not its subfolders), or none when there is no such folder.
List<String> filesIn(String folder) {
  final dir = Directory(folder);
  if (!dir.existsSync()) return const [];
  return [for (final e in dir.listSync().whereType<File>()) e.path];
}
