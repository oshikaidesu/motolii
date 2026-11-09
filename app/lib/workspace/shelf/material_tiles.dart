// Create's Material tiles drawn as the Effects shelf's are (effect_tiles.dart) and the Expression tiles (copies_tiles.dart):
// on a document of its own in another isolate, by the inside, a ball wearing the material before a ramp of two colours
// (glass is seen by what it bends), one still made small with sips, where the effect tiles go (~/Library/Caches/Motolii/
// tiles, named by the material and when its compiled material was written: drawn again once that is built again).
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FileImage, ResizeImage;

import '../../engine/motolii.dart';
import 'effect_tiles.dart' show EffectTiles;

abstract final class MaterialTiles {
  static final _asked = <String>{}, _queue = <(String, String)>[];
  static var _drawing = false;

  /// Told once some are drawn: the tiles look again.
  static final drawn = ValueNotifier<int>(0);

  /// The compiled material a ball wearing [wears] is drawn with (doc_match.h: surface_model, thick_glass, solid_wear).
  static const _filamat = {'lit': 'floor_lit', 'cloth': 'solid_cloth', 'subsurface': 'solid_subsurface', 'glass': 'thick_glass', 'filament_glass': 'own_glass', 'lacquer': 'blade', 'bubble': 'bubble_worn'};

  /// What a ball wearing [wears] is given besides, to show what it is: its colour, its own numbers, and a sun from
  /// behind (turned round, Y degrees, how strong) where light through it or a rim is the material. Without, Lit, Cloth
  /// and Subsurface are the same pale ball (the default colour, d9d2c3). Lit: red, glossy (its sharp highlights);
  /// Cloth: blue, rough, its sheen (Filament's cloth: no highlight, a soft rim); Subsurface: orange, thin, lit from
  /// behind (Filament's subsurface: the light through it glows at its edge and fills its shadow warm).
  static const _shows = <String, (String, Map<String, double>, (double, double)?)>{
    'lit': ('e8452c', {'roughness': .25}, null),
    'cloth': ('2a3fa8', {'roughness': 1, 'sheen': 1}, (150, 1.5)),
    'subsurface': ('ff5a2a', {'thickness': .02, 'roughness': .7}, (180, 1.5)),
  };

  /// Where [wears]'s tile goes: by the material, how it is shown and when its compiled material was written.
  static String home(String wears) {
    final f = File('$motoliiDir/out/wgpu_kit/${_filamat[wears] ?? wears}.filamat');
    var hash = 1469598103934665603;
    for (final c in 'material|$wears|${_shows[wears]}|${f.existsSync() ? f.lastModifiedSync().microsecondsSinceEpoch : 0}'.codeUnits) {
      hash = (hash ^ c) * 1099511628211;
    }
    return '${Platform.environment['HOME']}/Library/Caches/Motolii/tiles/material_${(hash & 0x7fffffffffffffff).toRadixString(16)}.png';
  }

  /// [wears]'s tile ('' none: not drawn yet, or the inside did not draw it), asked for once.
  static String of(String wears) {
    final h = home(wears);
    if (File(h).existsSync()) return h;
    if (File('$h.none').existsSync() || Platform.environment['FLUTTER_TEST'] == 'true' || !_asked.add(h)) return '';
    _queue.add((wears, h));
    if (!_drawing) unawaited(_work());
    return '';
  }

  static Future<void> _work() async {
    _drawing = true;
    final dir = motoliiDir;
    try {
      while (_queue.isNotEmpty) {
        final some = [..._queue];
        _queue.clear();
        for (final h in await Isolate.run(() => draw(dir, some))) {
          ResizeImage(FileImage(File(h)), width: EffectTiles.readWide).evict();
        }
        drawn.value++;
      }
    } catch (_) {
    } finally {
      _drawing = false;
    }
  }

  /// Each material's tile drawn where its home says; the homes drawn.
  static List<String> draw(String dir, List<(String, String)> materials) {
    final folder = Directory.systemTemp.createTempSync('motolii_materials'), made = <String>[];
    for (final (i, (wears, home)) in materials.indexed) {
      final m = Motolii.open('${folder.path}/material_$i.motolii', wide: 1080, high: 1080, dir: dir);
      if (m == null) continue;
      try {
        Directory(File(home).parent.path).createSync(recursive: true);
        final back = m.add('shape', 'rect');   // (what glass bends and tints: a ramp across it)
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
        if (!m.at(0) || !m.still(still)) {
          File('$home.none').writeAsStringSync('');
          continue;
        }
        Process.runSync('sips', ['-Z', '192', still]);
        File(still).renameSync(home);
        made.add(home);
      } catch (_) {
        try {
          File('$home.none').writeAsStringSync('');
        } catch (_) {}
      } finally {
        m.close();
      }
    }
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
    return made;
  }
}
