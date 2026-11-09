// The number field's picture.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens.dart';

class NumberSpec {
  const NumberSpec({
    required this.value,
    required this.width,
    required this.height,
    required this.fillColor,
    required this.borderColor,
    required this.rangeColor,
    this.editor,
    this.caption,
    this.fill,
    this.zeroAt = 0,
    this.bipolar = false,
    this.editing = false,
    this.keyDot,
    this.keyEmpty = false,
    this.pad = 8,
  });

  /// The number as text, when it is not being typed.
  final Widget value;

  /// The text being typed. The field owns it; a form only places it.
  final Widget? editor;
  final String? caption;
  final double width, height, pad, zeroAt;

  /// 0..1 along a bounded field. Null: the field has no range, so no mark travels.
  final double? fill;
  final bool bipolar, editing;
  final Color fillColor, borderColor, rangeColor;
  final Color? keyDot;

  /// The key mark drawn hollow: the value takes keys and has none here (Alight Motion's diamond beside a value, empty).
  final bool keyEmpty;
}

/// A value's key mark: a diamond, as Alight Motion's beside each value and the timeline's keys (filled: a key here;
/// faint: keys elsewhere; [empty]: none, yet it takes them). Pressed, the field keys the value there (num_field_state).
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

/// The field as the window has drawn it: a filled well, a range along the bottom, the axis as a stripe.
Widget usualNumber(BuildContext context, NumberSpec n) {
  final shown = n.editing && n.editor != null ? n.editor! : n.value;
  return Container(
    height: n.height,
    decoration: BoxDecoration(
      color: n.fillColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: n.borderColor),
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
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(n.pad, Shape.s(4), n.pad, Shape.s(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (n.caption != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(n.caption!, maxLines: 1, style: T.micro(Grey.g63).copyWith(height: 1.1)),
                    ),
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
