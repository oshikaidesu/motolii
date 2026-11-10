// The stage's rulers along its edges and the points of a path, drawn over the preview.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/stage/view_painter.dart' show linePaint;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/art_scene.dart';

/// Paints the rulers along the top and the left of the stage, with the guides' markers and the pointer's position.
class RulerPainter extends CustomPainter {
  RulerPainter(this.v, this.cursor, this.scene) : super(repaint: cursor);
  final StageViewport v;
  final ArtScene scene;
  final ValueNotifier<Offset?> cursor;

  static double _step(double s) {
    for (final st in [25.0, 50.0, 100.0, 200.0, 250.0, 500.0, 1000.0]) {
      if (st * s >= 56) return st;
    }
    return 2000;
  }

  @override
  void paint(Canvas c, Size size) {
    final r = StageTokens.ruler;
    final comp = v.compositionRect,
        bg = Paint()..color = StageTokens.rulerGround,
        span = Paint()..color = StageTokens.rulerSpan;
    c.drawRect(Rect.fromLTWH(0, 0, size.width, r), bg);
    c.drawRect(Rect.fromLTWH(0, 0, r, size.height), bg);
    c.drawRect(
      Rect.fromLTRB(
        math.max(comp.left, r),
        0,
        math.min(comp.right, size.width),
        r,
      ),
      span,
    );
    c.drawRect(
      Rect.fromLTRB(
        0,
        math.max(comp.top, r),
        r,
        math.min(comp.bottom, size.height),
      ),
      span,
    );
    final edge = linePaint(WindowTokens.line);
    c.drawLine(Offset(0, r - .5), Offset(size.width, r - .5), edge);
    c.drawLine(Offset(r - .5, 0), Offset(r - .5, size.height), edge);
    final step = _step(v.scale),
        minor = step / 5,
        tick = Paint()..color = StageTokens.tick;
    final label = TextStyles.micro(Grey.g56);

    c.save();
    c.clipRect(Rect.fromLTWH(r, 0, size.width - r, r));
    final x0 = (v.toComposition(Offset(r, 0)).dx / minor).floor() * minor,
        x1 = v.toComposition(Offset(size.width, 0)).dx;
    for (var x = x0; x <= x1; x += minor) {
      final sx = v.toScreen(Offset(x, 0)).dx.roundToDouble() + .5,
          major = (x / step).round() * step == x;
      c.drawLine(Offset(sx, major ? 2 : r - 4), Offset(sx, r), tick);
      if (major) lineText('${x.round()}', label).paint(c, Offset(sx + 3, 2));
    }
    c.restore();

    c.save();
    c.clipRect(Rect.fromLTWH(0, r, r, size.height - r));
    final y0 = (v.toComposition(Offset(0, r)).dy / minor).floor() * minor,
        y1 = v.toComposition(Offset(0, size.height)).dy;
    for (var y = y0; y <= y1; y += minor) {
      final sy = v.toScreen(Offset(0, y)).dy.roundToDouble() + .5,
          major = (y / step).round() * step == y;
      c.drawLine(Offset(major ? 2 : r - 4, sy), Offset(r, sy), tick);
      if (major) {
        c.save();
        c.translate(2, sy - 3);
        c.rotate(-math.pi / 2);
        lineText('${y.round()}', label).paint(c, Offset.zero);
        c.restore();
      }
    }
    c.restore();

    final g = Paint()..color = StageTokens.guide;
    for (final gx in scene.guidesX) {
      final x = v.toScreen(Offset(gx, 0)).dx;
      if (x > r) {
        c.drawPath(
          Path()..addPolygon([
            Offset(x - 4, r - 5),
            Offset(x + 4, r - 5),
            Offset(x, r),
          ], true),
          g,
        );
      }
    }
    for (final gy in scene.guidesY) {
      final y = v.toScreen(Offset(0, gy)).dy;
      if (y > r) {
        c.drawPath(
          Path()..addPolygon([
            Offset(r - 5, y - 4),
            Offset(r - 5, y + 4),
            Offset(r, y),
          ], true),
          g,
        );
      }
    }

    if (cursor.value case final p?) {
      final s = v.toScreen(p),
          hot = Paint()
            ..color = WindowTokens.accent
            ..strokeWidth = 1;
      if (s.dx > r) c.drawLine(Offset(s.dx, 0), Offset(s.dx, r), hot);
      if (s.dy > r) c.drawLine(Offset(0, s.dy), Offset(r, s.dy), hot);
    }
    c.drawRect(Rect.fromLTWH(0, 0, r, r), bg);
  }

  @override
  bool shouldRepaint(RulerPainter o) =>
      o.v != v || o.cursor != cursor || o.scene != scene;
}

/// Paints a path's points as squares and its bezier handles as dots on a line to their point.
class PointsPainter extends CustomPainter {
  PointsPainter(this.at, this.handles);
  final List<Offset> at;
  final List<(Offset, Offset)> handles;
  @override
  void paint(Canvas c, Size _) {
    final edge = linePaint(WindowTokens.accent),
        inside = Paint()..color = const Color(0xFFFFFFFF);
    for (final (h, o) in handles) {
      if ((h - o).distance < 1) continue;
      c
        ..drawLine(o, h, edge)
        ..drawCircle(h, 3, inside)
        ..drawCircle(h, 3, edge);
    }
    for (final p in at) {
      final r = Rect.fromCenter(
        center: p,
        width: Shape.z(6),
        height: Shape.z(6),
      );
      c
        ..drawRect(r, inside)
        ..drawRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(PointsPainter o) =>
      !listEquals(o.at, at) || !listEquals(o.handles, handles);
}
