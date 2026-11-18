// Scrub/scroll/type numeric field. Stores no value; reads on demand, reports every change.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/number_field_state.dart';

/// Two clicks within this time count as a double-click.
const doubleClickTime = Duration(milliseconds: 320);

/// Colour inversion to mark a value outside the caller's known range.
const pastInk = ColorFilter.matrix(<double>[
  -1,
  0,
  0,
  0,
  255,
  0,
  -1,
  0,
  0,
  255,
  0,
  0,
  -1,
  0,
  255,
  0,
  0,
  0,
  1,
  0,
]);

/// The text style for the number in a tile.
TextStyle blockValue(Color c) => TextStyles.value(c).copyWith(
  fontSize: TextStyles.px(14),
  fontWeight: FontWeight.w600,
  height: 1.1,
);

/// A numeric field: scrub, scroll, arrow-key nudge, and type.
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
    this.name,
  });

  /// Current value (read on demand). Null = "Mixed" (multi-selection; changes go through [onBy]).
  final double? Function() value;

  /// Formats a value for display. Typing starts from this text formatted with infinite `room`.
  final String Function(double value, double room) text;

  /// Unit suffix shown after the number, or ''.
  final String Function(double value, double room)? unit;

  /// [onChange]: every drag/nudge step. [onBy]: delta when value is null. [onType]: typed value.
  final ValueChanged<double>? onChange, onBy, onType;

  /// [onGrab]/[onDrop]: bracket a drag as one undo step. Esc restores the starting value.
  /// [onReset]: double-click, or Delete/Backspace when [keys] is true.
  final VoidCallback? onGrab, onDrop, onReset;

  /// [perPx]: value change per pixel. Null = no scrub. [step]: per arrow key. Null = no arrows.
  final double? perPx, step;

  /// Clamps the target value. `from` is the drag start (null for slides/nudges). Typed values bypass this.
  final double Function(double to, double? from)? reach;

  /// Parses typed text. Null keeps the field open. Default: plain number parse.
  final double? Function(String said)? parse;

  /// Allowed characters as a RegExp source. Null = any.
  final String? allow;

  /// [keys]: persistent keyboard focus (arrows nudge, Return types, Tab moves, Delete resets).
  /// [typeOnTap]: click starts typing. [sayOnLeave]: false = only Return commits.
  final bool keys, typeOnTap, sayOnLeave;

  /// True = caller owns press (field does nothing). False = caller owns but field takes focus. Null = field's.
  final bool? Function(PointerDownEvent e, double room)? onPress;

  /// True for positions the field should not claim (e.g. a dial inside it).
  final bool Function(Offset at, double room)? ownsPress;

  /// Key handler called after Esc (drag cancel) and before the field's own handling.
  final KeyEventResult Function(KeyEvent e)? onKey;

  /// True to invert colours ([pastInk]). Argument: whether a drag is in progress.
  final bool Function(bool live)? past;

  /// [caption]: label above (or beside when [inline]).
  final String? caption;

  /// Picture in the corner. [glyphTall] = full height.
  final Widget? glyph;

  /// [min]/[max]: range mark ends. [bipolar]: fills from zero. [keyEmpty]: hollow key mark.
  final bool bipolar, glyphTall, keyEmpty, picked, inline;
  final double? min, max, glyphBox, height, pad;

  /// [keyDot]: key mark colour. [accent]: range mark and caret colour.
  final Color? keyDot, accent;
  final TextStyle? style;

  /// Key for the editor while typing.
  final Key? editorKey;

  /// Document name (e.g. `js_amp`) for [typeInto] to find this field.
  final Object? name;

  /// Opens the field named [name] for typing. Waits up to 5 s for it to appear on screen.
  static void typeInto(Object name) {
    final at = DateTime.now();
    asked.value = (name, at);
    Timer(const Duration(seconds: 5), () {
      if (asked.value?.$2 == at) asked.value = null;
    });
  }

  /// Pending typeInto request; cleared when opened or after 5 s.
  static final asked = ValueNotifier<(Object, DateTime)?>(null);

  /// Custom painter. Receives the number as text, or the editor while `typing`.
  final Widget Function(BuildContext context, Widget shown, bool typing)? paint;

  @override
  State<NumberField> createState() => NumberFieldState();
}

/// Wins the gesture arena immediately so a parent scroll view cannot steal the scrub.
class ScrubClaim extends EagerGestureRecognizer {
  bool Function(PointerDownEvent) takes = (_) => false;
  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      takes(event) && super.isPointerAllowed(event);
}
