// What the stage shows of a gesture that is not done yet: the pen's scribble or its handle being pulled out, the box of a layer being drawn,
// the numbers beside a held layer, and the brush's path so far. Each is a widget (or null) for the stage's stack; none changes anything.
import 'dart:ui' show PointMode;

import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/draw_tools.dart';
import 'package:motolii/workspace/stage/ruler_painter.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';

/// What the drawing tool in use shows from where the pointer went down to [last]; null when nothing is being drawn.
Widget? stageDrawPreview({
  required DrawTools draw,
  required StageViewport view,
  required Offset? last,
  required Offset? hover,
  required String? make,
}) {
  final from = draw.drawFrom;
  final shift = HardwareKeyboard.instance.isShiftPressed;
  // Rubber-band line from the last pen anchor to the cursor (45° snapped with Shift).
  if (make == 'pen' && from == null && draw.penLast != null && hover != null) {
    final prev = view.toScreen(draw.penLast!);
    final next = draw.penTarget(view, hover);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PenRubberBand(prev, next, snapped: shift),
      ),
    );
  }
  if (from == null || last == null) return null;
  // A scribble is drawn thin like the brush and becomes a path on release.
  if (make == 'pen' &&
      draw.penWay != null &&
      DrawTools.scribbled(draw.penWay!, from, last)) {
    final way = shift ? [from, snapAngle45(from, last)] : draw.penWay!;
    return IgnorePointer(child: CustomPaint(painter: BrushWay(way)));
  }
  // The pen's handle being pulled out, drawn through its point both ways.
  if (make == 'pen') {
    final anchor = draw.penTarget(view, from);
    final rawEnd = anchor + (last - from);
    final end = shift ? snapAngle45(anchor, rawEnd) : rawEnd;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: PointsPainter(
          [anchor],
          [(end, anchor), (anchor * 2 - end, anchor)],
        ),
      ),
    );
  }
  // The box of the layer being drawn (1:1 constrained with Shift).
  final end = shift && (make == 'rect' || make == 'circle')
      ? snapSquare(from, last)
      : last;
  return Positioned.fromRect(
    rect: Rect.fromPoints(from, end),
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: WindowTokens.chosen,
          borderRadius: make == 'circle' ? BorderRadius.circular(9999) : null,
        ),
      ),
    ),
  );
}

/// The numbers beside the pointer while a layer is dragged does; Alight Motion shows none. Null when nothing has moved.
Widget? stageHeldSays({required StageDrag drag, required Offset? last}) {
  final h = drag.held;
  if (h == null || !h.moved || last == null) return null;
  final says = drag.heldSays(h.by);
  if (says == null) return null;
  return Positioned(
    left: last.dx + 14,
    top: last.dy + 14,
    child: IgnorePointer(
      child: Container(
        key: const ValueKey('ws-held-says'),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(7),
          vertical: Shape.s(4),
        ),
        decoration: BoxDecoration(
          // Dark pill with a thin accent-tinted outline
          color: Grey.g10.withValues(alpha: .92),
          borderRadius: Shape.round(4),
          border: Border.all(color: WindowTokens.line),
        ),
        child: Text(
          says,
          style: TextStyles.micro(Grey.g95).copyWith(
            // Tabular figures so the numbers do not jiggle as they change.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
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

class _PenRubberBand extends CustomPainter {
  const _PenRubberBand(this.from, this.to, {required this.snapped});
  final Offset from, to;
  final bool snapped;
  @override
  void paint(Canvas c, Size s) {
    final col = WindowTokens.accent;
    c.drawLine(
      from,
      to,
      Paint()
        ..color = Grey.g00.withValues(alpha: .55)
        ..strokeWidth = snapped ? 3.2 : 2.2
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      from,
      to,
      Paint()
        ..color = col.withValues(alpha: snapped ? .95 : .65)
        ..strokeWidth = snapped ? 1.6 : 1.1
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(to, snapped ? 3.8 : 3.0, Paint()..color = Grey.g00);
    c.drawCircle(
      to,
      snapped ? 2.6 : 2.0,
      Paint()..color = col.withValues(alpha: .95),
    );
  }

  @override
  bool shouldRepaint(_PenRubberBand o) =>
      o.from != from || o.to != to || o.snapped != snapped;
}
