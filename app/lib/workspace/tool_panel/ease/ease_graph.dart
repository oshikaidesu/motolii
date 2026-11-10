// The easing graph.

import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_handle.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';

import 'package:motolii/widgets/two_finger_gestures.dart';

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

/// The graph: value up, time across.
///
/// The user drags handles, and only a drag or hover repaints it. The two ends each stand on a bar, left and right,
/// and are dragged up and down them. [onEnd] receives which end moved and how far, measured in the bars' own scale:
/// 1 is the distance between the two key values as they first were. [ends] is where the ends stand.
/// With [jump] on, a dashed line shows the value jumping there, as the keys it creates will.
class EaseGraph extends StatefulWidget {
  const EaseGraph({
    super.key,
    required this.ease,
    required this.span,
    required this.frame,
    required this.onChanged,
    this.onEnd,
    this.onEndMove,
    this.endSays,
    this.jump = true,
    this.overshoot = false,
    this.beats = const [],
    this.trial,
    this.onion,
    this.ends = (0, 1),
  });

  final Ease ease;

  /// Where the start and end stand on their bars, in the bars' scale.
  final (double, double) ends;

  /// What all the cards make together, drawn faint behind the card being edited.
  final Ease? onion;

  /// The span being edited, or null for none.
  final EaseSpan? span;

  final int frame;

  final ValueChanged<Ease> onChanged;

  /// Called when an end drag is released ([onEnd]) and on every update during it ([onEndMove]).
  final void Function(bool start, double by)? onEnd, onEndMove;

  /// The text shown beside the dragged end, describing the value it now gives.
  final String? Function(bool start, double by)? endSays;

  /// [jump] draws the dashed jump at a dragged end. [overshoot] lets the view and the handles go past 0 and 1,
  /// as Alight Motion's Enable Overshoot does.
  final bool jump, overshoot;

  /// Progress of a preview of the easing, 0 to 1, shown when there is no span to follow (ease_trial.dart).
  final double? trial;

  /// Where the document's beats fall in the span, 0 to 1. Each gets a line, and a handle snaps to one it comes near,
  /// as on the timeline's grid.
  final List<double> beats;
  @override
  State<EaseGraph> createState() => _EaseGraphState();
}

class _EaseGraphState extends State<EaseGraph> {
  // For _drag and _hot: below this is a handle's index in easeHandles, this is the start end and this + 1 the end end.
  static const _end = 100;
  int? _drag, _hot;
  double? _endAt;
  double _endFrom = 0;
  // The vertical range, frozen while something is dragged so the graph does not move under the pointer.
  (double, double)? _reachHeld;
  // Where the drag began, and where the handle was then. The handle moves by the pointer's movement, as in Alight Motion.
  Offset _from = Offset.zero, _handle = Offset.zero;
  static Rect _box(Size s) => easeBox(s);

  (double, double) get _reach =>
      _reachHeld ??
      easeFit(widget.ease, widget.overshoot, widget.ends, widget.onion);
  Offset _px(Rect g, Offset v) => _pxIn(
    g,
    _reach,
    Offset(v.dx, widget.ends.$1 + (widget.ends.$2 - widget.ends.$1) * v.dy),
  );
  static Offset _pxIn(Rect g, (double, double) reach, Offset v) => Offset(
    g.left + v.dx * g.width,
    g.bottom - (v.dy - reach.$1) / (reach.$2 - reach.$1) * g.height,
  );

  int? _near(Rect g, Offset p) {
    if (widget.onEnd != null && widget.span != null) {
      final reach = Shape.z(9);
      if ((p.dx - (g.left - easeBarOut)).abs() < reach) return _end;
      if ((p.dx - (g.right + easeBarOut)).abs() < reach) return _end + 1;
    }
    final d = [
      for (final (i, h) in easeHandles(widget.ease).indexed)
        ((_px(g, Offset(h.x, h.y)) - p).distance, i),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return d.isEmpty || d.first.$1 > 14 ? null : d.first.$2;
  }

  void _take(int? which, Offset at) {
    _drag = which;
    _from = at;
    if (which != null) _reachHeld = _reach;
    if (which != null && which >= _end) {
      _endFrom = which == _end ? widget.ends.$1 : widget.ends.$2;
    }
    final hs = easeHandles(widget.ease);
    if (which != null && which < hs.length) {
      _handle = Offset(hs[which].x, hs[which].y);
    }
  }

  void _move(Rect g, Offset p) {
    final (lo, hi) = _reach;
    final (y0, y1) = widget.ends;
    if (_drag! >= _end) {
      setState(
        () => _endAt = (lo + (g.bottom - p.dy) / g.height * (hi - lo)).clamp(
          lo + .02,
          hi - .02,
        ),
      );
      return widget.onEndMove?.call(_drag == _end, _endAt! - _endFrom);
    }
    final hs = easeHandles(widget.ease);
    if (_drag! >= hs.length) return;
    final h = hs[_drag!], d = (p - _from) * h.damping;
    var u = (_handle.dx + d.dx / g.width).clamp(0.0, 1.0);
    final v =
        _handle.dy -
        d.dy / g.height * (hi - lo) / ((y1 - y0).abs() < 1e-6 ? 1 : y1 - y0);
    if (!HardwareKeyboard.instance.isMetaPressed) {
      for (final b in widget.beats) {
        if ((b - u).abs() * g.width <= Shape.z(6)) u = b;
      }
    }
    widget.onChanged(
      h.moved(
        u,
        h.along
            ? u
            : h.overshoot || widget.overshoot
            ? v.clamp(lo, hi)
            : v.clamp(0.0, 1.0),
      ),
    );
  }

  void _let(_) {
    final end = _drag, at = _endAt;
    setState(() {
      _drag = _endAt = _reachHeld = null;
    });
    if (end != null && end >= _end && at != null) {
      widget.onEnd?.call(end == _end, at - _endFrom);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final g = _box(box.biggest);
      return MouseRegion(
        cursor: _hot != null || _drag != null
            ? SystemMouseCursors.grab
            : MouseCursor.defer,
        onHover: (e) {
          final n = _near(g, e.localPosition);
          if (n != _hot) setState(() => _hot = n);
        },
        onExit: (_) {
          if (_hot != null) setState(() => _hot = null);
        },
        child: GestureDetector(
          supportedDevices: pressingDevices,
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) {
            _take(_near(g, d.localPosition), d.localPosition);
            if (_drag != null) setState(() {});
          },
          onPanUpdate: (d) {
            if (_drag != null) _move(g, d.localPosition);
          },
          onPanEnd: _let,
          onPanCancel: () => setState(() {
            _drag = _endAt = _reachHeld = null;
          }),
          child: Stack(
            children: [
              CustomPaint(
                size: box.biggest,
                painter: _GraphPainter(
                  ghosts: _ghosts(
                    WorkspaceScope.of(context, {WorkspaceAspect.document}),
                    widget.span,
                  ),
                  ease: widget.ease,
                  from: widget.span?.from,
                  to: widget.span?.to,
                  frame: widget.frame,
                  active: _drag ?? _hot,
                  dragging: _drag != null,
                  endAt: _endAt,
                  jump: widget.jump,
                  beats: widget.beats,
                  trial: widget.trial,
                  overshoot: widget.overshoot,
                  onion: widget.onion,
                  ends: widget.ends,
                  reach: _reach,
                ),
              ),
              if (_drag != null && _drag! >= _end && _endAt != null
                      ? widget.endSays?.call(_drag == _end, _endAt! - _endFrom)
                      : null
                  case final says?)
                Positioned(
                  left: _drag == _end ? g.left + 10 : null,
                  right: _drag == _end + 1 ? box.maxWidth - g.right + 10 : null,
                  top: (_pxIn(g, _reach, Offset(0, _endAt!)).dy - 18).clamp(
                    0.0,
                    math.max(0.0, box.maxHeight - 16),
                  ),
                  child: IgnorePointer(
                    child: Text(
                      says,
                      key: const ValueKey('ease-end-says'),
                      style: TextStyles.value(Grey.g95)
                          .copyWith(fontSize: TextStyles.px(10)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Copies of a behaviour's curve, one per member layer after the first, each delayed by its lag times its position.
///
/// They are drawn in the layer's own colour and cannot be edited, as Blender shows curves it will not let the user change.
List<(double, Color)> _ghosts(WorkspaceController ws, EaseSpan? span) {
  final m = ws.inside, t = int.tryParse(span?.layer.id ?? '');
  if (m == null ||
      t == null ||
      span == null ||
      span.to <= span.from ||
      m.word(t, 'kind') != 'behaviour') {
    return const [];
  }
  final lag =
      (m.value(t, 'lag', 0) ?? 0) *
      WorkspaceController.fps /
      (span.to - span.from);
  final members = [
    for (final s in m.word(t, 'members').split(' '))
      if (s.isNotEmpty && s != '_') s,
  ];
  if (lag <= 0 || members.length < 2) return const [];
  return [
    for (final (i, id) in members.indexed)
      if (i > 0) (lag * i, layerLabelColor(id)),
  ];
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
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
    final g = _EaseGraphState._box(s),
        handles = easeHandles(ease),
        end = _EaseGraphState._end;
    Offset px(Offset v) => _EaseGraphState._pxIn(g, reach, v);
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
  bool shouldRepaint(_GraphPainter o) =>
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
