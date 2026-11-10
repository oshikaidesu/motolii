// Inspector parts. What the Inspector must DO comes from research/intents/inspector.md.
// How it LOOKS is the lab's (DESIGN.md): hairlines, type carries hierarchy, grey levels, accent only Role.selected. The old Motolii is not a source.

import 'package:flutter/widgets.dart';

import '../skin/theme.dart';
import '../skin/tokens.dart';
import 'inspector_state.dart';

export 'inspector_badges.dart';
export 'inspector_choosers_header.dart';
export 'inspector_card.dart';
export 'controls/inspector_number_field.dart';
export 'inspector_panel.dart';
export 'controls/inspector_param_controls_link.dart';
export 'controls/inspector_param_controls.dart';
export 'rows/inspector_rows.dart';
export 'inspector_small.dart';
export 'inspector_state.dart';
export 'controls/param_infer.dart';

// ---- 0. open values -------------------------------------------------------------------------------------------------
// [open] one narrowing rule for the whole panel (H1): a cell narrower than _wUnit drops its unit, narrower than _wTight drops decimals (never to a false 0).
const wUnit = 72.0, wTight = 60.0;
// [open] two clicks within this are a double click.
const dblParts = Duration(milliseconds: 320);

/// The bold skin of the direct-manipulation prototype: rounded cards, filled badges, one lime fill for "selected".
class Pop extends InheritedWidget {
  const Pop({super.key, required super.child});
  static bool on(BuildContext c) => c.getInheritedWidgetOfExactType<Pop>() != null;
  static Color get accent => Accent.fill; // (the skin's: one accent for the window)
  static Color get onAccent => Accent.on;
  static Color get keyDot => Accent.key;

  /// The accent as a line or text on a ground (the skin's, made deep enough to read on white). Fills stay [accent].
  static Color get accentInk => Accent.ink;
  static Color get card => Grey.g13;
  static Color get well => Grey.g15;

  /// The one spacing rule: cards are inset [inset] at the sides and [insetY] top and bottom,
  /// a card's title sits [titleGap] above its content, and cards stand [gap] apart and from the panel edge.
  /// Tight on purpose: the panel is read as a list, so more rows on screen beats air.
  /// Shape carries meaning: containers (cards, the canvas) are square and tile edge to edge; what you touch or read (fields, chips, badges, switches) is round.
  /// Colour is flat and opaque, never a tint laid over grey.
  static double get inset => Shape.s(8.0);
  static double get insetY => Shape.s(6.0);
  static double get titleGap => Shape.s(4.0);
  static double get gap => Shape.s(2.0);
  static double get titleH => Shape.z(16.0);
  static double get cell => Shape.z(22.0);

  /// A parameter block: name on top, value large at the bottom, its picture in the top-right corner; text always starts at the same x.
  static double get tile => Shape.z(42); // (the skin's Size and Spacing)
  static double get tileMin => Shape.z(100);
  static double get glyph => Shape.z(20);
  static double get tileGap => Shape.s(4);
  static double get tilePad => Shape.s(8);

  /// Each card wears its kind as a colour, so a folded stack reads by hue before it reads by word.
  /// The layer's own cards are muted; effects are saturated, since they are the ones that pile up.
  static Color get toneLayer => ColorTheme.of('ToneLayer', const Color(0xFF9AA4B2));
  static Color get toneBlend => ColorTheme.of('ToneBlend', const Color(0xFF7FB8B0));

  /// Host features (no shader): one hue per family, so a Repeater and a Trim Paths never read as the same kind of card.
  static Color get tonePlace => ColorTheme.of('TonePlace', const Color(0xFFF08A5D));
  static Color get toneTextAnim => ColorTheme.of('ToneTextAnim', const Color(0xFFE8C76A));
  static Color get toneTime => ColorTheme.of('ToneTime', const Color(0xFFE58FB4));
  static Color get toneLayout => ColorTheme.of('ToneLayout', const Color(0xFF7C9CBF));
  @override
  bool updateShouldNotify(Pop old) => false;
}

class Ctx extends InheritedWidget {
  const Ctx({super.key, required this.doc, required this.tick, required super.child});
  final Doc doc;

  /// Bumped by the host when more than numbers changed (its shape, its words, a pick): only then is everything that
  /// reads the inspector built again; a number alone tells the field that shows it (Doc.watch).
  final int tick;
  static Ctx of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Ctx>()!;
  static Ctx read(BuildContext c) => c.getInheritedWidgetOfExactType<Ctx>()!;
  @override
  bool updateShouldNotify(Ctx old) => old.tick != tick || old.doc != doc;
}
