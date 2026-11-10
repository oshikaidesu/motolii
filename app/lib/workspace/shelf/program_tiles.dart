// A program's tile, by AbsentMotion's numbers for its moving ones (tools/effect_thumbs.py, Apache-2.0): rendered at 384,
// kept at 192, one looping file that plays by itself; its 1.33 seconds at 24 a second, not its 12, which steps. Theirs are made once on an emulator
// from a table written beforehand, one line an effect; a program moves by itself, so it needs no line and no sample, and
// its maker needs no developer. Drawn on a document of its own on another isolate, as effect_tiles.dart's, one after
// another, and again once the file has changed. APNG, as ffmpeg writes it and Flutter's engine plays
// it (image_generator_apng.cc); no ffmpeg where the window was opened from: one picture. From a second in, where a sketch
// that builds its picture has something up (no source for that).
import 'dart:io';

import '../../bridge/motolii.dart';
import 'copies_tiles.dart' show TileQueue, tileHome;
import 'effect_tiles.dart' show ffmpeg;

abstract final class ProgramTiles {
  static const _render = 384, _keep = 192, _pictures = 32, _perSecond = 24, _from = 1.0;
  static final _tiles = TileQueue<(String, String)>(_draw, batch: 4); // (four at a time: one that takes the window down takes at most four)

  /// Where its tile goes: one place a program, so the last one drawn shows until the next is there.
  static String home(String file) => tileHome('program24', file);

  /// The programs whose tile is not drawn since they last changed, put in line. One that took the window down with it
  /// (its .trying left behind) waits for its file to change.
  static void ask(Iterable<String> files, void Function() changed) {
    if (Platform.environment['FLUTTER_TEST'] == 'true') return; // (as EffectTiles.ask)
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
      m.at(0); // (what is placed comes on where the clock stands)
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
    ]); // (no ffmpeg: the one picture, below)
    File(File(moving).existsSync() ? moving : '$folder/${_pictures ~/ 2}.png').copySync(to);
  }
}
