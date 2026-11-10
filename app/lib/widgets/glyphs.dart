// A small line-icon set, drawn: one stroke weight, one size grid, g63 idle / g95 active. Placeholders (empty squares) are what the critique flagged, so every tool and tile has a real mark.
import 'package:flutter/widgets.dart';

import '../skin/svg_parts.dart';
import '../skin/tokens.dart';
import 'media.dart' show glyph;

/// A set of named marks (the enums here, the timeline's, the dock's): its skin key, its stroke weight on its own grid, its drawing. The one [Glyph] draws any of them.
abstract interface class GlyphKind {
  String get skin;
  double stroke(double w);
  void draw(Canvas c, Size s, Paint st, Paint fl);
}

class Glyph extends StatelessWidget {
  const Glyph(this.kind, {super.key, required this.size, required this.color, this.fade = false});
  final GlyphKind kind;
  final double size;
  final Color color;
  final bool fade; // (the colour eases over, as the timeline's marks do)
  Widget _box(Color c) => glyph(size, (cv, s) {
    if (SkinParts.draw(cv, s, kind.skin, c)) return; // (the skin's own picture, if it brings one)
    final st = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = kind.stroke(s.width)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    kind.draw(cv, s, st, Paint()..color = c);
  }, (kind, c));
  @override
  Widget build(BuildContext context) => fade
      ? TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: Mo.dur,
          curve: Curves.easeOut,
          builder: (_, v, _) => _box(v ?? color),
        )
      : _box(color);
}

enum G implements GlyphKind {
  select,
  move,
  rect,
  ellipse,
  pen,
  text,
  brush,
  image,
  camera,
  grid,
  shape,
  media;

  @override
  String get skin => 'glyph.$name';
  @override
  double stroke(double w) => w * .08;
  @override
  void draw(Canvas c, Size s, Paint st, Paint fl) {
    final w = s.width;
    Offset p(double x, double y) => Offset(x * w, y * w);
    switch (this) {
      case G.select:
        c.drawPath(
          Path()
            ..moveTo(w * .26, w * .14)
            ..lineTo(w * .26, w * .82)
            ..lineTo(w * .44, w * .66)
            ..lineTo(w * .58, w * .9)
            ..lineTo(w * .68, w * .85)
            ..lineTo(w * .55, w * .62)
            ..lineTo(w * .78, w * .6)
            ..close(),
          st,
        );
      case G.move:
        c.drawLine(p(.5, .12), p(.5, .88), st);
        c.drawLine(p(.12, .5), p(.88, .5), st);
        for (final d in const [Offset(.5, .12), Offset(.5, .88), Offset(.12, .5), Offset(.88, .5)]) {
          final dx = d.dx == .5 ? 0.0 : (d.dx < .5 ? .09 : -.09), dy = d.dy == .5 ? 0.0 : (d.dy < .5 ? .09 : -.09);
          c.drawLine(p(d.dx, d.dy), p(d.dx + (dx == 0 ? .08 : dx), d.dy + (dy == 0 ? .08 : dy)), st);
          c.drawLine(p(d.dx, d.dy), p(d.dx + (dx == 0 ? -.08 : dx), d.dy + (dy == 0 ? -.08 : dy)), st);
        }
      case G.rect || G.shape:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .18, w * .22, w * .64, w * .56), Radius.circular(w * .08)), st);
      case G.ellipse:
        c.drawOval(Rect.fromLTWH(w * .16, w * .2, w * .68, w * .6), st);
      case G.pen:
        c.drawPath(
          Path()
            ..moveTo(w * .5, w * .1)
            ..lineTo(w * .78, w * .46)
            ..lineTo(w * .56, w * .9)
            ..lineTo(w * .44, w * .9)
            ..lineTo(w * .22, w * .46)
            ..close(),
          st,
        );
        c.drawCircle(p(.5, .52), w * .06, fl);
        c.drawLine(p(.5, .58), p(.5, .9), st);
      case G.brush: // (a stroke drawn by hand, thick in the middle)
        c.drawPath(
          Path()
            ..moveTo(w * .16, w * .74)
            ..cubicTo(w * .3, w * .3, w * .46, w * .86, w * .6, w * .46)
            ..quadraticBezierTo(w * .7, w * .2, w * .84, w * .26),
          st
            ..strokeWidth = st.strokeWidth * 1.6
            ..strokeCap = StrokeCap.round,
        );
      case G.text:
        c.drawLine(p(.22, .2), p(.78, .2), st);
        c.drawLine(p(.5, .2), p(.5, .84), st);
        c.drawLine(p(.38, .84), p(.62, .84), st);
      case G.image:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .14, w * .2, w * .72, w * .6), Radius.circular(w * .08)), st);
        c.drawPath(
          Path()
            ..moveTo(w * .2, w * .72)
            ..lineTo(w * .42, w * .46)
            ..lineTo(w * .58, w * .62)
            ..lineTo(w * .68, w * .52)
            ..lineTo(w * .82, w * .7),
          st,
        );
        c.drawCircle(p(.66, .36), w * .05, fl);
      case G.camera:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .12, w * .3, w * .76, w * .5), Radius.circular(w * .08)), st);
        c.drawCircle(p(.5, .55), w * .15, st);
        c.drawLine(p(.34, .3), p(.4, .2), st);
        c.drawLine(p(.4, .2), p(.6, .2), st);
        c.drawLine(p(.6, .2), p(.66, .3), st);
      case G.grid:
        for (var i = 0; i < 2; i++) {
          c.drawLine(p(.38 + i * .24, .16), p(.38 + i * .24, .84), st);
          c.drawLine(p(.16, .38 + i * .24), p(.84, .38 + i * .24), st);
        }
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .16, w * .16, w * .68, w * .68), Radius.circular(w * .06)), st);
      case G.media:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .14, w * .2, w * .72, w * .6), Radius.circular(w * .08)), st);
        c.drawPath(
          Path()
            ..moveTo(w * .44, w * .38)
            ..lineTo(w * .64, w * .5)
            ..lineTo(w * .44, w * .62)
            ..close(),
          fl,
        );
    }
  }
}
