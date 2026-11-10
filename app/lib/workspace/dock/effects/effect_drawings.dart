// The pictures the app draws itself on an Effects tile, where the engine has no image.
import 'package:flutter/widgets.dart';

/// A tile's image drawn by the app where the engine has none: a layer effect gets its small drawing, Empty gets its plus.
Widget Function(bool) paintedArt(CustomPainter p) =>
    (_) => FittedBox(
      child: CustomPaint(size: const Size(18, 16), painter: p),
    );

/// Small drawings of what the engine's path effects do to a square, for effects the shelf has no image for:
/// a half-drawn path, and a dot moving along one. An effect the app does not know has no drawing.
void drawEffectLook(Canvas c, String name) {
  const ink = Color(0xFFE0A35A), r = Rect.fromLTWH(4, 3, 10, 10);
  switch (name) {
    case 'Trim Paths':
      c.drawArc(
        Rect.fromCircle(center: r.center, radius: 5.5),
        -1.6,
        3.8,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    case 'Move Along Path':
      c.drawArc(
        Rect.fromCircle(center: r.center, radius: 5.5),
        -1.6,
        3.8,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      c.drawCircle(r.center + const Offset(0, -5.5), 2, Paint()..color = ink);
  }
}
