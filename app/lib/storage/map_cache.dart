// Where a shelf's map is kept between sessions: its positions as JSON, one file for each shelf.
import 'package:motolii/storage/host_platform.dart' show homeFolder;

import 'dart:io';

/// Where the maps are cached between sessions. A test points it elsewhere with [shelfMapsAt], so the user's own
/// cache is left alone.
Directory _cacheFolder = Directory('$homeFolder/Library/Caches/Motolii');

/// Sets where the maps are cached between sessions. A test points it at a folder of its own.
void shelfMapsAt(Directory d) => _cacheFolder = d;

Future<String> readMapCache(String name) =>
    File('${_cacheFolder.path}/map_$name.json').readAsString();

Future<void> writeMapCache(String name, String text) async {
  final f = File('${_cacheFolder.path}/map_$name.json');
  f.parent.createSync(recursive: true);
  await f.writeAsString(text);
}
