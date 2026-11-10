import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/skin/tokens.dart';

/// A small live picture of a value, shown beside its label.
///
/// It draws a pie for a percentage, a bar for a level and a dot for a point.
class Gauge extends StatelessWidget {
  const Gauge(this.v, this.p, {super.key, this.x, this.y});
  final double? v, x, y;
  final Parameter p;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(22, 22), painter: _GaugePainter(v, p, x, y));
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.v, this.p, this.x, this.y);
  final double? v, x, y;
  final Parameter p;

  double _t(double? val) {
    final a = p.min, b = p.max;
    if (val == null || a == null || b == null || b == a) return 0;
    return ((val - a) / (b - a)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final dim = Paint()..color = Grey.g26;
    final lit = Paint()..color = Grey.g91;
    final line = Paint()
      ..color = Grey.g56
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    switch (p.look) {
      case ParameterLook.percent:
        final r = Rect.fromCircle(center: o, radius: 8);
        c.drawCircle(o, 8, dim);
        final t =
            (v ?? 0) /
            ((p.max ?? 100) == 0
                ? 100
                : (p.max!.abs() > 100 ? p.max!.abs() : 100));
        c.drawArc(r, -math.pi / 2, 2 * math.pi * t.clamp(-1.0, 1.0), true, lit);
        if (t.abs() > 1) c.drawCircle(o, 8, line..color = Grey.g91);
      case ParameterLook.vertical:
        final box = Rect.fromCenter(
          center: o,
          width: Shape.z(8),
          height: Shape.z(18),
        );
        c.drawRRect(RRect.fromRectAndRadius(box, Shape.r(2)), dim);
        final h = box.height * _t(v);
        final fill = Rect.fromLTRB(
          box.left,
          box.bottom - h,
          box.right,
          box.bottom,
        );
        c.drawRRect(RRect.fromRectAndRadius(fill, Shape.r(2)), lit);
        final tip = box.top - 1;
        c.drawLine(Offset(o.dx - 2.5, tip + 2.5), Offset(o.dx, tip), line);
        c.drawLine(Offset(o.dx + 2.5, tip + 2.5), Offset(o.dx, tip), line);
      case ParameterLook.horizontal:
        final box = Rect.fromCenter(
          center: o,
          width: Shape.z(18),
          height: Shape.z(8),
        );
        c.drawRRect(RRect.fromRectAndRadius(box, Shape.r(2)), dim);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(box.left, box.top, box.width * _t(v), box.height),
            Shape.r(2),
          ),
          lit,
        );
      case ParameterLook.bipolar:
        final box = Rect.fromCenter(
          center: o,
          width: Shape.z(18),
          height: Shape.z(8),
        );
        c.drawRRect(RRect.fromRectAndRadius(box, Shape.r(2)), dim);
        final z = box.left + box.width * _t(0),
            at = box.left + box.width * _t(v);
        c.drawRect(
          Rect.fromLTRB(math.min(z, at), box.top, math.max(z, at), box.bottom),
          lit,
        );
        c.drawLine(Offset(z, box.top - 2), Offset(z, box.bottom + 2), line);
      case ParameterLook.bar:
        final t = _t(v);
        for (var i = 0; i < 5; i++) {
          final h = 4.0 + i * 3;
          final r = Rect.fromLTWH(o.dx - 9 + i * 3.8, o.dy + 8 - h, 2.6, h);
          c.drawRRect(
            RRect.fromRectAndRadius(r, Shape.r(1)),
            (i + .5) / 5 <= t ? lit : dim,
          );
        }
      case ParameterLook.scrub:
        c.drawLine(Offset(o.dx - 7, o.dy), Offset(o.dx + 7, o.dy), line);
        for (final d in const [-1.0, 1.0]) {
          final tip = Offset(o.dx + d * 8, o.dy);
          c.drawLine(tip, tip + Offset(-d * 3, -3), line);
          c.drawLine(tip, tip + Offset(-d * 3, 3), line);
        }
      case ParameterLook.point:
        final box = Rect.fromCenter(
          center: o,
          width: Shape.z(18),
          height: Shape.z(18),
        );
        c.drawRRect(RRect.fromRectAndRadius(box, Shape.r(3)), dim);
        final px = box.left + box.width * _t(x),
            py = box.top + box.height * _t(y);
        c.drawLine(Offset(px, box.top), Offset(px, box.bottom), line);
        c.drawLine(Offset(box.left, py), Offset(box.right, py), line);
        c.drawCircle(Offset(px, py), 2.6, lit);
      case ParameterLook.size:
        final mx = math.max(x ?? 1, y ?? 1).abs();
        final w = mx == 0 ? 0.0 : 18 * (x ?? 0).abs() / mx,
            h = mx == 0 ? 0.0 : 18 * (y ?? 0).abs() / mx;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: o,
              width: math.max(w, 1.5),
              height: math.max(h, 1.5),
            ),
            Shape.r(2),
          ),
          lit,
        );
      default:
    }
  }

  @override
  bool shouldRepaint(_GaugePainter o) =>
      o.v != v || o.x != x || o.y != y || o.p != p;
}
