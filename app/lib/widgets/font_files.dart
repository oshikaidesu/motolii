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

/// One variable-font axis: its four-letter tag (wght, wdth, slnt, GRAD, ...), the name the font gives it, and its
/// range and default.
typedef FontAxis = ({
  String tag,
  String name,
  double min,
  double def,
  double max,
});

final _axes = <String, Future<List<FontAxis>>>{};

/// The variable-font axes of the font file [path] that a font shows to people, as its fvar table lists them; empty
/// for a font that has none or a file that cannot be read. In a collection (.ttc) the first font's. The layout is the
/// OpenType specification's: the table directory (offset 4 numTables, records of 16 bytes from 12 with the offset at
/// +8), the TTC header (offset 12, the first font's offset), fvar (axesArrayOffset at 4, axisCount at 8, axisSize at
/// 10; each axis a tag, min, default and max as 16.16 Fixed, flags at 16 and axisNameID at 18; an axis flagged
/// HIDDEN_AXIS, 0x0001, is one the specification says not to show) and name (count at 2, stringOffset at 4, records
/// of 12 bytes from 6: platformID, encodingID, languageID, nameID, length, offset). An axis without a name keeps its
/// tag.
Future<List<FontAxis>> fontFileAxes(String path) =>
    _axes[path] ??= File(path)
        .readAsBytes()
        .then(_readAxes, onError: (Object _) => const <FontAxis>[]);

List<FontAxis> _readAxes(Uint8List bytes) {
  try {
    final b = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    final font = tag(0) == 'ttcf' ? b.getUint32(12) : 0;
    final tables = {
      for (var i = 0, n = b.getUint16(font + 4); i < n; i++)
        tag(font + 12 + 16 * i): b.getUint32(font + 12 + 16 * i + 8),
    };
    final fvar = tables['fvar'];
    if (fvar == null) return const [];
    final size = b.getUint16(fvar + 10);
    double fixed(int at) => b.getInt32(at) / 65536;
    return [
      for (
        var a = 0, at = fvar + b.getUint16(fvar + 4);
        a < b.getUint16(fvar + 8);
        a++, at += size
      )
        if (b.getUint16(at + 16) & 1 == 0)
          (
            tag: tag(at),
            name:
                _name(bytes, b, tables['name'], b.getUint16(at + 18)) ??
                tag(at),
            min: fixed(at + 4),
            def: fixed(at + 8),
            max: fixed(at + 12),
          ),
    ];
  } on RangeError {
    // A damaged file lists no axes.
  }
  return const [];
}

/// The string [id] of the name table at [table]: Windows' US English first, then any Windows one (UTF-16BE), then a
/// Macintosh one (Roman, read as Latin-1).
String? _name(Uint8List bytes, ByteData b, int? table, int id) {
  if (table == null) return null;
  final strings = table + b.getUint16(table + 4);
  String? windows, english, mac;
  for (var i = 0, n = b.getUint16(table + 2); i < n; i++) {
    final r = table + 6 + 12 * i;
    if (b.getUint16(r + 6) != id) continue;
    final from = strings + b.getUint16(r + 10), length = b.getUint16(r + 8);
    switch (b.getUint16(r)) {
      case 3:
        final s = String.fromCharCodes([
          for (var k = 0; k + 1 < length; k += 2) b.getUint16(from + k),
        ]);
        windows ??= s;
        if (b.getUint16(r + 4) == 0x409) english ??= s;
      case 1:
        mac ??= String.fromCharCodes(bytes.sublist(from, from + length));
    }
  }
  return english ?? windows ?? mac;
}
