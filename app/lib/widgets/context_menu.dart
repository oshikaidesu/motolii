// The workspace's right-click menu.
//
// It lists what can be done to the item under the pointer, so the mouse alone is enough (Ableton Live's context menus, Figma's right-click).
// Flutter's RawMenuAnchor opens it at the pointer and closes it on a click outside.
// A row is a label. A disabled row shows why it cannot be done, and the keyboard shortcut is dimmed on the right.
// It behaves as the menus of macOS and Windows do, the same on every system: the arrow keys move between rows and Return runs one,
// a right press held down and let go over a row runs it, and it closes when the window goes to the back, is resized or scrolls.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show GestureBinding, HitTestResult;
import 'package:flutter/rendering.dart' show RenderMetaData;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/dismiss_region.dart' show DismissRegion;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// One row of a menu.
///
/// A null [go] means the row cannot be done now, and [why] says why. [keys] is the keyboard shortcut shown beside it.
/// The shortcut is never the only way to run it. [ContextMenuItem.rule] is a divider between groups.
class ContextMenuItem {
  const ContextMenuItem(
    this.label,
    this.go, {
    this.keys = '',
    this.why = '',
    this.id,
  }) : colors = const [],
       picked = -1,
       pick = null;
  const ContextMenuItem.rule()
    : label = '',
      go = null,
      keys = '',
      why = '',
      id = null,
      colors = const [],
      picked = -1,
      pick = null;

  /// A row of colours to choose from, as Ableton Live's context menus end with the clip or track colours.
  ///
  /// [picked] is the index of the current colour, or -1 for none. [pick] is called with the index of the one clicked.
  const ContextMenuItem.colors(this.colors, this.picked, this.pick)
    : label = '',
      go = null,
      keys = '',
      why = '',
      id = null;
  final String label, keys, why;

  /// The row's widget key, when it should not be derived from the label.
  final String? id;
  final VoidCallback? go;
  final List<Color> colors;
  final int picked;
  final void Function(int)? pick;
}

class ContextMenu extends StatefulWidget {
  const ContextMenu({super.key, required this.child});
  final Widget child;
  @override
  State<ContextMenu> createState() => ContextMenuState();
}

/// A floating panel of [items], [width] wide, scrolling when taller than [max].
///
/// Choosing an item runs it and then calls [close]. The workspace context menu and the inspector's ⋮ and right-click lists all use this.
class ContextMenuList extends StatelessWidget {
  const ContextMenuList({
    super.key,
    required this.items,
    required this.close,
    required this.max,
    required this.width,
  });
  final List<ContextMenuItem> items;
  final VoidCallback close;
  final double max, width;

  static double get _row => Shape.z(22);
  static double get _swatch => Shape.z(20);
  static double high(ContextMenuItem it) => it.colors.isNotEmpty
      ? (it.colors.length / 8).ceil() * (_swatch + Shape.s(4)) + Shape.s(4)
      : it.label.isEmpty
      ? Shape.s(8) + 1
      : _row;

  Widget _one(ContextMenuItem it) => it.colors.isNotEmpty
      ? Padding(
          // Eight swatches to a row.
          padding: EdgeInsets.all(Shape.s(4)),
          child: Wrap(
            spacing: Shape.s(4),
            runSpacing: Shape.s(4),
            children: [
              for (var k = 0; k < it.colors.length; k++)
                Pressable(
                  key: ValueKey('ws-menu-colour-$k'),
                  cursor: SystemMouseCursors.click,
                  onTap: () {
                    close();
                    it.pick?.call(k);
                  },
                  builder: (_, h) => Container(
                    width: _swatch,
                    height: _swatch,
                    decoration: BoxDecoration(
                      color: it.colors[k],
                      borderRadius: BorderRadius.all(Shape.r(3)),
                      border: Border.all(
                        color: k == it.picked || h
                            ? Grey.g95
                            : const Color(0x00000000),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
      : it.label.isEmpty
      ? Padding(
          padding: EdgeInsets.symmetric(vertical: Shape.s(4)),
          child: SizedBox(height: 1, child: ColoredBox(color: Grey.g20)),
        )
      : MetaData(
          // A right press held down and let go here runs the row (ContextMenuState._let).
          metaData: it,
          behavior: HitTestBehavior.translucent,
          child: Pressable(
            key: ValueKey(it.id ?? 'ws-menu-${it.label}'),
            cursor: it.go != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onTap: it.go == null
                ? null
                : () {
                    close();
                    it.go!();
                  },
            builder: (_, h) => Container(
              height: _row,
              padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
              decoration: BoxDecoration(
                color: h && it.go != null ? Grey.g20 : null,
                borderRadius: BorderRadius.all(Shape.r(4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      it.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.name(
                        it.go != null ? Grey.g91 : Grey.g56,
                      ),
                    ),
                  ),
                  if (it.go == null && it.why.isNotEmpty)
                    Text(it.why, maxLines: 1, style: TextStyles.label(Grey.g56))
                  else if (it.keys.isNotEmpty)
                    Text(
                      it.keys,
                      maxLines: 1,
                      style: TextStyles.label(Grey.g56),
                    ),
                ],
              ),
            ),
          ),
        );

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('ws-menu'),
    width: width,
    padding: EdgeInsets.all(Shape.s(4)),
    decoration: BoxDecoration(
      color: Grey.g13,
      borderRadius: BorderRadius.all(Shape.r(6)),
      border: Border.all(color: Grey.g26),
      boxShadow: [
        BoxShadow(
          color: const Color(0x80000000),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ConstrainedBox(
      // A long list scrolls within [max].
      constraints: BoxConstraints(maxHeight: max),
      child: SingleChildScrollView(
        child: FocusTraversalGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final it in items) _one(it)],
          ),
        ),
      ),
    ),
  );
}

/// The arrow keys of a menu, around its [DismissRegion].
///
/// Down and up move between the rows in reading order, as in the menus of macOS and Windows; each row is a NakedButton,
/// which runs on Return or Space while it has the focus. It sits outside the DismissRegion because the region holds the focus
/// when the menu opens, and keys go outward from the focus. The workspace's own arrow keys (nudging the layer) do not run meanwhile.
class MenuKeys extends StatelessWidget {
  const MenuKeys({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (node, e) {
      if (e is! KeyDownEvent) return KeyEventResult.ignored;
      final at = FocusManager.instance.primaryFocus;
      if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
        at?.nextFocus();
      } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
        at?.previousFocus();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    },
    child: child,
  );
}

class ContextMenuState extends State<ContextMenu> with WidgetsBindingObserver {
  final _m = MenuController();
  List<ContextMenuItem> _items = const [];
  // Where the pointer was when the menu opened, in global coordinates.
  Offset? _from;
  // Whether [_let] is listening for the release.
  bool _listening = false;

  void _stopListening() {
    if (_listening) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_let);
    }
    _listening = false;
  }

  /// Opens the menu with [items] at [at], a position within the child.
  ///
  /// Another menu that is open closes first: only one is open at a time.
  void show(Offset at, List<ContextMenuItem> items) {
    setState(() => _items = items);
    final box = context.findRenderObject() as RenderBox?;
    _from = box?.localToGlobal(at);
    if (!_listening) GestureBinding.instance.pointerRouter.addGlobalRoute(_let);
    _listening = true;
    _m.open(position: at);
  }

  // The first release after opening: over an enabled row, and away from where the menu opened, it runs that row.
  // A plain right-click lets go where it opened, so the menu stays open, as on macOS and Windows.
  void _let(PointerEvent e) {
    if (e is! PointerUpEvent && e is! PointerCancelEvent) return;
    _stopListening();
    final from = _from;
    if (e is! PointerUpEvent || !_m.isOpen || from == null) return;
    if ((e.position - from).distance < 4) return;
    final hit = HitTestResult();
    WidgetsBinding.instance.hitTestInView(hit, e.position, e.viewId);
    for (final entry in hit.path) {
      if (entry.target case RenderMetaData(
        metaData: ContextMenuItem(:final go?),
      )) {
        _m.close();
        go();
        return;
      }
    }
  }

  void _shut() {
    if (_m.isOpen) _m.close();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopListening();
    super.dispose();
  }

  // The window went to the back or was hidden.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _shut();
  }

  // The window was resized or moved to another screen.
  @override
  void didChangeMetrics() => _shut();

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    // What the menu was opened on scrolled away.
    onNotification: (_) {
      _shut();
      return false;
    },
    child: RawMenuAnchor(
      controller: _m,
      overlayBuilder: (context, info) {
        final w = Shape.z(220), pad = Shape.s(4);
        final h =
            math.min(
              info.overlaySize.height * .5,
              [for (final it in _items) ContextMenuList.high(it)]
                  .fold(0.0, (a, b) => a + b),
            ) +
            pad * 2;
        final at = info.anchorRect.topLeft + (info.position ?? Offset.zero);
        return Positioned(
          left: math.max(0.0, math.min(at.dx, info.overlaySize.width - w)),
          // Opens downward from the pointer, or upward where there is no room.
          top: at.dy + h <= info.overlaySize.height
              ? at.dy
              : math.max(0.0, at.dy - h),
          child: NotificationListener<ScrollNotification>(
            // The menu's own scrolling does not close it.
            onNotification: (_) => true,
            child: MenuKeys(
              child: DismissRegion(
                // The anchor only closes on a left press outside it and the widget it was opened on, which is the whole stage or timeline.
                // DismissRegion closes on any press outside the menu itself, and on Esc, like every floating panel.
                shut: _m.close,
                swallow: true,
                child: ContextMenuList(
                  items: _items,
                  close: _m.close,
                  max: info.overlaySize.height * .5,
                  width: w,
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    ),
  );
}
