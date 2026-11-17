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
  return _apply(m, moves);
}

Iterable<int> _apply(
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

/// A cached snapshot of which properties and values a set of keyframes carry.
/// Built once at drag start ([prepare]), then [step] writes the moves without touching the engine for reads.
class KeyframeSlide {
  final _entries =
      <
        (int, String, int, double, String)
      >[]; // (layer, prop, frame, value, easing)
  final _layers = <int>{};
  int _slid = 0;

  /// Collects the properties and values of [keys] from the engine once.
  void prepare(Motolii m, Iterable<SelectedKeyframe> keys) {
    _entries.clear();
    _layers.clear();
    _slid = 0;
    for (final k in keys) {
      final t = int.tryParse(k.layer);
      if (t == null) continue;
      _layers.add(t);
      final at = k.frame / WorkspaceController.fps;
      for (final n in m.moving(t)) {
        if (!m
            .keyTimes(t, n)
            .any((s) => (s - at).abs() < .5 / WorkspaceController.fps)) {
          continue;
        }
        _entries.add((
          t,
          n,
          k.frame,
          m.value(t, n, at) ?? 0,
          m.easingOf(t, n, at),
        ));
      }
    }
  }

  /// Writes the unkey/key pairs for a step from the last written position to [by] frames from the original.
  Iterable<int> step(Motolii m, int by) {
    if (by == _slid || _entries.isEmpty) return const [];
    final fps = WorkspaceController.fps, dur = WorkspaceController.duration;
    final moves = <(int, String, double, double, double, String)>[];
    for (final (t, n, frame, v, way) in _entries) {
      final from = (frame + _slid) / fps, to = (frame + by).clamp(0, dur) / fps;
      moves.add((t, n, from, to, v, way));
    }
    _slid = by;
    return _apply(m, moves);
  }

  bool get isEmpty => _entries.isEmpty;
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
