// The Motolii projects on disk: listing them in a folder, copying one, and moving one to the Trash. Panels import this
// instead of dart:io.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder, slashed;

typedef ProjectFile = ({String path, DateTime modified, int size});

/// The projects directly in [folder]: each file whose name ends in .motolii, with when it was last changed and its size.
/// Throws when [folder] cannot be listed.
List<ProjectFile> projectFilesIn(String folder) {
  final found = <ProjectFile>[];
  for (final f in Directory(folder).listSync().whereType<File>()) {
    if (!f.path.endsWith('.motolii')) continue;
    final s = f.statSync();
    found.add((path: slashed(f.path), modified: s.modified, size: s.size));
  }
  return found;
}

/// Bundled starter projects in [folder], sorted by filename. Empty if [folder] does not exist.
List<ProjectFile> sampleProjectsIn(String folder) {
  final dir = Directory(folder);
  if (!dir.existsSync()) return const [];
  final found = projectFilesIn(folder)
    ..sort((a, b) => a.path.compareTo(b.path));
  return found;
}

/// Copies the file at [from] to [to].
void copyProjectFile(String from, String to) => File(from).copySync(to);

/// Moves the file at [from] to [to]. False if it could not be moved.
bool moveProjectFile(String from, String to) {
  try {
    File(from).renameSync(to);
  } catch (_) {
    return false;
  }
  return true;
}

/// The user's Trash folder, as the Finder keeps it.
String trashFolder() => '$homeFolder/.Trash';

/// Moves [file] to Windows' Recycle Bin, as Explorer's Delete does (.NET's FileSystem.DeleteFile with SendToRecycleBin).
/// False if it could not be moved.
bool recycleFile(String file) {
  try {
    return Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('${file.replaceAll('/', r'\').replaceAll("'", "''")}', 'OnlyErrorDialogs', 'SendToRecycleBin')",
        ]).exitCode ==
        0;
  } on ProcessException {
    return false;
  }
}
