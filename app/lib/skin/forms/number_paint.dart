// How a number field looks, kept out of the field's own file to avoid an import cycle.
//
// The field's file is imported by the inspector, and the inspector is imported by the forms, so the field cannot import
// the forms. Instead the forms call [bindNumber] when they load.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Everything a form needs to draw one number field.
class NumberSpec {
  const NumberSpec({
    required this.value,
    required this.width,
    required this.height,
    required this.fillColor,
    required this.borderColor,
    required this.rangeColor,
    this.editor,
    this.lead,
    this.glyph,
    this.caption,
    this.fill,
    this.zeroAt = 0,
    this.bipolar = false,
    this.editing = false,
    this.glyphTall = false,
    this.on = true,
    this.hot = false,
    this.live = false,
    this.keyDot,
    this.keyEmpty = false,
    this.pad = 8,
    this.glyphBox = 22,
    this.inline = false,
  });

  /// The number as text, when it is not being typed.
  final Widget value;

  /// The text field shown while the user types. The field owns it; a form only places it.
  final Widget? editor;
  final Widget? lead, glyph;
  final String? caption;
  final double width, height, pad, glyphBox, zeroAt;

  /// Position of the range mark from 0 to 1 along a bounded field. Null means the field has no range, so no mark is drawn.
  final double? fill;
  final bool bipolar, editing, glyphTall, on, hot, live;
  final Color fillColor, borderColor, rangeColor;
  final Color? keyDot;

  /// Draws the keyframe mark hollow: the property can be keyframed but has no keyframe here.
  ///
  /// This follows Alight Motion's empty diamond beside a value.
  final bool keyEmpty;

  /// Lays out the caption and the number in one row with no frame: the caption first, the number at the right.
  ///
  /// Used for the small numbers in a tool panel.
  final bool inline;
}

/// A keyframe mark for a value: a diamond, as in Alight Motion beside each value and in the timeline.
///
/// Filled means a keyframe at this time, faint means keyframes at other times, and [empty] means none yet.
/// When the user presses it, the field adds a keyframe there (see lib/widgets/number_field_state.dart).
Widget keyDiamond(Color colour, {bool empty = false}) => Transform.rotate(
  angle: math.pi / 4,
  child: Container(
    width: Shape.z(5),
    height: Shape.z(5),
    decoration: BoxDecoration(
      color: empty ? null : colour,
      border: empty ? Border.all(color: colour) : null,
    ),
  ),
);

typedef NumberPaint = Widget Function(BuildContext context, NumberSpec spec);

NumberPaint _paint = usualNumber;

/// Installs a form's [Forms.number] when the forms library loads.
void bindNumber(NumberPaint paint) => _paint = paint;

Widget paintNumber(BuildContext context, NumberSpec spec) => _paint(context, spec);

/// The app's default number field: a filled well with the range mark along the bottom.
Widget usualNumber(BuildContext context, NumberSpec n) {
  final shown = n.editing && n.editor != null ? n.editor! : n.value;
  return Container(
    height: n.height,
    decoration: BoxDecoration(
      color: n.fillColor,
      borderRadius: BorderRadius.circular(6),
      border: n.inline ? null : Border.all(color: n.borderColor),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        children: [
          if (n.fill != null && n.bipolar)
            Positioned(
              left: (n.width - 2) * (n.fill! < n.zeroAt ? n.fill! : n.zeroAt),
              bottom: 0,
              height: Shape.z(2),
              width: math.max(1, (n.width - 2) * (n.fill! - n.zeroAt).abs()),
              child: ColoredBox(color: n.rangeColor),
            )
          else if (n.fill != null)
            Positioned(
              left: 0,
              bottom: 0,
              height: Shape.z(2),
              width: (n.width - 2) * n.fill!,
              child: ColoredBox(color: n.rangeColor),
            ),
          if (n.keyDot != null)
            Positioned(
              bottom: 7,
              right: n.pad,
              child: keyDiamond(n.keyDot!, empty: n.keyEmpty),
            ),
          if (n.glyph != null)
            Positioned(
              right: n.glyphTall ? 4 : n.pad - 3,
              top: 4,
              width: n.glyphBox,
              height: n.glyphTall ? null : n.glyphBox,
              bottom: n.glyphTall ? 4 : null,
              child: Center(child: n.glyph),
            ),
          Positioned.fill(
            child: Padding(
              padding: n.inline
                  ? EdgeInsets.symmetric(horizontal: n.pad)
                  : EdgeInsets.fromLTRB(n.pad, Shape.s(4), n.glyph != null ? n.glyphBox + n.pad : n.pad, Shape.s(5)),
              child: Flex(
                // A tile is a column, with the caption above the number.
                direction: n.inline ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: n.inline ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (n.caption != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(n.caption!, maxLines: 1, style: n.inline ? T.label(Grey.g63) : T.micro(n.on ? Grey.g63 : Grey.g44).copyWith(height: 1.1)),
                    ),
                  if (n.inline)
                    Expanded(
                      child: Align(alignment: Alignment.centerRight, child: shown),
                    )
                  else
                    SizedBox(
                      height: Shape.z(18),
                      child: Align(alignment: Alignment.centerLeft, child: shown),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
