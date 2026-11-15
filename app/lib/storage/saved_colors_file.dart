// The Colors shelf's saved colors on disk (~/.motolii/colors.json) and the photos its palettes were taken from.
// Panels import this instead of dart:io.
import 'dart:io';
import 'dart:typed_data';

import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/storage/json_file.dart' show fileJson, fileKeep;

File _saved = File('$homeFolder/.motolii/colors.json');

/// Sets where the saved colors are stored. A test points it at a file of its own before it opens a window.
void colorsAt(String path) => _saved = File(path);

/// The saved colors as JSON, or null when there is no file or it is not JSON.
Object? savedColorsJson() => fileJson(_saved);

/// Writes [text] as the saved colors.
void keepSavedColors(String text) => fileKeep(_saved, text);

/// The bytes of the photo at [path].
Future<Uint8List> photoBytes(String path) => File(path).readAsBytes();

/// Copies the photo at [path] beside the user's palettes, as ~/.motolii/references/<time>_<[name]>. Returns the copy's path.
String keepReference(String path, String name) {
  final kept = Directory('$homeFolder/.motolii/references')
    ..createSync(recursive: true);
  final copy = '${kept.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
  File(path).copySync(copy);
  return copy;
}
