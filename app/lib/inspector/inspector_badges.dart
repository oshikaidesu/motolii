import 'package:flutter/widgets.dart';

/// The layer mark knocked out in [ink], for a [Badge]'s child (the badge is 16 square: its radius is .32 of that).
void drawLayerMark(Canvas c, Size s, Color ink) {
  final u = s.width / 20, o = s.center(Offset.zero);
  final fill = Paint()..color = ink;
  Paint stroke(double w) => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * u
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Offset p(double x, double y) => o + Offset(x, y) * u;
  Path dia(double y) => Path()
    ..moveTo(p(0, y - 3.2).dx, p(0, y - 3.2).dy)
    ..lineTo(p(6, y).dx, p(6, y).dy)
    ..lineTo(p(0, y + 3.2).dx, p(0, y + 3.2).dy)
    ..lineTo(p(-6, y).dx, p(-6, y).dy)
    ..close();
  c.drawPath(dia(2.2), stroke(1.5));
  c.drawPath(dia(-1.8), fill);
}
