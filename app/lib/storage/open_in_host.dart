// Opens a file or a folder with the Mac's `open` command, as the Finder does. Panels import this instead of dart:io.
import 'dart:io';

/// Opens [path] in the app that owns it.
Future<ProcessResult> openInHost(String path) => Process.run('open', [path]);

/// Opens the folder [path] in the Finder, making it, and any folder above it, first if it is not there.
Future<ProcessResult> openFolderInHost(String path) {
  final folder = Directory(path)..createSync(recursive: true);
  return Process.run('open', [folder.path]);
}

/// Asks the user to pick a folder with the system dialog. Returns the path, or null if cancelled.
Future<String?> pickFolder({String prompt = 'Choose a folder'}) async {
  final r = await Process.run('osascript', [
    '-e',
    'set f to choose folder with prompt "$prompt"\nreturn POSIX path of f',
  ]);
  final path = (r.stdout as String).trim();
  return path.isEmpty ? null : path.replaceFirst(RegExp(r'/$'), '');
}
