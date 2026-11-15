// The keyframe marks beside a value (no keyframes, animated, keyframe at this time): reading them. Setting them is in
// state/inspector_actions.dart.
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/inspector/inspector_reads.dart';
import 'package:motolii/workspace/state/inspector/inspector_values.dart'
    show drawnTime;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The keyframe mark of every keyable value of a layer, plus one per property (the strongest mark of its values).
Map<String, KeyframeState> keyframeMarks(WorkspaceController ws, String? id) {
  final t = id == null ? 0 : int.tryParse(id);
  if (!projectOpen(ws) || t == null) return const {};
  final at = drawnTime(ws);
  final marks = {
    for (final MapEntry(:key, :value) in keyableValuesOf(ws, t).entries)
      key: KeyframeState.values[keyedStateAt(ws, t, value, at)],
  };
  // A property's mark is the strongest mark among its values: a keyframe on any of them marks the property as animated.
  final props = <String, KeyframeState>{};
  for (final MapEntry(:key, :value) in marks.entries) {
    final p = propOf(key);
    if (p != key && (props[p] == null || value.index > props[p]!.index)) {
      props[p] = value;
    }
  }
  return {...marks, ...props};
}
