// Where a font goes on the Fonts shelf's map: by how FontCLIP sees its specimen, as FontMap does, or by its dot.
import 'dart:io';
import 'dart:typed_data';

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';

/// Embeds each font with FontCLIP ([model]) from a specimen image drawn as FontMap draws it for FontCLIP.
///
/// FontMap's code is tfrere/fontmap, pipeline/render/2-generate-svgs.mjs, generateEmbeddingSVG. The specimen has
/// "Hamburge" over "fonstiv" in a 224 pixel square with a 12 pixel margin. Each line fits in its half, at most 200 wide
/// and 85 tall, is set at size 75 or smaller and is centred on its half. The text is black on white.
/// Fonts are embedded 32 at a time, and an entry is null when the font could not be drawn.
/// [wordOf] gives the sample text of a font: its lines 1 and 2 are the two lines of the specimen.
Future<List<Float32List?>> byFontClip(
  Motolii m,
  String model,
  List<String> files,
  String Function(String path, int line) wordOf,
) async {
  String key(String f) {
    // The cache key is the model, the font and its modification time, as for the effect thumbnails, so only a new font is embedded.
    try {
      return '$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}\n${wordOf(f, 1)} ${wordOf(f, 2)}';
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
        for (final _ in const [1, 2])
          List<Uint8List?>.filled(missing.length, null),
      ],
      byWords = <(String, String), List<int>>{};
  for (final (k, f) in missing.indexed) {
    (byWords[(wordOf(f, 1), wordOf(f, 2))] ??= []).add(k);
  }
  for (final MapEntry(key: (a, b), value: ks) in byWords.entries) {
    // A font with its own sample text uses its own two lines.
    for (final (j, w) in [a, b].indexed) {
      final drawn = await m.typePictures(
        [for (final k in ks) missing[k]],
        w,
        202,
        87,
        most: 75,
      );
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
    final told = drawn.isEmpty
        ? null
        : await m.likeness(model, [
            for (final k in drawn) _specimen(lines[0][k]!, lines[1][k]!),
          ]);
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

/// A font's kind on the map. FontMap colours fonts by category: sans-serif, serif, handwriting, monospace and decorative.
///
/// The kind is the class CoreText gives the font (motolii_font_tags). Monospace is checked first, as Google files
/// monospace fonts. Returns '' if no kind is known.
String fontKindOf(Motolii m, String path) {
  final t = m.fontTags(path);
  return t.contains('mono')
      ? 'mono'
      : const [
          'serif',
          'sans',
          'script',
          'ornaments',
          'symbols',
        ].firstWhere(t.contains, orElse: () => '');
}

/// A font's dot at half size, each pixel the average of four, as numbers from 0 to 1: what the map compares when
/// there is no FontCLIP model.
Float32List halvedDot(Uint8List g) {
  final (w, h) = (fontDotSize.$1 ~/ 2, fontDotSize.$2 ~/ 2);
  final out = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      out[y * w + x] =
          (g[2 * y * fontDotSize.$1 + 2 * x] +
              g[2 * y * fontDotSize.$1 + 2 * x + 1] +
              g[(2 * y + 1) * fontDotSize.$1 + 2 * x] +
              g[(2 * y + 1) * fontDotSize.$1 + 2 * x + 1]) /
          1020;
    }
  }
  return out;
}
