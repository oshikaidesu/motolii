// The keyframe marks beside a value (no keyframes, animated, keyframe at this time): reading them and setting them.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/workspace/inspector_feed/values.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The keyframe mark of every keyable value of a layer, plus one per property (the strongest mark of its values).
Map<String, KeyframeState> keyframeMarks(WorkspaceController ws, String? id) {
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id);
  if (m == null || t == null) return const {};
  final at = drawnTime(ws);
  final marks = {for (final MapEntry(:key, :value) in _keyable(ws, t).entries) key: KeyframeState.values[m.keyed(t, value, at)]};
  // A property's mark is the strongest mark among its values: a keyframe on any of them marks the property as animated.
  final props = <String, KeyframeState>{};
  for (final MapEntry(:key, :value) in marks.entries) {
    final p = propOf(key);
    if (p != key && (props[p] == null || value.index > props[p]!.index)) props[p] = value;
  }
  return {...marks, ...props};
}

/// The values on the cards that can take keyframes, mapping the inspector's id to the document's name.
Map<String, String> _keyable(WorkspaceController ws, int t) {
  final m = ws.inside!, moving = m.moving(t).toSet();
  return {
    for (final (_, names) in m.cards(t))
      for (final n in names)
        if (moving.contains(n)) 'v_$n': n,
  };
}

/// Applies a keyframe mark chosen in the inspector: a keyframe at the playhead, that keyframe removed, or no keyframes at all.
void applyKeyframeMark(WorkspaceController ws, String? id, String prop, KeyframeState mark) {
  final m = ws.inside!, t = id == null ? 0 : int.tryParse(id);
  if (t == null) return;
  final at = ws.frame / WorkspaceController.fps, has = m.values(t).toSet();
  // Only values the layer has are keyed. A flat layer has no scale_z, and asking for a key on it was refused,
  // which rolled back the whole undo step including the number just released.
  // With Animate on, that lost the first scale of a flat layer.
  // The calls form one undo step and do not wait for the result.
  m.later('together', number: 1);
  for (final n in [
    for (final MapEntry(:key, :value) in _keyable(ws, t).entries)
      if (key == prop || propOf(key) == prop) value,
  ].where(has.contains)) {
    m.later(
      switch (mark) {
        KeyframeState.at => 'key_here',
        KeyframeState.anim => 'unkey',
        KeyframeState.off => 'stay',
      },
      layer: t,
      name: n,
      number: at,
    );
  }
  ws.after(m.later('together'));
}
