import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/controls/inspector_number_field_num_field_state.dart';
import 'package:motolii/inspector/controls/param_infer.dart' show Param;

import 'package:motolii/widgets/float_shut.dart' show FloatShut;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/menu.dart' show WsMenuItem, WsMenuList;

/// The Inspector's number field: a [NumberField] wired to the document, with a caption and an optional glyph.
class NumField extends StatefulWidget {
  const NumField(this.p, {super.key, required this.id, required this.caption, this.glyph, this.glyphOwnsPointer = false, this.glyphTall = false});

  /// The parameter as its card declares it. [NumFieldState] reads its unit, decimal places and range from it.
  final Param p;

  /// The document id of the number this field edits.
  final String id;

  /// The label shown above the value.
  final String caption;

  /// A picture of the value, drawn in the top-right corner.
  final Widget? glyph;

  /// Whether a press on [glyph] belongs to the glyph (a dial, a die) instead of starting a drag on the number.
  ///
  /// Every number in the Inspector drags sideways, whatever it means, so only a glyph may behave differently.
  final bool glyphOwnsPointer;

  /// Whether the glyph spans the block's full height on the right (stacked buttons) instead of sitting in the corner.
  final bool glyphTall;
  @override
  State<NumField> createState() => NumFieldState();
}

/// Placed around a card's fields by the card. It lets their numbers be dragged past the slider's ends.
///
/// [flag] is a document flag. A right click on any of the fields toggles it, and holding Option does the same for a single drag
/// (a quasimode, as in Raskin's The Humane Interface). The slider range is only what the effect vouches for. Beyond it the value
/// may go as far as the engine accepts, as with Houdini's non-strict ranges (FloatParmTemplate minIsStrict).
class PastRange extends InheritedWidget {
  const PastRange({super.key, required this.flag, required super.child});

  /// The document flag that allows going past the slider's ends.
  final String flag;

  /// The flag of the nearest [PastRange], or null outside one.
  static String? of(BuildContext c) => c.getInheritedWidgetOfExactType<PastRange>()?.flag;
  @override
  bool updateShouldNotify(PastRange o) => o.flag != flag;
}

/// A short menu at the pointer position, kept inside the window. It is the right-click menu of a number.
///
/// It shows a [WsMenuList]. Each row has the id `name-key:of`.
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
          child: FloatShut(
            shut: hide,
            keep: keep,
            child: WsMenuList(
              items: [for (final (k, l, f) in items) WsMenuItem(l, f, id: '$name-$k:$of')],
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
