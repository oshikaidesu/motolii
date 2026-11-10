// Shared parts of the Inspector.
// What the Inspector must do comes from research/intents/inspector.md.
// How it looks follows DESIGN.md: hairlines, type carries the hierarchy, grey levels, and the accent only for Role.selected.

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

// Width thresholds shared by the whole panel.
// A cell narrower than wUnit drops its unit. A cell narrower than wTight drops decimals, but never rounds to a false 0.
const wUnit = 72.0, wTight = 60.0;

/// The Inspector's skin: rounded cards, filled badges, and one lime fill for "selected".
class Pop extends InheritedWidget {
  const Pop({super.key, required super.child});
  static bool on(BuildContext c) => c.getInheritedWidgetOfExactType<Pop>() != null;
  static Color get accent => Accent.fill; // The skin's single accent for the window.
  static Color get onAccent => Accent.on;
  static Color get keyDot => Accent.key;

  /// The accent as a line or text on a background, darkened enough to read on white. Fills use [accent].
  static Color get accentInk => Accent.ink;
  static Color get card => Grey.g13;
  static Color get well => Grey.g15;

  /// The spacing rule: card content is inset [inset] at the sides and [insetY] top and bottom.
  /// A card's title sits [titleGap] above its content, and cards are [gap] apart and from the panel edge.
  ///
  /// The spacing is tight on purpose. The panel is read as a list, so more rows on screen beats air.
  /// Containers (cards, the canvas) are square and tile edge to edge.
  /// Things the user touches or reads (fields, chips, badges, switches) are round.
  /// Colour is flat and opaque, never a tint laid over grey.
  static double get inset => Shape.s(8.0);
  static double get insetY => Shape.s(6.0);
  static double get titleGap => Shape.s(4.0);
  static double get gap => Shape.s(2.0);
  static double get titleH => Shape.z(16.0);
  static double get cell => Shape.z(22.0);

  /// A parameter block: the name on top, the value large at the bottom, and its glyph in the top-right corner.
  /// Text always starts at the same x.
  /// The tile sizes come from the skin's Size and Spacing.
  static double get tile => Shape.z(42);
  static double get tileMin => Shape.z(100);
  static double get glyph => Shape.z(20);
  static double get tileGap => Shape.s(4);
  static double get tilePad => Shape.s(8);

  /// Each card is tinted by its kind, so a folded stack reads by hue before it reads by title.
  /// The layer's own cards are muted. Effects are saturated, since they are the ones that pile up.
  static Color get toneLayer => ColorTheme.of('ToneLayer', const Color(0xFF9AA4B2));
  static Color get toneBlend => ColorTheme.of('ToneBlend', const Color(0xFF7FB8B0));

  /// Features the app provides itself (no shader), with one hue per family so a Repeater and a Trim Paths never look like the same kind of card.
  static Color get tonePlace => ColorTheme.of('TonePlace', const Color(0xFFF08A5D));
  static Color get toneTextAnim => ColorTheme.of('ToneTextAnim', const Color(0xFFE8C76A));
  static Color get toneTime => ColorTheme.of('ToneTime', const Color(0xFFE58FB4));
  static Color get toneLayout => ColorTheme.of('ToneLayout', const Color(0xFF7C9CBF));
  @override
  bool updateShouldNotify(Pop old) => false;
}

/// Gives the Inspector's widgets the current document and a rebuild tick.
class Ctx extends InheritedWidget {
  const Ctx({super.key, required this.doc, required this.tick, required super.child});
  final Doc doc;

  /// Bumped by the app when more than numbers changed, such as the card structure, labels or the selection.
  /// Only then is everything that reads the Inspector rebuilt.
  /// A changed number only notifies the field that shows it (Doc.watch).
  final int tick;
  static Ctx of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Ctx>()!;
  static Ctx read(BuildContext c) => c.getInheritedWidgetOfExactType<Ctx>()!;
  @override
  bool updateShouldNotify(Ctx old) => old.tick != tick || old.doc != doc;
}
