// Where the engine, the shelves, the user's own folder and the project to open are on disk.
import 'dart:io';

/// The engine folder: --dart-define=MOTOLII_DIR=/path/to/motolii/engine, or else the nearest engine/ found by walking up
/// from the working directory or from the executable (the app is built under app/build/).
final String motoliiDir = () {
  const given = String.fromEnvironment('MOTOLII_DIR');
  if (given.isNotEmpty) return given;
  for (final from in [
    Directory.current,
    File(Platform.resolvedExecutable).parent,
  ]) {
    for (var d = from.absolute; ; d = d.parent) {
      if (File('${d.path}/engine/edit.sh').existsSync()) {
        return '${d.path}/engine';
      }
      if (d.parent.path == d.path) break;
    }
  }
  return 'engine';
}();

/// The shelves that ship with Motolii (effects, create, skins…): shelves/, next to engine/.
final String motoliiShelves =
    '${Directory(motoliiDir).absolute.parent.path}/shelves';

/// The user's own shelf folder, with one subfolder per shelf: MOTOLII_OWN, or ~/Library/Application Support/Motolii (the same rule as the engine's doc_folders).
String get motoliiOwn =>
    Platform.environment['MOTOLII_OWN'] ??
    '${Platform.environment['HOME']}/Library/Application Support/Motolii';

/// The project the app opens: --dart-define=MOTOLII_DOC=/path/to.motolii, or the MOTOLII_DOC environment variable of
/// the launch (so a built app opens any project without being built again), or else engine/out/skin.motolii.
String get motoliiDoc {
  const given = String.fromEnvironment('MOTOLII_DOC');
  final launched = Platform.environment['MOTOLII_DOC'] ?? '';
  return given.isNotEmpty
      ? given
      : launched.isNotEmpty
      ? launched
      : '$motoliiDir/out/skin.motolii';
}

/// The full path of the program [name], found the way execvp does: the first regular file named [name] with an execute
/// bit set, in the folders of [path] (a ':'-separated PATH value, in order; empty entries are skipped), then in
/// [fallbacks]. A [name] containing '/' is returned as it is; so is [name] when nothing matches.
/// An app started from Finder has PATH=/usr/bin:/bin, which has no Homebrew in it.
String findProgram(
  String name,
  String path, {
  List<String> fallbacks = const ['/opt/homebrew/bin', '/usr/local/bin'],
}) {
  if (name.contains('/')) return name;
  for (final folder in [...path.split(':'), ...fallbacks]) {
    if (folder.isEmpty) continue;
    final file = folder.endsWith('/') ? '$folder$name' : '$folder/$name';
    final stat = FileStat.statSync(file);
    if (stat.type == FileSystemEntityType.file && stat.mode & 0x49 != 0) {
      return file;
    }
  }
  return name;
}
