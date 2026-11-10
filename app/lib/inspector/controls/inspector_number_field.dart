import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/controls/inspector_number_field_state.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart' show Parameter;

/// The Inspector's number field: a [NumberField] wired to the document, with a caption and an optional glyph.
class InspectorNumberField extends StatefulWidget {
  const InspectorNumberField(this.p, {super.key, required this.id, required this.caption, this.glyph, this.glyphOwnsPointer = false, this.glyphTall = false});

  /// The parameter as its card declares it. [InspectorNumberFieldState] reads its unit, decimal places and range from it.
  final Parameter p;

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
  State<InspectorNumberField> createState() => InspectorNumberFieldState();
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
