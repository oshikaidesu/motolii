// Helpers for drawing in a painter: a painted glyph for a press tile, text and dashed lines.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// A painted glyph for an [IconPress] tile: fills the tile, in the ink the press gives.
Widget Function(Color) paintInk(CustomPainter Function(Color ink) glyph) =>
    (ink) => SizedBox.expand(child: CustomPaint(painter: glyph(ink)));

/// Draws a line of text in a painter, anchored by [ax] / [ay] (0 left/top, 1 right/bottom).
void toolText(Canvas c, String s, Offset at, TextStyle st, {double ax = 0, double ay = 0}) {
  final tp = lineText(s, st);
  tp.paint(c, at - Offset(tp.width * ax, tp.height * ay));
  tp.dispose();
}

/// A straight dashed line from [p] to [q]: [on] long, [off] apart.
void dashed(Canvas c, Offset p, Offset q, Color ink, double wide, double on, double off) {
  final line = Paint()
        ..color = ink
        ..strokeWidth = wide,
      far = (q - p).distance;
  for (var d = 0.0; d < far; d += on + off) {
    c.drawLine(Offset.lerp(p, q, d / far)!, Offset.lerp(p, q, ((d + on) / far).clamp(0.0, 1.0))!, line);
  }
}
