// The whole project in miniature under the tracks. The visible part is highlighted and can be dragged.
part of 'timeline.dart';

/// The overview strip. [onDrag] receives the pointer position within the strip.
class _Overview extends StatefulWidget {
  const _Overview({required this.from, required this.to, required this.frame, required this.onDrag});
  final double from, to;
  final int frame;
  final ValueChanged<Offset> onDrag;
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      supportedDevices: wsPressing,
      behavior: HitTestBehavior.opaque,
      onPanDown: (d) => widget.onDrag(d.localPosition),
      onPanUpdate: (d) => widget.onDrag(d.localPosition),
      child: SizedBox(
        height: WtM.overview,
        child: CustomPaint(
          painter: WtOverviewPainter(from: widget.from, to: widget.to, frame: widget.frame, hot: _h),
        ),
      ),
    ),
  );
}
