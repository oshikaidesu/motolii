import 'package:flutter/widgets.dart' show Color;

/// Parses a hex colour as the project and the theme file write it: `rrggbb` or `rrggbbaa` (alpha last), with or without a `#`.
///
/// Returns null if [word] is not such a hex colour.
/// flutter_colorpicker's colorFromHex is not used because it reads `aarrggbb`.
Color? colorOfHex(String word) {
  final hex = word.startsWith('#') ? word.substring(1) : word,
      v = int.tryParse(hex, radix: 16);
  if (v == null || hex.length != 6 && hex.length != 8) return null;
  return hex.length == 8
      ? Color(((v & 0xFF) << 24) | (v >> 8))
      : Color(0xFF000000 | v);
}
