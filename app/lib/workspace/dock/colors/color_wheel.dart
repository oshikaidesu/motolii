// The Colors shelf's color wheel: a hue ring with a square inside it for saturation and value,
// like the Color Wheel palette in CLIP STUDIO PAINT.
// It stacks flutter_colorpicker's ring and square the way its HueRingPicker does (the square is 1/1.6 of the ring),
// without that picker's hex field, because the shelf has its own.
// It does not use flex_color_picker's ColorWheelPicker: that one compares the pointer's screen position
// with its own corner, so when the window is drawn scaled down (WindowZoom, 76%) clicks missed the wheel.
// The ring and square used here convert the position with globalToLocal, which works at any scale.
import 'package:flutter/widgets.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    show ColorPickerArea, ColorPickerHueRing, PaletteType;

/// A hue ring with a saturation and value square inside it. [onChanged] gets every new color.
class ColorWheel extends StatelessWidget {
  const ColorWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.onStart,
    this.onEnd,
  });
  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  /// Called when a pointer goes down on the wheel and when it is released or cancelled.
  /// It uses a Listener, which sees the pointer without taking it from the ring or square.
  final VoidCallback? onStart, onEnd;

  static const _ring = 14.0;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => onStart?.call(),
    onPointerUp: (_) => onEnd?.call(),
    onPointerCancel: (_) => onEnd?.call(),
    child: LayoutBuilder(
      builder: (context, box) {
        final s = box.biggest.shortestSide - _ring;
        return Stack(
          alignment: Alignment.center,
          children: [
            // The ring is stroked on the edge of its box, half of it outside, as HueRingPicker pads it.
            // That outer half takes no clicks, so an invisible ring of the full size takes them instead.
            // The hue is the angle from the center, so both rings give the same result.
            SizedBox.square(
              dimension: s,
              child: IgnorePointer(
                child: ColorPickerHueRing(color, onChanged, strokeWidth: _ring),
              ),
            ),
            SizedBox.square(
              dimension: s + _ring,
              child: Opacity(
                opacity: 0,
                child: ColorPickerHueRing(color, onChanged, strokeWidth: _ring),
              ),
            ),
            SizedBox.square(
              dimension: s / 1.6,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                child: ColorPickerArea(color, onChanged, PaletteType.hsv),
              ),
            ),
          ],
        );
      },
    ),
  );
}
