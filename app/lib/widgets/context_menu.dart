// The workspace's right-click menu, built on naked_ui's NakedMenu.
// What the library lacks is added here: right-press-and-release runs a row,
// left press outside closes without side effects, and hiding the window closes the menu.
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

/// One row of a menu. Null [go] = disabled; [ContextMenuItem.rule] = divider.
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

  /// A row of colour swatches. [picked] = current index (-1 = none).
  const ContextMenuItem.colors(this.colors, this.picked, this.pick)
    : label = '',
      go = null,
      keys = '',
      why = '',
      id = null;
  final String label, keys, why;

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

/// A floating panel of [items]. Choosing an item runs it and calls [close].
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

/// The one wrapper around [NakedMenu] that every menu in the app uses.
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

/// Closes on press outside. Left press is consumed; right press passes through.
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
  Offset? _from;
  bool _listening = false;

  void _stopListening() {
    if (_listening) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_let);
    }
    _listening = false;
  }

  /// Opens the menu with [items] at [at]. Only one menu at a time.
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

  // Release over an enabled row (away from the open point) runs it.
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

  // Window went to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _m.isOpen) _m.close();
  }

  // The menu is anchored at this point inside the child.
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        // Close if the content under the menu scrolls (RawMenuAnchor does not detect this).
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
