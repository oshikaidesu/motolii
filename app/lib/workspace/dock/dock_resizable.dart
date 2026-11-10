// A band of a shelf whose height the user sets by dragging its grip.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';

/// A band whose height the user sets by dragging the grip on its lower edge.
///
/// The height is clamped to 44..[max]. A double-click on the grip sets it back to [reset].
class DockResizable extends StatefulWidget {
  const DockResizable({
    super.key,
    required this.height,
    required this.max,
    required this.onHeight,
    required this.child,
    required this.reset,
    required this.gripKey,
  });

  /// The current height, the largest height the grip allows, and the height a double-click on the grip sets.
  final double height, max, reset;
  final Key gripKey;

  /// Called with the new height while the user drags the grip, and on a double-click.
  final ValueChanged<double> onHeight;
  final Widget child;
  @override
  State<DockResizable> createState() => _DockResizableState();
}

class _DockResizableState extends State<DockResizable> {
  final _box = GlobalKey();
  bool _hover = false, _drag = false;
  double _h = 0, _from = 0;

  double _clamp(double v) => v.clamp(44.0, widget.max < 44 ? 44.0 : widget.max);

  @override
  Widget build(BuildContext context) {
    final lit = _hover || _drag;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(key: _box, height: _clamp(widget.height), child: widget.child),
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            supportedDevices: pressingDevices,
            key: widget.gripKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: (d) => setState(() {
              _drag = true;
              _from = d.globalPosition.dy;
              _h = _box.currentContext?.size?.height ?? widget.height;
            }),
            onVerticalDragUpdate: (d) => widget.onHeight(_clamp(_h + d.globalPosition.dy - _from)),
            onVerticalDragEnd: (_) => setState(() => _drag = false),
            onDoubleTap: () => widget.onHeight(widget.reset),
            child: Container(
              height: Shape.z(7),
              color: lit ? WindowTokens.raised : WindowTokens.ground,
              alignment: Alignment.center,
              child: Container(
                width: Shape.z(28),
                height: Shape.z(3),
                decoration: BoxDecoration(color: lit ? WindowTokens.accent : Grey.g38, borderRadius: BorderRadius.all(Shape.r(1.5))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
