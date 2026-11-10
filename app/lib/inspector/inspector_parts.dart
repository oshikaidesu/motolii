// Shared parts of the Inspector.
// What the Inspector must do comes from research/intents/inspector.md.
// How it looks follows DESIGN.md: hairlines, type carries the hierarchy, grey levels, and the accent only for Role.selected.

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_values.dart';

export 'inspector_badges.dart';
export 'inspector_choosers_header.dart';
export 'inspector_card.dart';
export 'controls/inspector_number_field.dart';
export 'inspector_panel.dart';
export 'controls/inspector_param_controls_link.dart';
export 'controls/inspector_param_controls.dart';
export 'rows/inspector_rows.dart';
export 'inspector_state.dart';
export 'controls/param_infer.dart';

// Width thresholds shared by the whole panel.
// A cell narrower than wUnit drops its unit. A cell narrower than wTight drops decimals, but never rounds to a false 0.
const wUnit = 72.0, wTight = 60.0;

/// Gives the Inspector's widgets the current document and a rebuild tick.
class InspectorScope extends InheritedWidget {
  const InspectorScope({super.key, required this.doc, required this.tick, required super.child});
  final InspectorValues doc;

  /// Bumped by the app when more than numbers changed, such as the card structure, labels or the selection.
  /// Only then is everything that reads the Inspector rebuilt.
  /// A changed number only notifies the field that shows it (InspectorValues.watch).
  final int tick;
  static InspectorScope of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<InspectorScope>()!;
  static InspectorScope read(BuildContext c) => c.getInheritedWidgetOfExactType<InspectorScope>()!;
  @override
  bool updateShouldNotify(InspectorScope old) => old.tick != tick || old.doc != doc;
}
