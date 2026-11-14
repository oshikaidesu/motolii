import 'package:flutter/gestures.dart'
    show GestureArenaMember, GestureBinding, GestureDisposition, kPrimaryButton;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Closes a floating widget, such as a menu, when the user presses outside it with either button or presses Esc.
/// Built on Flutter's TapRegion, as the menus on macOS and Windows are.
/// [keep] returns true for a press that must not close it, such as the press that opens it again.
/// [group] sets which regions count as inside.
/// With [swallow], the left press that closes it does nothing else, as a press outside a macOS or Windows menu.
/// A right press still reaches what is under it, so a right-click elsewhere opens a menu there.
class DismissRegion extends StatefulWidget {
  const DismissRegion({
    super.key,
    required this.shut,
    required this.child,
    this.group,
    this.keep,
    this.swallow = false,
  });
  final VoidCallback shut;
  final Widget child;
  final Object? group;
  final bool Function(PointerDownEvent)? keep;
  final bool swallow;
  @override
  State<DismissRegion> createState() => _DismissRegionState();
}

class _DismissRegionState extends State<DismissRegion> {
  final _keys = FocusNode(debugLabel: 'float');
  // The widget that had keyboard focus before this one, restored on dispose.
  final _was = FocusManager.instance.primaryFocus;

  @override
  void initState() {
    super.initState();
    // Take focus so Esc is handled here; a focused text field would consume it.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? _keys.requestFocus() : null,
    );
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
      if (widget.keep?.call(e) ?? false) return;
      widget.shut();
      // TapRegion.consumeOutsideTaps takes every button; this takes the left one only, the same way:
      // a member that wins the press at once, so no gesture under it starts.
      if (widget.swallow && e.buttons & kPrimaryButton != 0) {
        GestureBinding.instance.gestureArena
            .add(e.pointer, _Swallow())
            .resolve(GestureDisposition.accepted);
      }
    },
    child: Focus(
      focusNode: _keys,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) {
          return KeyEventResult.ignored;
        }
        widget.shut();
        return KeyEventResult.handled;
      },
      child: widget.child,
    ),
  );
}

class _Swallow extends GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}
  @override
  void rejectGesture(int pointer) {}
}
