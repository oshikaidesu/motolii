// The small pictures before the Transform rows: each row's value as a shape, read before its number is.
// Restored from 52289b693~1 (inspector_direct_transform_value_glyph.dart, LinkMark in inspector_small.dart).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// The four-way arrows every hand knows for moving a thing.
void drawMove(Canvas c, Size s, Color ink) {
  final mid = s.center(Offset.zero);
  final arm = Paint()
    ..color = ink
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final d = Offset(math.cos(i * math.pi / 2), math.sin(i * math.pi / 2)),
        tip = mid + d * 8,
        side = Offset(-d.dy, d.dx) * 2.5;
    c.drawLine(mid, tip, arm);
    c.drawLine(tip, tip - d * 2.5 + side, arm);
    c.drawLine(tip, tip - d * 2.5 - side, arm);
  }
}

/// The scale's proportion: a uniform scale keeps the square.
void drawScale(Canvas c, Size s, Color ink, double sx, double sy) {
  final big = math.max(sx.abs(), sy.abs());
  c.drawRect(
    Rect.fromCenter(
      center: s.center(Offset.zero),
      width: big == 0 ? 1 : math.max(1.5, 14 * sx.abs() / big),
      height: big == 0 ? 1 : math.max(1.5, 14 * sy.abs() / big),
    ),
    Paint()..color = ink.withValues(alpha: .85),
  );
}

/// A dial pointing the way the layer is turned, with a dot for each whole turn (up to three).
void drawRotation(Canvas c, Size s, Color ink, double degrees) {
  final mid = s.center(Offset.zero), a = degrees * math.pi / 180 - math.pi / 2;
  c.drawCircle(
    mid,
    8,
    Paint()
      ..color = Grey.g44
      ..style = PaintingStyle.stroke,
  );
  c.drawLine(
    mid,
    mid + Offset(math.cos(a), math.sin(a)) * 8,
    Paint()
      ..color = ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
  c.drawCircle(mid, 1.5, Paint()..color = ink);
  for (var i = 0; i < (degrees.abs() / 360).floor().clamp(0, 3); i++) {
    c.drawCircle(Offset(s.width - 1.5, 2 + i * 4.0), 1.2, Paint()..color = ink);
  }
}

/// A checkerboard under a square as opaque as the layer; the checks always show through a little.
void drawOpacity(Canvas c, Size s, Color ink, double percent) {
  final r = Rect.fromCenter(
    center: s.center(Offset.zero),
    width: 14,
    height: 14,
  );
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      c.drawRect(
        Rect.fromLTWH(r.left + x * 3.5, r.top + y * 3.5, 3.5, 3.5),
        Paint()..color = (x + y).isEven ? Grey.g26 : Grey.g15,
      );
    }
  }
  c.drawRect(
    r,
    Paint()
      ..color = ink.withValues(alpha: .1 + .7 * (percent / 100).clamp(0, 1)),
  );
  c.drawRect(
    r,
    Paint()
      ..color = Grey.g44
      ..style = PaintingStyle.stroke,
  );
}

/// Two links of a chain: drawn solid when the layer goes with a parent, grey when it goes with none.
/// [open] draws them apart with a break, as a free link between two fields.
void drawChain(
  Canvas c,
  Size s,
  Color ink, {
  bool open = false,
  double width = 2,
  double scale = 1,
}) {
  final mid = s.center(Offset.zero);
  c.save();
  c.translate(mid.dx, mid.dy);
  c.scale(scale);
  c.translate(-mid.dx, -mid.dy);
  final ring = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  final gap = open ? 1.5 : 0.0;
  for (final dir in const [-1.0, 1.0]) {
    c.save();
    c.translate(mid.dx + dir * (3.5 + gap), mid.dy - dir * (3.5 + gap));
    c.rotate(-math.pi / 4);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 11, height: 6),
        const Radius.circular(3),
      ),
      ring,
    );
    c.restore();
  }
  c.restore();
}
