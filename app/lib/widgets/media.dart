// Private helpers of media_set: art, badges, interaction shells. Colours only from tokens.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';

String clock(double s) => '${s ~/ 60}:${(s % 60).floor().toString().padLeft(2, '0')}';

String hexOf(Color c) {
  String h(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${h(c.r)}${h(c.g)}${h(c.b)}';
}

enum Kind {
  image('IMG', 'Image'),
  video('VID', 'Video'),
  audio('AUD', 'Audio'),
  model('3D', '3D'),
  pano('360°', '360°');

  const Kind(this.badge, this.label);
  final String badge, label;
  bool get timed => this == video || this == audio || this == pano;
}

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

/// A thin horizontal slider: the track is grey, the value is the brightest thing.
class MiniSlider extends StatelessWidget {
  const MiniSlider({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 1, this.width = 88, this.track});
  final double value, min, max, width;
  final Color? track; // (none: the skin's grey)
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final span = max - min;
    return NakedSlider(
      values: [value.clamp(min, max).toDouble()],
      min: min,
      max: max,
      step: span / width,
      mouseCursor: SystemMouseCursors.resizeLeftRight,
      enableFeedback: false,
      onChanged: (next) => onChanged(next.first),
      builder: (context, st, _) {
        final t = st.visualPercentageAt(0);
        return SizedBox(
          width: width,
          height: Shape.z(20),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: Shape.z(2),
                decoration: BoxDecoration(color: track ?? Grey.g26, borderRadius: BorderRadius.all(Shape.r(1))),
              ),
              Container(
                width: width * t,
                height: Shape.z(2),
                decoration: BoxDecoration(color: Grey.g56, borderRadius: BorderRadius.all(Shape.r(1))),
              ),
              Positioned(
                left: (width - 10) * t,
                child: Container(
                  width: Shape.z(10),
                  height: Shape.z(10),
                  decoration: BoxDecoration(color: Grey.g95, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
