// The font map: each family's sample word drawn by the engine, and where FontCLIP places it, as FontMap does.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiQuestions;
import 'package:motolii/workspace/dock/dock_files.dart' show dockRead;
import 'package:motolii/workspace/dock/dock_map.dart';

/// The size in pixels of a font's dot on the map.
///
/// The engine draws each family's sample word into [fontDotsDrawn], because not every font is loaded in Flutter.
/// The embedding input is that image at half size, where each pixel averages four.
const fontDotSize = (96, 32);
final fontDotsDrawn = <String, Uint8List?>{};
Future<void>? _drawing;
Future<void> drawFontDots(Motolii m, List<String> files) => _drawing ??= Zone.root.run<Future<void>>(() async {
  // Runs once, like fontsRead.
  final byWord = <String, List<String>>{};
  for (final f in files) {
    (byWord[_wordOf(f, 0)] ??= []).add(f);
  }
  for (final MapEntry(key: w, value: some) in byWord.entries) {
    final drawn = await m.typePictures(some, w, fontDotSize.$1, fontDotSize.$2);
    for (final (i, f) in some.indexed) {
      fontDotsDrawn[f] = drawn[i];
    }
  }
  dockRead.value++;
});

/// Sample text for fonts that cannot show Latin letters, keyed by file. Filled by fontsRead.
var fontSamples = const <String, String>{};

/// The sample text for a font: line 0 is for its dot on the map, and lines 1 and 2 are the two lines FontMap uses for FontCLIP.
///
/// A font that cannot show Latin letters uses its own sample text. Line 0 is its first word, and lines 1 and 2 are the
/// two halves of its words. For a script with no spaces between words the halves are of its letters.
String _wordOf(String path, int line) {
  final own = fontSamples[path];
  if (own == null) return const ['Motion', 'Hamburge', 'fonstiv'][line];
  final words = own.split(' '), letters = own.runes.toList();
  final some = words.length > 1 ? words : [for (final r in letters) String.fromCharCode(r)], half = (some.length / 2).ceil(), by = words.length > 1 ? ' ' : '';
  return switch (line) {
    0 => words.length > 1 ? words.first : some.take(6).join(),
    1 => some.take(half).join(by),
    _ => some.skip(half).join(by),
  };
}

/// Embeds each font with FontCLIP ([model]) from a specimen image drawn as FontMap draws it for FontCLIP.
///
/// FontMap's code is tfrere/fontmap, pipeline/render/2-generate-svgs.mjs, generateEmbeddingSVG. The specimen has
/// "Hamburge" over "fonstiv" in a 224 pixel square with a 12 pixel margin. Each line fits in its half, at most 200 wide
/// and 85 tall, is set at size 75 or smaller and is centred on its half. The text is black on white.
/// Fonts are embedded 32 at a time, and an entry is null when the font could not be drawn.
Future<List<Float32List?>> byFontClip(Motolii m, String model, List<String> files) async {
  String key(String f) {
    // The cache key is the model, the font and its modification time, as for the effect thumbnails, so only a new font is embedded.
    try {
      return '$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}\n${_wordOf(f, 1)} ${_wordOf(f, 2)}';
    } catch (_) {
      return '';
    }
  }

  final out = [for (final f in files) dockLookKept(key(f))],
      missing = [
        for (final (k, f) in files.indexed)
          if (out[k] == null && key(f).isNotEmpty) f,
      ];
  if (missing.isEmpty) return out;
  final lines = [
        for (final _ in const [1, 2]) List<Uint8List?>.filled(missing.length, null),
      ],
      byWords = <(String, String), List<int>>{};
  for (final (k, f) in missing.indexed) {
    (byWords[(_wordOf(f, 1), _wordOf(f, 2))] ??= []).add(k);
  }
  for (final MapEntry(key: (a, b), value: ks) in byWords.entries) {
    // A font with its own sample text uses its own two lines.
    for (final (j, w) in [a, b].indexed) {
      final drawn = await m.typePictures([for (final k in ks) missing[k]], w, 202, 87, most: 75);
      for (final (i, k) in ks.indexed) {
        lines[j][k] = drawn[i];
      }
    }
  }
  for (var i = 0; i < missing.length; i += 32) {
    final some = [for (var k = i; k < missing.length && k < i + 32; k++) k],
        drawn = [
          for (final k in some)
            if (lines[0][k] != null && lines[1][k] != null) k,
        ];
    final told = drawn.isEmpty ? null : await m.likeness(model, [for (final k in drawn) _specimen(lines[0][k]!, lines[1][k]!)]);
    for (final (j, k) in drawn.indexed) {
      if (told?[j] case final t?) {
        dockLookKeep(key(missing[k]), t);
        out[files.indexOf(missing[k])] = t;
      }
    }
  }
  return out;
}

Uint8List _specimen(Uint8List top, Uint8List bottom) {
  final px = Uint8List(224 * 224 * 4)..fillRange(0, 224 * 224 * 4, 255);
  for (final (line, g) in [top, bottom].indexed) {
    // Centres the line on the middle of its half.
    final y0 = 12 + 100 * line + 50 - 87 ~/ 2, x0 = 112 - 202 ~/ 2;
    for (var y = 0; y < 87; y++) {
      for (var x = 0; x < 202; x++) {
        final at = ((y0 + y) * 224 + x0 + x) * 4;
        px[at] = px[at + 1] = px[at + 2] = 255 - g[y * 202 + x];
      }
    }
  }
  return px;
}
