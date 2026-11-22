// Where the engine, the shelves, the user's own folder and the project to open are on disk.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder, slashed;

/// The engine folder: --dart-define=MOTOLII_DIR=/path/to/motolii/engine, then a bundled app's Resources/engine
/// (macOS .app) or adjacent engine/ (Windows release), or else the nearest engine/ found by walking up from cwd/exe.
final String motoliiDir = () {
  const given = String.fromEnvironment('MOTOLII_DIR');
  if (given.isNotEmpty) return given;
  final exeDir = File(Platform.resolvedExecutable).parent.absolute;
  for (final bundled in [
    // macOS standalone Motolii.app/Contents/Resources/engine
    '${exeDir.parent.path}/Resources/engine',
    // Windows standalone release folder <exeDir>/engine
    '${exeDir.path}/engine',
  ]) {
    if (Directory('$bundled/out/filament_webgpu').existsSync()) {
      return slashed(bundled);
    }
  }
  for (final from in [Directory.current, exeDir]) {
    for (var d = from.absolute; ; d = d.parent) {
      if (File('${d.path}/engine/edit.sh').existsSync()) {
        return slashed('${d.path}/engine');
      }
      if (d.parent.path == d.path) break;
    }
  }
  return 'engine';
}();

/// The extension of the engine library the build writes to `engine/out/libmotolii.<extension>`.
final String libraryExtension = Platform.isWindows ? 'dll' : 'dylib';

/// Path to the bundled engine library inside a standalone release package, or null in dev repo builds.
final String? bundledEngineLibrary = () {
  final exeDir = File(Platform.resolvedExecutable).parent.absolute;
  final candidates = Platform.isMacOS
      ? ['${exeDir.parent.path}/Frameworks/libmotolii.dylib']
      : Platform.isWindows
      ? [
          '${exeDir.path}/libmotolii.dll',
          '${exeDir.path}/engine/out/libmotolii.dll',
        ]
      : const <String>[];
  for (final c in candidates) {
    if (File(c).existsSync()) return slashed(c);
  }
  return null;
}();

/// The shelves that ship with Motolii (effects, create, skins…): shelves/, next to engine/.
final String motoliiShelves =
    '${Directory(motoliiDir).absolute.parent.path}/shelves';

/// The user's own shelf folder, with one subfolder per shelf: MOTOLII_OWN, or %APPDATA%/Motolii on Windows, or
/// ~/Library/Application Support/Motolii (the same rule as the engine's doc_folders).
String get motoliiOwn =>
    Platform.environment['MOTOLII_OWN'] ??
    (Platform.isWindows
        ? '${slashed(Platform.environment['APPDATA']!)}/Motolii'
        : '$homeFolder/Library/Application Support/Motolii');

/// The project the app opens: --dart-define=MOTOLII_DOC=/path/to.motolii, or the MOTOLII_DOC environment variable of
/// the launch (so a built app opens any project without being built again), or engine/out/skin.motolii in dev checkouts,
/// or a writable Projects folder inside [motoliiOwn] when running from a standalone app bundle.
String get motoliiDoc {
  const given = String.fromEnvironment('MOTOLII_DOC');
  final launched = Platform.environment['MOTOLII_DOC'] ?? '';
  if (given.isNotEmpty) return given;
  if (launched.isNotEmpty) return launched;
  final devSkin = '$motoliiDir/out/skin.motolii';
  if (bundledEngineLibrary == null && File(devSkin).existsSync()) {
    return devSkin;
  }
  final projectsDir = Directory('$motoliiOwn/Projects')
    ..createSync(recursive: true);
  return slashed('${projectsDir.path}/Untitled.motolii');
}

/// The separator of a PATH value's folders.
final String pathSeparator = Platform.isWindows ? ';' : ':';

/// The full path of the program [name], found the way execvp does: the first regular file named [name] with an execute
/// bit set, in the folders of [path] (a [pathSeparator]-separated PATH value, in order; empty entries are skipped), then
/// in [fallbacks]. On Windows the file is [name].exe, and any file counts. A [name] containing '/' is returned as it
/// is; so is [name] when nothing matches.
/// An app started from Finder has PATH=/usr/bin:/bin, which has no Homebrew in it.
String findProgram(
  String name,
  String path, {
  List<String> fallbacks = const ['/opt/homebrew/bin', '/usr/local/bin'],
}) {
  if (name.contains('/')) return name;
  final named = Platform.isWindows ? '$name.exe' : name;
  for (final folder in [...path.split(pathSeparator), ...fallbacks]) {
    if (folder.isEmpty) continue;
    final file = folder.endsWith('/') ? '$folder$named' : '$folder/$named';
    final stat = FileStat.statSync(file);
    if (stat.type == FileSystemEntityType.file &&
        (Platform.isWindows || stat.mode & 0x49 != 0)) {
      return file;
    }
  }
  return name;
}
