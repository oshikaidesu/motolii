// The skins on disk: the folders they are read from, each skin's theme file, and watching that file for changes.
import 'dart:async';
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder;

/// The folders skins are read from, later ones winning when two skins have the same name.
///
/// The user's own folder wins over shelves/skins. ~/.motolii/skins is an older location, still read so that a skin worn
/// from there is not lost.
List<String> skinFolders({required String shelves, required String own}) => [
  '$shelves/skins',
  '$homeFolder/.motolii/skins',
  '$own/skins',
];

/// The folder of each skin, by skin name. A folder counts as a skin when it holds a theme.xml.
Map<String, String> skinFoldersByName({
  required String shelves,
  required String own,
}) {
  final by = <String, String>{};
  for (final at in skinFolders(shelves: shelves, own: own)) {
    try {
      for (final d in Directory(at).listSync().whereType<Directory>()) {
        if (File('${d.path}/theme.xml').existsSync()) {
          by[d.uri.pathSegments[d.uri.pathSegments.length - 2]] = d.path;
        }
      }
    } catch (_) {
      // A folder that is not there has no skins.
    }
  }
  return by;
}

/// Calls [changed] whenever the file at [path] is written. Its folder is made first.
/// Null when the folder cannot be watched, and the file is then read once.
StreamSubscription<dynamic>? watchFile(String path, void Function() changed) {
  try {
    final file = File(path);
    file.parent.createSync(recursive: true);
    return file.parent
        .watch()
        .where((e) => e.path == file.path)
        .listen((_) => changed());
  } catch (_) {
    // A folder that cannot be watched is read once.
    return null;
  }
}
