import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge;
import 'package:motolii/widgets/media.dart' show Draw;

/// Draws the layer mark in [ink], for use as the child of a [Badge].
///
/// The badge is 16 square and its corner radius is 0.32 of that.
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

/// The small round badge at the head of a card or a ghost of one: the layer mark in white on [tone].
Widget layerBadge(Color tone) => Badge(
  tone,
  size: 16,
  radius: const Radius.circular(16 * .32),
  mark: Draw(
    (c, s) => drawLayerMark(c, s, InspectorSkin.onAccent),
    InspectorSkin.onAccent,
  ),
);
