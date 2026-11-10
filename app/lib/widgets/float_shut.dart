import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

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
