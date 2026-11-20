// What the host is: its system, its processor, its login shell and its environment. Panels import this instead of
// dart:io and dart:ffi.
import 'dart:ffi' show Abi;
import 'dart:io';

bool get hostIsWindows => Platform.isWindows;

bool get hostIsMacOS => Platform.isMacOS;

/// The system's name, as a registry spells it: `darwin` on macOS, else Dart's own name.
String get hostOperatingSystem =>
    Platform.isMacOS ? 'darwin' : Platform.operatingSystem;

/// Whether the processor is arm64.
bool get hostIsArm64 => '${Abi.current()}'.contains('arm64');

/// The login shell, or /bin/sh when the launch has none.
String get loginShell => Platform.environment['SHELL'] ?? '/bin/sh';

/// The user's home folder, from the launch's environment: HOME, or USERPROFILE on Windows, where HOME is usually not
/// set. With forward slashes ([slashed]).
String? get homeFolder {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  return home == null ? null : slashed(home);
}

/// [path] with forward slashes, as the engine writes every path (generic_string) and as Windows takes them too. Paths
/// the system gives (environment variables, the temp folder, a folder's listing) come through this, so the rest of the
/// app can cut and join paths at '/' on either system.
String slashed(String path) =>
    Platform.isWindows ? path.replaceAll(r'\', '/') : path;

/// Whether [path] starts at the root of a disk: /… on the Mac, C:/… or C:\… on Windows.
bool isRooted(String path) =>
    path.startsWith('/') ||
    (Platform.isWindows && RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path));

/// The folders Windows keeps fonts in: the system's, and the user's own. None elsewhere.
List<String> get windowsFontFolders => Platform.isWindows
    ? [
        slashed('${Platform.environment['WINDIR']}/Fonts'),
        slashed(
          '${Platform.environment['LOCALAPPDATA']}/Microsoft/Windows/Fonts',
        ),
      ]
    : const [];

/// The system's temporary folder.
String get tempFolder => Directory.systemTemp.path;

/// Whether [name] exists as an executable in PATH or common user tool folders.
bool hostHasProgram(String name) {
  if (name.isEmpty) return false;
  if (name.contains('/') || name.contains(r'\')) {
    final s = FileStat.statSync(name);
    return s.type == FileSystemEntityType.file &&
        (Platform.isWindows || s.mode & 0x49 != 0);
  }
  final sep = Platform.isWindows ? ';' : ':';
  final named = Platform.isWindows ? '$name.exe' : name;
  final home = homeFolder;
  final dirs = <String>[
    ...(Platform.environment['PATH'] ?? '').split(sep),
    if (!Platform.isWindows) ...[
      '/opt/homebrew/bin',
      '/usr/local/bin',
      if (home != null) ...[
        '$home/.local/bin',
        '$home/.cargo/bin',
        '$home/.bun/bin',
      ],
    ],
  ];
  for (final d in dirs) {
    if (d.isEmpty) continue;
    final path = d.endsWith('/') ? '$d$named' : '$d/$named';
    final s = FileStat.statSync(path);
    if (s.type == FileSystemEntityType.file &&
        (Platform.isWindows || s.mode & 0x49 != 0)) {
      return true;
    }
  }
  return false;
}
