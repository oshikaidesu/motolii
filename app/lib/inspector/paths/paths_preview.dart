// The shape preview at the top of the Paths card: the engine's outline fitted into a small box,
// with a fallback polygon when SVG path data is not available.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

import 'package:motolii/skin/tokens.dart';

class PathsPreview extends StatelessWidget {
  const PathsPreview({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
    super.key,
  });
  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: CustomPaint(
      key: const ValueKey('paths-preview'),
      size: Size.fromHeight(Shape.z(60)),
      painter: _PreviewPaint(
        round: round,
        points: points,
        inner: inner,
        shape: shape,
        svgPath: svgPath,
      ),
    ),
  );
}

class _PreviewPaint extends CustomPainter {
  const _PreviewPaint({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
  });
  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;

  // The engine's outline (motolii_shape_svg: SVG path data) as a Path fitted into a 2 [r] box about ([cx], [cy]).
  // The outline is meant to be a unit high about the origin, but a strong deform (a large round, a rough edge) carries
  // it well past that, so its real bounds are measured and scaled to fit rather than assumed. Null when it is not path data.
  Path? _parseSvg(double cx, double cy, double r) {
    final unit = Path();
    try {
      writeSvgPathDataToPath(svgPath, _IntoPath(unit));
    } catch (_) {
      return null;
    }
    final b = unit.getBounds();
    if (b.isEmpty) return null;
    final k = r * 2 / math.max(b.width, b.height);
    return unit.transform(
      Float64List.fromList([
        k,
        0,
        0,
        0,
        0,
        k,
        0,
        0,
        0,
        0,
        1,
        0,
        cx - b.center.dx * k,
        cy - b.center.dy * k,
        0,
        1,
      ]),
    );
  }

  Path _fallbackPath(double cx, double cy, double r) {
    final path = Path();
    final isRect = shape == 'rect' && points == 4 && inner <= 0;
    if (points == 0 || points >= 50) {
      path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    } else if (isRect || points < 3) {
      final rr = math.min(round * r * 2, r * 0.49);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          Radius.circular(rr),
        ),
      );
    } else {
      final rr = round.clamp(0.0, 0.49) * r;
      final step = 2 * math.pi / points;
      final start = -math.pi / 2;
      for (var i = 0; i < points; i++) {
        final a = start + step * i;
        final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else if (rr > 0) {
          final prev = start + step * (i - 1);
          final mx = cx + r * math.cos(prev + step / 2) * 0.95;
          final my = cy + r * math.sin(prev + step / 2) * 0.95;
          path.quadraticBezierTo(mx, my, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)),
      Paint()..color = Grey.g07,
    );
    final cx = s.width / 2, cy = s.height / 2;
    final r = math.min(s.width, s.height) * 0.32;
    final path =
        (svgPath.isNotEmpty ? _parseSvg(cx, cy, r) : null) ??
        _fallbackPath(cx, cy, r);
    c.drawPath(
      path,
      Paint()
        ..color = Grey.g15
        ..style = PaintingStyle.fill,
    );
    c.drawPath(
      path,
      Paint()
        ..color = Accent.fill.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PreviewPaint o) =>
      o.round != round ||
      o.points != points ||
      o.inner != inner ||
      o.shape != shape ||
      o.svgPath != svgPath;
}

/// What path_parsing reads of an SVG path, drawn into a Flutter [Path].
class _IntoPath extends PathProxy {
  _IntoPath(this.path);
  final Path path;
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}
