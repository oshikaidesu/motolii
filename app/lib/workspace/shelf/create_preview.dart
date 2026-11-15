// Motion previews for the recipe tiles on the Create shelf.
//
// The engine creates each recipe on a project of its own, in another isolate so the window never waits (state/recipe_motions.dart).
// It reports where every layer and copy is at each time step, in 3D (motolii_path3). The tile draws those positions as points, seen a
// little from above and turning, and loops them. Nothing is cached on disk: the motion is recomputed whenever the shelf
// is shown.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import 'package:motolii/workspace/state/tiles/recipe_motions.dart';

export 'package:motolii/workspace/state/tiles/recipe_motions.dart'
    show RecipeMotion, RecipeMotions;

final _clock = ValueNotifier<int>(0);
Timer? _ticking;

/// A recipe's motion drawn in its tile, looping by itself.
class RecipeMotionView extends StatelessWidget {
  const RecipeMotionView(this.recipe, {super.key});

  /// The recipe whose motion is shown.
  final String recipe;
  @override
  Widget build(BuildContext context) {
    _ticking ??= Timer.periodic(
      const Duration(milliseconds: 1000 * 3 ~/ 24),
      (_) => _clock.value++,
    );
    return ValueListenableBuilder<int>(
      valueListenable: RecipeMotions.ready,
      builder: (context, _, _) {
        final motion = RecipeMotions.of(recipe);
        if (motion == null || motion.isEmpty) return const SizedBox.shrink();
        // A single path shape that does not move is drawn as its outline.
        if (motion case [final one]
            when one.outline.isNotEmpty && one.copies.length <= 1) {
          return _Outline(one);
        }
        return ValueListenableBuilder<int>(
          valueListenable: _clock,
          builder: (context, k, _) => CustomPaint(
            painter: _MotionPainter(motion, k % recipeMoments, k),
          ),
        );
      },
    );
  }
}

class _MotionPainter extends CustomPainter {
  _MotionPainter(this.motion, this.at, this.tick);
  final RecipeMotion motion;
  final int at, tick;

  @override
  void paint(Canvas canvas, Size s) {
    // View from slightly above, turning slowly, so depth reads as depth.
    final look = Matrix4.identity()
      ..rotateX(-0.35)
      ..rotateY(tick * 0.01);
    final points = <(Offset, double, int)>[];
    var lo = const Offset(double.infinity, double.infinity),
        hi = const Offset(-double.infinity, -double.infinity);
    for (final part in motion) {
      for (final c in part.copies) {
        for (var i = 0; i < c.length ~/ 4; i++) {
          // The bounding box covers every time step, so the picture stays fitted while the points move.
          final v = look.transform3(
            Vector3(c[4 * i], c[4 * i + 1], c[4 * i + 2]),
          );
          final o = Offset(v.x, -v.y);
          lo = Offset(math.min(lo.dx, o.dx), math.min(lo.dy, o.dy));
          hi = Offset(math.max(hi.dx, o.dx), math.max(hi.dy, o.dy));
          if (i == at) points.add((o, c[4 * i + 3], part.colour));
        }
      }
    }
    if (points.isEmpty) return;
    final span = math.max(hi.dx - lo.dx, hi.dy - lo.dy), pad = 6.0;
    final k = span <= 0 ? 1.0 : (math.min(s.width, s.height) - 2 * pad) / span;
    final mid = (lo + hi) / 2, centre = Offset(s.width / 2, s.height / 2);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final (o, size, colour) in points) {
      paint
        ..color = Color(colour)
        ..strokeWidth = (1.6 + size.abs() * 1.2).clamp(1.2, 5.0);
      canvas.drawPoints(PointMode.points, [centre + (o - mid) * k], paint);
    }
  }

  @override
  bool shouldRepaint(_MotionPainter o) =>
      o.at != at || o.tick != tick || !identical(o.motion, motion);
}

/// A path shape's outline in its tile, in its own colour and fitted to the tile, drawn by flutter_svg.
///
/// The path uses M, L, C and Z commands, so its numbers alternate x and y.
class _Outline extends StatelessWidget {
  const _Outline(this.part);
  final ({
    int colour,
    List<Float32List> copies,
    String outline,
    bool evenOdd,
    bool edge,
  })
  part;
  @override
  Widget build(BuildContext context) {
    final n = [
      for (final m in RegExp(
        r'-?[0-9.]+(?:e-?[0-9]+)?',
      ).allMatches(part.outline))
        double.parse(m.group(0)!),
    ];
    if (n.length < 2) return const SizedBox.shrink();
    final xs = [for (var i = 0; i + 1 < n.length; i += 2) n[i]],
        ys = [for (var i = 1; i < n.length; i += 2) n[i]];
    final lo = (xs.reduce(math.min), ys.reduce(math.min)),
        side = math.max(
          xs.reduce(math.max) - lo.$1,
          ys.reduce(math.max) - lo.$2,
        ),
        pad = side * .12 + .05;
    final hex = (part.colour & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final paint = part.edge
        ? 'fill="none" stroke="#$hex" stroke-width="${side * .08}" stroke-linecap="round"'
        : 'fill="#$hex"${part.evenOdd ? ' fill-rule="evenodd"' : ''}';
    return Padding(
      // Leaves room for the tile's name below.
      padding: const EdgeInsets.only(bottom: 14),
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${lo.$1 - pad} ${lo.$2 - pad} ${side + 2 * pad} ${side + 2 * pad}"><path d="${part.outline}" $paint/></svg>',
      ),
    );
  }
}
