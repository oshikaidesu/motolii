// The easing graph.

import 'package:motolii/workspace/tool_panel/ease/ease_graph_painter.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/skin/layer_colors.dart';

import 'dart:math' as math;

import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_handle.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';

import 'package:motolii/widgets/two_finger_gestures.dart';

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
  int? _drag, _hot;
  double? _endAt;
  double _endFrom = 0;
  // The vertical range, frozen while something is dragged so the graph does not move under the pointer.
  (double, double)? _reachHeld;
  // Where the drag began, and where the handle was then. The handle moves by the pointer's movement, as in Alight Motion.
  Offset _from = Offset.zero, _handle = Offset.zero;

  (double, double) get _reach =>
      _reachHeld ??
      easeFit(widget.ease, widget.overshoot, widget.ends, widget.onion);
  Offset _px(Rect g, Offset v) => easePx(
    g,
    _reach,
    Offset(v.dx, widget.ends.$1 + (widget.ends.$2 - widget.ends.$1) * v.dy),
  );

  int? _near(Rect g, Offset p) {
    if (widget.onEnd != null && widget.span != null) {
      final reach = Shape.z(9);
      if ((p.dx - (g.left - easeBarOut)).abs() < reach) return easeEnd;
      if ((p.dx - (g.right + easeBarOut)).abs() < reach) return easeEnd + 1;
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
    if (which != null && which >= easeEnd) {
      _endFrom = which == easeEnd ? widget.ends.$1 : widget.ends.$2;
    }
    final hs = easeHandles(widget.ease);
    if (which != null && which < hs.length) {
      _handle = Offset(hs[which].x, hs[which].y);
    }
  }

  void _move(Rect g, Offset p) {
    final (lo, hi) = _reach;
    final (y0, y1) = widget.ends;
    if (_drag! >= easeEnd) {
      setState(
        () => _endAt = (lo + (g.bottom - p.dy) / g.height * (hi - lo)).clamp(
          lo + .02,
          hi - .02,
        ),
      );
      return widget.onEndMove?.call(_drag == easeEnd, _endAt! - _endFrom);
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
    if (end != null && end >= easeEnd && at != null) {
      widget.onEnd?.call(end == easeEnd, at - _endFrom);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final g = easeBox(box.biggest);
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
                painter: EaseGraphPainter(
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
              if (_drag != null && _drag! >= easeEnd && _endAt != null
                      ? widget.endSays?.call(
                          _drag == easeEnd,
                          _endAt! - _endFrom,
                        )
                      : null
                  case final says?)
                Positioned(
                  left: _drag == easeEnd ? g.left + 10 : null,
                  right: _drag == easeEnd + 1
                      ? box.maxWidth - g.right + 10
                      : null,
                  top: (easePx(g, _reach, Offset(0, _endAt!)).dy - 18).clamp(
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
      (m.value(t, 'js_lag', 0) ?? 0) *
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
