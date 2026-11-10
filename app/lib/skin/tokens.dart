// Every value here comes from docs/app/DESIGN.md, and the comment on it says where.
// A part uses a token and never picks a number of its own.
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/hct/hct.dart';

import 'package:motolii/skin/theme.dart';

/// The app's one motion: 120 ms, ease-out, started the moment the input lands.
///
/// Every state change (hover, select, drop) uses this and nothing else.
abstract final class Motion {
  static const dur = Duration(milliseconds: 120);
  static const ease = Curves.easeOut;
}

/// The dark grey ramp, named by lightness from 00 to 100.
abstract final class DarkGrey {
  static const g00 = Color(0xFF000000), g07 = Color(0xFF131313), g10 = Color(0xFF191919), g13 = Color(0xFF202020), g15 = Color(0xFF262626);
  static const g20 = Color(0xFF343434), g26 = Color(0xFF424242), g38 = Color(0xFF616161), g44 = Color(0xFF717171), g56 = Color(0xFF8E8E8E);
  static const g63 = Color(0xFFA1A1A1), g76 = Color(0xFFC1C1C1), g91 = Color(0xFFE7E7E7), g95 = Color(0xFFF2F2F2), g100 = Color(0xFFFFFFFF);
}

/// The two shades of the colour theme.
///
/// Themed parts (the workspace and the inspector library) read [Grey], never [DarkGrey].
/// [DarkGrey] stays the dark ramp for the older studies, which are dark only.
enum Shade { dark, light }

/// The grey ramp for the current [Grey.shade], using [DarkGrey]'s names.
///
/// Each step keeps its role in both shades: ground (the gutter), body, card, well, raised, lines, quiet text, text, strong text.
/// Only the lightness turns around: in the light shade the cards are the brightest and the text the darkest.
/// The dark shade is exactly [DarkGrey].
abstract final class Grey {
  static final shade = ValueNotifier<Shade>(Shade.dark);
  // A skin that names its shade overrides the switch.
  static bool get light => ColorTheme.shadeSaid.value ?? shade.value == Shade.light;
  // The theme file's colour for the role, else the shade's own step.
  static Color _p(String role, Color dark, Color light) => ColorTheme.of(role, _made(Grey.light ? light : dark));

  /// Moves a step [own] of the shade's ramp onto the skin's `Background` and `Foreground` colours.
  ///
  /// A skin therefore sets two colours and every grey follows. If it sets neither, [own] is returned unchanged.
  /// The tone of the result sits between the two colours at the same relative position that [own] has between the shade's
  /// body (Grey07) and text (Grey95). Tones use Material's HCT, so equal tones look equally light.
  /// The hue comes from the nearer of the two colours. The body is the Background itself and the text is the Foreground itself.
  static Color _made(Color own) {
    final bg = ColorTheme.roles.value['Background'], fg = ColorTheme.roles.value['Foreground'];
    if (bg == null && fg == null) return own;
    return _madeOnce.putIfAbsent((own, bg, fg, light), () {
      final body = light ? const Color(0xFFF2F2F4) : DarkGrey.g07, text = light ? const Color(0xFF121318) : DarkGrey.g95;
      final b = bg ?? body, f = fg ?? text, tb = Hct.fromInt(b.toARGB32()).tone, tf = Hct.fromInt(f.toARGB32()).tone;
      final t =
          (Hct.fromInt(own.toARGB32()).tone - Hct.fromInt(body.toARGB32()).tone) / (Hct.fromInt(text.toARGB32()).tone - Hct.fromInt(body.toARGB32()).tone);
      // Grounds take the background's hue and inks the foreground's, so two strong colours never mix into mud.
      final side = Hct.fromInt((t < .5 ? b : f).toARGB32());
      final made = t == 0 ? b : (t == 1 ? f : Color(Hct.from(side.hue, side.chroma, (tb + (tf - tb) * t).clamp(0.0, 100.0)).toInt()));
      return made.withAlpha((own.a * 255).round());
    });
  }

  static final _madeOnce = <(Color, Color?, Color?, bool), Color>{};

  static Color get g00 => _p('Grey00', DarkGrey.g00, const Color(0xFFCFD0D4));
  static Color get g07 => _p('Grey07', DarkGrey.g07, const Color(0xFFF2F2F4));
  static Color get g10 => _p('Grey10', DarkGrey.g10, const Color(0xFFECECEF));
  static Color get g13 => _p('Grey13', DarkGrey.g13, const Color(0xFFFFFFFF));
  static Color get g15 => _p('Grey15', DarkGrey.g15, const Color(0xFFEAEAED));
  static Color get g20 => _p('Grey20', DarkGrey.g20, const Color(0xFFDEDFE3));
  static Color get g26 => _p('Grey26', DarkGrey.g26, const Color(0xFFD2D3D8));
  static Color get g38 => _p('Grey38', DarkGrey.g38, const Color(0xFFB4B5BC));
  static Color get g44 => _p('Grey44', DarkGrey.g44, const Color(0xFF9C9DA5));
  static Color get g56 => _p('Grey56', DarkGrey.g56, const Color(0xFF7A7B84));
  static Color get g63 => _p('Grey63', DarkGrey.g63, const Color(0xFF696A73));
  static Color get g76 => _p('Grey76', DarkGrey.g76, const Color(0xFF4A4B53));
  static Color get g91 => _p('Grey91', DarkGrey.g91, const Color(0xFF22232A));
  static Color get g95 => _p('Grey95', DarkGrey.g95, const Color(0xFF121318));
  static Color get g100 => _p('Grey100', DarkGrey.g100, const Color(0xFF000000));
  // The timeline's rows alternate between bandA and bandB, with rowLine between them.
  static Color get bandA => ColorTheme.of('BandA', g10);
  static Color get bandB => ColorTheme.of('BandB', g13);
  static Color get rowLine => ColorTheme.of('RowLine', g10);
}

/// The colours for states. There is one palette, so each name is one colour.
abstract final class Role {
  static const selected = Color(0xFF7A87E3);
  static const warning = Color(0xFFF69260);
  static const error = Color(0xFFE5584B);
}

/// The app's one accent colour, from the skin's theme roles (Ableton's names, with the keyframe mark named after Blender's).
///
/// It comes as a fill, the ink drawn on the fill, the keyframe mark, and [ink] for the accent as a line or text.
/// In the light shade [ink] is darkened enough to read on white, unless the skin sets it.
abstract final class Accent {
  static Color get fill => ColorTheme.of('ChosenDefault', const Color(0xFFB3C66B));
  static Color get on => ColorTheme.of('ControlOnForeground', const Color(0xFF15170D));
  static Color get key => ColorTheme.of('Keyframe', const Color(0xFFF2C94C));
  static Color get ink {
    if (!Grey.light) return ColorTheme.of('ChosenInk', fill);
    final h = HSLColor.fromColor(fill);
    return ColorTheme.of('ChosenInk', h.withLightness(h.lightness.clamp(0, .34)).toColor());
  }
}

/// The skin's shapes, set by theme file roles. A role the skin does not set keeps the built-in value.
abstract final class Shape {
  /// How round every corner is. Any number a skin sets is clamped to what the app can draw.
  static double get corner => ColorTheme.number('Corner', 1).clamp(0, 10);

  /// A corner radius of [x] px, scaled by the skin's `Corner`.
  static Radius r(double x) => Radius.circular(x * corner);

  /// A margin of [x] px, scaled by the skin's `Spacing`.
  ///
  /// Spacing is limited to twice the default, because more than that pushes the dock's tabs out of the window.
  static double s(double x) => x * ColorTheme.number('Spacing', 1).clamp(0, 2);

  /// A size of [x] px for a part such as a row height, a strip or a rail, scaled by the skin's `Size`.
  ///
  /// Size is limited to 0.85 at the smallest, because smaller parts leave no room for the text.
  static double z(double x) => x * ColorTheme.number('Size', 1).clamp(.85, 1.5);
}

/// A laid-out single line of [s] in style [st], to measure or paint on a canvas.
///
/// The caller disposes it.
TextPainter lineText(String s, TextStyle st) => TextPainter(
  text: TextSpan(text: s, style: st),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();

/// The app's text styles and sizes.
abstract final class TextStyles {
  static String get sans => ColorTheme.word('FontSans', 'Inter');
  static String get mono => ColorTheme.word('FontMono', 'Menlo');

  /// A text size of [x] px, scaled by the skin's `TextScale`.
  static double px(double x) => x * ColorTheme.number('TextScale', 1).clamp(.85, 1.3);

  // No text is dimmer than g56 or smaller than 10 px. Adobe Spectrum's smallest UI text is also 10 px.
  // Only dim text on a dark ground is lifted (luminance between g26 and g56).
  // In the light shade, text paler than Grey.g56 is darkened to it.
  // Dark ink (g00 to g20, such as the text on a light fill like the playhead head) is left alone,
  // because lifting it to g56 made it unreadable.

  /// The colour [c] for text, raised to the minimum brightness described above.
  static Color ink(Color c) => _floor(c);
  static Color _floor(Color c) {
    if (c.a < .5) return c;
    final l = c.computeLuminance();
    if (Grey.light) return l <= Grey.g56.computeLuminance() || l > .6 ? c : Grey.g56;
    return l >= DarkGrey.g56.computeLuminance() || l < .04 ? c : DarkGrey.g56;
  }

  static TextStyle _sans(Color? c, Color dim, double size, FontWeight? w, double height, [double? ls]) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: const ['.AppleSystemUIFont'],
    fontSize: px(size),
    fontWeight: w,
    color: ink(c ?? dim),
    height: height,
    letterSpacing: ls,
    decoration: TextDecoration.none,
  );

  /// The style for a name. [size], [w] and [height] let a form set its text larger or heavier.
  static TextStyle name([Color? c, double size = 11, FontWeight? w, double height = 1]) => _sans(c, Grey.g91, size, w, height, .05);
  static TextStyle label([Color? c]) => _sans(c, Grey.g63, 10, null, 1, .1);
  static TextStyle micro([Color? c]) => _sans(c, Grey.g63, 10, FontWeight.w500, 1, .15);
  static TextStyle value([Color? c]) => TextStyle(fontFamily: mono, fontSize: px(11), color: ink(c ?? Grey.g91), height: 1, decoration: TextDecoration.none);
  static TextStyle title([Color? c]) => _sans(c, Grey.g95, 13, FontWeight.w600, 1.1);
}

/// Typed text with the full-width letters and digits of a Japanese input method turned into plain ones.
///
/// For example `１２８：３０` becomes `128:30`.
String halfWidth(String said) => said.replaceAllMapped(RegExp('[！-～]'), (c) => String.fromCharCode(c[0]!.codeUnitAt(0) - 0xFEE0));
