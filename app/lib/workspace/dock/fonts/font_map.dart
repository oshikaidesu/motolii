// Where a font goes on the Fonts shelf's map: by how FontCLIP sees its specimen (fonts_service.dart), or by its dot.
import 'dart:typed_data';

import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';

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
