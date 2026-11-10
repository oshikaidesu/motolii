// The colors, palettes and gradients the user has saved on the Colors shelf, kept in ~/.motolii/colors.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/storage/json_file.dart' show fileJson, fileKeep;
import 'package:motolii/workspace/dock/colors/color_palette.dart';

/// The range of the box size slider. The size can be any value in it, not a few steps,
/// like Finder's icon size, Photoshop's Swatches panel and Lightroom's thumbnails.
const bentoTileLeast = 16.0, bentoTileMost = 120.0;

/// What the user has saved on the Colors shelf, kept in ~/.motolii/colors.json:
/// {"palettes": [{"name": "", "colors": ["#rrggbb"]}], "gradients": [{"name": "", "colors": [], "blend": "oklab"}], "colours": [], "tile": 52}.
class SavedColors {
  /// Where the saved colors are stored. A test points it elsewhere with [colorsAt].
  static File _file = File(
    '${Platform.environment['HOME']}/.motolii/colors.json',
  );

  /// The user's own palettes, newest first.
  final palettes = <ColorPalette>[];

  /// The user's own colors, saved one by one, as in CLIP STUDIO PAINT's color set: Add Color stores the drawing color,
  /// pressing a tile draws with it, and a tile's menu replaces or deletes it.
  final colors = <Color>[];

  /// The user's own gradients, newest first.
  final gradients = <ShelfGradient>[];

  /// The size of a box of the color bento, between [bentoTileLeast] and [bentoTileMost].
  double tile = 52;
  bool _read = false;

  /// Reads the file, the first time it is called.
  void read() {
    if (_read) return;
    _read = true;
    try {
      final told = fileJson(_file) as Map;
      for (final (i, p) in ((told['palettes'] as List?) ?? const []).indexed) {
        final cs = [for (final h in (p['colors'] as List)) ?colorOfHex('$h')];
        final sh = (p['shares'] as List?)
            ?.map((v) => (v as num).toDouble())
            .toList();
        if (cs.isNotEmpty) {
          palettes.add(
            ColorPalette(
              'mine$i',
              '${p['name']}',
              cs,
              saved: true,
              reference: p['reference'] as String?,
              shares: sh != null && sh.length == cs.length ? sh : null,
            ),
          );
        }
      }
      colors.addAll([
        for (final h in (told['colours'] as List?) ?? const [])
          ?colorOfHex('$h'),
      ]);
      if (told['tile'] case final num v) {
        tile = v.toDouble().clamp(bentoTileLeast, bentoTileMost);
      }
      for (final g in (told['gradients'] as List?) ?? const []) {
        final cs = [for (final h in (g['colors'] as List)) ?colorOfHex('$h')];
        final at = (g['at'] as List?)
            ?.map((v) => (v as num).toDouble())
            .toList();
        if (cs.length > 1) {
          gradients.add(
            ShelfGradient(
              '${g['name']}',
              cs,
              blend:
                  g['blend'] as String? ??
                  (g['oklab'] == false ? 'rgb' : 'oklab'),
              saved: true,
              at: at != null && at.length == cs.length ? at : null,
            ),
          );
        }
      }
    } catch (_) {
      // No file: only the starters are shown.
    }
  }

  /// Writes everything to the file.
  void keep() {
    fileKeep(
      _file,
      jsonEncode({
        'palettes': [
          for (final p in palettes)
            {
              'name': p.name,
              'colors': [for (final c in p.colors) hexOfColor(c)],
              'reference': p.reference,
              'shares': p.shares,
            },
        ],
        'gradients': [
          for (final g in gradients)
            {
              'name': g.name,
              'colors': [for (final c in g.colors) hexOfColor(c)],
              'blend': g.blend,
              'at': g.at,
            },
        ],
        'colours': [for (final c in colors) hexOfColor(c)],
        'tile': tile,
      }),
    );
  }

  /// The user's palettes, then the starters.
  List<ColorPalette> get allPalettes => [...palettes, ...starterPalettes];

  /// The user's gradients, then the starters.
  List<ShelfGradient> get allGradients => [...gradients, ...starterGradients];
}

/// Sets where the saved colors are stored. A test points it at a file of its own before it opens a window.
void colorsAt(File f) => SavedColors._file = f;
