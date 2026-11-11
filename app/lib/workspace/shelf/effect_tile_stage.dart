// The stage of the tile studio: a small project of its own with a sample photo, a grid, a card that moves, some words, a drawing and a
// sound, and the equipment to use it - laying out what is seen (lay), drawing the sample (sketch) and taking sixteen pictures (shoot). It also
// takes the pictures every effect is compared with. TileStudio (effect_tile_studio.dart) takes each effect's tile on it.

import 'dart:io';
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart'
    show defaultTextFont;
import 'package:motolii/workspace/shelf/effect_tiles_difference.dart';
import 'package:motolii/workspace/shelf/effect_tiles_showcase.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

class TileStage {
  TileStage(this.dir, this.folder, this.m);

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

  /// Opens the stage: makes the layers and takes the sample's own pictures.
  void setUp() {
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

  /// Closes the project and removes the folder the pictures were made in.
  void close() {
    m.close();
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
  }
}
