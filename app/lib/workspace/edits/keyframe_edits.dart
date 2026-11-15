// Editing keyframes on the timeline: slide, remove, copy and paste.
//
// Sliding works like dragging keyframes in After Effects. Every property of the layer that has a keyframe at that
// time keeps its value and easing at the new time, all as one undo step. The edit is queued on the engine without
// waiting. While the user drags, the timeline shows the keyframes at the playhead until the drag ends.
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/layers/keyframe_moves.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/workspace_controller.dart';

// slideWrites is the engine's side of the slide; timeline_service.dart takes it from here.
export 'package:motolii/workspace/state/layers/keyframe_moves.dart'
    show slideWrites;

/// Moves the keyframes [keys] (each a row and a frame) [by] frames later, or earlier when [by] is negative.
void slideKeyframes(
  WorkspaceController ws,
  Iterable<SelectedKeyframe> keys,
  int by,
) {
  if (by == 0 || keys.isEmpty) return;
  ws.live.done(slideWritesOf(keys, by), (_) => ws.reread());
}

/// Removes the selected keyframes, and those of the other properties of the layer at the same time, as one undo step.
void removeKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  if (!projectOpen(ws) || keys.isEmpty) return;
  groupBegin(ws);
  unkeyAtKeyframes(ws, keys);
  ws.clearKeys();
  ws.after(groupEnd(ws), (_, _) => ws.reread());
}

/// The keyframes of the last copy: property, frames after the first one, value, easing.
/// Empty when the last copy was a layer.
List<(String, int, double, String)> copiedKeyframes = const [];

/// Copies the selected keyframes, as Copy and Paste of keyframes do in After Effects.
void copyKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  if (!projectOpen(ws) || keys.isEmpty) return;
  copiedKeyframes = keyframeCopies(ws, keys);
}

/// Pastes the copied keyframes onto the selected layer as one undo step, the first at the playhead, and selects them.
void pasteKeyframes(WorkspaceController ws) {
  final t = int.tryParse(ws.selected ?? '');
  if (!projectOpen(ws) || t == null || copiedKeyframes.isEmpty) return;
  final closed = pasteKeyframeCopies(ws, t, copiedKeyframes);
  final pasted = [
    for (final f in {for (final k in copiedKeyframes) ws.frame + k.$2})
      (layer: '$t', frame: f),
  ];
  ws.after(closed, (_, _) {
    ws
      ..reread()
      ..pickKeys(pasted);
  });
}
