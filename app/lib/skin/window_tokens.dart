import 'package:flutter/widgets.dart';

import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/tokens.dart';

/// The window's own sizes and colours. A panel names one of these; it never types a number that is the window's business.
abstract final class WsT {
  /// The gutter between panels: the dark you see between tiles.
  static const gutter = 2.0;

  /// A panel's header strip (title, tabs, small actions).
  static double get header => Shape.z(28);

  /// The stage's tool column.
  static double get rail => Shape.z(40);

  /// Panel widths and the lower band's height, at the reference window (1600 x 960).
  static const dock = 300.0, inspector = 372.0, lower = 300.0;
  static double get topBar => Shape.z(40);
  static const minWindow = Size(1280, 800);

  /// Grounds: the gutter, a panel's body, a card or row inside it, a well (field) inside that.
  static Color get ground => Grey.g00;
  static Color get body => Grey.g07;
  static Color get card => Grey.g13;
  static Color get well => Grey.g15;
  static Color get raised => Grey.g20;
  static Color get line => Grey.g20;

  /// The one accent (same as the Inspector's) and the ink drawn on it.
  static Color get accent => Accent.fill;
  static Color get accentHot => Color.lerp(accent, const Color(0xFFFFFFFF), .14)!;
  static Color get onAccent => Accent.on;
  static Color get keyDot => Accent.key;

  /// The accent drawn as a line or text on a ground. Lime reads on dark but vanishes on white, so the light shade inks it darker; fills stay [accent].
  static Color get accentInk => Accent.ink;

  /// Round things you touch: fields, chips, tabs, buttons.
  static const radius = 6.0, chipRadius = 4.0;

  /// Paddings inside a panel.
  static double get inset => Shape.s(8);
  static double get gap => Shape.s(4);

  /// Hues per kind of layer or asset, shared by timeline bars, browser tiles and the preview artwork, so a kind keeps its colour everywhere.
  /// Modelled on Ableton's clip colours.
  static Color get toneShape => ColorTheme.of('Clip1', const Color(0xFFF08A5D));
  static Color get toneText => ColorTheme.of('Clip2', const Color(0xFFD9D2C3));
  static Color get toneImage => ColorTheme.of('Clip3', const Color(0xFF7FB8B0));
  static Color get toneCamera => ColorTheme.of('Clip4', const Color(0xFFA7B4C8));
  static Color get toneGroup => ColorTheme.of('Clip5', const Color(0xFFB0A6F0));
  static Color get toneParticles => ColorTheme.of('Clip6', const Color(0xFFF2A65A));
  static Color get toneAudio => ColorTheme.of('Clip7', const Color(0xFF5CC8E8));
  // The marks on the ruler for a layer's intro and outro, like Alight Motion's small yellow ones.
  static Color get toneMark => ColorTheme.of('ElementMark', const Color(0xFFF2C94C));

  /// The playhead line: the accent, so "now" is the loudest line in the window. Its head is an [accent] fill.
  static Color get playhead => accentInk;
}
