// Opens a file or a folder as the system's file manager does: the Mac's `open` command, Windows' Explorer. Panels
// import this instead of dart:io.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show hostIsWindows, slashed;

/// Opens [path] in the app that owns it.
Future<ProcessResult> openInHost(String path) => hostIsWindows
    ? Process.run('explorer', [path.replaceAll('/', r'\')])
    : Process.run('open', [path]);

/// Opens the folder [path] in the Finder (Explorer on Windows), making it, and any folder above it, first if it is not
/// there.
Future<ProcessResult> openFolderInHost(String path) {
  final folder = Directory(path)..createSync(recursive: true);
  return openInHost(folder.path);
}

/// Asks the user to pick a folder with the system dialog. Returns the path, or null if cancelled.
Future<String?> pickFolder({String prompt = 'Choose a folder'}) async {
  final r = hostIsWindows
      // Windows' own folder dialog, through PowerShell (which every Windows has), its answer in UTF-8.
      ? await Process.run('powershell', [
          '-NoProfile',
          '-STA',
          '-Command',
          '[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName System.Windows.Forms; '
              r'$d=New-Object System.Windows.Forms.FolderBrowserDialog; '
              "\$d.Description='${prompt.replaceAll("'", "''")}'; "
              r"if($d.ShowDialog() -eq 'OK'){$d.SelectedPath}",
        ], stdoutEncoding: utf8)
      : await Process.run('osascript', [
          '-e',
          'set f to choose folder with prompt "$prompt"\nreturn POSIX path of f',
        ]);
  final path = slashed((r.stdout as String).trim());
  return path.isEmpty ? null : path.replaceFirst(RegExp(r'/$'), '');
}
