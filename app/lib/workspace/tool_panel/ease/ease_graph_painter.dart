// The easing graph's painter: the grid, the curves (the chosen one and the ghosts of a behaviour's members), the handles' guides and the playhead.
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_handle.dart';
import 'package:motolii/widgets/paint_helpers.dart';

/// For a drag or a hover: below this is a handle's index in easeHandles, this is the start end and this + 1 the end end.
const easeEnd = 100;

/// Where the point [v] (x from 0 to 1, y in the curve's own values) lies in the graph box [g], for the vertical range [reach].
Offset easePx(Rect g, (double, double) reach, Offset v) => Offset(
  g.left + v.dx * g.width,
  g.bottom - (v.dy - reach.$1) / (reach.$2 - reach.$1) * g.height,
);

/// The rectangle the curve's square occupies in a graph of size [s]: as large as possible, with room at each side for the bars.
Rect easeBox(Size s) {
  // Room below for the bars, the layer name, the frames and the easing name, whatever the size of the graph.
  final side = Shape.z(14) + easeBarOut, top = Shape.z(22), under = Shape.z(36);
  return Rect.fromLTRB(
    side,
    top,
    math.max(side + 1, s.width - side),
    math.max(top + 1, s.height - under),
  );
}

/// How far outside the square the bars stand. It is beyond any handle, which goes no further than the square's edge.
double get easeBarOut => Shape.z(16);

/// The vertical range a graph shows: the easing's own range, widened to include the ends and the whole stack, so one card's overshoot fits too.
(double, double) easeFit(
  Ease e,
  bool over,
  (double, double) ends,
  Ease? onion,
) {
  var (lo, hi) = easeReach(e, over);
  lo = math.min(lo, math.min(ends.$1, ends.$2) - .15);
  hi = math.max(hi, math.max(ends.$1, ends.$2) + .15);
  for (final v in [...?onion?.drawn, if (easeIsLaid(said(e))) ...?e.drawn]) {
    final y = ends.$1 + (ends.$2 - ends.$1) * v;
    lo = math.min(lo, y - .1);
    hi = math.max(hi, y + .1);
  }
  return (lo, hi);
}

class EaseGraphPainter extends CustomPainter {
  const EaseGraphPainter({
    required this.ease,
    required this.from,
    required this.to,
    required this.frame,
    required this.active,
    required this.dragging,
    this.ghosts = const [],
    this.beats = const [],
    this.trial,
    this.overshoot = false,
    this.onion,
    this.ends = (0, 1),
    required this.reach,
    this.endAt,
    this.jump = true,
  });
  final (double, double) reach;

  /// A behaviour's member layers: how much later each starts across the span, and its colour.
  final List<(double, Color)> ghosts;
  final List<double> beats;
  final double? trial;
  final Ease ease;
  final int? from, to, active;
  final int frame;
  final bool dragging, jump, overshoot;
  final Ease? onion;
  final (double, double) ends;

  /// Where the key at an end is while it is dragged.
  final double? endAt;

  @override
  void paint(Canvas c, Size s) {
    // Follows AbsentMotion's EasingPanel.kt drawGraph: the grid, dashed 0 and 1 lines, the stems, the curve and the handles.
    final g = easeBox(s), handles = easeHandles(ease), end = easeEnd;
    Offset px(Offset v) => easePx(g, reach, v);
    // While an end is dragged, the curve runs from where the start is to where the end is, as the keys it creates will.
    final pulled = endAt != null && dragging && (active ?? 0) >= end
        ? active
        : null;
    final y0 = pulled == end ? endAt! : ends.$1,
        y1 = pulled == end + 1 ? endAt! : ends.$2;
    double along(double x) => y0 + (y1 - y0) * ease.at(x);
    final a = px(Offset(0, y0)),
        b = px(Offset(1, y1)),
        home = (px(Offset.zero), px(const Offset(1, 1)));
    final top = home.$2.dy, bottom = home.$1.dy;
    final grid = Paint()
      ..strokeWidth = 1
      // Few lines, so the grid stays light. AbsentMotion's 32 lines would look like grain at this size.
      ..color = Grey.g20;
    for (var i = 0; i <= 8; i++) {
      final x = (g.left + i * g.width / 8).floorToDouble() + .5;
      c.drawLine(Offset(x, top), Offset(x, bottom), grid);
    }
    for (final b in beats) {
      final x = g.left + g.width * b;
      c.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..strokeWidth = 1
          ..color = Grey.g38,
      );
    }
    for (var i = 1; i < 4; i++) {
      final y = (top + i * (bottom - top) / 4).floorToDouble() + .5;
      c.drawLine(Offset(g.left, y), Offset(g.right, y), grid);
    }
    dashed(c, Offset(g.left, top), Offset(g.right, top), Grey.g56, 1, 4, 3);
    dashed(
      c,
      Offset(g.left, bottom),
      Offset(g.right, bottom),
      Grey.g56,
      1,
      4,
      3,
    );
    // The delayed copies of the curve: thin and faint, under the curve being edited.
    c.save();
    c.clipRect(g);
    for (final (shift, hue) in ghosts) {
      final copy = Path()..moveTo(px(Offset(shift, 0)).dx, a.dy);
      for (var i = 1; i <= 96; i++) {
        final x = i / 96,
            o = px(Offset(x + shift, y0 + (y1 - y0) * (onion ?? ease).at(x)));
        copy.lineTo(o.dx, o.dy);
      }
      copy.lineTo(g.right + 4, b.dy);
      c.drawPath(
        copy,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = hue.withValues(alpha: .55),
      );
    }
    c.restore();
    if (onion case final whole?) {
      final skin = Path()..moveTo(a.dx, a.dy);
      for (var i = 1; i <= 192; i++) {
        final o = px(Offset(i / 192, y0 + (y1 - y0) * whole.at(i / 192)));
        skin.lineTo(o.dx, o.dy);
      }
      c.drawPath(
        skin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..color = Grey.g56,
      );
    }
    // The stems. Handles move with the ends while an end is dragged.
    Offset handle(double x, double y) => px(Offset(x, y0 + (y1 - y0) * y));
    for (final h in handles) {
      if (h.fromX == null || h.fromY == null) continue;
      final o = handle(h.fromX!, h.fromY!),
          ink = h.param ? WindowTokens.keyDot : Grey.g95;
      if (h.dashed) {
        dashed(c, o, handle(h.x, 0), ink, 1, 2.5, 2.5);
      } else {
        c.drawLine(
          o,
          handle(h.x, h.y),
          Paint()
            ..color = ink
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    // The curve.
    final path = Path()..moveTo(a.dx, a.dy);
    const n = 192;
    for (var i = 1; i <= n; i++) {
      final x = i / n;
      final o = px(Offset(x, along(x)));
      if (ease.kind == EaseKind.hold && i == n) path.lineTo(o.dx, a.dy);
      path.lineTo(o.dx, o.dy);
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = WindowTokens.accentInk,
    );
    // The timeline position: the playhead in its own color, where the easing is now, and the frame numbers.
    final numbers = TextStyles.micro(Grey.g56);
    if (from != null && to != null && to! > from!) {
      if (g.width > Shape.z(80)) {
        // When too narrow, only the current frame is shown.
        toolText(c, '$from', Offset(g.left, bottom + 6), numbers);
        toolText(c, '$to', Offset(g.right, bottom + 6), numbers, ax: 1);
      }
      if (frame >= from! && frame <= to!) {
        final u = (frame - from!) / (to! - from!),
            x = g.left + g.width * u,
            y = y0 + (y1 - y0) * (onion ?? ease).at(u),
            line = Paint()
              ..color = WindowTokens.playhead
              ..strokeWidth = 1.5;
        c.drawLine(Offset(x, top - 8), Offset(x, bottom + 4), line);
        c.drawCircle(
          px(Offset(u, y)),
          4.5,
          Paint()..color = WindowTokens.playhead,
        );
        if (frame != from && frame != to) {
          toolText(
            c,
            '$frame',
            Offset(x, bottom + 6),
            TextStyles.micro(WindowTokens.playhead)
                .copyWith(fontWeight: FontWeight.w700),
            ax: .5,
          );
        }
      } else if (g.width > Shape.z(80)) {
        // The frame is outside this span: show which side it lies on.
        final before = frame < from!;
        toolText(
          c,
          before ? '‹ $frame' : '$frame ›',
          Offset(g.center.dx, bottom + 6),
          TextStyles.micro(WindowTokens.playhead)
              .copyWith(fontWeight: FontWeight.w700),
          ax: .5,
        );
      }
    }
    // A previewed easing: where it has reached on its curve, and a ball on the bar moving as a value would.
    if (trial case final u?) {
      final at = px(Offset(u, y0 + (y1 - y0) * (onion ?? ease).at(u)));
      c.drawLine(
        Offset(at.dx, top - 8),
        Offset(at.dx, bottom + 4),
        Paint()
          ..color = WindowTokens.playhead
          ..strokeWidth = 1.5,
      );
      c.drawCircle(at, 4.5, Paint()..color = WindowTokens.playhead);
      c.drawCircle(
        Offset(g.right + easeBarOut, at.dy),
        6,
        Paint()..color = WindowTokens.playhead,
      );
    }
    // The jump at the dragged end: from where the value was (the key the jump leaves outside) to where it is now.
    if (pulled != null && jump) {
      final was = pulled == end ? home.$1 : home.$2,
          now = pulled == end ? a : b;
      dashed(c, was, now, Role.warning, 1.6, 3.5, 2.5);
      c.drawCircle(was, 3, Paint()..color = Grey.g63);
    }
    // The handles: large ones are the user's. Yellow marks the preset's parameters, white the rest.
    for (final (i, h) in handles.indexed) {
      final o = handle(h.x, h.y),
          on = active == i,
          ink = h.param ? WindowTokens.keyDot : Grey.g95;
      c.drawCircle(o, on ? 7 : 6, Paint()..color = ink);
      if (dragging && on && !h.param) {
        toolText(
          c,
          '${h.x.toStringAsFixed(2)}, ${h.y.toStringAsFixed(2)}',
          o + Offset(h.x < .5 ? 9 : -9, -9),
          TextStyles.value(Grey.g95).copyWith(fontSize: TextStyles.px(10)),
          ax: h.x < .5 ? 0 : 1,
          ay: 1,
        );
      }
    }
    // The bars at left and right, as tall as the easing's 0 to 100, longer where an end has gone past. Each end has its own grip.
    final rail = easeBarOut;
    for (final (i, (x, k, inward)) in [
      (g.left - rail, a, 1.0),
      (g.right + rail, b, -1.0),
    ].indexed) {
      final on = active == end + i, cap = rail * .35;
      final bar = Paint()
        ..color = on ? WindowTokens.accentInk : Grey.g63
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      c.drawLine(
        Offset(x, math.min(top, k.dy)),
        Offset(x, math.max(bottom, k.dy)),
        bar,
      );
      c.drawLine(Offset(x, top), Offset(x + inward * cap, top), bar);
      c.drawLine(Offset(x, bottom), Offset(x + inward * cap, bottom), bar);
      c.drawLine(
        Offset(x, k.dy),
        k,
        Paint()
          ..color = Grey.g63
          ..strokeWidth = 1,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, k.dy),
            width: on ? 11 : 9,
            height: on ? 18 : 14,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = WindowTokens.accentInk,
      );
    }
  }

  @override
  bool shouldRepaint(EaseGraphPainter o) =>
      o.trial != trial ||
      o.beats != beats ||
      o.reach != reach ||
      o.ease != ease ||
      o.onion != onion ||
      o.ends != ends ||
      o.overshoot != overshoot ||
      o.endAt != endAt ||
      o.jump != jump ||
      o.from != from ||
      o.to != to ||
      o.frame != frame ||
      o.active != active ||
      o.dragging != dragging ||
      o.ghosts.length != ghosts.length ||
      (ghosts.isNotEmpty && o.ghosts.first.$1 != ghosts.first.$1);
}
