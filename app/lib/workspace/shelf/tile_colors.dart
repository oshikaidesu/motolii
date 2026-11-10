// The colors and small marks every shelf draws: fill and ink of a tile, the badge of a shelf, the glyph of a header button.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Badge;

/// A [Badge] for a shelf: a tile of [hue] with the glyph at 0.62 of its size.
Widget dockBadge(DockG g, Color hue, {required double size}) => Badge(
  hue,
  size: size,
  child: Glyph(g, size: size * .62, color: WindowTokens.onAccent),
);

/// Fill and ink colors: a selected item uses the accent with dark ink, and hover is one grey step lighter.
Color dockFill(bool sel, bool hover, [Color? rest]) => sel ? WindowTokens.accent : (hover ? WindowTokens.card : rest ?? WindowTokens.body);
Color dockInk(bool sel, [Color? rest]) => sel ? WindowTokens.onAccent : rest ?? Grey.g91;

/// The glyph of an [IconPress] in the dock's header: 11 wide, in the ink color the press gives.
Widget Function(Color) dockMark(DockG g) =>
    (ink) => Glyph(g, size: Shape.z(11), color: ink);
