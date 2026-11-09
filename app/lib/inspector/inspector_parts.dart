// Inspector parts.
// How it LOOKS is the lab's (DESIGN.md): hairlines, type carries hierarchy, grey levels, accent only Role.selected. The old Motolii is not a source.

import 'package:flutter/widgets.dart';

import '../skin/theme.dart';
import '../skin/tokens.dart';
import 'inspector_state.dart';

export 'inspector_choosers_header.dart';
export 'inspector_card.dart';
export 'controls/inspector_number_field.dart';
export 'inspector_panel.dart';
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

/// Set by a row: its controls are off (locked, driven or disabled).
class RowOff extends InheritedWidget {
  const RowOff({super.key, required this.off, required super.child});
  final bool off;
  static RowOff? maybe(BuildContext c) => c.dependOnInheritedWidgetOfExactType<RowOff>();
  static bool offOf(BuildContext c) => maybe(c)?.off ?? false;
  @override
  bool updateShouldNotify(RowOff o) => o.off != off;
}

/// For controls that cannot recolour themselves (Segmented): off = a fixed dim and no pointer.
class Dis extends StatelessWidget {
  const Dis({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final off = RowOff.offOf(context);
    return IgnorePointer(
      ignoring: off,
      child: Opacity(opacity: off ? .6 : 1, child: child),
    );
  }
}

/// The inspector's colours and measures, from the skin.
abstract final class Pop {
  static Color get accent => Accent.fill; // (the skin's: one accent for the window)
  static Color get onAccent => Accent.on;
  static Color get keyDot => Accent.key;

  /// The accent as a line or text on a ground (the skin's, made deep enough to read on white). Fills stay [accent].
  static Color get accentInk => Accent.ink;
  static Color get card => Grey.g13;
  static Color get well => Grey.g15;

  /// Cards are inset [inset] at the sides, and stand [gap] apart and from the panel edge.
  static double get inset => Shape.s(8.0);
  static double get gap => Shape.s(2.0);
  static double get cell => Shape.z(22.0);

  /// A parameter block: name on top, the value under it.
  static double get tile => Shape.z(42); // (the skin's Size and Spacing)
  static double get tileMin => Shape.z(100);
  static double get tileGap => Shape.s(4);
  static double get tilePad => Shape.s(8);

  /// A card's name, one colour.
  static Color get toneLayer => ColorTheme.of('ToneLayer', const Color(0xFF9AA4B2));
}

class Ctx extends InheritedWidget {
  const Ctx({super.key, required this.doc, this.tick, required super.child});
  final Doc doc;

  /// Bumped by the host when more than numbers changed (its shape, its words, a pick): only then is everything that
  /// reads the inspector built again; a number alone tells the field that shows it (Doc.watch).
  final int? tick; // (none: a host that does not count, everything again each time, as before)
  static Ctx of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Ctx>()!;
  static Ctx read(BuildContext c) => c.getInheritedWidgetOfExactType<Ctx>()!;
  @override
  bool updateShouldNotify(Ctx old) => tick == null || old.tick != tick || old.doc != doc;
}
