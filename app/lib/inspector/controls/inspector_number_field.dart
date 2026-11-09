import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/controls/inspector_number_field_num_field_state.dart';

import 'package:motolii/inspector/inspector_small.dart' show FloatShut, Hov;

import '../../style/tokens.dart';

TextStyle blockValue(Color c) => T.value(c).copyWith(fontSize: T.px(14), fontWeight: FontWeight.w600, height: 1.1);

class NumField extends StatefulWidget {
  const NumField({
    super.key,
    required this.id,
    this.label,
    this.unit = '',
    this.decimals = 0,
    this.min,
    this.max,
    this.open = false,
    this.validMin,
    this.validMax,
    this.step = 1,
    this.perPx = 1,
    this.zeroWord,
    this.enabled = true,
    this.axis,
    this.turns = false,
    this.onSet,
    this.onReset,
    this.bipolar = false,
    this.caption,
    this.glyph,
    this.glyphOwnsPointer = false,
    this.glyphTall = false,
  });
  final String id;
  final String? label, unit, zeroWord;
  final int decimals;
  final double? min, max;
  final double step, perPx;
  final bool enabled, turns;

  /// [min] and [max] are how far a scrub goes; a number typed goes past them, only a [min] of 0 or more holding
  /// (After Effects' slider and valid ranges, PF_FloatSliderDef).
  final bool open;

  /// How far a number typed goes when it is less than [open]'s all: PF_FloatSliderDef's valid_min and valid_max, its
  /// slider_min and slider_max being [min] and [max].
  final double? validMin, validMax;
  final Color? axis;
  final ValueChanged<double>? onSet;
  final VoidCallback? onReset;

  /// A range around zero fills out from the middle.
  final bool bipolar;

  /// Block form: [caption] on top, the value large under it, [glyph] (a picture of the value) in the top-right corner.
  /// With [glyphOwnsPointer] a press on the glyph is the glyph's (a dial, a die), not a scrub.
  /// contract: every number in the Inspector scrubs sideways, whatever it means (a Y, a height); only a glyph may move otherwise.
  final String? caption;
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

/// Past what is vouched for: a number drawn the other way about, light for dark (Flutter's ColorFilter.matrix inversion).
const pastInk = ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]);


/// A short list over the panel, one picked does that and closes: an effect card's ⋮, a number's right click.
class TinyMenu extends StatelessWidget {
  const TinyMenu({super.key, required this.name, required this.of, required this.items, required this.hide});
  final String name, of; // (each row keyed name-word:of)
  final List<(String, String, VoidCallback)> items;
  final VoidCallback hide;
  @override
  Widget build(BuildContext context) => Container(
    width: Shape.z(150),
    padding: EdgeInsets.all(Shape.s(3)),
    decoration: BoxDecoration(color: Grey.g15, borderRadius: BorderRadius.all(Shape.r(8)), border: Border.all(color: Grey.g26)),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (key, label, does) in items)
        Hov(
          key: ValueKey('$name-$key:$of'),
          onTap: () {
            hide();
            does();
          },
          builder: (_, h) => Container(
            height: Shape.z(22),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: h ? Grey.g26 : null, borderRadius: BorderRadius.all(Shape.r(5))),
            child: Text(label, maxLines: 1, style: T.name(h ? Grey.g95 : Grey.g76)),
          ),
        ),
    ]),
  );
}

/// [TinyMenu] where the hand pressed, kept inside the window.
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
    return Stack(children: [
      Positioned(
        left: at.dx.clamp(0, math.max(0, room.width - wide)).toDouble(),
        top: (at.dy + high <= room.height ? at.dy : math.max(0, at.dy - high)).toDouble(),
        child: FloatShut(shut: hide, keep: keep, child: TinyMenu(name: name, of: of, items: items, hide: hide)),
      ),
    ]);
  }
}

/// The field's claim on a press that scrubs it: taken at once, before a scroll round it can (Flutter's EagerGestureRecognizer, asked first).
class ScrubClaim extends OneSequenceGestureRecognizer {
  bool Function(PointerDownEvent) takes = (_) => false;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!takes(event)) return;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
    stopTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'scrub';
  @override
  void didStopTrackingLastPointer(int pointer) {}
  @override
  void handleEvent(PointerEvent event) {}
}
