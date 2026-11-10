// Tiles for the Copies entries on the Create shelf: the Repeater and any copy expressions the user added (dock_make_3.dart).
//
// They are drawn the way the Effects shelf draws its tiles (effect_tiles.dart):
// - The engine draws them in another isolate, on a project of its own.
// - Each tile has the sixteen times of EffectTiles.moments. They are shrunk with sips, and ffmpeg encodes the moving
//   ones as JPEG.
// - They are cached in ~/Library/Caches/Motolii/tiles, named by the file path and its modification time.
// - TileMoving plays them under the pointer.
//
// A tile shows the head of the Repeater recipe (create/repeats/repeater.js): a circle with five copies. The file's own
// header lines change it: "// make shape", "// set size" and "// set copies". After Effects expressions work in the
// pixels of a composition, here a 1080 square. The file's expression (fx_file) is then applied to that layer.
// If the engine rejects the expression (a SyntaxError), the tile is marked and keeps its glyph.
//
// A closed pack on the Program shelf (dock_program.dart) is drawn the same way, but it is created by name, as the
// shelf creates it.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FileImage, ResizeImage;

import '../../bridge/motolii.dart';
import 'effect_tiles.dart' show EffectTiles, ffmpeg;

/// The cache path of a tile: [kind] and a hash of [key] under the tiles' cache folder.
String tileHome(String kind, String key) {
  var hash = 1469598103934665603;
  for (final c in key.codeUnits) {
    hash = (hash ^ c) * 1099511628211;
  }
  return '${Platform.environment['HOME']}/Library/Caches/Motolii/tiles/${kind}_${(hash & 0x7fffffffffffffff).toRadixString(16)}.png';
}

/// A queue that draws the tiles of one kind, each requested once, in another isolate.
///
/// [draw] draws up to [batch] jobs at a time and returns the paths it drew. With [moving], the frames beside each still
/// are evicted from the image cache too. [progress] reports how many are drawn out of how many.
class TileQueue<T> {
  TileQueue(this.draw, {this.moving = false, this.batch = 1 << 30, this.progress});
  final List<String> Function(String dir, List<T> jobs) draw;
  final bool moving;
  final int batch;
  final ValueNotifier<(int, int)?>? progress;
  final _asked = <String>{}, _queue = <T>[];
  var _drawing = false;

  /// Notifies after a batch is drawn, so the tiles redraw.
  final drawn = ValueNotifier<int>(0);

  /// Called with the paths of each batch drawn.
  void Function(List<String> homes)? onDrawn;

  /// Returns the tile at [home], or '' when it is not drawn yet or the engine could not draw it.
  ///
  /// [job] is queued once.
  String of(String home, T job) {
    if (File(home).existsSync()) return home;
    if (!File('$home.none').existsSync()) {
      ask(home, job);
      start();
    }
    return '';
  }

  /// Queues [job] once per [key], at index [at] or at the end, whatever is on disk (the caller has decided the tile is stale).
  ///
  /// Returns false when [key] was already requested, or under flutter test, where nothing is drawn.
  bool ask(String key, T job, {int? at}) {
    if (Platform.environment['FLUTTER_TEST'] == 'true' || !_asked.add(key)) return false;
    _queue.insert(at ?? _queue.length, job);
    return true;
  }

  void forget(String key) => _asked.remove(key);
  void drop(bool Function(T job) where) => _queue.removeWhere(where);
  void start() {
    if (!_drawing && _queue.isNotEmpty) unawaited(_work());
  }

  Future<void> _work() async {
    _drawing = true;
    final dir = motoliiDir, draw = this.draw;
    var done = 0;
    try {
      while (_queue.isNotEmpty) {
        progress?.value = (done, done + _queue.length);
        final some = _queue.take(batch).toList();
        _queue.removeRange(0, some.length);
        done += some.length;
        final homes = await Isolate.run(() => draw(dir, some));
        for (final h in homes) {
          for (final p in [
            h,
            if (moving)
              for (final (k, _) in EffectTiles.moments.indexed) EffectTiles.frame(h, k),
          ]) {
            ResizeImage(FileImage(File(p)), width: EffectTiles.readWide).evict();
          }
        }
        onDrawn?.call(homes);
        drawn.value++;
      }
    } catch (_) {
    } finally {
      _drawing = false;
      progress?.value = null;
    }
  }
}

/// Draws each job's tile on a project of its own (1080 square, in a temp folder named from [prefix]) at [homeOf].
///
/// [one] draws a single tile. If it returns false or throws, a `.none` file marks that the engine could not draw it.
/// Returns the paths of the tiles made.
List<String> drawTiles<T>(String dir, String prefix, List<T> jobs, String Function(T) homeOf, bool Function(Motolii m, T job, String home) one) {
  final folder = Directory.systemTemp.createTempSync(prefix), made = <String>[];
  for (final (i, job) in jobs.indexed) {
    final home = homeOf(job), m = Motolii.open('${folder.path}/$i.motolii', wide: 1080, high: 1080, dir: dir);
    if (m == null) continue;
    try {
      Directory(File(home).parent.path).createSync(recursive: true);
      if (one(m, job, home)) {
        made.add(home);
      } else {
        File('$home.none').writeAsStringSync('');
      }
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

/// Tiles for the Copies entries on the Create shelf.
abstract final class CopiesTiles {
  static final _tiles = TileQueue<(String, String, String?)>(draw, moving: true);

  /// Notifies after a batch is drawn, so the tiles redraw.
  static final drawn = _tiles.drawn;

  /// The cache path of [file]'s tile, named by its path and modification time, as the engine's doc_tile names an effect's.
  static String home(String file, {String? make}) {
    final at = File(file).existsSync() ? File(file).lastModifiedSync().microsecondsSinceEpoch : 0;
    return tileHome('copies', '$file|$at|${make == null ? 'copies 5' : 'make $make'}');
  }

  /// Returns [file]'s tile, or '' when it is not drawn yet or the engine rejects the file. It is requested once.
  ///
  /// With [make], the recipe of that name is created from [file] as it is (a pack).
  static String of(String file, {String? make}) {
    final h = home(file, make: make);
    return _tiles.of(h, (file, h, make));
  }

  /// Draws each file's tile at its cache path and returns the paths drawn.
  static List<String> draw(String dir, List<(String, String, String?)> files) => drawTiles(dir, 'motolii_copies', files, (j) => j.$2, (m, job, home) {
    // Each tile gets its own project, so the parameter values one expression sets (js_<name>) do not reach the next.
    final (f, _, make) = job;
    // A pack is created by name, as the Program shelf creates it.
    final on = make != null ? _answer(m, m.later('create', word: make)) >= 1 : _put(m, f);
    final base = home.substring(0, home.length - 4);
    final pictures = [
      if (on)
        for (final (k, at) in EffectTiles.moments.indexed)
          if (m.at(at) && m.still('${base}_$k.png')) '${base}_$k.png',
    ];
    if (pictures.length >= EffectTiles.moments.length) {
      Process.runSync('sips', ['-Z', '192', ...pictures]);
      File(pictures[EffectTiles.still]).copySync(home);
      // Without ffmpeg only the still exists.
      ffmpeg(['-i', '${base}_%d.png', '-q:v', '6', '-start_number', '0', '${base}_%d.jpg']);
    }
    for (final p in pictures) {
      File(p).deleteSync();
    }
    return pictures.length >= EffectTiles.moments.length;
  });

  /// Builds the tile's layer for expression file [f]: the shape its header names, with the expression applied.
  ///
  /// Returns whether the engine accepted the expression as code.
  static bool _put(Motolii m, String f) {
    // The header's shape, for example the lines of a maze.
    final shape = _said(f, 'make shape') ?? 'circle', t = m.add('shape', shape);
    m
      ..say(t, 'fill', 'ff3366')
      // Enlarged so it stays visible at 192 px.
      ..set(t, 'size', (_head(f, 'size') ?? 0.1) * 2.5)
      ..set(t, 'copies', _head(f, 'copies') ?? 5);
    // The other header lines set the layer's remaining values, as the recipe does, such as a maze's white or a row's height.
    for (final l in File(f).readAsLinesSync().takeWhile((l) => l.startsWith('//') && !l.startsWith('// then '))) {
      if (RegExp(r'^// (say|set) ([a-z_]+) (.+)$').firstMatch(l) case final w? when !{'size', 'copies', 'script'}.contains(w[2])) {
        w[1] == 'say' ? m.say(t, w[2]!, w[3]!) : m.set(t, w[2]!, double.tryParse(w[3]!) ?? 0);
      }
    }
    // A line is thickened so it reads at 192 px.
    if (shape == 'line') m.set(t, 'tall', (_head(f, 'tall') ?? 1) * 4);
    // Apply the file, then check that the engine accepts it as code. A SyntaxError fails (FxCode: "does not compile").
    return _answered(m, m.later('fx_file', layer: t, word: f)) && _answered(m, m.later('code', word: f));
  }

  /// The number a header line sets, such as "// set size 0.03", or null when the header has none.
  static double? _head(String file, String name) {
    for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// set $name ([0-9.]+)').firstMatch(l)?[1] case final v?) return double.tryParse(v);
    }
    return null;
  }

  /// The word a header line gives, such as "// make shape line", or null when the header has none.
  static String? _said(String file, String what) {
    for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// $what ([a-z_]+)').firstMatch(l)?[1] case final v?) return v;
    }
    return null;
  }

  static bool _answered(Motolii m, int ticket) => _answer(m, ticket) == 1;

  /// Waits for the engine's answer to request [ticket].
  ///
  /// Returns -1 if there is no answer within ten seconds. For a created recipe the answer is the new layer.
  static int _answer(Motolii m, int ticket) {
    var a = -1;
    for (var n = 0; n < 2000 && (a = m.answer(ticket)) == -1; n++) {
      sleep(const Duration(milliseconds: 5));
    }
    return a;
  }
}
