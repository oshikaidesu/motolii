// Puts an empty effect, or an empty expression, on the selected layer with its code open on its card. It gives the user
// somewhere to paste code found on the net (an ISF effect, or a .js with each(), see engine/document/scripts/expressions.h).
// The file is written fresh on each press, in the user's programs folder where a layer's own copy lives (effect_code.dart),
// so what is typed belongs to that layer alone. The engine's side is in state/effect_put.dart.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

export 'package:motolii/workspace/state/tiles/effect_put.dart'
    show emptyPut, putEffectFile;

/// The "+" drawn on the empty effect's tile.
class EmptyLook extends CustomPainter {
  const EmptyLook();
  @override
  void paint(Canvas c, Size s) {
    final ink = Paint()
      ..color = Grey.g76
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      Offset(s.width / 2, s.height * .2),
      Offset(s.width / 2, s.height * .8),
      ink,
    );
    c.drawLine(
      Offset(s.width / 2 - s.height * .3, s.height / 2),
      Offset(s.width / 2 + s.height * .3, s.height / 2),
      ink,
    );
  }

  @override
  bool shouldRepaint(EmptyLook old) => false;
}
