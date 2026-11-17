// The engine's side of moving, removing and copying keyframes on the timeline. Each is one undo step.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/live_edit.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The writes that slide [keys] by [by] frames, for [WorkspaceController.live] to apply at each step of a drag.
LiveWrites slideWritesOf(Iterable<SelectedKeyframe> keys, int by) =>
    (m) => slideWrites(m, keys, by);

/// Writes the move of [slideWritesOf] and returns the layers it changed. A drag on the timeline gives it to
/// [WorkspaceController.live] at each step, so the keyframes, the stage and the panels follow the hand.
Iterable<int> slideWrites(Motolii m, Iterable<SelectedKeyframe> keys, int by) {
  if (by == 0) return const [];
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
  return _applyMoves(m, moves);
}

Iterable<int> _applyMoves(
  Motolii m,
  List<(int, String, double, double, double, String)> moves,
) {
  for (final (t, n, at, _, _, _) in moves) {
    m.later('unkey', layer: t, name: n, number: at);
  }
  for (final (t, n, _, to, v, way) in moves) {
    m.later('key', layer: t, name: n, word: '$to', number: v);
    if (way.isNotEmpty) {
      m.later('easing', layer: t, name: n, number: to, word: way);
    }
  }
  return {for (final (t, _, _, _, _, _) in moves) t};
}

/// Caches the FFI reads on the first step and reuses them on later steps.
/// [slid] is read at execution time (a field getter), not captured at call time.
class KeyframeSlideCache {
  List<(int, String, int, double, String)>? _entries;
  int _slid = 0;

  void reset() {
    _entries = null;
    _slid = 0;
  }

  /// A LiveWrites that slides [keys] by [by] frames, caching reads on the first call.
  Iterable<int> step(Motolii m, List<SelectedKeyframe> keys, int by) {
    _entries ??= _collect(m, keys);
    if (by == _slid || _entries!.isEmpty) return const [];
    final fps = WorkspaceController.fps, dur = WorkspaceController.duration;
    final moves = <(int, String, double, double, double, String)>[];
    for (final (t, n, frame, v, way) in _entries!) {
      moves.add((
        t,
        n,
        (frame + _slid) / fps,
        (frame + by).clamp(0, dur) / fps,
        v,
        way,
      ));
    }
    _slid = by;
    return _applyMoves(m, moves);
  }

  static List<(int, String, int, double, String)> _collect(
    Motolii m,
    List<SelectedKeyframe> keys,
  ) {
    final out = <(int, String, int, double, String)>[];
    for (final k in keys) {
      final t = int.tryParse(k.layer);
      if (t == null) continue;
      final at = k.frame / WorkspaceController.fps;
      for (final n in m.moving(t)) {
        if (!m
            .keyTimes(t, n)
            .any((s) => (s - at).abs() < .5 / WorkspaceController.fps)) {
          continue;
        }
        out.add((t, n, k.frame, m.value(t, n, at) ?? 0, m.easingOf(t, n, at)));
      }
    }
    return out;
  }
}

/// Queues the removal of the keyframes [keys], and of the other properties' keyframes at the same times, in the open undo
/// step. The step is begun and ended by the caller (see [groupBegin] and [groupEnd]).
void unkeyAtKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  final m = ws.inside!;
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
}

/// The keyframes [keys] as a copy: property, frames after the first one, value, easing.
List<(String, int, double, String)> keyframeCopies(
  WorkspaceController ws,
  Iterable<SelectedKeyframe> keys,
) {
  final m = ws.inside!;
  final first = keys.map((k) => k.frame).reduce((a, b) => a < b ? a : b);
  return [
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

/// Queues [copies] on layer [t], the first at the playhead, as one undo step. Returns the ticket that closes the step.
int pasteKeyframeCopies(
  WorkspaceController ws,
  int t,
  List<(String, int, double, String)> copies,
) {
  final m = ws.inside!;
  groupBegin(ws);
  for (final (n, after, v, way) in copies) {
    final at = (ws.frame + after) / WorkspaceController.fps;
    m.later('key', layer: t, name: n, word: '$at', number: v);
    if (way.isNotEmpty) {
      m.later('easing', layer: t, name: n, number: at, word: way);
    }
  }
  return groupEnd(ws);
}
