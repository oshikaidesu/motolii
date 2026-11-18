// The queue that draws tiles in another isolate, one batch after another, and the cache path a tile is drawn to.
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/engine_paths.dart' show motoliiDir;
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/storage/disk.dart' show existsFile, imageFile;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/workspace/state/tiles/tile_frames.dart';

/// The cache path of a tile: [kind] and a hash of [key] under the tiles' cache folder.
String tileHome(String kind, String key) {
  var hash = 1469598103934665603;
  for (final c in key.codeUnits) {
    hash = (hash ^ c) * 1099511628211;
  }
  return '${envVar('HOME')}/Library/Caches/Motolii/tiles/${kind}_${(hash & 0x7fffffffffffffff).toRadixString(16)}.png';
}

/// A queue that draws the tiles of one kind, each requested once, in another isolate.
/// [draw] draws up to [batch] jobs at a time and returns the paths it drew. With [moving], the frames beside each still
/// are evicted from the image cache too. [progress] reports how many are drawn out of how many.
class TileQueue<T> {
  TileQueue(
    this.draw, {
    this.moving = false,
    this.batch = 1 << 30,
    this.progress,
  });
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
  /// [job] is queued once.
  String of(String home, T job) {
    if (existsFile(home)) return home;
    if (!existsFile('$home.none')) {
      ask(home, job);
      start();
    }
    return '';
  }

  /// Queues [job] once per [key], at index [at] or at the end, whatever is on disk (the caller has decided the tile is stale).
  /// Returns false when [key] was already requested, or under flutter test, where nothing is drawn.
  bool ask(String key, T job, {int? at}) {
    if (envVar('FLUTTER_TEST') == 'true' || !_asked.add(key)) {
      return false;
    }
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
              for (final (k, _) in tileMoments.indexed) tileFrame(h, k),
          ]) {
            imageFile(p, cacheWidth: tileReadWide).evict();
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
/// [one] draws a single tile. If it returns false or throws, a `.none` file marks that the engine could not draw it.
/// Returns the paths of the tiles made.
List<String> drawTiles<T>(
  String dir,
  String prefix,
  List<T> jobs,
  String Function(T) homeOf,
  bool Function(Motolii m, T job, String home) one,
) {
  final folder = makeTempFolder(prefix), made = <String>[];
  for (final (i, job) in jobs.indexed) {
    final home = homeOf(job),
        m = Motolii.open(
          '$folder/$i.motolii',
          wide: 1080,
          high: 1080,
          dir: dir,
        );
    if (m == null) continue;
    try {
      makeFolderOf(home);
      if (one(m, job, home)) {
        made.add(home);
      } else {
        writeText('$home.none', '');
      }
    } catch (_) {
      try {
        writeText('$home.none', '');
      } catch (_) {}
    } finally {
      m.close();
    }
  }
  try {
    removeFolder(folder);
  } catch (_) {}
  return made;
}
