// The app's numeric field.
//
// - Dragging sideways changes the value. Shift makes it finer, Cmd or Ctrl ten times coarser.
// - A horizontal mouse wheel or two-finger slide over it does the same, the arrow keys nudge it, and the user can type a value.
// - It stores no value and enforces no limit. It reads the value when needed and reports every change.
//   [NumberField.min] and [NumberField.max] only position the range mark it draws.
// - How far the value may go is up to the caller through [NumberField.reach], together with the source of that limit.
// - It paints with the skin's form (lib/widgets/number_field_look.dart) or with the caller's [NumberField.paint].
//   A panel normally supplies only value, text and onChange.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/number_field_state.dart';

/// Two clicks within this time count as a double-click.
const doubleClickTime = Duration(milliseconds: 320);

/// Inverts a number's colours (light for dark) to mark a value outside the range the caller has a source for.
/// Implemented as a color inversion with Flutter's ColorFilter.matrix.
const pastInk = ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]);

/// The text style for the number in a tile. A row uses TextStyles.value at size 10.5 instead.
TextStyle blockValue(Color c) => TextStyles.value(c).copyWith(fontSize: TextStyles.px(14), fontWeight: FontWeight.w600, height: 1.1);

/// A numeric field that can be scrubbed, scrolled, nudged with the arrow keys, and typed into. See the file header.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.text,
    this.unit,
    this.onChange,
    this.onBy,
    this.onType,
    this.onGrab,
    this.onDrop,
    this.onReset,
    this.perPx,
    this.step,
    this.reach,
    this.parse,
    this.allow = r'[0-9.\-+eE*/() ]',
    this.keys = false,
    this.typeOnTap = true,
    this.sayOnLeave = true,
    this.onPress,
    this.ownsPress,
    this.onKey,
    this.past,
    this.min,
    this.max,
    this.bipolar = false,
    this.caption,
    this.glyph,
    this.glyphTall = false,
    this.glyphBox,
    this.keyDot,
    this.keyEmpty = false,
    this.picked = false,
    this.inline = false,
    this.height,
    this.pad,
    this.style,
    this.accent,
    this.editorKey,
    this.paint,
  });

  /// Returns the current value. It is read each time it is needed, so the caller need not rebuild during a drag.
  /// Null means several values: the field shows "Mixed" and moves them through [onBy].
  final double? Function() value;

  /// Formats a value for a field `room` wide. Typing starts from this text, formatted with an infinite `room`.
  final String Function(double value, double room) text;

  /// Returns a small unit shown after the number, or an empty string for none.
  final String Function(double value, double room)? unit;

  /// Callbacks for user input. Any that is null is ignored.
  ///
  /// [onChange] receives the new value on every step of a drag, slide or nudge, and the typed value when [onType] is null.
  /// [onBy] receives the change while [value] returns null. [onType] receives the typed value.
  final ValueChanged<double>? onChange, onBy, onType;

  /// [onGrab] is called on the first move of a drag and [onDrop] when it ends, so the caller can treat a drag as a single step.
  /// Esc or a pointer cancel restores the starting value and then calls [onDrop].
  /// [onReset] is called on a double-click, and on Delete or Backspace when [keys] is true.
  final VoidCallback? onGrab, onDrop, onReset;

  /// [perPx] is how much one pixel of drag or slide changes the value. Null means the field cannot be scrubbed and shows a text cursor.
  /// [step] is the change per arrow key press. Null means the field ignores the arrow keys.
  final double? perPx, step;

  /// Limits how far the user can take the value. It receives the target value and, for a drag, the value where the drag began.
  /// `from` is null for a slide, a nudge, or an arrow step while typing. A typed number does not pass through it.
  final double Function(double to, double? from)? reach;

  /// Converts typed text to a number. Returning null keeps the field open. Defaults to a plain number parse.
  final double? Function(String said)? parse;

  /// The characters that may be typed, as a RegExp source. Null allows any.
  final String? allow;

  /// [keys]: a press gives the field keyboard focus and it keeps it, as the inspector's fields do. Arrows nudge, Return or a digit
  /// starts typing, Tab moves to the next field and Delete resets. When false the field handles keys only while being typed in.
  /// [typeOnTap]: a click without a drag starts typing, so double-click cannot be used.
  /// [sayOnLeave]: when false, only Return reports the typed text; leaving the field discards it, as [TypedField] does.
  final bool keys, typeOnTap, sayOnLeave;

  /// Asked about every press first. True means the press belongs to the caller, for example a menu or a mark, and the field does nothing.
  /// False also means it belongs to the caller, but the field still takes keyboard focus, for example for a pick.
  /// Null leaves the press to the field.
  final bool? Function(PointerDownEvent e, double room)? onPress;

  /// Returns true for a position that is not a scrub and that the field does not claim, for example a dial inside the field.
  final bool Function(Offset at, double room)? ownsPress;

  /// Asked about each key event after the drag's Esc handling and before the field's own handling.
  final KeyEventResult Function(KeyEvent e)? onKey;

  /// Returns true to draw the number inverted ([pastInk]). The argument is whether a drag is in progress.
  final bool Function(bool live)? past;

  /// Appearance in the skin's form, which fills the width it is given.
  ///
  /// [caption] is shown over the number, or before it on one row when [inline]. [picked] marks the field as one of several picked.
  final String? caption;

  /// A picture of the value drawn in the corner. [glyphTall] makes it the full height.
  final Widget? glyph;

  /// [min] and [max] are the ends of the range mark. Set both or neither. When [bipolar], a range around zero fills out from the middle.
  /// [keyEmpty] draws the key mark hollow.
  final bool bipolar, glyphTall, keyEmpty, picked, inline;
  final double? min, max, glyphBox, height, pad;

  /// [keyDot] is the colour of the key mark. [accent] colours the range mark and the caret.
  final Color? keyDot, accent;
  final TextStyle? style;

  /// Key given to the editor while the user is typing.
  final Key? editorKey;

  /// Replaces the skin's picture, for example with a quiet readout. It receives the number as text or, while `typing`, the editor.
  final Widget Function(BuildContext context, Widget shown, bool typing)? paint;

  @override
  State<NumberField> createState() => NumberFieldState();
}

/// Claims a press that scrubs the field immediately, so an enclosing scroll view cannot take it first.
/// Based on Flutter's EagerGestureRecognizer.
class ScrubClaim extends EagerGestureRecognizer {
  bool Function(PointerDownEvent) takes = (_) => false;
  @override
  bool isPointerAllowed(PointerDownEvent event) => takes(event) && super.isPointerAllowed(event);
}
