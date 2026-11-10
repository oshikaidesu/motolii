// A trackpad's two-finger gestures as Flutter reports them. Since Flutter 3.3 a trackpad's two-finger move and pinch arrive as
// pan/zoom events, not as wheel scroll events (https://docs.flutter.dev/release/breaking-changes/trackpad-gestures).
// Their meaning follows Apple's guidelines: two fingers move the content and a pinch zooms about the fingers
// (https://developer.apple.com/design/human-interface-guidelines/pointing-devices).
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The pointer kinds that press and drag: mouse (including a trackpad's click and drag), touch and stylus.
/// It excludes a trackpad's two-finger gesture, which a drag recognizer would otherwise treat as a drag (see GestureDetector.supportedDevices).
const wsPressing = {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus, PointerDeviceKind.unknown};

/// Reports a trackpad's two-finger gestures over [child].
class WsTwoFingers extends StatefulWidget {
  const WsTwoFingers({super.key, this.onPan, this.onPinch, this.onPinchStep, this.onWheel, required this.child});

  /// Called with a mouse wheel's scroll delta. This is the other way to move the view.
  final void Function(Offset by)? onWheel;

  /// Called on each move with the movement of the fingers in local points and their position.
  final void Function(Offset by, Offset at)? onPan;

  /// Called on each change of the spread between the fingers with the scale ratio since the previous update and the position of the fingers.
  final void Function(double by, Offset at)? onPinch;

  /// Called with +1 or -1 each time the spread has opened or closed by a quarter, for zooming in a few discrete steps.
  final void Function(int step)? onPinchStep;
  final Widget child;

  @override
  State<WsTwoFingers> createState() => _WsTwoFingersState();
}

class _WsTwoFingersState extends State<WsTwoFingers> {
  // Flutter's scale is relative to where the fingers touched down, so each change is converted to a ratio.
  // _spread accumulates that ratio until it triggers a pinch step.
  double _scale = 1, _spread = 1;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (e) {
      if (e is PointerScrollEvent) widget.onWheel?.call(e.scrollDelta);
    },
    onPointerPanZoomStart: (_) => _scale = _spread = 1,
    onPointerPanZoomUpdate: (e) {
      if (e.scale != _scale) {
        widget.onPinch?.call(e.scale / _scale, e.localPosition);
        _spread *= e.scale / _scale;
        _scale = e.scale;
        if (widget.onPinchStep != null && (_spread > 1.25 || _spread < .8)) {
          widget.onPinchStep!(_spread > 1 ? 1 : -1);
          _spread = 1;
        }
      }
      if (e.localPanDelta != Offset.zero) widget.onPan?.call(e.localPanDelta, e.localPosition);
    },
    child: widget.child,
  );
}
