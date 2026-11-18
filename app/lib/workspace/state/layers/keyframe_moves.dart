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

/// Keyframe data cached at drag start so each step only issues writes.
typedef SlideEntry = ({
  int layer,
  int frame,
  List<({String name, double value, String easing})> props,
});

/// Snapshots which properties each selected keyframe carries, their values and
/// easings. Called once at drag start; the returned list drives every step.
List<SlideEntry> cacheSlide(Motolii m, Iterable<SelectedKeyframe> keys) {
  final out = <SlideEntry>[];
  for (final k in keys) {
    final t = int.tryParse(k.layer);
    if (t == null) continue;
    final at = k.frame / WorkspaceController.fps;
    final props = <({String name, double value, String easing})>[];
    for (final n in m.moving(t)) {
      if (!m
          .keyTimes(t, n)
          .any((s) => (s - at).abs() < .5 / WorkspaceController.fps)) {
        continue;
      }
      props.add((
        name: n,
        value: m.value(t, n, at) ?? 0,
        easing: m.easingOf(t, n, at),
      ));
    }
    if (props.isNotEmpty) out.add((layer: t, frame: k.frame, props: props));
  }
  return out;
}

/// Writes the cached keyframes at their new positions. [slid] is how far they
/// have been moved so far; [by] is the new total offset from their original
/// positions. Returns the layers that changed.
Iterable<int> cachedSlideWrites(
  Motolii m,
  List<SlideEntry> cache,
  int slid,
  int by,
) {
  if (by == slid) return const [];
  final dur = WorkspaceController.duration;
  for (final e in cache) {
    final from = (e.frame + slid).clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later('unkey', layer: e.layer, name: p.name, number: from);
    }
  }
  for (final e in cache) {
    final to = (e.frame + by).clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later(
        'key',
        layer: e.layer,
        name: p.name,
        word: '$to',
        number: p.value,
      );
      if (p.easing.isNotEmpty) {
        m.later(
          'easing',
          layer: e.layer,
          name: p.name,
          number: to,
          word: p.easing,
        );
      }
    }
  }
  return {for (final e in cache) e.layer};
}

/// Writes a staggered slide: each keyframe's offset is spread proportionally to
/// its position among the selected set. The first keyframe moves least, the last
/// moves [by] frames. [slid] is a per-entry list of how far each has been moved
/// so far (null on first call, in which case all zeros are assumed).
Iterable<int> staggerSlideWrites(
  Motolii m,
  List<SlideEntry> cache,
  List<int>? slid,
  int by,
) {
  if (cache.length < 2) {
    return cachedSlideWrites(m, cache, slid?.firstOrNull ?? 0, by);
  }
  final dur = WorkspaceController.duration;
  final n = cache.length - 1;
  for (var i = 0; i < cache.length; i++) {
    final e = cache[i], prev = slid?[i] ?? 0;
    final from = (e.frame + prev).clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later('unkey', layer: e.layer, name: p.name, number: from);
    }
  }
  for (var i = 0; i < cache.length; i++) {
    final e = cache[i];
    final offset = (by * i / n).round();
    final to = (e.frame + offset).clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later(
        'key',
        layer: e.layer,
        name: p.name,
        word: '$to',
        number: p.value,
      );
      if (p.easing.isNotEmpty) {
        m.later(
          'easing',
          layer: e.layer,
          name: p.name,
          number: to,
          word: p.easing,
        );
      }
    }
  }
  return {for (final e in cache) e.layer};
}

/// Writes a stretch (proportional scale) of cached keyframes about [anchor].
/// [scale] is the ratio newSpan / originalSpan. [slid] is how far a uniform
/// slide has moved the keyframes so far (0 when only stretching).
Iterable<int> stretchSlideWrites(
  Motolii m,
  List<SlideEntry> cache,
  int anchor,
  double scale,
  int slid,
) {
  final dur = WorkspaceController.duration;
  for (final e in cache) {
    final from = (e.frame + slid).clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later('unkey', layer: e.layer, name: p.name, number: from);
    }
  }
  for (final e in cache) {
    final scaled = anchor + ((e.frame - anchor) * scale).round();
    final to = scaled.clamp(0, dur) / WorkspaceController.fps;
    for (final p in e.props) {
      m.later(
        'key',
        layer: e.layer,
        name: p.name,
        word: '$to',
        number: p.value,
      );
      if (p.easing.isNotEmpty) {
        m.later(
          'easing',
          layer: e.layer,
          name: p.name,
          number: to,
          word: p.easing,
        );
      }
    }
  }
  return {for (final e in cache) e.layer};
}

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
  for (final (t, n, at, _, _, _) in moves) {
    m.later('unkey', layer: t, name: n, number: at); // All are removed first so that a keyframe slid onto another's old time is not lost.
  }
  for (final (t, n, _, to, v, way) in moves) {
    m.later('key', layer: t, name: n, word: '$to', number: v);
    if (way.isNotEmpty) {
      m.later('easing', layer: t, name: n, number: to, word: way);
    }
  }
  return {for (final (t, _, _, _, _, _) in moves) t};
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
