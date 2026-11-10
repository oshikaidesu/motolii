import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_values.dart';

/// Gives the Inspector's widgets the current document and a rebuild tick.
class InspectorScope extends InheritedWidget {
  const InspectorScope({
    super.key,
    required this.doc,
    required this.tick,
    required super.child,
  });
  final InspectorValues doc;

  /// Bumped by the app when more than numbers changed, such as the card structure, labels or the selection.
  /// Only then is everything that reads the Inspector rebuilt.
  /// A changed number only notifies the field that shows it (InspectorValues.watch).
  final int tick;
  static InspectorScope of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<InspectorScope>()!;
  static InspectorScope read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<InspectorScope>()!;
  @override
  bool updateShouldNotify(InspectorScope old) =>
      old.tick != tick || old.doc != doc;
}
