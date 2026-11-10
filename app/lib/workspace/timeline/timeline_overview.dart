// The whole project in miniature under the tracks. The visible part is highlighted and can be dragged.
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

/// The overview strip. [onDrag] receives the pointer position within the strip.
class TimelineOverview extends StatefulWidget {
  const TimelineOverview({super.key, required this.from, required this.to, required this.frame, required this.onDrag});
  final double from, to;
  final int frame;
  final ValueChanged<Offset> onDrag;
  @override
  State<TimelineOverview> createState() => _OverviewState();
}

class _OverviewState extends State<TimelineOverview> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      supportedDevices: pressingDevices,
      behavior: HitTestBehavior.opaque,
      onPanDown: (d) => widget.onDrag(d.localPosition),
      onPanUpdate: (d) => widget.onDrag(d.localPosition),
      child: SizedBox(
        height: TimelineMetrics.overview,
        child: CustomPaint(
          painter: TimelineOverviewPainter(from: widget.from, to: widget.to, frame: widget.frame, hot: _h),
        ),
      ),
    ),
  );
}
