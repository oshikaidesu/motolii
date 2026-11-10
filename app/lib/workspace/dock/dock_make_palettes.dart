// The Colors shelf's palettes and gradients: the starters and the user's own, saved in ~/.motolii/colors.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/storage/json_file.dart' show fileJson, fileKeep;
import 'package:motolii/workspace/dock/dock_make_colors.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// A color palette: the starters, the user's saved ones, or one taken from a photo.
class ColorPalette {
  const ColorPalette(this.id, this.name, this.colors, {this.saved = false, this.reference, this.shares});
  final String id, name;
  final List<Color> colors;
  final bool saved;

  /// The photo the colors were taken from. A copy is kept beside the palette, so it is there whenever the palette is shown.
  final String? reference;

  /// How much of the image each color covers. The palette strip is drawn in these proportions.
  final List<double>? shares;
}

/// A gradient: its colors run down the layer as a straight linear ramp. Linear or radial is chosen in the inspector.
///
/// [blend] is how the colors are mixed between stops, and it is saved with the gradient:
/// - rgb
/// - oklab: the way an eye mixes, with no muddy middle between blue and yellow
/// - hue: around the hue circle
/// - steps: each color is held until the next
///
/// The engine does the mixing (gradient_blend, CSS Color 4's color-interpolation-method).
class ShelfGradient {
  const ShelfGradient(this.name, this.colors, {this.blend = 'oklab', this.saved = false, this.at});
  final String name;
  final List<Color> colors;

  /// Where each color sits, as a fraction of the way along the ramp. Null spreads them evenly.
  final List<double>? at;
  final String blend;
  final bool saved;
}

const _starterPals = <ColorPalette>[
  ColorPalette('pop', 'Pop Poster', [Color(0xFFB3C66B), Color(0xFF4781E5), Color(0xFFF08A5D), Color(0xFFE974AB), Color(0xFFEFCB4E), Color(0xFF15170D)]),
  ColorPalette('riso', 'Riso Print', [Color(0xFFFF48B0), Color(0xFF0078BF), Color(0xFFFFE800), Color(0xFF00A95C), Color(0xFFF15060), Color(0xFFF2EDE4)]),
  ColorPalette('coda', 'Coda Title', [Color(0xFFD9D2C3), Color(0xFFF08A5D), Color(0xFF7FB8B0), Color(0xFF3B3631), Color(0xFFF2C94C)]),
  ColorPalette('market', 'Night Market', [Color(0xFF1B1F3B), Color(0xFF53354A), Color(0xFFE84545), Color(0xFFFFB740), Color(0xFF2B9EB3)]),
  ColorPalette('candy', 'Candy Shop', [Color(0xFFFFB5C2), Color(0xFFB5EAD7), Color(0xFFC7CEEA), Color(0xFFFFDAC1), Color(0xFFE2F0CB), Color(0xFF9ADCFF)]),
  ColorPalette('signal', 'Signal', [Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00), Color(0xFF34C759), Color(0xFF007AFF), Color(0xFFAF52DE)]),
];

const _starterGrads = <ShelfGradient>[
  ShelfGradient('Lime dusk', [Color(0xFFB3C66B), Color(0xFF4781E5)]),
  ShelfGradient('Hot pink', [Color(0xFFE974AB), Color(0xFFF08A5D), Color(0xFFEFCB4E)]),
  ShelfGradient('Deep sea', [Color(0xFF15170D), Color(0xFF2B9EB3), Color(0xFF7DD5B1)]),
];

// What the user has saved, in ~/.motolii/colors.json: {"palettes": [{"name": "", "colors": ["#rrggbb"]}], "gradients": [{"name": "", "colors": [], "blend": "oklab"}], "colours": [], "tile": 52}.
final ownPalettes = <ColorPalette>[];

/// The user's own colors, saved one by one, as in CLIP STUDIO PAINT's color set: Add Color stores the drawing color,
/// pressing a tile draws with it, and a tile's menu replaces or deletes it.
final ownColors = <Color>[];
final ownGradients = <ShelfGradient>[];
bool _mineRead = false;
File _mineFile = File('${Platform.environment['HOME']}/.motolii/colors.json');

/// Sets where the saved colors are stored. A test points it elsewhere, and what was read is forgotten, as easeStarsAt does.
void colorsAt(File f) {
  _mineFile = f;
  _mineRead = false;
  ownPalettes.clear();
  ownColors.clear();
  ownGradients.clear();
  bentoTile = 52;
}

void colorsRead() {
  if (_mineRead) return;
  _mineRead = true;
  try {
    final told = fileJson(_mineFile) as Map;
    for (final (i, p) in ((told['palettes'] as List?) ?? const []).indexed) {
      final cs = [for (final h in (p['colors'] as List)) ?colorOfHex('$h')];
      final sh = (p['shares'] as List?)?.map((v) => (v as num).toDouble()).toList();
      if (cs.isNotEmpty) {
        ownPalettes.add(
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
    ownColors.addAll([for (final h in (told['colours'] as List?) ?? const []) ?colorOfHex('$h')]);
    if (told['tile'] case final num v) bentoTile = v.toDouble().clamp(bentoTileLeast, bentoTileMost);
    for (final g in (told['gradients'] as List?) ?? const []) {
      final cs = [for (final h in (g['colors'] as List)) ?colorOfHex('$h')];
      final at = (g['at'] as List?)?.map((v) => (v as num).toDouble()).toList();
      if (cs.length > 1) {
        ownGradients.add(
          ShelfGradient(
            '${g['name']}',
            cs,
            blend: g['blend'] as String? ?? (g['oklab'] == false ? 'rgb' : 'oklab'),
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

void colorsKeep() {
  fileKeep(
    _mineFile,
    jsonEncode({
      'palettes': [
        for (final p in ownPalettes)
          {
            'name': p.name,
            'colors': [for (final c in p.colors) hexOfColor(c)],
            'reference': p.reference,
            'shares': p.shares,
          },
      ],
      'gradients': [
        for (final g in ownGradients)
          {
            'name': g.name,
            'colors': [for (final c in g.colors) hexOfColor(c)],
            'blend': g.blend,
            'at': g.at,
          },
      ],
      'colours': [for (final c in ownColors) hexOfColor(c)],
      'tile': bentoTile,
    }),
  );
}

List<ColorPalette> get colorPalettes => [...ownPalettes, ..._starterPals];
List<ShelfGradient> get shelfGradients => [...ownGradients, ..._starterGrads];

String hexOfColor(Color c) {
  String h(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${h(c.r)}${h(c.g)}${h(c.b)}';
}

/// The colors that layers are filled with, keyed by layer name. A gradient counts as its first color.
Map<String, Color> usedColors(WorkspaceController ws) {
  final m = ws.inside;
  if (m == null) return const {};
  return {
    for (final l in ws.layers)
      if (m.word(int.parse(l.id), 'fill').split(' ').first.split('@').first case final f when f.length == 6)
        if (int.tryParse(f, radix: 16) case final v?) l.name: Color(0xFF000000 | v),
  };
}
