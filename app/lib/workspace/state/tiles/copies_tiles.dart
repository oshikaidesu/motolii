// Tiles for the Copies entries on the Create shelf: the Repeater and any copy expressions the user added (dock_make_3.dart).
// They are drawn the way the Effects shelf draws its tiles (tile_queue.dart and effect_tiles.dart):
// - The engine draws them in another isolate, on a project of its own.
// - Each tile has the sixteen times of tileMoments. They are shrunk with sips, and ffmpeg encodes the moving
//   ones as JPEG.
// - They are cached in ~/Library/Caches/Motolii/tiles, named by the file path and its modification time.
// - TileMoving plays them under the pointer.
// A tile shows the head of the Repeater recipe (create/repeats/repeater.js): a circle with five copies. The file's own
// header lines change it: "// make shape", "// set size" and "// set copies".
// pixels of a composition, here a 1080 square. The file's expression (fx_file) is then applied to that layer.
// If the engine rejects the expression (a SyntaxError), the tile is marked and keeps its glyph.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/script_files.dart' show linesOf, writtenAt;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/workspace/state/tiles/tile_frames.dart';
import 'package:motolii/workspace/state/tiles/tile_media.dart';
import 'package:motolii/workspace/state/tiles/tile_queue.dart';

/// Tiles for the Copies entries on the Create shelf.
abstract final class CopiesTiles {
  static final _tiles = TileQueue<(String, String)>(draw, moving: true);

  /// Notifies after a batch is drawn, so the tiles redraw.
  static final drawn = _tiles.drawn;

  /// The cache path of [file]'s tile, named by its path and modification time, as the engine's doc_tile names an effect's.
  static String home(String file) {
    final at = existsFile(file) ? writtenAt(file).microsecondsSinceEpoch : 0;
    return tileHome('copies', '$file|$at|copies 5');
  }

  /// Returns [file]'s tile, or '' when it is not drawn yet or the engine rejects the file. It is requested once.
  static String of(String file) {
    final h = home(file);
    return _tiles.of(h, (file, h));
  }

  /// Draws each file's tile at its cache path and returns the paths drawn.
  static List<String> draw(String dir, List<(String, String)> files) =>
      drawTiles(dir, 'motolii_copies', files, (j) => j.$2, (m, job, home) {
        // Each tile gets its own project, so the parameter values one expression sets (js_<name>) do not reach the next.
        final (f, _) = job;
        final on = _put(m, f);
        final base = home.substring(0, home.length - 4);
        final pictures = [
          if (on)
            for (final (k, at) in tileMoments.indexed)
              if (m.at(at) && m.still('${base}_$k.png')) '${base}_$k.png',
        ];
        if (pictures.length >= tileMoments.length) {
          runTool('sips', ['-Z', '192', ...pictures]);
          copyFile(pictures[tileStill], home);
          // Without ffmpeg only the still exists.
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
        for (final p in pictures) {
          deleteFile(p);
        }
        return pictures.length >= tileMoments.length;
      });

  /// Builds the tile's layer for expression file [f]: the shape its header names, with the expression applied.
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
    for (final l in linesOf(
      f,
    ).takeWhile((l) => l.startsWith('//') && !l.startsWith('// then '))) {
      if (RegExp(r'^// (say|set) ([a-z_]+) (.+)$').firstMatch(l) case final w?
          when !{'size', 'copies', 'script'}.contains(w[2])) {
        w[1] == 'say'
            ? m.say(t, w[2]!, w[3]!)
            : m.set(t, w[2]!, double.tryParse(w[3]!) ?? 0);
      }
    }
    // A line is thickened so it reads at 192 px.
    if (shape == 'line') m.set(t, 'tall', (_head(f, 'tall') ?? 1) * 4);
    // Apply the file, then check that the engine accepts it as code. A SyntaxError fails (EffectCode: "does not compile").
    return _answered(m, m.later('fx_file', layer: t, word: f)) &&
        _answered(m, m.later('code', word: f));
  }

  /// The number a header line sets, such as "// set size 0.03", or null when the header has none.
  static double? _head(String file, String name) {
    for (final l in linesOf(file).takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// set $name ([0-9.]+)').firstMatch(l)?[1] case final v?) {
        return double.tryParse(v);
      }
    }
    return null;
  }

  /// The word a header line gives, such as "// make shape line", or null when the header has none.
  static String? _said(String file, String what) {
    for (final l in linesOf(file).takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// $what ([a-z_]+)').firstMatch(l)?[1] case final v?) {
        return v;
      }
    }
    return null;
  }

  static bool _answered(Motolii m, int ticket) => _answer(m, ticket) == 1;

  /// Waits for the engine's answer to request [ticket].
  /// Returns -1 if there is no answer within ten seconds. For a created recipe the answer is the new layer.
  static int _answer(Motolii m, int ticket) {
    var a = -1;
    for (var n = 0; n < 2000 && (a = m.answer(ticket)) == -1; n++) {
      pauseFor(const Duration(milliseconds: 5));
    }
    return a;
  }
}
