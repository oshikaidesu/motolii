// Live vector typography marks for the Text card's compact numeric rows
// (mirroring transform/row_marks.dart): each glyph reads at a glance without
// reading its word and responds subtly to the live parameter value.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Two T glyphs (small left, large right) whose height ratio tracks font size.
void drawTextSize(Canvas c, Size s, Color ink, double value) {
  final t = (value / 0.25).clamp(0.25, 1.0);
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  final bot = s.height - 1.2;
  // Small reference T on the left.
  final smallTop = bot - s.height * 0.44;
  c
    ..drawLine(Offset(1.0, smallTop), Offset(4.4, smallTop), p)
    ..drawLine(Offset(2.7, smallTop), Offset(2.7, bot), p);
  // Larger T on the right growing with size.
  final bigTop = bot - s.height * (0.58 + 0.26 * t);
  c
    ..drawLine(Offset(5.4, bigTop), Offset(s.width - 0.8, bigTop), p)
    ..drawLine(
      Offset((5.4 + s.width - 0.8) * 0.5, bigTop),
      Offset((5.4 + s.width - 0.8) * 0.5, bot),
      p,
    );
}

/// Slanted serif I glyph that tilts live with the oblique angle.
void drawTextSlant(Canvas c, Size s, Color ink, double degrees) {
  // Show a gentle canonical italic tilt at 0° so the icon reads immediately,
  // then lean further as slant increases.
  final rad = ((degrees == 0 ? 14.0 : degrees) * math.pi / 180.0).clamp(
    -0.6,
    0.6,
  );
  final dx = math.sin(rad) * (s.height * 0.42);
  final cx = s.width * 0.5;
  final top = 1.6;
  final bot = s.height - 1.6;
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(cx + dx - 2.0, top), Offset(cx + dx + 2.2, top), p)
    ..drawLine(Offset(cx + dx, top), Offset(cx - dx, bot), p)
    ..drawLine(Offset(cx - dx - 2.2, bot), Offset(cx - dx + 2.0, bot), p);
}

/// Baseline rule with a letter bar rising or sinking according to baseline shift.
void drawTextBaseline(Canvas c, Size s, Color ink, double shiftEm) {
  final baseY = s.height * 0.78;
  final lift = (shiftEm * 3.0).clamp(-2.0, 3.2);
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  // Reference baseline rule.
  c.drawLine(
    Offset(0.8, baseY),
    Offset(s.width - 0.8, baseY),
    Paint()
      ..color = ink.withValues(alpha: 0.45)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round,
  );
  // Shifted A glyph above/below the baseline.
  final footY = (baseY - 1.4 - lift).clamp(4.5, s.height - 1.0);
  final topY = (footY - 5.2).clamp(1.0, footY - 3.0);
  final cx = s.width * 0.5;
  c
    ..drawLine(Offset(cx, topY), Offset(cx - 2.6, footY), p)
    ..drawLine(Offset(cx, topY), Offset(cx + 2.6, footY), p)
    ..drawLine(
      Offset(cx - 1.4, (topY + footY) * 0.58),
      Offset(cx + 1.4, (topY + footY) * 0.58),
      p..strokeWidth = 1.0,
    );
}

/// Two letter stems over a horizontal double-headed arrow whose gap follows tracking.
void drawTextTracking(Canvas c, Size s, Color ink, double tracking) {
  final t = ((tracking + 100.0) / 600.0).clamp(0.0, 1.0);
  final spread = 1.6 + t * 2.4;
  final cx = s.width * 0.5;
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  // Two vertical letter stems moving apart with tracking.
  c
    ..drawLine(
      Offset(cx - spread, 1.2),
      Offset(cx - spread, s.height * 0.54),
      p,
    )
    ..drawLine(
      Offset(cx + spread, 1.2),
      Offset(cx + spread, s.height * 0.54),
      p,
    );
  // Horizontal bidirectional arrow underneath.
  final ay = s.height - 2.0;
  final aPaint = Paint()
    ..color = ink.withValues(alpha: 0.8)
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(1.4, ay), Offset(s.width - 1.4, ay), aPaint)
    ..drawLine(Offset(2.9, ay - 1.4), Offset(1.2, ay), aPaint)
    ..drawLine(Offset(2.9, ay + 1.4), Offset(1.2, ay), aPaint)
    ..drawLine(
      Offset(s.width - 2.9, ay - 1.4),
      Offset(s.width - 1.2, ay),
      aPaint,
    )
    ..drawLine(
      Offset(s.width - 2.9, ay + 1.4),
      Offset(s.width - 1.2, ay),
      aPaint,
    );
}

/// Vertical double-headed arrow beside two stacked text lines whose gap follows line height.
void drawTextLineHeight(Canvas c, Size s, Color ink, double lineHeight) {
  final t = ((lineHeight - 0.5) / 2.5).clamp(0.0, 1.0);
  final halfGap = 1.8 + t * 2.2;
  final midY = s.height * 0.5;
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  // Two stacked lines on the right.
  c
    ..drawLine(
      Offset(4.8, midY - halfGap),
      Offset(s.width - 1.0, midY - halfGap),
      p,
    )
    ..drawLine(
      Offset(4.8, midY + halfGap),
      Offset(s.width - 2.2, midY + halfGap),
      p,
    );
  // Vertical double-headed arrow on the left.
  final ax = 2.2;
  final aPaint = Paint()
    ..color = ink.withValues(alpha: 0.8)
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(ax, 1.4), Offset(ax, s.height - 1.4), aPaint)
    ..drawLine(Offset(ax - 1.3, 2.8), Offset(ax, 1.2), aPaint)
    ..drawLine(Offset(ax + 1.3, 2.8), Offset(ax, 1.2), aPaint)
    ..drawLine(
      Offset(ax - 1.3, s.height - 2.8),
      Offset(ax, s.height - 1.2),
      aPaint,
    )
    ..drawLine(
      Offset(ax + 1.3, s.height - 2.8),
      Offset(ax, s.height - 1.2),
      aPaint,
    );
}

/// Two lines bounded by a movable right margin rail for Wrap at.
void drawTextWrapWidth(Canvas c, Size s, Color ink, double wrapAt) {
  final t = ((wrapAt - 4.0) / 36.0).clamp(0.0, 1.0);
  final rx = s.width * (0.58 + 0.30 * t);
  final p = Paint()
    ..color = ink
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(
      Offset(1.0, s.height * 0.30),
      Offset(rx - 2.0, s.height * 0.30),
      p,
    )
    ..drawLine(
      Offset(1.0, s.height * 0.70),
      Offset(rx * 0.65, s.height * 0.70),
      p,
    )
    ..drawLine(
      Offset(rx, 1.2),
      Offset(rx, s.height - 1.2),
      Paint()
        ..color = ink.withValues(alpha: 0.85)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
}

/// Variable-font axis mark: weight thickens the stroke, width stretches the A.
void drawTextAxis(
  Canvas c,
  Size s,
  Color ink,
  String tag,
  double value,
  double min,
  double max,
) {
  final t = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.5;
  final strokeW = tag == 'wght' ? (0.8 + t * 1.4) : 1.15;
  final spread = tag == 'wdth' ? (2.0 + t * 2.4) : 3.0;
  final cx = s.width * 0.5;
  final p = Paint()
    ..color = ink
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(cx, 1.4), Offset(cx - spread, s.height - 1.4), p)
    ..drawLine(Offset(cx, 1.4), Offset(cx + spread, s.height - 1.4), p)
    ..drawLine(
      Offset(cx - spread * 0.52, s.height * 0.62),
      Offset(cx + spread * 0.52, s.height * 0.62),
      p..strokeWidth = math.min(strokeW, 1.4),
    );
}
