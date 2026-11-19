// A card's drawing with one handle on it that the pointer takes: the Play card's graph, the Source card's film strip.
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';

/// A drawing whose handle is taken with the primary button. The pointer is a grabbing hand over the handle and while
/// it is held, and the whole hold is one gesture of the Inspector's values.
class HandleDrag extends StatefulWidget {
  const HandleDrag({
    super.key,
    required this.near,
    required this.onDrag,
    required this.builder,
  });

  /// Whether a pointer at this place in the drawing is over the handle.
  final bool Function(Offset at) near;

  /// What the press sets, and every move while it is held, from the pointer's place in the drawing.
  final ValueChanged<Offset> onDrag;

  /// The drawing, lit while the handle is held or the pointer is over it.
  final Widget Function(bool lit) builder;

  @override
  State<HandleDrag> createState() => _HandleDragState();
}

class _HandleDragState extends State<HandleDrag> {
  bool _held = false, _near = false;

  void _let() {
    if (!_held) return;
    InspectorScope.of(context).doc.endGesture();
    setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: _held || _near ? SystemMouseCursors.grab : MouseCursor.defer,
    onHover: (e) {
      final n = widget.near(e.localPosition);
      if (n != _near) setState(() => _near = n);
    },
    onExit: (_) => setState(() => _near = false),
    child: Listener(
      onPointerDown: (e) {
        if (e.buttons != kPrimaryButton) return;
        InspectorScope.of(context).doc.beginGesture();
        setState(() => _held = true);
        widget.onDrag(e.localPosition);
      },
      onPointerMove: (e) {
        if (_held) widget.onDrag(e.localPosition);
      },
      onPointerUp: (_) => _let(),
      onPointerCancel: (_) => _let(),
      child: widget.builder(_held || _near),
    ),
  );
}
