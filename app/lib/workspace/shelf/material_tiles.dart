// Tiles for the materials in the Create tab, drawn like the Effects shelf's tiles (effect_tiles.dart) and the
// expression tiles (copies_tiles.dart).
// Each tile is drawn in another isolate, by the engine, on a separate document: a ball with the material in front of a
// two-colour ramp (glass is recognised by what it bends). The still is shrunk with sips and stored with the effect tiles
// (~/Library/Caches/Motolii/tiles), named by the material and by when its compiled material was written, so a tile is
// drawn again once the material is rebuilt.
import 'dart:io';

import '../../bridge/motolii.dart';
import 'copies_tiles.dart' show TileQueue, drawTiles, tileHome;

abstract final class MaterialTiles {
  static final _tiles = TileQueue<(String, String)>(draw);

  /// Notifies listeners once some tiles are drawn, so the tiles reload.
  static final drawn = _tiles.drawn;

  /// The compiled material that a ball with the material [wears] is drawn with (document/match.h: surface_model, thick_glass, solid_wear).
  static const _filamat = {
    'lit': 'floor_lit',
    'cloth': 'solid_cloth',
    'subsurface': 'solid_subsurface',
    'glass': 'thick_glass',
    'filament_glass': 'own_glass',
    'lacquer': 'blade',
    'bubble': 'bubble_worn',
  };

  /// Extra settings that make a ball show what its material looks like.
  ///
  /// Each entry is the fill colour, extra parameter values, and an optional sun placed behind the ball as
  /// (Y rotation in degrees, intensity). The sun is for materials where light through the ball or a rim is the point.
  /// Without these, Lit, Cloth and Subsurface all look like the same pale ball (default colour d9d2c3).
  /// - Lit: red and glossy, to show sharp highlights.
  /// - Cloth: blue and rough with sheen. Filament's cloth has no highlight and a soft rim.
  /// - Subsurface: orange and thin, lit from behind. Filament's subsurface glows at the edge and fills the shadow warm.
  static const _shows = <String, (String, Map<String, double>, (double, double)?)>{
    'lit': ('e8452c', {'roughness': .25}, null),
    'cloth': ('2a3fa8', {'roughness': 1, 'sheen': 1}, (150, 1.5)),
    'subsurface': ('ff5a2a', {'thickness': .02, 'roughness': .7}, (180, 1.5)),
  };

  /// The cache path of the tile for [wears]. It depends on the material, how it is shown, and when its compiled material was written.
  static String home(String wears) {
    final f = File('$motoliiDir/out/filament_webgpu/${_filamat[wears] ?? wears}.filamat');
    return tileHome('material', 'material|$wears|${_shows[wears]}|${f.existsSync() ? f.lastModifiedSync().microsecondsSinceEpoch : 0}');
  }

  /// The tile for [wears], or '' if it is not drawn yet or the engine failed to draw it. Requests it once.
  static String of(String wears) {
    final h = home(wears);
    return _tiles.of(h, (wears, h));
  }

  /// Draws each material's tile at its home path and returns the paths drawn.
  static List<String> draw(String dir, List<(String, String)> materials) => drawTiles(dir, 'motolii_materials', materials, (j) => j.$2, (m, job, home) {
    final wears = job.$1, back = m.add('shape', 'rect'); // The backdrop glass bends and tints: a colour ramp.
    m
      ..say(back, 'fill', 'ff3366 3366ff')
      ..set(back, 'gradient_angle', 90)
      ..set(back, 'scale_x', 4)
      ..set(back, 'scale_y', 4)
      ..set(back, 'z', -1);
    final ball = m.add('solid', 'ball');
    m
      ..say(ball, 'shading', wears)
      ..set(ball, 'scale_x', 1.4)
      ..set(ball, 'scale_y', 1.4)
      ..set(ball, 'scale_z', 1.4);
    if (_shows[wears] case (final fill, final numbers, final sun)) {
      m.say(ball, 'fill', fill);
      for (final e in numbers.entries) {
        m.set(ball, e.key, e.value);
      }
      if (sun != null) {
        final light = m.add('light', 'sun');
        m
          ..set(light, 'rotate_y', sun.$1)
          ..set(light, 'intensity', sun.$2);
      }
    }
    final still = '${home.substring(0, home.length - 4)}_still.png';
    if (!m.at(0) || !m.still(still)) return false;
    Process.runSync('sips', ['-Z', '192', still]);
    File(still).renameSync(home);
    return true;
  });
}
