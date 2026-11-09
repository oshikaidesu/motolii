// Every value here is read from docs/app/DESIGN.md (the tag in the comment says where it came from). A part names a token; it never picks a number.
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/hct/hct.dart';

import 'theme.dart';

abstract final class N {
  static const g00 = Color(0xFF000000), g07 = Color(0xFF131313), g10 = Color(0xFF191919), g13 = Color(0xFF202020), g15 = Color(0xFF262626);
  static const g20 = Color(0xFF343434), g26 = Color(0xFF424242), g38 = Color(0xFF616161), g44 = Color(0xFF717171), g56 = Color(0xFF8E8E8E);
  static const g63 = Color(0xFFA1A1A1), g76 = Color(0xFFC1C1C1), g91 = Color(0xFFE7E7E7), g95 = Color(0xFFF2F2F2), g100 = Color(0xFFFFFFFF);
  // [decided] the timeline's two row bands and its row line
  static const bandA = Color(0xFF1E1E1E), bandB = Color(0xFF2A2A2A), rowLine = Color(0xFF161616);
}

/// The window's colour theme. Themed parts (the Workspace and the Inspector library) read [Grey], never [N]; [N] stays the dark
/// ramp of the older studies, which are dark only.
enum Shade { dark, light }

/// The grey ramp that follows [Grey.shade], with [N]'s names. Each step keeps its role in both shades — ground (the gutter),
/// body, card, well, raised, lines, quiet text, text, strong text — only the lightness turns around: in light, cards are the
/// brightest and text the darkest. Dark is exactly [N].
abstract final class Grey {
  static final shade = ValueNotifier<Shade>(Shade.dark);
  static bool get light => ColorTheme.shadeSaid.value ?? shade.value == Shade.light; // (a skin that names its shade has it)
  static Color _p(String role, Color dark, Color light) => ColorTheme.of(role, _made(Grey.light ? light : dark)); // (the theme file's, else the shade's own)

  /// A step of the shade's own ramp moved onto the skin's `Background` and `Foreground` (neither said: as it is), so a skin
  /// names two colours and every grey follows: the step's tone sits between theirs where the shade's own body (Grey07) and
  /// text (Grey95) put it (Material's HCT, so equal tones look equally light), its colour the nearer one's; the body is the
  /// Background itself and the text the Foreground itself.
  static Color _made(Color own) {
    final bg = ColorTheme.roles.value['Background'], fg = ColorTheme.roles.value['Foreground'];
    if (bg == null && fg == null) return own;
    return _madeOnce.putIfAbsent((own, bg, fg, light), () {
      final body = light ? const Color(0xFFF2F2F4) : N.g07, text = light ? const Color(0xFF121318) : N.g95;
      final b = bg ?? body, f = fg ?? text, tb = Hct.fromInt(b.toARGB32()).tone, tf = Hct.fromInt(f.toARGB32()).tone;
      final t =
          (Hct.fromInt(own.toARGB32()).tone - Hct.fromInt(body.toARGB32()).tone) / (Hct.fromInt(text.toARGB32()).tone - Hct.fromInt(body.toARGB32()).tone);
      final side = Hct.fromInt(
        (t < .5 ? b : f).toARGB32(),
      ); // (grounds wear the background's colour, inks the foreground's: never a muddy mix of two strong ones)
      final made = t == 0 ? b : (t == 1 ? f : Color(Hct.from(side.hue, side.chroma, (tb + (tf - tb) * t).clamp(0.0, 100.0)).toInt()));
      return made.withAlpha((own.a * 255).round());
    });
  }

  static final _madeOnce = <(Color, Color?, Color?, bool), Color>{};

  static Color get g00 => _p('Grey00', N.g00, const Color(0xFFCFD0D4));
  static Color get g07 => _p('Grey07', N.g07, const Color(0xFFF2F2F4));
  static Color get g10 => _p('Grey10', N.g10, const Color(0xFFECECEF));
  static Color get g13 => _p('Grey13', N.g13, const Color(0xFFFFFFFF));
  static Color get g15 => _p('Grey15', N.g15, const Color(0xFFEAEAED));
  static Color get g20 => _p('Grey20', N.g20, const Color(0xFFDEDFE3));
  static Color get g26 => _p('Grey26', N.g26, const Color(0xFFD2D3D8));
  static Color get g38 => _p('Grey38', N.g38, const Color(0xFFB4B5BC));
  static Color get g44 => _p('Grey44', N.g44, const Color(0xFF9C9DA5));
  static Color get g56 => _p('Grey56', N.g56, const Color(0xFF7A7B84));
  static Color get g63 => _p('Grey63', N.g63, const Color(0xFF696A73));
  static Color get g76 => _p('Grey76', N.g76, const Color(0xFF4A4B53));
  static Color get g91 => _p('Grey91', N.g91, const Color(0xFF22232A));
  static Color get g95 => _p('Grey95', N.g95, const Color(0xFF121318));
  static Color get g100 => _p('Grey100', N.g100, const Color(0xFF000000));
  static Color get bandA => ColorTheme.of('BandA', g10); // (the timeline's rows, in turn, and the line between them)
  static Color get bandB => ColorTheme.of('BandB', g13);
  static Color get rowLine => ColorTheme.of('RowLine', g10);
}

abstract final class C {
  /// The accent. Delegates to [Role.mode].
  static Color get mode => Role.mode;
}

/// The window's role colours. One palette is set, so each name is that colour.
abstract final class Role {
  static const selected = Color(0xFF7A87E3);
  static const mode = Color(0xFF7A87E3);
  static const warning = Color(0xFFF69260);
  static const error = Color(0xFFE5584B);
}

/// The window's one accent, from the skin (the theme's roles: Ableton's names, the key mark Blender's): a fill, the ink drawn on
/// it, the key mark, and the accent as a line or text (in the light shade made deep enough to read on white, unless the skin names it).
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

/// The skin's shapes (theme file roles; a role it does not say is the window's own): how round every corner is.
abstract final class Shape {
  static double get corner => ColorTheme.number('Corner', 1).clamp(0, 10); // (any number a skin says is held to what the window can draw)

  /// A corner of today's [x] px, as round as the skin says.
  static Radius r(double x) => Radius.circular(x * corner);

  /// A margin of today's [x] px, as airy as the skin says (`Spacing`).
  static double s(double x) => x * ColorTheme.number('Spacing', 1).clamp(0, 2); // (more than twice the air pushes the dock's tabs out of the window)

  /// A part's size of today's [x] px (a row's height, a strip, a rail), as large as the skin says (`Size`).
  static double z(double x) => x * ColorTheme.number('Size', 1).clamp(.85, 1.5); // (smaller parts than this leave no room for the words)
}

abstract final class T {
  static String get sans => ColorTheme.word('FontSans', 'Inter');
  static String get mono => ColorTheme.word('FontMono', 'Menlo');

  /// A type size of today's [x] px, as large as the skin says.
  static double px(double x) => x * ColorTheme.number('TextScale', 1).clamp(.85, 1.3);

  /// No text is dimmer than g56 nor smaller than 10 px (precedents: Adobe Spectrum's smallest UI text is 10 px; critique 2026-10-02: 87 of 126 use cases had 9 px / g44 captions).
  /// Only DIM text on a dark ground is lifted (luminance between g26 and g56); in the light shade, text paler than Grey.g56 is darkened to it. Dark INK (g00..g20, the text on a light fill such as the playhead head) is left alone: lifting it to g56 made it unreadable (critique pass 3).

  /// The ink of a text, held to that floor.
  static Color ink(Color c) => _floor(c);
  static Color _floor(Color c) {
    if (c.a < .5) return c;
    final l = c.computeLuminance();
    if (Grey.light) return l <= Grey.g56.computeLuminance() || l > .6 ? c : Grey.g56;
    return l >= N.g56.computeLuminance() || l < .04 ? c : N.g56;
  }

  static TextStyle name([Color? c]) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: const ['.AppleSystemUIFont'],
    fontSize: px(11),
    color: ink(c ?? Grey.g91),
    height: 1,
    letterSpacing: .05,
    decoration: TextDecoration.none,
  );
  static TextStyle label([Color? c]) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: const ['.AppleSystemUIFont'],
    fontSize: px(10),
    color: ink(c ?? Grey.g63),
    height: 1,
    letterSpacing: .1,
    decoration: TextDecoration.none,
  );
  static TextStyle micro([Color? c]) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: const ['.AppleSystemUIFont'],
    fontSize: px(10),
    fontWeight: FontWeight.w500,
    color: ink(c ?? Grey.g63),
    height: 1,
    letterSpacing: .15,
    decoration: TextDecoration.none,
  );
  static TextStyle value([Color? c]) => TextStyle(fontFamily: mono, fontSize: px(11), color: ink(c ?? Grey.g91), height: 1, decoration: TextDecoration.none);
  static TextStyle title([Color? c]) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: const ['.AppleSystemUIFont'],
    fontSize: px(13),
    fontWeight: FontWeight.w600,
    color: ink(c ?? Grey.g95),
    height: 1.1,
    decoration: TextDecoration.none,
  );
}

/// What was typed, a Japanese input method's wide letters and digits as plain ones (１２８：３０ is 128:30).
String halfWidth(String said) => said.replaceAllMapped(RegExp('[！-～]'), (c) => String.fromCharCode(c[0]!.codeUnitAt(0) - 0xFEE0));
