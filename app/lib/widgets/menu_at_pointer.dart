import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/dismiss_region.dart';
import 'package:motolii/widgets/context_menu.dart' show ContextMenuItem, ContextMenuList;

/// A short menu at the pointer position, kept inside the window. It is the right-click menu of a number.
///
/// It shows a [ContextMenuList]. Each row has the id `name-key:of`.
class TinyMenuAt extends StatelessWidget {
  const TinyMenuAt({super.key, required this.at, required this.name, required this.of, required this.items, required this.hide, this.keep});

  /// Where the pointer was pressed, in the overlay's coordinates.
  final Offset at;

  /// The first part of each row's id.
  final String name;

  /// The last part of each row's id.
  final String of;

  /// The rows as (key, label, action).
  final List<(String, String, VoidCallback)> items;

  /// Closes the menu.
  final VoidCallback hide;

  /// Whether a pointer-down should leave the menu open instead of closing it.
  final bool Function(PointerDownEvent)? keep;
  @override
  Widget build(BuildContext context) {
    final room = MediaQuery.sizeOf(context), wide = Shape.z(150), high = items.length * Shape.z(22) + 2 * Shape.s(3) + 2;
    return Stack(
      children: [
        Positioned(
          left: at.dx.clamp(0, math.max(0, room.width - wide)).toDouble(),
          top: (at.dy + high <= room.height ? at.dy : math.max(0, at.dy - high)).toDouble(),
          child: DismissRegion(
            shut: hide,
            keep: keep,
            child: ContextMenuList(
              items: [for (final (k, l, f) in items) ContextMenuItem(l, f, id: '$name-$k:$of')],
              close: hide,
              max: room.height * .5,
              width: wide,
            ),
          ),
        ),
      ],
    );
  }
}
