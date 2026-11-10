// Private helpers of media_set: art, badges, interaction shells. Colours only from tokens.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';

class Draw extends CustomPainter {
  const Draw(this.fn, [this.key]);
  final void Function(Canvas canvas, Size size) fn;
  final Object? key;
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(Draw o) => o.key != key;
}

Widget glyph(double size, void Function(Canvas, Size) fn, [Object? key]) => SizedBox(
  width: size,
  height: size,
  child: CustomPaint(painter: Draw(fn, key)),
);

void drawStar(Canvas c, Size s, Color col, bool fill) {
  final ctr = Offset(s.width / 2, s.height / 2 + .5), ro = s.width * .46, ri = ro * .45;
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? ro : ri, an = -math.pi / 2 + i * math.pi / 5;
    final pt = ctr + Offset(math.cos(an) * rr, math.sin(an) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  c.drawPath(
    p,
    Paint()
      ..color = col
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round,
  );
}

/// A thin horizontal slider with one or two handles: the track is grey, the part up to (or between) the handles is
/// filled. Groove, colours, handle shape and the minimum gap between two handles are arguments.
class MiniSlider extends StatelessWidget {
  const MiniSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    required this.width,
    this.step,
    this.gap = 0,
    this.height = 20,
    this.groove = 2,
    this.well,
    this.fill,
    this.thumb = const Size.square(10),
    this.thumbRadius,
    this.thumbColor,
    this.inset,
    this.cursor = SystemMouseCursors.resizeLeftRight,
  });
  final List<double> values;
  final double min, max, width, gap, height, groove;
  final double? step, thumbRadius, inset;
  final Color? well, fill, thumbColor;
  final Size thumb;
  final MouseCursor cursor;
  final ValueChanged<List<double>> onChanged;
  @override
  Widget build(BuildContext context) {
    final span = max - min;
    return NakedSlider(
      values: [for (final v in values) v.clamp(min, max).toDouble()],
      min: min,
      max: max,
      step: step ?? span / width,
      minSpacing: gap,
      mouseCursor: cursor,
      enableFeedback: false,
      onChanged: onChanged,
      builder: (context, st, _) {
        final tw = Shape.z(thumb.width), pad = inset ?? tw / 2;
        final xs = [for (var i = 0; i < values.length; i++) pad + (width - 2 * pad) * st.visualPercentageAt(i)];
        final from = xs.length > 1 ? xs.first : 0.0;
        Widget bar(double w, Color c) => Container(
          width: w,
          height: Shape.z(groove),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.all(Shape.r(groove / 2))),
        );
        return SizedBox(
          width: width,
          height: Shape.z(height),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              bar(width, well ?? Grey.g26),
              Positioned(left: from, child: bar(xs.last - from, fill ?? Grey.g56)),
              for (final x in xs)
                Positioned(
                  left: x - tw / 2,
                  child: Container(
                    width: tw,
                    height: Shape.z(thumb.height),
                    decoration: BoxDecoration(color: thumbColor ?? Grey.g95, borderRadius: BorderRadius.all(Radius.circular(thumbRadius ?? 99))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
