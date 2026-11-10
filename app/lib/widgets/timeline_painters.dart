// Timeline helpers: ruler tick spacing and the timeline's icon set.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/glyphs.dart' show GlyphKind;

// ---------------------------------------------------------------- ruler ticks

double tpMajor(double ppf, int fps) {
  final steps = {1, 2, 5, 10, fps ~/ 2, fps, 2 * fps, 5 * fps, 10 * fps, 30 * fps, 60 * fps}.where((f) => f > 0).toList()..sort();
  return steps.firstWhere((f) => f * ppf >= 70, orElse: () => steps.last).toDouble();
}

double tpFine(double ppf, int fps, double major) {
  final steps = {1, 2, 5, 10, fps ~/ 2, fps, 2 * fps, 5 * fps, 10 * fps}.where((f) => f > 0 && f < major && major % f == 0 && f * ppf >= 12);
  var best = major;
  for (final f in steps) {
    if ((f * ppf - 30).abs() < (best * ppf - 30).abs()) best = f.toDouble();
  }
  return best;
}

// ---------------------------------------------------------------- glyphs

enum TpGlyph implements GlyphKind {
  eye,
  eyeOff,
  solo,
  lock,
  unlock,
  caretR,
  caretD,
  play,
  pause,
  toStart,
  stepBack,
  stepFwd,
  loop,
  fit,
  plus,
  minus;

  @override
  String get skin => 'tp.$name';
  @override
  // The stroke width on the centred 12-unit grid used by [draw].
  double stroke(double w) => 1.2;
  @override
  void draw(Canvas c, Size s, Paint line, Paint fill) {
    c.translate(s.width / 2, s.height / 2);
    c.scale(s.shortestSide / 12);
    Path tri(double x0, double y0, double x1, double y1, double x2, double y2) => Path()
      ..moveTo(x0, y0)
      ..lineTo(x1, y1)
      ..lineTo(x2, y2)
      ..close();
    switch (this) {
      case TpGlyph.eye:
        c.drawPath(
          Path()
            ..moveTo(-5.5, 0)
            ..quadraticBezierTo(0, -6, 5.5, 0)
            ..quadraticBezierTo(0, 6, -5.5, 0),
          line,
        );
        c.drawCircle(Offset.zero, 1.7, fill);
      case TpGlyph.eyeOff:
        c.drawPath(
          Path()
            ..moveTo(-5.5, -1)
            ..quadraticBezierTo(0, 4, 5.5, -1),
          line,
        );
        c.drawLine(const Offset(-3, 2), const Offset(-4, 3.6), line);
        c.drawLine(const Offset(0, 3), const Offset(0, 4.8), line);
        c.drawLine(const Offset(3, 2), const Offset(4, 3.6), line);
      case TpGlyph.solo:
        c.drawCircle(Offset.zero, 4.6, line);
        c.drawCircle(Offset.zero, 1.8, fill);
      case TpGlyph.lock:
      case TpGlyph.unlock:
        c.drawRRect(RRect.fromLTRBR(-3.6, 0, 3.6, 5.2, Shape.r(1.2)), line);
        final sh = Path()
          ..moveTo(-2.3, 0)
          ..lineTo(-2.3, -1.8)
          ..arcTo(Rect.fromCircle(center: const Offset(0, -1.8), radius: 2.3), math.pi, math.pi, false);
        if (this == TpGlyph.lock) sh.lineTo(2.3, 0);
        c.drawPath(sh, line);
      case TpGlyph.caretR:
        c.drawPath(tri(-2, -3.6, 2.8, 0, -2, 3.6), fill);
      case TpGlyph.caretD:
        c.drawPath(tri(-3.6, -2, 3.6, -2, 0, 2.8), fill);
      case TpGlyph.play:
        c.drawPath(tri(-3, -4.6, 4.8, 0, -3, 4.6), fill);
      case TpGlyph.pause:
        c.drawRect(const Rect.fromLTRB(-3.6, -4.4, -1, 4.4), fill);
        c.drawRect(const Rect.fromLTRB(1, -4.4, 3.6, 4.4), fill);
      case TpGlyph.toStart:
        c.drawRect(const Rect.fromLTRB(-5, -4.6, -3.8, 4.6), fill);
        c.drawPath(tri(5, -4.6, -2.2, 0, 5, 4.6), fill);
      case TpGlyph.stepBack:
        c.drawPath(tri(3, -4.2, -3, 0, 3, 4.2), fill);
      case TpGlyph.stepFwd:
        c.drawPath(tri(-3, -4.2, 3, 0, -3, 4.2), fill);
      case TpGlyph.loop:
        c.drawRRect(RRect.fromLTRBR(-5, -3, 5, 3, Shape.r(3)), line);
        c.drawPath(tri(1.5, -5.6, 4.6, -3, 1.5, -.4), fill);
      case TpGlyph.fit:
        for (final sx in const [-1.0, 1.0]) {
          for (final sy in const [-1.0, 1.0]) {
            c.drawPath(
              Path()
                ..moveTo(sx * 5, sy * 1.8)
                ..lineTo(sx * 5, sy * 5)
                ..lineTo(sx * 1.8, sy * 5),
              line,
            );
          }
        }
      case TpGlyph.plus:
        c.drawLine(const Offset(-4, 0), const Offset(4, 0), line);
        c.drawLine(const Offset(0, -4), const Offset(0, 4), line);
      case TpGlyph.minus:
        c.drawLine(const Offset(-4, 0), const Offset(4, 0), line);
    }
  }
}
