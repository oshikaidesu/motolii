import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/media.dart' show glyph;

/// The disclosure triangle on a card's heading.
///
/// It points right when the card is folded and down when it is open, so the user can see that the card folds before touching it.
class DisclosureTriangle extends StatelessWidget {
  const DisclosureTriangle({super.key, required this.open, required this.hot});

  /// Fields: `open` is whether the card is open (the triangle points down); `hot` is whether the pointer is over the
  /// heading, which draws the triangle brighter.
  final bool open, hot;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? .25 : 0,
    duration: const Duration(milliseconds: 120),
    child: glyph(8, (c, s) => _drawFold(c, s, hot ? Grey.g95 : Grey.g56), hot),
  );
}

void _drawFold(Canvas c, Size s, Color ink) => c.drawPath(
  Path()
    ..moveTo(s.width * .3, s.height * .12)
    ..lineTo(s.width * .7, s.height * .5)
    ..lineTo(s.width * .3, s.height * .88),
  Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round,
);
