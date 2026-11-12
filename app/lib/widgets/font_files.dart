// Font files that are not bundled with the app: set text in one, and read the variable-font axes it has.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

/// The font files handed to Flutter so far. Flutter keeps a loaded font for as long as the app runs, so this set
/// lasts as long, whichever window asked.
final _loaded = <String>{};

/// Returns the font family that sets text in the font file [path], loading its bytes the first time it is asked.
/// FontLoader is Flutter's way to use a font that is not bundled with the app. Until the file is read, and if it has
/// gone, text falls back to the style's fallback families.
String fontFileFamily(String path) {
  if (_loaded.add(path)) {
    Zone.root.run(
      () =>
          (FontLoader(path)
                ..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
              .load()
              .catchError((Object _) {}),
    );
  }
  return path;
}

/// One variable-font axis: its four-letter tag (wght, wdth, slnt, ...) and its range and default.
typedef FontAxis = ({String tag, double min, double def, double max});

final _axes = <String, Future<List<FontAxis>>>{};

/// The variable-font axes of the font file [path], as its fvar table lists them; empty for a font that has none
/// or a file that cannot be read. In a collection (.ttc) the first font's. The layout is the OpenType
/// specification's: the table directory (offset 4 numTables, records of 16 bytes from 12 with the offset at +8),
/// the TTC header (offset 12, the first font's offset) and fvar (axesArrayOffset at 4, axisCount at 8, axisSize at
/// 10; each axis a tag and min, default and max as 16.16 Fixed).
Future<List<FontAxis>> fontFileAxes(String path) =>
    _axes[path] ??= File(path)
        .readAsBytes()
        .then(_readAxes, onError: (Object _) => const <FontAxis>[]);

List<FontAxis> _readAxes(Uint8List bytes) {
  try {
    final b = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    final font = tag(0) == 'ttcf' ? b.getUint32(12) : 0;
    for (var i = 0, n = b.getUint16(font + 4); i < n; i++) {
      final record = font + 12 + 16 * i;
      if (tag(record) != 'fvar') continue;
      final fvar = b.getUint32(record + 8), size = b.getUint16(fvar + 10);
      double fixed(int at) => b.getInt32(at) / 65536;
      return [
        for (
          var a = 0, at = fvar + b.getUint16(fvar + 4);
          a < b.getUint16(fvar + 8);
          a++, at += size
        )
          (
            tag: tag(at),
            min: fixed(at + 4),
            def: fixed(at + 8),
            max: fixed(at + 12),
          ),
      ];
    }
  } on RangeError {
    // A damaged file lists no axes.
  }
  return const [];
}
