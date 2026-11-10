import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_parts.dart';

/// Gives the rows below it the keyframe state of their property.
///
/// A row reads this when its own value has no keyframe state yet.
class RowInfo extends InheritedWidget {
  const RowInfo({super.key, required this.keys, required super.child});

  /// The keyframe state of the property the rows below belong to.
  final KeyS keys;
  static RowInfo of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<RowInfo>()!;
  @override
  bool updateShouldNotify(RowInfo old) => old.keys != keys;
}
