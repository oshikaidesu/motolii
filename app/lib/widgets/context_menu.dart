// The workspace's right-click menu.
//
// It lists what can be done to the item under the pointer, so the mouse alone is enough (Ableton Live's context menus, Figma's right-click).
// naked_ui's NakedMenu (on Flutter's RawMenuAnchor) places the panel, flipping and shifting it at the window's edge, moves between rows with the arrow keys,
// closes on Esc and on a resize. Every menu is a [MenuHost] around it: this one, the ⋮ of a card (more_menu.dart) and the right-click of a number.
// A row is a label. A disabled row shows why it cannot be done, and the keyboard shortcut is dimmed on the right.
// What the two libraries lack is written once, below: a right press held down and let go over a row runs it,
// a left press outside closes the menu and does nothing else, and the menu closes when the window goes to the back.
import 'package:flutter/gestures.dart'
    show
        GestureArenaMember,
        GestureBinding,
        GestureDisposition,
        HitTestResult,
        kPrimaryButton;
import 'package:flutter/rendering.dart' show RenderMetaData;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart' show NakedMenu, OverlayPositionConfig;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/gestures.dart';
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

  static double get _row => Shape.z(Gestures.menuRow);
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
                      borderRadius: Shape.round(3),
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
                borderRadius: Shape.round(4),
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
      borderRadius: Shape.round(6),
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

/// A menu: the one wrapper around naked_ui's [NakedMenu] that every menu in the app is made with, so they all behave alike.
///
/// [child] is what the menu is attached to; [positioning] says where the panel sits against it.
/// A press on [child] toggles the menu (NakedMenu's trigger); a [SizedBox.shrink] makes it a point, as the right-click menu does.
class MenuHost extends StatelessWidget {
  const MenuHost({
    super.key,
    required this.controller,
    required this.items,
    required this.width,
    required this.child,
    this.positioning = const OverlayPositionConfig(),
    this.useRootOverlay = false,
  });
  final MenuController controller;
  final List<ContextMenuItem> items;
  final double width;
  final Widget child;
  final OverlayPositionConfig positioning;
  final bool useRootOverlay;

  @override
  Widget build(BuildContext context) => NakedMenu<void>(
    controller: controller,
    positioning: positioning,
    useRootOverlay: useRootOverlay,
    // Closing is done by [PressOutside], which also keeps the closing press from reaching what is under it.
    closeOnClickOutside: false,
    consumeOutsideTaps: false,
    overlayBuilder: (context, info) => PressOutside(
      group: info.tapRegionGroupId,
      shut: controller.close,
      child: ContextMenuList(
        items: items,
        close: controller.close,
        max: info.overlaySize.height * .5,
        width: width,
      ),
    ),
    child: child,
  );
}

/// Closes a floating list on a press outside it. Every menu and select uses it (see [MenuHost], and the Inspector's Chooser).
/// A left press does nothing else, as outside a macOS or Windows menu;
/// a right press still reaches what is under it, so a right-click elsewhere opens a menu there.
/// (TapRegion.consumeOutsideTaps takes every button, so it is not used.)
class PressOutside extends StatelessWidget {
  const PressOutside({
    super.key,
    required this.group,
    required this.shut,
    required this.child,
  });
  final Object group;
  final VoidCallback shut;
  final Widget child;
  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: group,
    onTapOutside: (e) {
      shut();
      if (e.buttons & kPrimaryButton != 0) {
        GestureBinding.instance.gestureArena
            .add(e.pointer, _Swallow())
            .resolve(GestureDisposition.accepted);
      }
    },
    child: child,
  );
}

class _Swallow extends GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}
  @override
  void rejectGesture(int pointer) {}
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
    setState(() {
      _items = items;
      _at = at;
    });
    final box = context.findRenderObject() as RenderBox?;
    _from = box?.localToGlobal(at);
    if (!_listening) GestureBinding.instance.pointerRouter.addGlobalRoute(_let);
    _listening = true;
    // After the frame that moves the point, so the menu is placed against the new one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _m.open();
    });
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

  // The window went to the back or was hidden. (RawMenuAnchor itself closes on a resize and on a scroll above the anchor.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _m.isOpen) _m.close();
  }

  // Where the menu was opened, within the child. The menu is attached to a point there, so it opens at the pointer.
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        // What the menu was opened on scrolled away: a scroll inside the child, which RawMenuAnchor does not see.
        onNotification: (_) {
          if (_m.isOpen) _m.close();
          return false;
        },
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned(
              left: _at.dx,
              top: _at.dy,
              child: MenuHost(
                controller: _m,
                items: _items,
                width: Shape.z(Gestures.menuWidth),
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
}
