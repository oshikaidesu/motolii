// Editing keyframes on the timeline: slide, remove, copy and paste.
//
// Sliding works like dragging keyframes in After Effects. Every property of the layer that has a keyframe at that
// time keeps its value and easing at the new time, all as one undo step. The edit is queued on the engine without
// waiting. While the user drags, the timeline shows the keyframes at the playhead until the drag ends.
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';

/// Moves the keyframes [keys] (each a row and a frame) [by] frames later, or earlier when [by] is negative.
void slideKeyframes(
  WorkspaceController ws,
  Iterable<SelectedKeyframe> keys,
  int by,
) {
  final m = ws.inside;
  if (m == null || by == 0 || keys.isEmpty) return;
  final moves =
      <
        (int, String, double, double, double, String)
      >[]; // (layer, property, from, to, value, easing)
  for (final k in keys) {
    final t = int.tryParse(k.layer);
    if (t == null) continue;
    final at = k.frame / WorkspaceController.fps,
        to =
            (k.frame + by).clamp(0, WorkspaceController.duration) /
            WorkspaceController.fps;
    for (final n in m.moving(t)) {
      if (!m
          .keyTimes(t, n)
          .any((s) => (s - at).abs() < .5 / WorkspaceController.fps)) {
        continue;
      }
      moves.add((t, n, at, to, m.value(t, n, at) ?? 0, m.easingOf(t, n, at)));
    }
  }
  if (moves.isEmpty) return;
  m.later('together', number: 1);
  for (final (t, n, at, _, _, _) in moves) {
    m.later('unkey', layer: t, name: n, number: at); // All are removed first so that a keyframe slid onto another's old time is not lost.
  }
  for (final (t, n, _, to, v, way) in moves) {
    m.later('key', layer: t, name: n, word: '$to', number: v);
    if (way.isNotEmpty) {
      m.later('easing', layer: t, name: n, number: to, word: way);
    }
  }
  ws.after(m.later('together'), (_, _) => ws.reread());
}

/// Removes the selected keyframes, and those of the other properties of the layer at the same time, as one undo step.
void removeKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  final m = ws.inside;
  if (m == null || keys.isEmpty) return;
  m.later('together', number: 1);
  for (final k in keys) {
    final t = int.tryParse(k.layer);
    if (t == null) continue;
    final at = k.frame / WorkspaceController.fps;
    for (final n in m.moving(t)) {
      if (m
          .keyTimes(t, n)
          .any((s) => (s - at).abs() < .5 / WorkspaceController.fps)) {
        m.later('unkey', layer: t, name: n, number: at);
      }
    }
  }
  ws.clearKeys();
  ws.after(m.later('together'), (_, _) => ws.reread());
}

/// The keyframes of the last copy: property, frames after the first one, value, easing.
/// Empty when the last copy was a layer.
List<(String, int, double, String)> copiedKeyframes = const [];

/// Copies the selected keyframes, as Copy and Paste of keyframes do in After Effects.
void copyKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  final m = ws.inside;
  if (m == null || keys.isEmpty) return;
  final first = keys.map((k) => k.frame).reduce((a, b) => a < b ? a : b);
  copiedKeyframes = [
    for (final k in keys)
      if (int.tryParse(k.layer) case final t?)
        for (final n in m.moving(t))
          if (m
              .keyTimes(t, n)
              .any(
                (s) =>
                    (s - k.frame / WorkspaceController.fps).abs() <
                    .5 / WorkspaceController.fps,
              ))
            (
              n,
              k.frame - first,
              m.value(t, n, k.frame / WorkspaceController.fps) ?? 0,
              m.easingOf(t, n, k.frame / WorkspaceController.fps),
            ),
  ];
}

/// Pastes the copied keyframes onto the selected layer as one undo step, the first at the playhead, and selects them.
void pasteKeyframes(WorkspaceController ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null || copiedKeyframes.isEmpty) return;
  m.later('together', number: 1);
  for (final (n, after, v, way) in copiedKeyframes) {
    final at = (ws.frame + after) / WorkspaceController.fps;
    m.later('key', layer: t, name: n, word: '$at', number: v);
    if (way.isNotEmpty) {
      m.later('easing', layer: t, name: n, number: at, word: way);
    }
  }
  final pasted = [
    for (final f in {for (final k in copiedKeyframes) ws.frame + k.$2})
      (layer: '$t', frame: f),
  ];
  ws.after(m.later('together'), (_, _) {
    ws
      ..reread()
      ..pickKeys(pasted);
  });
}
