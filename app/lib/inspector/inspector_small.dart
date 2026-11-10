import 'package:motolii/skin/inspector_tokens.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// Closes a floating widget, such as a menu, when the user presses outside it with either button or presses Esc.
/// Built on Flutter's TapRegion, as the menus on macOS and Windows are.
/// [keep] returns true for a press that must not close it, such as the press that opens it again.
/// [group] sets which regions count as inside.
class FloatShut extends StatefulWidget {
  const FloatShut({super.key, required this.shut, required this.child, this.group, this.keep});
  final VoidCallback shut;
  final Widget child;
  final Object? group;
  final bool Function(PointerDownEvent)? keep;
  @override
  State<FloatShut> createState() => _FloatShutState();
}

class _FloatShutState extends State<FloatShut> {
  final _keys = FocusNode(debugLabel: 'float');
  // The widget that had keyboard focus before this one, restored on dispose.
  final _was = FocusManager.instance.primaryFocus;

  @override
  void initState() {
    super.initState();
    // Take focus so Esc is handled here; a focused text field would consume it.
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _keys.requestFocus() : null);
  }

  @override
  void dispose() {
    if (_keys.hasFocus) _was?.requestFocus();
    _keys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: widget.group,
    onTapOutside: (e) {
      if (!(widget.keep?.call(e) ?? false)) widget.shut();
    },
    child: Focus(
      focusNode: _keys,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
        widget.shut();
        return KeyEventResult.handled;
      },
      child: widget.child,
    ),
  );
}

String fmt(double v, int dec, {bool tight = false}) {
  var d = tight ? 0 : dec;
  var s = v.toStringAsFixed(d);
  while (v != 0 && double.parse(s) == 0 && d < 4) {
    d++;
    s = v.toStringAsFixed(d);
  }
  return s == '-0' ? '0' : s;
}

/// The 28x16 on/off track.
class PopSwitch extends StatelessWidget {
  const PopSwitch({super.key, required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    width: Shape.z(28),
    height: Shape.z(16),
    padding: EdgeInsets.all(Shape.s(2)),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(color: on ? Pop.accent : Grey.g26, borderRadius: BorderRadius.all(Shape.r(8))),
    child: Container(
      width: Shape.z(12),
      height: Shape.z(12),
      decoration: BoxDecoration(color: on ? Pop.onAccent : Grey.g63, shape: BoxShape.circle),
    ),
  );
}
