// What the stage shows of a gesture that is not done yet: the pen's scribble or its handle being pulled out, the box of a layer being drawn,
// the numbers beside a held layer, and the brush's path so far. Each is a widget (or null) for the stage's stack; none changes anything.
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/draw_tools.dart';
import 'package:motolii/workspace/stage/ruler_painter.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';

/// What the drawing tool in use shows from where the pointer went down to [last]; null when nothing is being drawn.
Widget? stageDrawPreview({
  required DrawTools draw,
  required Offset? last,
  required String? make,
}) {
  final from = draw.drawFrom;
  if (from == null || last == null) return null;
  // A scribble is drawn thin like the brush and becomes a path on release.
  if (make == 'pen' &&
      draw.penWay != null &&
      DrawTools.scribbled(draw.penWay!, from, last)) {
    return IgnorePointer(child: CustomPaint(painter: BrushWay(draw.penWay!)));
  }
  // The pen's handle being pulled out, drawn through its point both ways.
  if (make == 'pen') {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: PointsPainter([from], [(last, from), (from * 2 - last, from)]),
      ),
    );
  }
  // The box of the layer being drawn.
  return Positioned.fromRect(
    rect: Rect.fromPoints(from, last),
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: WindowTokens.accent),
        ),
      ),
    ),
  );
}

/// The numbers beside the pointer while a layer is dragged, as Figma does; Alight Motion shows none. Null when nothing has moved.
Widget? stageHeldSays({required StageDrag drag, required Offset? last}) {
  final h = drag.held;
  if (h == null || !h.moved || last == null) return null;
  final says = drag.heldSays(h.by);
  if (says == null) return null;
  return Positioned(
    left: last.dx + 16,
    top: last.dy + 16,
    child: IgnorePointer(
      child: Container(
        key: const ValueKey('ws-held-says'),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(6),
          vertical: Shape.s(3),
        ),
        decoration: BoxDecoration(
          color: WindowTokens.raised,
          borderRadius: BorderRadius.all(Shape.r(3)),
        ),
        child: Text(says, style: TextStyles.micro(Grey.g95)),
      ),
    ),
  );
}

class BrushWay extends CustomPainter {
  const BrushWay(this.way);
  final List<Offset> way;
  @override
  void paint(Canvas c, Size s) => c.drawPoints(
    PointMode.polygon,
    way,
    Paint()
      ..color = WindowTokens.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
  @override
  bool shouldRepaint(BrushWay o) => true;
}
