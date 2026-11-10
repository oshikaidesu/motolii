// The workspace's right-click menu.
//
// It lists what can be done to the item under the pointer, so the mouse alone is enough (Ableton Live's context menus, Figma's right-click).
// Flutter's RawMenuAnchor opens it at the pointer and closes it on a click outside.
// A row is a label. A disabled row shows why it cannot be done, and the keyboard shortcut is dimmed on the right.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/float_shut.dart' show FloatShut;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// One row of a menu.
///
/// A null [go] means the row cannot be done now, and [why] says why. [keys] is the keyboard shortcut shown beside it.
/// The shortcut is never the only way to run it. [ContextMenuItem.rule] is a divider between groups.
class ContextMenuItem {
  const ContextMenuItem(this.label, this.go, {this.keys = '', this.why = '', this.id}) : colors = const [], picked = -1, pick = null;
  const ContextMenuItem.rule() : label = '', go = null, keys = '', why = '', id = null, colors = const [], picked = -1, pick = null;

  /// A row of colours to choose from, as Ableton Live's context menus end with the clip or track colours.
  ///
  /// [picked] is the index of the current colour, or -1 for none. [pick] is called with the index of the one clicked.
  const ContextMenuItem.colors(this.colors, this.picked, this.pick) : label = '', go = null, keys = '', why = '', id = null;
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
  const ContextMenuList({super.key, required this.items, required this.close, required this.max, required this.width});
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
                      border: Border.all(color: k == it.picked || h ? Grey.g95 : const Color(0x00000000), width: 2),
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
      : Pressable(
          key: ValueKey(it.id ?? 'ws-menu-${it.label}'),
          cursor: it.go != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onTap: it.go == null
              ? null
              : () {
                  close();
                  it.go!();
                },
          builder: (_, h) => Container(
            height: _row,
            padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
            decoration: BoxDecoration(color: h && it.go != null ? Grey.g20 : null, borderRadius: BorderRadius.all(Shape.r(4))),
            child: Row(
              children: [
                Expanded(
                  child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.name(it.go != null ? Grey.g91 : Grey.g56)),
                ),
                if (it.go == null && it.why.isNotEmpty)
                  Text(it.why, maxLines: 1, style: TextStyles.label(Grey.g56))
                else if (it.keys.isNotEmpty)
                  Text(it.keys, maxLines: 1, style: TextStyles.label(Grey.g56)),
              ],
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
      boxShadow: [BoxShadow(color: const Color(0x80000000), blurRadius: 24, offset: const Offset(0, 8))],
    ),
    child: ConstrainedBox(
      // A long list scrolls within [max].
      constraints: BoxConstraints(maxHeight: max),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final it in items) _one(it)]),
      ),
    ),
  );
}

class ContextMenuState extends State<ContextMenu> {
  final _m = MenuController();
  List<ContextMenuItem> _items = const [];

  /// Opens the menu with [items] at [at], a position within the child.
  void show(Offset at, List<ContextMenuItem> items) {
    setState(() => _items = items);
    _m.open(position: at);
  }

  @override
  Widget build(BuildContext context) => RawMenuAnchor(
    controller: _m,
    overlayBuilder: (context, info) {
      final w = Shape.z(220), pad = Shape.s(4);
      final h = math.min(info.overlaySize.height * .5, [for (final it in _items) ContextMenuList.high(it)].fold(0.0, (a, b) => a + b)) + pad * 2;
      final at = info.anchorRect.topLeft + (info.position ?? Offset.zero);
      return Positioned(
        left: math.max(0.0, math.min(at.dx, info.overlaySize.width - w)),
        // Opens downward from the pointer, or upward where there is no room.
        top: at.dy + h <= info.overlaySize.height ? at.dy : math.max(0.0, at.dy - h),
        child: FloatShut(
          // The anchor only closes on a left press outside. FloatShut also closes on any press and on Esc, like every floating panel.
          group: info.tapRegionGroupId,
          shut: _m.close,
          child: ContextMenuList(items: _items, close: _m.close, max: info.overlaySize.height * .5, width: w),
        ),
      );
    },
    child: widget.child,
  );
}
