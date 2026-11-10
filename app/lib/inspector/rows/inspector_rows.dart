import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import '../../widgets/media.dart' show glyph;
import '../inspector_parts.dart';

// ---- 5. sections and rows -------------------------------------------------------------------------------------------
/// A card's fold mark: points right when folded, down when open, so a card that can fold says so before it is touched.
class FoldMark extends StatelessWidget {
  const FoldMark({super.key, required this.open, required this.hot});
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

class RowInfo extends InheritedWidget {
  const RowInfo({super.key, required this.keys, required super.child});
  final KeyS keys;
  static RowInfo of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<RowInfo>()!;
  @override
  bool updateShouldNotify(RowInfo old) => old.keys != keys;
}
