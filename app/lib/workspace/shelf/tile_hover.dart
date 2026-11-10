// Hover and tap handling for a shelf tile, with the double-click and drag-to-preview a tile with an action of its own has.
import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout, kPrimaryButton;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// Hover and tap handling for a tile. It rebuilds only when the pointer enters or leaves.
class DockHover extends StatefulWidget {
  const DockHover({
    super.key,
    required this.builder,
    this.onTap,
    this.onDoubleTap,
    this.picks = false,
    this.onHover,
    this.onMenu,
    this.onMove,
  });

  /// Whether Cmd was held when the last tile was pressed.
  static bool cmdAtPress = false;

  /// True after a tile with a double-click action was pressed, while a second press may still come (see [ShelfContext.foot]).
  static final secondMayCome = ValueNotifier(false);
  static Timer? _past;
  final Widget Function(BuildContext context, bool hover) builder;
  final VoidCallback? onTap;

  /// Called on a double-click. It runs the item's own action directly, for a tile that has no footer button.
  final VoidCallback? onDoubleTap;

  /// Whether a single press only selects the tile. [onTap] is called as soon as the button goes down.
  /// A font tile does not do this, because its tap sets the font of a role.
  final bool picks;

  /// Called with true when the pointer enters and false when it leaves.
  ///
  /// It is also called with false if the tile is removed while the pointer is over it,
  /// because a MouseRegion that is unmounted under the pointer sends no exit event.
  final ValueChanged<bool>? onHover;

  /// Called on a secondary press (right click) with its position on the screen.
  final ValueChanged<Offset>? onMenu;

  /// Called when the pointer moves over the tile, with its position in the tile.
  final ValueChanged<Offset>? onMove;
  @override
  State<DockHover> createState() => _DockHoverState();
}

class _DockHoverState extends State<DockHover> {
  bool _h = false;
  // Active while a second press would make a double-click.
  Timer? _second;

  @override
  void dispose() {
    _second?.cancel();
    if (_h) widget.onHover?.call(false);
    super.dispose();
  }

  void _hover(bool h) {
    setState(() => _h = h);
    widget.onHover?.call(h);
  }

  // A tile that is selected by one press and acted on by two is selected as the button goes down, as Finder does with an icon.
  // Waiting until a second press could no longer come (Flutter's tap waits kDoubleTapTimeout beside a double tap)
  // left the shelf's button acting on the previously selected tile. The second press belongs to the double-click.
  void _down(PointerDownEvent e) {
    DockHover.cmdAtPress = HardwareKeyboard.instance.isMetaPressed;
    if (!widget.picks ||
        widget.onDoubleTap == null ||
        widget.onTap == null ||
        e.buttons != kPrimaryButton) {
      return;
    }
    final second = _second?.isActive ?? false;
    _second?.cancel();
    _second = second ? null : Timer(kDoubleTapTimeout, () {});
    DockHover._past?.cancel();
    DockHover.secondMayCome.value = true;
    if (!second) widget.onTap!();
  }

  // The window is counted from the release, as in Flutter's own double tap (multitap.dart, _registerFirstTap).
  void _up(PointerEvent e) {
    if (!DockHover.secondMayCome.value) return;
    DockHover._past?.cancel();
    DockHover._past = Timer(
      kDoubleTapTimeout,
      () => DockHover.secondMayCome.value = false,
    );
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    onEnter: (_) => _hover(true),
    onExit: (_) => _hover(false),
    onHover: widget.onMove == null
        ? null
        : (e) => widget.onMove!(e.localPosition),
    child: _carried(
      Listener(
        // Sees the press as it arrives, before the gesture arena decides what it is.
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.picks && widget.onDoubleTap != null
              ? null
              : widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTapDown: widget.onMenu == null
              ? null
              : (d) => widget.onMenu!(d.globalPosition),
          child: widget.builder(context, _h),
        ),
      ),
    ),
  );

  /// Lets a tile with an action of its own be dragged to the preview, where dropping it does what a double-click does.
  Widget _carried(Widget tile) => widget.onDoubleTap == null
      ? tile
      : Draggable<VoidCallback>(
          data: widget.onDoubleTap!,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: IgnorePointer(
            child: Container(
              width: Shape.z(22),
              height: Shape.z(22),
              decoration: BoxDecoration(
                color: WindowTokens.accent,
                borderRadius: BorderRadius.all(Shape.r(4)),
              ),
            ),
          ),
          child: tile,
        );
}
