// The motion of each Create recipe, computed by the engine on a project of its own, in another isolate, so the window never
// waits. It reports where every layer and copy is at each time step, in 3D (motolii_path3). The tile draws those positions
// (create_preview.dart). Nothing is cached on disk: the motion is recomputed whenever the shelf is shown.
import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:motolii/storage/halt_flag.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The moving parts of a recipe.
/// Each part has a colour, and for each copy its positions over time (x y z size per time step). [outline] is the SVG
/// path of a path shape, or '' for other kinds. [evenOdd] selects the even-odd fill rule and [edge] means only the
/// outline is drawn.
typedef RecipeMotion =
    List<
      ({
        int colour,
        List<Float32List> copies,
        String outline,
        bool evenOdd,
        bool edge,
      })
    >;

/// The number of time steps a recipe's motion is read at.
const recipeMoments = 24;

const _seconds = 3.0, _mostCopies = 160;

/// Computes the motion of every recipe once, in another isolate, and caches it in memory for the tiles.
abstract final class RecipeMotions {
  static final _all = <String, RecipeMotion>{};
  static bool _asked = false;
  // Set to 1 to tell the isolate to stop after the recipe it is on. The isolate reads it between recipes.
  static HaltFlag? _halt;
  static Completer<void>? _ended;

  /// Stops the computation after the current recipe, closes its project, and waits for the isolate to finish.
  /// This keeps the isolate from opening projects while the app exits, for example when the window closes or a test file
  /// ends. A later [ask] starts again.
  static Future<void> stop() async {
    final halt = _halt, ended = _ended;
    if (halt == null || ended == null) return;
    halt.raise();
    await ended.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    halt.dispose();
    _halt = null;
    _ended = null;
    _asked = false;
  }

  /// Notifies each time another recipe's motion has been read.
  static final ready = ValueNotifier<int>(0);

  /// The motion of [recipe], or null until it has been read.
  static RecipeMotion? of(String recipe) => _all[recipe];

  /// Creates every recipe in [recipes] on a project of its own, reads its motion, and closes the project. Only the
  /// first call does anything. The engine is the one of [ws].
  /// Each recipe's tile can show as soon as its motion is read. A recipe with many copies takes seconds, and the ones
  /// after it do not wait for all of them.
  static void ask(WorkspaceController ws, List<String> recipes) {
    if (_asked) return;
    _asked = true;
    final libDir = parentFolderOf(parentFolderOf(ws.inside!.libPath));
    final port = ReceivePort(),
        halt = _halt = HaltFlag.create(),
        ended = _ended = Completer<void>();
    port.listen((got) {
      if (got case (final String r, final RecipeMotion motion)) {
        _all[r] = motion;
        ready.value++;
      } else {
        port.close();
        if (!ended.isCompleted) ended.complete();
      }
    });
    Isolate.spawn(_reckon, (
      libDir,
      recipes,
      port.sendPort,
      halt.address,
    ), onExit: port.sendPort);
  }

  static void _reckon((String, List<String>, SendPort, int) asked) {
    final (dir, recipes, tell, at) = asked;
    final halt = HaltFlag.at(at);
    final folder = makeTempFolder('motolii_previews');
    final m = Motolii.open(
      '$folder/previews.motolii',
      wide: 1080,
      high: 1080,
      dir: dir,
    );
    if (m == null) return tell.send(null);
    for (final r in recipes) {
      // After a stop request the project is still closed below, as when every recipe is done.
      if (halt.raised) break;
      final before = m.layers.toSet();
      if (m.create(r) == 0) continue;
      final parts =
          <
            ({
              int colour,
              List<Float32List> copies,
              String outline,
              bool evenOdd,
              bool edge,
            })
          >[];
      for (final t in m.layers.where((t) => !before.contains(t))) {
        if (const {
          'behaviour',
          'camera',
          'light',
        }.contains(m.word(t, 'kind'))) {
          continue;
        }
        final n = math.max(1, (m.value(t, 'copies', 0) ?? 1).round());
        final step = math.max(1, (n / _mostCopies).ceil());
        final copies = <Float32List>[];
        for (var c = 0; c < n; c += step) {
          final p = m.path3(t, copy: c, to: _seconds, n: recipeMoments);
          if (p != null) copies.add(Float32List.fromList(p));
        }
        final fill = m.word(t, 'fill').split(' ').first, edge = fill == 'none';
        final outline = m.word(t, 'shape') == 'path' ? m.word(t, 'path') : '';
        parts.add((
          colour:
              0xFF000000 |
              (int.tryParse(edge ? m.word(t, 'stroke') : fill, radix: 16) ??
                  0xD9D2C3),
          copies: copies,
          outline: outline,
          evenOdd: m.word(t, 'fill_rule') == 'evenodd',
          edge: edge,
        ));
      }
      tell.send((r, parts));
    }
    m.close();
    try {
      removeFolder(folder);
    } catch (_) {}
    tell.send(null);
  }
}
