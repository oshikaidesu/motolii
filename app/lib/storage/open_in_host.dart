// Opens a file or a folder as the system's file manager does: the Mac's `open` command, Windows' Explorer. Panels
// import this instead of dart:io.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/host_platform.dart'
    show homeFolder, hostHasProgram, hostIsMacOS, hostIsWindows, slashed;

/// Opens [path] in the app that owns it.
Future<ProcessResult> openInHost(String path) => hostIsWindows
    ? Process.run('explorer', [path.replaceAll('/', r'\')])
    : Process.run('open', [path]);

({String name, List<String> command})? _detectedEditor() {
  final env =
      (Platform.environment['VISUAL'] ?? Platform.environment['EDITOR'] ?? '')
          .trim();
  if (env.isNotEmpty) {
    final parts = env.split(RegExp(r'\s+'));
    if (parts.isNotEmpty && hostHasProgram(parts.first)) {
      final base = slashed(parts.first).split('/').last;
      return (name: base, command: parts);
    }
  }
  if (hostIsMacOS) {
    final home = homeFolder;
    const apps = [
      ('Cursor', 'Cursor.app'),
      ('VS Code', 'Visual Studio Code.app'),
      ('Zed', 'Zed.app'),
      ('Windsurf', 'Windsurf.app'),
      ('Antigravity', 'Antigravity.app'),
    ];
    for (final (name, bundle) in apps) {
      for (final root in [
        '/Applications',
        if (home != null) '$home/Applications',
      ]) {
        if (Directory('$root/$bundle').existsSync()) {
          return (name: name, command: ['open', '-a', '$root/$bundle']);
        }
      }
    }
  }
  const clis = [
    ('Cursor', 'cursor'),
    ('VS Code', 'code'),
    ('Zed', 'zed'),
    ('Windsurf', 'windsurf'),
  ];
  for (final (name, bin) in clis) {
    if (hostHasProgram(bin)) return (name: name, command: [bin]);
  }
  return null;
}

/// Display name of the external IDE detected on this machine (e.g. `Cursor`, `VS Code`, `Zed`).
String externalEditorName() => _detectedEditor()?.name ?? 'Editor';

/// Opens [path] in the detected external IDE, falling back to the OS default app.
Future<ProcessResult> openInEditor(String path) {
  final ed = _detectedEditor();
  if (ed == null) return openInHost(path);
  return Process.run(ed.command.first, [...ed.command.skip(1), path]);
}

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
