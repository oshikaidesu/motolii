// The stage's own sizes and colours.
import 'dart:ui' show Color;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// Viewport sizes: the ruler band, the margin a fit leaves around the composition, the HUD pill and the navigator.
abstract final class StageTokens {
  static double get ruler => Shape.z(16.0);
  static double get fitMargin => Shape.s(28.0);
  static double get hud => Shape.z(22.0);
  static double get mapW => Shape.z(136.0);
  static double get pad => Shape.s(8.0);
  static double get handle => Shape.z(7.0);
  static double get stem => Shape.z(18.0);
  static double get tagH => Shape.z(16.0);
  static Color get surround => Grey.g10;
  static Color get rulerGround => Grey.g13;
  static Color get rulerSpan => Grey.g15;
  static Color get tick => Grey.g38;
  static Color get guide => WindowTokens.toneAudio;
  static const overlay = Color(0x40FFFFFF), safe = Color(0x99F6EFDD);
}
