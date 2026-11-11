// The photo studio the tiles of the Effects shelf are taken in. It opens a small project of its own with a sample photo, a grid, a card
// that moves, some words, a drawing and a sound, takes the pictures that every effect is compared with (the sample as it is, moving,
// on the road, on nothing), and then takes each effect's tile: it puts the effect on, chooses what to turn (the weights, the table, the
// reviewer), takes sixteen pictures, judges whether the effect did anything, and writes the still, the moving pictures and the marks
// beside them. EffectTiles queues the effects and runs this in another isolate.
import 'package:motolii/workspace/shelf/effect_tile_profile.dart';
import 'package:motolii/workspace/easing/ease.dart';

import 'dart:io';
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart'
    show defaultTextFont;
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';
import 'package:motolii/workspace/shelf/effect_tiles_knob.dart';
import 'package:motolii/workspace/shelf/effect_tiles_difference.dart';
import 'package:motolii/workspace/shelf/effect_tiles_showcase.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

class TileStudio {
  TileStudio._(this.dir, this.folder, this.m);

  /// The folder of effects (the engine's), the temporary folder the pictures are made in, and the project that takes them.
  final String dir;
  final Directory folder;
  final Motolii m;

  /// The layers of the stage: the grid, the picture a transition goes to, the sample photo, the moving card, the sound, the words.
  late final int grid, under, photo, card, song, words;

  /// Whether the sample's own pictures were taken, the table of what each effect should show, and the values of the layers above.
  late final bool enough;
  late final Map<String, dynamic> shows;
  late final Set<String> own;

  /// Whether the sound was read once, aside (sound_level.h sound_of). Until then it is silent.
  bool heard = false;

  /// AbsentMotion's sample drawing, made the first time it is needed; -1 when it could not be made.
  int drawing = 0;

  /// The photo is small over the grid (the _lay "small" entry).
  bool small = false;

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
    return TileStudio._(dir, folder, m).._stage();
  }

  void _stage() {
    ffmpeg([
      '-f',
      'lavfi',
      '-i',
      'color=c=0x2c2c34:s=384x384,drawgrid=w=48:h=48:t=1:c=0x45454f',
      '-frames:v',
      '1',
      '${folder.path}/grid.png',
    ]); // AbsentMotion's grid, where its "move" layout stands.
    // The picture under the photo is what a transition goes to. On a clip, a transition takes the photo away and shows what is under it (doc_fx_file),
    // as gl-transitions' previews do. On the whole screen it had nothing to go to and went to black.
    final sample =
        '${Directory(dir).absolute.parent.path}/shelves/effects/sources';
    grid = m.add('picture', '${folder.path}/grid.png');
    under = m.add('picture', '$sample/fx_sample_end.jpg');
    photo = m.add('picture', '$sample/fx_sample.jpg');
    card = m.add('picture', '$sample/fx_sample.jpg');
    // For effects that hear: a kick three times a second under a tone rising from 300 to 2000 Hz, made by the same ffmpeg lavfi as the grid.
    ffmpeg([
      '-f',
      'lavfi',
      '-i',
      "aevalsrc='0.9*sin(2*PI*(50+120*exp(-25*mod(t,1/3)))*t)*exp(-9*mod(t,1/3))+0.25*sin(2*PI*(300+850*t)*t)*(0.5+0.5*sin(6*PI*t))':s=48000:d=2",
      '${folder.path}/beat.wav',
    ]);
    song = m.add('film', '${folder.path}/beat.wav'); // Sound only: AviUtl2 scripts hear it (audiobuffer, doc_sound_now) and ISF effects hear it through the audio input a parameter names.
    m.set(song, 'opacity', 0); // Hidden but still heard, as a sound added in the app is (Alight Motion's sound layer has no picture).
    words = m.add('text', defaultTextFont); // For effects that work on text: white words over the grid, as AbsentMotion's effect_thumbs.py lays its "text" layout.
    m
      ..say(words, 'fill', 'ffffff')
      ..set(words, 'size', 0.4)
      ..set(grid, 'size', 3.6)
      ..set(under, 'size', 3.6)
      ..set(photo, 'size', 3.6)
      ..set(card, 'size', 1.8)
      ..key(card, 'x', EffectTiles.moments.first, -0.84)
      ..key(card, 'x', EffectTiles.moments.last, 0.84);

    lay(false);
    final plain = shoot(
      '${folder.path}/plain.png',
    ); // The sample as it is, to tell a tile that shows nothing.
    if (m.at(EffectTiles.moments[EffectTiles.still])) {
      m.still(
        '${folder.path}/sample.png',
      ); // Full size, like the tries it is compared with.
    }
    lay(true);
    final moved = shoot('${folder.path}/moved.png');
    for (final moving in [false, true]) {
      // Each again with the road photo under it, as an effect laid on the road is drawn. Beside these it is seen whether the effect did anything.
      lay(moving, road: true);
      shoot('${folder.path}/${moving ? 'moved' : 'plain'}_road.png');
    }
    for (final (empty, seen) in [('none', null), ('stage', grid)]) {
      // Nothing on the stage (black), then the grid alone. A tile hardly different from either shows nothing, by the same
      // looksSame test. The road alone is not used: rain on a pane, thin streaks over it, is hardly different from it by the mean.
      for (final t in [grid, card, photo, under, words]) {
        m.set(t, 'opacity', t == seen ? 1 : 0);
      }
      shoot('${folder.path}/$empty.png');
    }
    enough =
        plain.length == EffectTiles.moments.length &&
        moved.length == EffectTiles.moments.length;
    shows = table(dir);
    own = {
      for (final t in [photo, card, words]) ...m.values(t),
    }; // A drawing's values belong to a shape, so none of them start with js_.
  }

  int sketch() {
    // effect_thumbs.py sketch(): a spiral and a wave drawn as pen strokes, as the app's brush makes them (doc_brush), at its RENDER size of 384.
    if (drawing != 0) return drawing;
    m.at(0); // A stroke starts at the current time, as an added layer does, so go to the first time as the tile's pictures do.
    final made = <int>[];
    for (final (wide, line) in [
      (
        16,
        [
          for (var j = 0; j < 100; j++)
            (
              192 + math.cos(j / 9) * (14 + j * 1.1),
              172 + math.sin(j / 9) * (14 + j * 1.1),
            ),
        ],
      ),
      (
        12,
        [
          for (var j = 0; j < 41; j++)
            (62 + j * 6.5, 302 + math.sin(j / 3) * 18),
        ],
      ),
    ]) {
      final ticket = m.later(
        'brush',
        word:
            '0 $wide ${[for (final (x, y) in line) '${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} 1'].join(' ')}',
      );
      var made1 = -1;
      for (var n = 0; n < 2000 && (made1 = m.answer(ticket)) == -1; n++) {
        sleep(const Duration(milliseconds: 5));
      }
      made.add(made1); // The layer the brush made.
    }
    if (made.any((t) => t <= 0)) return drawing = -1;
    m
      ..say(
        made[0],
        'drawing',
        '${m.word(made[0], 'drawing')} ; ${m.word(made[1], 'drawing')}',
      ) // Both strokes as one drawing, as in AbsentMotion.
      ..say(
        made[0],
        'path',
        '${m.word(made[0], 'path')} ${m.word(made[1], 'path')}',
      )
      ..say(made[0], 'fill', 'ffc23d')
      ..set(made[1], 'opacity', 0);
    return drawing = made[0];
  }

  void lay(bool moving, {bool road = false, int only = 0}) {
    for (final (thing, seen) in [
      (grid, moving || only != 0 || small),
      (card, moving),
      (photo, !moving && only == 0),
      (under, road),
      (words, only == words),
      if (drawing > 0) (drawing, only == drawing),
    ]) {
      m.set(thing, 'opacity', seen ? 1 : 0);
    }
  }

  List<String> shoot(
    String home, {
    bool plays = false,
    void Function(double at)? turn,
  }) {
    // Draws its pictures, shrunk. [plays] is for an effect that keeps its previous frame (ISF's PERSISTENT): it is stepped
    // through from the start at 30 fps and the sixteen pictures are kept as they pass, as fx_tiles.sh warms one up.
    final made = <String>[];
    bool one(double at, String to) {
      turn?.call(at);
      return m.at(at) && m.still(to);
    }

    if (plays) {
      for (
        var n = 1, k = 0;
        k < EffectTiles.moments.length &&
            n <= (EffectTiles.moments.last * 30).round();
        n++
      ) {
        final keep = n == (EffectTiles.moments[k] * 30).round();
        if (one(
              n / 30,
              keep
                  ? EffectTiles.drawnFrame(home, k)
                  : '${folder.path}/warm.png',
            ) &&
            keep) {
          made.add(EffectTiles.drawnFrame(home, k));
        }
        if (keep) k++;
      }
    } else {
      made.addAll([
        for (final (k, at) in EffectTiles.moments.indexed)
          if (one(at, EffectTiles.drawnFrame(home, k)))
            EffectTiles.drawnFrame(home, k),
      ]);
    }
    if (made.isNotEmpty) Process.runSync('sips', ['-Z', '192', ...made]);
    return made;
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
        lists = profile.lists,
        ears = profile.ears,
        hears = profile.hears,
        weights = profile.weights,
        time = profile.time,
        chosen = profile.chosen,
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
      final filed = <String, double>{};
      for (final MapEntry(:key, :value) in {
        ...?show?.knobs,
        ...TileReview.held(dir, f),
      }.entries) {
        if (m.value(on, key, 0) case final was?
            when !vectorPart.hasMatch(key)) {
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

  /// Closes the project and removes the folder the pictures were made in.
  void close() {
    m.close();
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
  }
}
