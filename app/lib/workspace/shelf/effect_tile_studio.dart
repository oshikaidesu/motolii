// The photo studio the tiles of the Effects shelf are taken in. On its stage (effect_tile_stage.dart) it takes each effect's tile: it puts
// the effect on, chooses what to turn (the weights, the table, the reviewer), takes sixteen pictures, judges whether the effect did
// anything, and writes the still, the moving pictures and the marks beside them. EffectTiles queues the effects and runs this in another isolate.
import 'package:motolii/workspace/shelf/effect_tile_profile.dart';
import 'package:motolii/workspace/easing/ease.dart';

import 'dart:io';
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';
import 'package:motolii/workspace/shelf/effect_tiles_knob.dart';
import 'package:motolii/workspace/shelf/effect_tiles_difference.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/effect_tile_stage.dart';

class TileStudio extends TileStage {
  TileStudio._(super.dir, super.folder, super.m);

  /// Opens the studio and takes the pictures every effect is compared with; null when no project can be opened.
  static TileStudio? open(String dir) {
    final folder = Directory.systemTemp.createTempSync('motolii_tiles');
    final m = Motolii.open(
      '${folder.path}/tiles.motolii',
      wide: 384,
      high: 384,
      dir: dir,
    ); // AbsentMotion's RENDER size. Its THUMB size is below.
    if (m == null) {
      try {
        folder.deleteSync(recursive: true);
      } catch (_) {}
      return null;
    }
    return TileStudio._(dir, folder, m)..setUp();
  }

  /// Takes one effect's tile, [f] being the effect's file and [home] where its still goes; false when nothing could be written.
  bool tile(String f, String home) {
    try {
      Directory(File(home).parent.path).createSync(recursive: true);
    } catch (_) {
      return false;
    }
    final profile = TileProfile.of(m, dir, f, shows),
        show = profile.show,
        said = profile.said,
        plays = profile.plays,
        ears = profile.ears,
        hears = profile.hears,
        runs = profile.runs,
        first = profile.first;
    final base = home.substring(0, home.length - 4);
    var same = false, split = false, stands = true;
    var made = const <String>[];
    final worded = show?.text != null || TileReview.needs(dir, f) == 'text'; // For text effects, as the table or the reviewer says: shown on words alone.
    final alone = worded
        ? words
        : (show?.drawn ?? false) || TileReview.needs(dir, f) == 'path'
        ? math.max(sketch(), 0)
        : 0; // For strokes or a path: shown on the drawing alone.
    final aloneOk =
        alone != 0 &&
        () {
          if (worded) {
            m.say(
              words,
              'text',
              show?.text?.isNotEmpty ?? false ? show!.text! : 'Motolii',
            );
          }
          lay(false, only: alone);
          return shoot('${folder.path}/alone.png').length ==
              EffectTiles.moments.length;
        }();
    final bare = alone != 0 ? 'alone' : 'plain';
    // For effects that take the layer round a path (Mathy_Su's curves): the photo is small over the grid, so the path shows about it, not under it.
    small = alone == 0 && TileReview.entry(dir, f)['_lay'] == 'small';
    if (small) m.set(photo, 'size', 0.6);
    for (final moving in alone != 0 ? [false] : [first, if (!first) true]) {
      // Nothing shows on the whole photo, so use a card moving past, where its edge and motion effects show (AbsentMotion's "move").
      // A transition goes on the photo with the road under it. So does an effect that shows what is behind (rain on a pane over
      // nothing was black) and one for cut-outs, which gets its card over the road: a glass or a shape needs a background to refract.
      final passes =
          (said.contains('transition') ||
              const {'behind', 'shape'}.contains(TileReview.needs(dir, f))) &&
          alone == 0;
      lay(moving, road: passes, only: alone);
      // A screen effect. A .json is Filament's own settings (engine/stage/effects/viewer_settings.h). An AviUtl2 script goes on a layer instead.
      final whole =
          !moving &&
          !passes &&
          alone == 0 &&
          (f.endsWith('.fs') || f.endsWith('.wgsl') || f.endsWith('.json')) &&
          m.say(0, 'script', f);
      final thing = alone != 0
              ? alone
              : moving
              ? card
              : photo,
          on = whole ? 0 : thing,
          onIt =
              !whole &&
              m.say(
                thing,
                'fx',
                f,
              ); // Applied to a layer, as edit.sh says (engine/edit.sh).
      for (final e in ears) {
        m.set(
          on,
          'js_${TileReview.knobStem(f)}_$e',
          song.toDouble(),
        ); // On the beat.
      }
      if (hears && !heard && (whole || onIt)) {
        // Asked for once and waited for, so its pictures are drawn hearing it from the first.
        if (m.at(EffectTiles.moments.first)) m.still('${folder.path}/warm.png');
        sleep(const Duration(seconds: 1));
        heard = true;
      }
      final sweeps = _sweeps(f, on, profile);
      if (!moving &&
          alone == 0 &&
          !runs &&
          sweeps.isEmpty &&
          enough &&
          looksSame('${folder.path}/usual.png', '${folder.path}/sample.png')) {
        // Nothing on the photo: no sixteen pictures of nothing.
        if (whole) m.say(0, 'script', 'none');
        if (onIt) m.say(thing, 'fx', 'none');
        same = true;
        continue;
      }
      made = shoot(
        home,
        plays: plays,
        turn: (at) {
          final t =
              ((at - EffectTiles.moments.first) /
                      (EffectTiles.moments.last - EffectTiles.moments.first))
                  .clamp(0.0, 1.0);
          for (final MapEntry(key: knob, value: stops) in sweeps.entries) {
            m.set(
              on,
              knob,
              easeAlong(stops, t * t * (3 - 2 * t)),
            ); // Smoothstep, so it eases at its ends instead of hitting them.
          }
        },
      );
      if (whole) m.say(0, 'script', 'none');
      if (onIt) m.say(thing, 'fx', 'none');
      if (made.length < EffectTiles.moments.length) continue;
      // Also unchanged when hardly different from nothing, black, or the grid alone. A square that a sound, a video or what it lacks would fill is marked so.
      same =
          enough &&
          (alone == 0 || aloneOk) &&
          ([
            '${moving ? 'moved' : bare}${passes ? '_road' : ''}',
            'none',
            'stage',
          ].any(
            (b) => looksSame('${base}_%d.png', '${folder.path}/${b}_%d.png'),
          ));
      stands = !moving && !runs && sweeps.isEmpty;
      split = stands && !said.contains('generator');
      if (!same) break;
    }
    if (small) m.set(photo, 'size', 3.6);
    small = false;
    if (made.length < EffectTiles.moments.length || same) {
      // Put on but not drawn (a script that stops), or nothing seen: the sample as it is.
      for (final (k, _) in EffectTiles.moments.indexed) {
        if (enough) {
          File('${folder.path}/${aloneOk ? bare : 'plain'}_$k.png')
              .copySync(EffectTiles.drawnFrame(home, k));
        }
      }
      stands = true;
      if (!enough) return false;
    }
    _write(
      f,
      home,
      base: base,
      bare: bare,
      split: split,
      splitWord: show?.split,
      same: same,
      stands: stands,
    );
    return true;
  }

  /// Sets the parameters of layer [on] as the table and the reviewer set them and chooses what to turn while the sixteen pictures are taken:
  /// the stops each parameter goes through. A transition goes from 0 to 1; otherwise the reviewer's choice, then the table's, then the one
  /// the measure finds (tellingKnob); an effect that runs by the clock has its heaviest parameter turned as it runs, or none.
  Map<String, List<double>> _sweeps(String f, int on, TileProfile p) {
    final show = p.show,
        said = p.said,
        weights = p.weights,
        time = p.time,
        chosen = p.chosen,
        runs = p.runs,
        lists = p.lists;
    final filed = <String, double>{};
    for (final MapEntry(:key, :value) in {
      ...?show?.knobs,
      ...TileReview.held(dir, f),
    }.entries) {
      if (m.value(on, key, 0) case final was? when !vectorPart.hasMatch(key)) {
        filed[key] = was;
      }
      m.set(on, key, value); // As AbsentMotion shows it: the table's values, not the file's defaults.
    }
    final knobs = [
      for (final v in m.values(on))
        if (v.startsWith('js_') && !own.contains(v)) v,
    ];
    final sweeps = <String, List<double>>{...?show?.sweeps};
    final heaviest = ([
      for (final k in knobs)
        if (weights[k] case final w? when w > time) (k, w),
    ]..sort((a, b) => b.$2.compareTo(a.$2))).firstOrNull?.$1; // The parameter whose weight shows the effect most, more than letting it run.
    if (knobs.where((k) => k.endsWith('_progress')).firstOrNull case final p?
        when said.contains('transition')) {
      sweeps[p] = const [
        0,
        1,
      ]; // A transition is seen going from 0 to 1 across its pictures.
    } else if (chosen case (final k, final from, final to)
        when sweeps.isEmpty && knobs.contains(k)) {
      sweeps[k] = [
        from,
        to,
      ]; // As the reviewer chose it, ahead of the measured one.
    } else if (sweeps.isEmpty && (!runs || heaviest != null)) {
      // An effect that runs by the clock has its heaviest parameter turned as it runs, or none.
      if (tellingKnob(
            m,
            on,
            knobs,
            filed,
            lists,
            folder.path,
            first: heaviest,
            alone: runs,
          )
          case final knob?) {
        sweeps[knob.$1] = [knob.$2, knob.$3];
      }
    }
    return sweeps;
  }

  /// Writes the tile of [f] at [home]: the still, the sixteen pictures as JPEG when something moves, and the marks beside them
  /// (.same for an effect that did nothing, .tells for what the tile was told). [base] is where the pictures were taken, [bare] the sample
  /// they are compared with, [split] a line going across for an effect with nothing to turn, [splitWord] where the table puts that line.
  void _write(
    String f,
    String home, {
    required String base,
    required String bare,
    required bool split,
    required double? splitWord,
    required bool same,
    required bool stands,
  }) {
    // AbsentMotion's split, at its 22 where one stands. With no parameter to turn, a line going across shows what the effect did, so no tile stands still.
    final at = split ? '0.1+0.8*(3*pow(N/15,2)-2*pow(N/15,3))' : splitWord;
    if (at != null && !same && enough) {
      // Before is at its left, as AbsentMotion's effect_thumbs.py lays the photo over it up to there, with a white line where they meet.
      if (ffmpeg([
            '-i',
            '${base}_%d.png',
            '-i',
            '${folder.path}/${bare}_%d.png',
            '-filter_complex',
            "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_expr='if(lt(abs(X-W*($at)),1),255,if(lt(X,W*($at)),B,A))'",
            '-start_number',
            '0',
            '${base}_%d.split.png',
          ])?.exitCode ==
          0) {
        for (final (k, _) in EffectTiles.moments.indexed) {
          File('${base}_$k.split.png')
              .renameSync(EffectTiles.drawnFrame(home, k));
        }
        stands = false;
      }
    }
    File(EffectTiles.drawnFrame(home, EffectTiles.still)).copySync(home);
    if (stands) {
      for (final (k, _) in EffectTiles.moments.indexed) {
        File(EffectTiles.frame(home, k)).existsSync()
            ? File(EffectTiles.frame(home, k)).deleteSync()
            : null; // Nothing moves, so only the still.
      }
    } else {
      ffmpeg([
        '-i',
        '${base}_%d.png',
        '-q:v',
        '6',
        '-start_number',
        '0',
        '${base}_%d.jpg',
      ]);
    }
    for (final (k, _) in EffectTiles.moments.indexed) {
      File(EffectTiles.drawnFrame(home, k)).deleteSync();
    }
    try {
      same
          ? File('$home.same').writeAsStringSync('')
          : File('$home.same').deleteSync();
    } catch (_) {}
    File('$home.tells').writeAsStringSync(TileReview.tells(dir, f));
  }
}
