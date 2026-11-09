import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import '../inspector_parts.dart';

/// A card's fold mark: points right when folded, down when open.
class FoldMark extends StatelessWidget {
  const FoldMark({super.key, required this.open, this.hot = false});
  final bool open, hot;
  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? .25 : 0,
    duration: const Duration(milliseconds: 120),
    child: CustomPaint(size: const Size(8, 8), painter: _FoldPaint(hot ? Grey.g95 : Grey.g56)),
  );
}

class _FoldPaint extends CustomPainter {
  const _FoldPaint(this.ink);
  final Color ink;
  @override
  void paint(Canvas c, Size s) => c.drawPath(
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
  @override
  bool shouldRepaint(_FoldPaint o) => o.ink != ink;
}

class RowInfo extends InheritedWidget {
  const RowInfo({super.key, required this.unit, required this.keys, required super.child});
  final String? unit;
  final KeyS keys;
  static RowInfo? of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<RowInfo>();
  @override
  bool updateShouldNotify(RowInfo old) => old.unit != unit || old.keys != keys;
}
