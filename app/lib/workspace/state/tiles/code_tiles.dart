// The tile for a code file, using the numbers AbsentMotion uses for its animated tiles
// (tools/effect_thumbs.py, Apache-2.0). Frames are rendered at 384 and stored at 192 as one looping file that plays
// by itself, 1.33 seconds at 24 frames a second (not 12, which looks stepped).
// AbsentMotion makes its tiles once on an emulator from a hand-written table with one line per effect. A code file moves
// by itself, so it needs no table line and no sample, and its author needs no developer.
// Tiles are drawn on a separate document in another isolate, one after another like effect_tiles.dart's, and again
// once the file has changed.
// The format is APNG, as ffmpeg writes it and Flutter's engine plays it (image_generator_apng.cc). Without ffmpeg
// (where the app was launched from) a single image is used instead.
// Capture starts one second in, so a sketch that builds its image up has something to show (no source for that value).
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/script_files.dart' show writtenAt;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/workspace/state/tiles/tile_media.dart';
import 'package:motolii/workspace/state/tiles/tile_queue.dart';

abstract final class CodeTiles {
  static const _render = 384,
      _keep = 192,
      _pictures = 32,
      _perSecond = 24,
      _from = 1.0;
  // Four at a time, so a code file that crashes the app loses at most four.
  static final _tiles = TileQueue<(String, String)>(_draw, batch: 4);

  /// The cache path of a code file's tile. There is one path per code file, so the last tile drawn shows until the next one is ready.
  static String home(String file) => tileHome('program24', file);

  /// Queues the code files whose tile has not been drawn since the file last changed.
  /// A code file that crashed the app (its .trying marker was left behind) waits until its file changes.
  static void ask(Iterable<String> files, void Function() changed) {
    // Same as EffectTiles.ask.
    if (envVar('FLUTTER_TEST') == 'true') return;
    _tiles.onDrawn = (_) => changed();
    for (final f in files) {
      final to = home(f), written = writtenAt(f);
      bool since(String p) => existsFile(p) && writtenAt(p).isAfter(written);
      if (!since(to) && !since('$to.trying')) {
        _tiles.ask('$f $written', (f, to));
      }
    }
    _tiles.start();
  }

  static List<String> _draw(String dir, List<(String, String)> files) {
    final folder = makeTempFolder('motolii_programs');
    final m = Motolii.open(
      '$folder/tiles.motolii',
      wide: _render,
      high: _render,
      dir: dir,
    );
    if (m == null) return [];
    for (final (f, to) in files) {
      makeFile('$to.trying');
      // Layers placed now appear at the current time.
      m.at(0);
      final ticket = m.later('adapter', word: f);
      var said = -1;
      for (var n = 0; said < 0 && n < 6000; n++) {
        pauseFor(const Duration(milliseconds: 10));
        said = m.answer(ticket);
      }
      if (said >= 1 &&
          [
            for (var k = 0; k < _pictures; k++)
              m.at(_from + k / _perSecond) && m.still('$folder/$k.png'),
          ].every((done) => done)) {
        _kept(folder, to);
      }
      for (final t in m.layers.toList()) {
        m.remove(t);
      }
      deleteFile('$to.trying');
    }
    m.close();
    try {
      removeFolder(folder);
    } catch (_) {}
    return [for (final (_, to) in files) to];
  }

  static void _kept(String folder, String to) {
    final moving = '$folder/moving.apng';
    ffmpeg([
      '-framerate',
      '$_perSecond',
      '-i',
      '$folder/%d.png',
      '-vf',
      'scale=$_keep:$_keep:flags=lanczos',
      '-plays',
      '0',
      '-f',
      'apng',
      moving,
    ]);
    // Without ffmpeg there is no animation, so the middle frame is used as a single image.
    copyFile(existsFile(moving) ? moving : '$folder/${_pictures ~/ 2}.png', to);
  }
}
