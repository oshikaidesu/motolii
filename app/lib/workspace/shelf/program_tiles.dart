// The tile for a program, using the numbers AbsentMotion uses for its animated tiles
// (tools/effect_thumbs.py, Apache-2.0). Frames are rendered at 384 and stored at 192 as one looping file that plays
// by itself, 1.33 seconds at 24 frames a second (not 12, which looks stepped).
// AbsentMotion makes its tiles once on an emulator from a hand-written table with one line per effect. A program moves
// by itself, so it needs no table line and no sample, and its author needs no developer.
// Tiles are drawn on a separate document in another isolate, one after another like effect_tiles.dart's, and again
// once the file has changed.
// The format is APNG, as ffmpeg writes it and Flutter's engine plays it (image_generator_apng.cc). Without ffmpeg
// (where the app was launched from) a single image is used instead.
// Capture starts one second in, so a sketch that builds its image up has something to show (no source for that value).
import 'dart:io';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart' show TileQueue, tileHome;
import 'package:motolii/workspace/shelf/effect_tiles_seen.dart' show ffmpeg;

abstract final class ProgramTiles {
  static const _render = 384, _keep = 192, _pictures = 32, _perSecond = 24, _from = 1.0;
  // Four at a time, so a program that crashes the app loses at most four.
  static final _tiles = TileQueue<(String, String)>(_draw, batch: 4);

  /// The cache path of a program's tile. There is one path per program, so the last tile drawn shows until the next one is ready.
  static String home(String file) => tileHome('program24', file);

  /// Queues the programs whose tile has not been drawn since the file last changed.
  /// A program that crashed the app (its .trying marker was left behind) waits until its file changes.
  static void ask(Iterable<String> files, void Function() changed) {
    // Same as EffectTiles.ask.
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;
    _tiles.onDrawn = (_) => changed();
    for (final f in files) {
      final to = home(f), written = File(f).lastModifiedSync();
      bool since(String p) => File(p).existsSync() && File(p).lastModifiedSync().isAfter(written);
      if (!since(to) && !since('$to.trying')) _tiles.ask('$f $written', (f, to));
    }
    _tiles.start();
  }

  static List<String> _draw(String dir, List<(String, String)> files) {
    final folder = Directory.systemTemp.createTempSync('motolii_programs');
    final m = Motolii.open('${folder.path}/tiles.motolii', wide: _render, high: _render, dir: dir);
    if (m == null) return [];
    for (final (f, to) in files) {
      final trying = File('$to.trying')..createSync(recursive: true);
      // Layers placed now appear at the current time.
      m.at(0);
      final ticket = m.later('adapter', word: f);
      var said = -1;
      for (var n = 0; said < 0 && n < 6000; n++) {
        sleep(const Duration(milliseconds: 10));
        said = m.answer(ticket);
      }
      if (said >= 1 && [for (var k = 0; k < _pictures; k++) m.at(_from + k / _perSecond) && m.still('${folder.path}/$k.png')].every((done) => done)) {
        _kept(folder.path, to);
      }
      for (final t in m.layers.toList()) {
        m.remove(t);
      }
      trying.deleteSync();
    }
    m.close();
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
    return [for (final (_, to) in files) to];
  }

  static void _kept(String folder, String to) {
    final moving = '$folder/moving.apng';
    ffmpeg(['-framerate', '$_perSecond', '-i', '$folder/%d.png', '-vf', 'scale=$_keep:$_keep:flags=lanczos', '-plays', '0', '-f', 'apng', moving]);
    // Without ffmpeg there is no animation, so the middle frame is used as a single image.
    File(File(moving).existsSync() ? moving : '$folder/${_pictures ~/ 2}.png').copySync(to);
  }
}
