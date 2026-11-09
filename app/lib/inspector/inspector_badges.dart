import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

/// A solid tone tile with the layer mark knocked onto it.
class ToneBadge extends StatelessWidget {
  const ToneBadge(this.tone, {super.key, this.dim = false, this.size = 16});
  final Color tone;
  final bool dim;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: dim ? Grey.g26 : tone, borderRadius: BorderRadius.circular(size * .32)),
    child: CustomPaint(painter: _MarkPaint(dim ? Grey.g56 : Pop.onAccent)),
  );
}

class _MarkPaint extends CustomPainter {
  const _MarkPaint(this.ink);
  final Color ink;

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 20, o = s.center(Offset.zero);
    final fill = Paint()..color = ink;
    Paint stroke(double w) => Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => o + Offset(x, y) * u;
    Path dia(double y) => Path()
      ..moveTo(p(0, y - 3.2).dx, p(0, y - 3.2).dy)
      ..lineTo(p(6, y).dx, p(6, y).dy)
      ..lineTo(p(0, y + 3.2).dx, p(0, y + 3.2).dy)
      ..lineTo(p(-6, y).dx, p(-6, y).dy)
      ..close();
    c.drawPath(dia(2.2), stroke(1.5));
    c.drawPath(dia(-1.8), fill);
  }

  @override
  bool shouldRepaint(_MarkPaint o) => o.ink != ink;
}

/// One summary value as a tag, so a folded card reads as a row of chips rather than a sentence. A colour value brings its swatch.
class BriefChip extends StatelessWidget {
  const BriefChip(this.text, {super.key, this.dim = false});
  final String text;
  final bool dim;

  static TextStyle get _style => T.label().copyWith(fontWeight: FontWeight.w600, height: 1);
  static Color? swatch(String t) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(t) ? Color(int.parse(t.substring(1), radix: 16) | 0xFF000000) : null;

  /// The chip's laid-out width, so a row can drop the chips that would not fit whole.
  static double width(String t) =>
      (TextPainter(
        text: TextSpan(text: t, style: _style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout()).width +
      12 +
      (swatch(t) != null ? 12 : 0);

  @override
  Widget build(BuildContext context) {
    final sw = swatch(text);
    return Container(
      height: Shape.z(16),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: dim ? Grey.g15 : Grey.g20, borderRadius: BorderRadius.all(Shape.r(8))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sw != null) ...[
            Container(
              width: Shape.z(8),
              height: Shape.z(8),
              decoration: BoxDecoration(color: sw, shape: BoxShape.circle),
            ),
            SizedBox(width: Shape.s(4)),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _style.copyWith(color: dim ? Grey.g56 : Grey.g95),
            ),
          ),
        ],
      ),
    );
  }
}
