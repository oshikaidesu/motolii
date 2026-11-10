import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// A die showing [face]. It is a solid square in [ink] with dark pips, or only the pips in [ink] when [filled] is false.
class DicePainter extends CustomPainter {
  const DicePainter(this.ink, this.face, {this.filled = true});
  final Color ink;
  final int face;
  final bool filled;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: Shape.z(16),
      height: Shape.z(16),
    );
    if (filled) {
      c.drawRRect(RRect.fromRectAndRadius(r, Shape.r(4)), Paint()..color = ink);
    }
    const pips = {
      1: [(0, 0)],
      2: [(-1, -1), (1, 1)],
      3: [(-1, -1), (0, 0), (1, 1)],
      4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
      5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)],
      6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)],
    };
    for (final (dx, dy) in pips[face]!) {
      c.drawCircle(
        r.center + Offset(dx * 4.0, dy * 4.0),
        1.5,
        Paint()..color = filled ? Grey.g10 : ink,
      );
    }
  }

  @override
  bool shouldRepaint(DicePainter o) =>
      o.ink != ink || o.face != face || o.filled != filled;
}
