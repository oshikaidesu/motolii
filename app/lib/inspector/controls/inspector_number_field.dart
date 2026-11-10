import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/controls/inspector_number_field_num_field_state.dart';
import 'package:motolii/inspector/controls/param_infer.dart' show Param;

import 'package:motolii/inspector/inspector_small.dart' show FloatShut;

import '../../skin/tokens.dart';
import '../../workspace/commands/context_menu.dart' show WsMenuItem, WsMenuList;

class NumField extends StatefulWidget {
  const NumField(this.p, {super.key, required this.id, required this.caption, this.glyph, this.glyphOwnsPointer = false, this.glyphTall = false});

  /// The value as its card declares it ([NumFieldState] reads its unit, its places and its ends), and which number of it.
  final Param p;
  final String id;

  /// [caption] on top, the value large under it, [glyph] (a picture of the value) in the top-right corner.
  /// With [glyphOwnsPointer] a press on the glyph is the glyph's (a dial, a die), not a scrub.
  /// contract: every number in the Inspector scrubs sideways, whatever it means (a Y, a height); only a glyph may move otherwise.
  final String caption;
  final Widget? glyph;
  final bool glyphOwnsPointer;

  /// The glyph runs the block's full height on the right (stacked buttons) instead of sitting in the corner.
  final bool glyphTall;
  @override
  State<NumField> createState() => NumFieldState();
}

/// A card whose numbers may be scrubbed past their sliders' ends, put round its fields by the card: [flag], its doc
/// flag, is set by a right click on any of them; a held Option does it for one scrub (a quasimode, Raskin's The Humane
/// Interface). The slider's span is what the effect vouches for; past it, as far as the inside takes (Houdini's
/// range not strict: FloatParmTemplate minIsStrict).
class PastRange extends InheritedWidget {
  const PastRange({super.key, required this.flag, required super.child});
  final String flag;
  static String? of(BuildContext c) => c.getInheritedWidgetOfExactType<PastRange>()?.flag;
  @override
  bool updateShouldNotify(PastRange o) => o.flag != flag;
}

/// A short list over the panel ([WsMenuList]; each row keyed name-word:of) where the hand pressed, kept inside the window: a number's right click.
class TinyMenuAt extends StatelessWidget {
  const TinyMenuAt({super.key, required this.at, required this.name, required this.of, required this.items, required this.hide, this.keep});
  final Offset at;
  final String name, of;
  final List<(String, String, VoidCallback)> items;
  final VoidCallback hide;
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
