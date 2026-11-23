// Optional VST-style visual styling and inherited theme tokens for declarative custom UI trees.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// Maps a semantic tone keyword (`accent`, `layout`, `blend`, `place`, `time`, `layer`,
/// `muted`, `border`, `text`, `surface`, `well`, `black`, `white`) or `#RRGGBB[AA]` hex to [Color].
Color? resolvePanelColor(String token) {
  if (token.isEmpty) return null;
  return switch (token) {
    'accent' => Accent.fill,
    'layout' => InspectorSkin.toneLayout,
    'blend' => InspectorSkin.toneBlend,
    'place' => InspectorSkin.tonePlace,
    'time' => InspectorSkin.toneTime,
    'layer' => InspectorSkin.toneLayer,
    'muted' => Grey.g56,
    'border' => Grey.g26,
    'text' => Grey.g91,
    'surface' => Grey.g15,
    'well' => InspectorSkin.well,
    'black' => DarkGrey.g00,
    'white' => DarkGrey.g100,
    _ => colorOfHex(token.trim()),
  };
}

/// Drop shadow specification for `ui.box`, controls, and card `surface` faceplates.
class PanelShadow {
  const PanelShadow({
    this.x = 0,
    this.y = 3,
    this.blur = 0,
    this.spread = 0,
    this.color = '',
  });

  final double x;
  final double y;
  final double blur;
  final double spread;
  final String color;

  static PanelShadow? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double n(String k, double d) =>
        raw[k] is num ? (raw[k] as num).toDouble() : d;
    return PanelShadow(
      x: n('x', 0),
      y: n('y', 3),
      blur: n('blur', 0).clamp(0.0, 64.0),
      spread: n('spread', 0).clamp(-16.0, 32.0),
      color: raw['color']?.toString() ?? '',
    );
  }

  BoxShadow toBoxShadow({Color? fallback}) => BoxShadow(
    offset: Offset(x, y),
    blurRadius: blur,
    spreadRadius: spread,
    color:
        resolvePanelColor(color) ??
        fallback ??
        DarkGrey.g00.withValues(alpha: 0.45),
  );
}

/// Optional per-node or faceplate styling overrides (`style` / `surface`).
/// Every omitted field falls back to inherited [PanelThemeScope] or Motolii's skin.
class PanelStyle {
  const PanelStyle({
    this.bg = '',
    this.bg2 = '',
    this.gradAngle = 135,
    this.fg = '',
    this.muted = '',
    this.accent = '',
    this.border = '',
    this.borderWidth,
    this.radius,
    this.pad,
    this.padX,
    this.padY,
    this.gap,
    this.fontSize,
    this.letterSpacing,
    this.height,
    this.mono = false,
    this.align = '',
    this.framed,
    this.shadow,
    this.controlBg = '',
    this.controlFg = '',
    this.controlBorder = '',
  });

  final String bg;
  final String bg2;
  final double gradAngle;
  final String fg;
  final String muted;
  final String accent;
  final String border;
  final double? borderWidth;
  final double? radius;
  final double? pad;
  final double? padX;
  final double? padY;
  final double? gap;
  final double? fontSize;
  final double? letterSpacing;
  final double? height;
  final bool mono;
  final String align;
  final bool? framed;
  final PanelShadow? shadow;
  final String controlBg;
  final String controlFg;
  final String controlBorder;

  bool get isEmpty =>
      bg.isEmpty &&
      bg2.isEmpty &&
      fg.isEmpty &&
      muted.isEmpty &&
      accent.isEmpty &&
      border.isEmpty &&
      borderWidth == null &&
      radius == null &&
      pad == null &&
      padX == null &&
      padY == null &&
      gap == null &&
      fontSize == null &&
      letterSpacing == null &&
      height == null &&
      !mono &&
      align.isEmpty &&
      framed == null &&
      shadow == null &&
      controlBg.isEmpty &&
      controlFg.isEmpty &&
      controlBorder.isEmpty;

  static PanelStyle? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double? optNum(String k) =>
        raw[k] is num ? (raw[k] as num).toDouble() : null;
    final st = PanelStyle(
      bg: raw['bg']?.toString() ?? '',
      bg2: raw['bg2']?.toString() ?? '',
      gradAngle: optNum('gradAngle') ?? 135.0,
      fg: raw['fg']?.toString() ?? '',
      muted: raw['muted']?.toString() ?? '',
      accent: raw['accent']?.toString() ?? '',
      border: raw['border']?.toString() ?? '',
      borderWidth: optNum('borderWidth'),
      radius: optNum('radius'),
      pad: optNum('pad'),
      padX: optNum('padX'),
      padY: optNum('padY'),
      gap: optNum('gap'),
      fontSize: optNum('fontSize'),
      letterSpacing: optNum('letterSpacing'),
      height: optNum('height'),
      mono: raw['mono'] == true,
      align: raw['align']?.toString() ?? '',
      framed: raw['framed'] is bool ? raw['framed'] as bool : null,
      shadow: PanelShadow.fromJson(raw['shadow']),
      controlBg: raw['controlBg']?.toString() ?? '',
      controlFg: raw['controlFg']?.toString() ?? '',
      controlBorder: raw['controlBorder']?.toString() ?? '',
    );
    return st.isEmpty ? null : st;
  }

  EdgeInsets? resolvePadding() {
    if (pad == null && padX == null && padY == null) return null;
    final h = padX ?? pad ?? 0.0;
    final v = padY ?? pad ?? 0.0;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  BoxDecoration toDecoration({
    Color? fallbackBg,
    Color? fallbackBorder,
    double fallbackBorderWidth = 1.0,
    double fallbackRadius = 6.0,
    bool forceBorder = false,
  }) {
    final c1 = resolvePanelColor(bg) ?? fallbackBg;
    final c2 = resolvePanelColor(bg2);
    final bCol = resolvePanelColor(border) ?? fallbackBorder;
    final bW =
        borderWidth ??
        (border.isNotEmpty || forceBorder ? fallbackBorderWidth : 0.0);
    final rad = radius ?? fallbackRadius;
    LinearGradient? grad;
    if (c1 != null && c2 != null) {
      final a = gradAngle * math.pi / 180.0;
      final dx = math.cos(a);
      final dy = math.sin(a);
      grad = LinearGradient(
        begin: Alignment(-dx, -dy),
        end: Alignment(dx, dy),
        colors: [c1, c2],
      );
    }
    return BoxDecoration(
      color: grad == null ? c1 : null,
      gradient: grad,
      borderRadius: BorderRadius.circular(rad),
      border: (bCol != null && bW > 0)
          ? Border.all(color: bCol, width: bW)
          : null,
      boxShadow: shadow == null ? null : [shadow!.toBoxShadow()],
    );
  }
}

/// Inherited faceplate theme pushed by a card's `surface` or a styled `ui.box` so
/// nested buttons, selects, knobs, and text adopt the creator's VST palette cleanly.
class PanelThemeData {
  const PanelThemeData({
    this.fg,
    this.muted,
    this.accent,
    this.border,
    this.borderWidth,
    this.radius,
    this.controlBg,
    this.controlFg,
    this.controlBorder,
    this.shadow,
    this.mono = false,
  });

  final Color? fg;
  final Color? muted;
  final Color? accent;
  final Color? border;
  final double? borderWidth;
  final double? radius;
  final Color? controlBg;
  final Color? controlFg;
  final Color? controlBorder;
  final PanelShadow? shadow;
  final bool mono;

  PanelThemeData mergeStyle(PanelStyle? s) {
    if (s == null) return this;
    final newFg = resolvePanelColor(s.fg) ?? fg;
    return PanelThemeData(
      fg: newFg,
      muted:
          resolvePanelColor(s.muted) ?? muted ?? newFg?.withValues(alpha: 0.65),
      accent: resolvePanelColor(s.accent) ?? accent,
      border: resolvePanelColor(s.border) ?? border,
      borderWidth: s.borderWidth ?? borderWidth,
      radius: s.radius ?? radius,
      controlBg: resolvePanelColor(s.controlBg) ?? controlBg,
      controlFg: resolvePanelColor(s.controlFg) ?? controlFg ?? newFg,
      controlBorder:
          resolvePanelColor(s.controlBorder) ??
          resolvePanelColor(s.border) ??
          controlBorder,
      shadow: s.shadow ?? shadow,
      mono: s.mono || mono,
    );
  }
}

class PanelThemeScope extends InheritedWidget {
  const PanelThemeScope({required this.data, required super.child, super.key});

  final PanelThemeData data;

  static PanelThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelThemeScope>()?.data ??
      const PanelThemeData();

  @override
  bool updateShouldNotify(PanelThemeScope oldWidget) => data != oldWidget.data;
}

/// Returns high-contrast foreground ink (`black` or `white`) for any background color.
Color readableInkOn(Color bg) =>
    bg.computeLuminance() > 0.45 ? DarkGrey.g00 : DarkGrey.g100;
