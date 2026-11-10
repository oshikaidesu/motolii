// The field of the Colors shelf where a color's hex value is typed.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// A field for typing a color's hex value, as in the color pickers of After Effects and Figma: #d4a72c, d4a72c or #da2.
/// It reports the color on Return or when the field loses focus.
class HexField extends StatelessWidget {
  /// A field showing [hex] that reports a typed color to [onTold].
  const HexField(this.hex, this.onTold, {super.key});

  /// The color shown, as #RRGGBB.
  final String hex;

  /// Called with the color typed, when it is a color and differs from [hex].
  final ValueChanged<Color> onTold;

  void _tell(String? said) {
    final bare = (said ?? '').trim().replaceFirst('#', ''),
        whole = bare.length == 3
            ? [for (final k in bare.split('')) '$k$k'].join()
            : bare;
    if (said == null ||
        whole.length != 6 ||
        colorOfHex(whole) == null ||
        '#${whole.toLowerCase()}' == hex.toLowerCase()) {
      return;
    }
    onTold(colorOfHex(whole)!);
  }

  @override
  Widget build(BuildContext context) => TypedField(
    text: hex,
    standing: true,
    pickOnFocus: true,
    style: TextStyles.value(Grey.g91).copyWith(fontWeight: FontWeight.w600),
    cursor: WindowTokens.accent,
    backgroundCursor: Grey.g44,
    selection: Grey.g38,
    cursorWidth: 1.5,
    onDone: _tell,
  );
}
