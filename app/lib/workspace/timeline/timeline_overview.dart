// The whole project in miniature under the tracks. The visible part is
// highlighted and can be dragged. Dragging either end of the visible window
// zooms the lanes
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

enum _Grab { body, start, end }

class TimelineOverview extends StatefulWidget {
  const TimelineOverview({
    super.key,
    required this.from,
    required this.to,
    required this.frame,
    required this.onPan,
    required this.onZoom,
  });
  final double from, to;
  final int frame;
  final ValueChanged<Offset> onPan;
  final void Function(double zoom, int anchor) onZoom;
  @override
  State<TimelineOverview> createState() => _OverviewState();
}

class _OverviewState extends State<TimelineOverview> {
  bool _h = false;
  _Grab? _grab;

  double _x(double f, double w) =>
      4 + f / WorkspaceController.duration * (w - 8);

  _Grab _hitTest(Offset p, double w) {
    final a = _x(widget.from, w), b = _x(widget.to, w);
    if ((p.dx - a).abs() <= 6) return _Grab.start;
    if ((p.dx - b).abs() <= 6) return _Grab.end;
    return _Grab.body;
  }

  void _down(DragDownDetails d) {
    final w = (context.findRenderObject() as RenderBox).size.width;
    _grab = _hitTest(d.localPosition, w);
    if (_grab == _Grab.body) widget.onPan(d.localPosition);
  }

  void _update(DragUpdateDetails d) {
    if (_grab == null) return;
    final w = (context.findRenderObject() as RenderBox).size.width;
    final dur = WorkspaceController.duration.toDouble();
    final strip = w - 8;
    if (_grab == _Grab.body) return widget.onPan(d.localPosition);

    final df = d.delta.dx / strip * dur;
    final span = widget.to - widget.from;
    if (_grab == _Grab.start) {
      final newSpan = math.max(6, span - df);
      final anchor = widget.to.round().clamp(0, dur.round());
      widget.onZoom(dur / newSpan, anchor);
    } else {
      final newSpan = math.max(6, span + df);
      final anchor = widget.from.round().clamp(0, dur.round());
      widget.onZoom(dur / newSpan, anchor);
    }
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: _h ? SystemMouseCursors.grab : MouseCursor.defer,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      supportedDevices: pressingDevices,
      behavior: HitTestBehavior.opaque,
      onPanDown: _down,
      onPanUpdate: _update,
      onPanEnd: (_) => _grab = null,
      onPanCancel: () => _grab = null,
      child: SizedBox(
        height: TimelineMetrics.overview,
        child: CustomPaint(
          painter: TimelineOverviewPainter(
            from: widget.from,
            to: widget.to,
            frame: widget.frame,
            hot: _h,
          ),
        ),
      ),
    ),
  );
}
