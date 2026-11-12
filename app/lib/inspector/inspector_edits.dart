import 'package:flutter/foundation.dart' show ValueChanged, VoidCallback;

import 'package:motolii/inspector/inspector_state.dart';

/// The callbacks through which the Inspector reports what was edited in it to the owner of the values.
class InspectorEdits {
  /// Creates the callbacks an Inspector reports its edits through.
  const InspectorEdits({
    required this.onValues,
    required this.onDrop,
    required this.onKey,
    required this.onWords,
    required this.onAnimateAll,
    required this.together,
    required this.onRoute,
    required this.onAim,
    this.onFlags,
  });

  /// Values changed in the inspector. [live] is true while a drag is still in progress, and the call is repeated once when the drag ends.
  final void Function(Map<String, double> changed, {required bool live})
  onValues;

  /// A drag was cancelled with Esc: what it showed is to be dropped.
  final VoidCallback onDrop;

  /// A property's key mark was changed in the inspector.
  final void Function(String prop, KeyframeState mark) onKey;

  /// Strings changed in the inspector, such as a text's content or a chooser's choice. [live] is true while a drag
  /// that changes them is still in progress (a text range's Size); the drag's last strings come with it false.
  /// Returns false if the caller did not take them, and the fields go back to their previous strings.
  final bool Function(Map<String, String> changed, {required bool live})
  onWords;

  /// On/off properties changed in the inspector, such as Clip to below. Null when the caller owns none.
  /// Returns false if the caller did not take the change (nothing is behind that switch), and the switch goes back.
  final bool Function(Map<String, bool> changed)? onFlags;

  /// Animate all was turned on or off. The caller's document may then key whatever a drag changes, wherever the drag is.
  final ValueChanged<bool> onAnimateAll;

  /// Wraps one change of the inspector, values then key marks, so the caller can record it as one undo step.
  final void Function(VoidCallback tells) together;

  /// A panel link asked to open a panel (`Browser › Fonts`, `Ease`); the caller opens it.
  final ValueChanged<String> onRoute;

  /// The slot a panel link pointed at when it asked for its panel, or '' for none. Called just before [onRoute].
  final ValueChanged<String> onAim;
}
