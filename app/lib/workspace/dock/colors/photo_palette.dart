// A palette taken from a photo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:material_color_utilities/material_color_utilities.dart'
    show QuantizerCelebi;

import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/saved_colors.dart';

/// Builds a palette from a photo. The image is shrunk and its pixels are grouped into colors by Google's quantizer
/// (material_color_utilities, as Material You takes a palette from a wallpaper). Each color records how many pixels it has.
/// The photo is copied beside the palette and stays there. [saved] is the user's palettes, which the new one is numbered after.
Future<ColorPalette?> paletteFromPhoto(String path, SavedColors saved) async {
  try {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
      targetWidth: 96,
    );
    final img = (await codec.getNextFrame()).image;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final pixels = <int>[
      for (var i = 0; i + 3 < data.lengthInBytes; i += 4)
        if (data.getUint8(i + 3) > 200)
          0xFF000000 |
              (data.getUint8(i) << 16) |
              (data.getUint8(i + 1) << 8) |
              data.getUint8(i + 2),
    ];
    if (pixels.isEmpty) return null;
    final found =
        (await QuantizerCelebi().quantize(
            pixels,
            6,
          )).colorToCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final total = found.fold<int>(0, (s, e) => s + e.value);
    final kept = Directory(
      '${Platform.environment['HOME']}/.motolii/references',
    )..createSync(recursive: true);
    final name = path.split('/').last,
        copy = '${kept.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
    File(path).copySync(copy);
    return ColorPalette(
      'mine${saved.palettes.length}',
      name.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), ''),
      [for (final e in found) Color(e.key)],
      saved: true,
      reference: copy,
      shares: [for (final e in found) e.value / total],
    );
  } catch (_) {
    return null;
  }
}
