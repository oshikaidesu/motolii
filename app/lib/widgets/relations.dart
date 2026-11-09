// A relation shown three ways: a tile (browser), a card with its gadget (inspector), and the gadget alone (a small picture you can hold).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';

/// The gadgets: a relation's parameters as one picture you can hold. Pictures only; the handles are drawn, nothing moves.
class Gadget extends StatelessWidget {
  const Gadget(this.fam, {super.key, this.size = 150});
  final Fam fam;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _Gadget(fam)),
  );
}

class _Gadget extends CustomPainter {
  const _Gadget(this.fam);
  final Fam fam;
  @override
  void paint(Canvas cv, Size s) {
    final w = s.width, c = fam.c, mid = Offset(w / 2, w / 2);
    Paint line([double a = 1, double sw = 1.2]) => Paint()
      ..color = c.withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    void handle(Offset o) {
      cv.drawCircle(o, 6, Paint()..color = c);
      cv.drawCircle(
        o,
        6,
        Paint()
          ..color = Grey.g100
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    switch (fam.name) {
      case 'Scatter':
        cv.drawCircle(mid, w * .46, line(.5, 1));
        final r = math.Random(3);
        for (var i = 0; i < 46; i++) {
          final d = w * .43 * math.sqrt(r.nextDouble()), a = r.nextDouble() * 6.283;
          cv.drawCircle(mid + Offset(math.cos(a), math.sin(a)) * d, 1.2 + r.nextDouble() * 1.6, Paint()..color = c);
        }
        handle(mid + Offset(w * .3, -w * .3));
      case 'Along Path':
        final p = Path()
          ..moveTo(w * .08, w * .82)
          ..cubicTo(w * .25, w * .1, w * .45, w * .95, w * .62, w * .5)
          ..cubicTo(w * .75, w * .2, w * .85, w * .3, w * .92, w * .14);
        cv.drawPath(p, line(1, 1.6));
        final m = p.computeMetrics().first;
        for (var i = 0; i < 5; i++) {
          cv.drawCircle(m.getTangentForOffset(m.length * i / 4)!.position, i == 4 ? 6 : 3.5, Paint()..color = c);
        }
      case 'Stagger':
        cv.drawLine(Offset(w * .1, w * .1), Offset(w * .1, w * .9), line(.35, 1));
        cv.drawLine(Offset(w * .1, w * .9), Offset(w * .9, w * .9), line(.35, 1));
        for (var i = 0; i < 7; i++) {
          final f = i / 6;
          cv.drawCircle(Offset(w * (.2 + f * .66), w * (.82 - f * .62)), 2.5 + f * 4, Paint()..color = c.withValues(alpha: .35 + f * .65));
        }
      case 'Face':
        cv.drawCircle(mid, w * .36, line(.8));
        cv.drawCircle(mid, w * .18, line(.45));
        cv.drawLine(mid, mid + Offset(w * .36, -w * .14), line());
        handle(mid);
        handle(mid + Offset(w * .36, -w * .14));
      case 'Follow':
        final p = Path()
          ..moveTo(w * .14, w * .72)
          ..cubicTo(w * .35, w * .85, w * .5, w * .42, w * .84, w * .26);
        for (final m in p.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 11) {
            cv.drawPath(m.extractPath(d, d + 6), line(.8, 1.4));
          }
        }
        handle(Offset(w * .14, w * .72));
        cv.drawPath(
          Path()
            ..moveTo(w * .76, w * .34)
            ..lineTo(w * .9, w * .24)
            ..lineTo(w * .8, w * .18)
            ..close(),
          Paint()..color = Grey.g95,
        );
      default: // Attach
        final a = Offset(w * .3, w * .62), b = Offset(w * .7, w * .38);
        cv.drawLine(a, b, line(.9, 1.4));
        cv.drawCircle(a, 9, line());
        cv.drawCircle(b, 9, line());
        handle(a);
        handle(b);
    }
  }

  @override
  bool shouldRepaint(_Gadget o) => o.fam != fam;
}
