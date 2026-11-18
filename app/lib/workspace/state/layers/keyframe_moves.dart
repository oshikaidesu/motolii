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
/// With [property], only that property is cached (lane stretch drag).
List<SlideEntry> cacheSlide(
  Motolii m,
  Iterable<SelectedKeyframe> keys, {
  String? property,
}) {
  final out = <SlideEntry>[];
  for (final k in keys) {
    final t = k.layer;
    final at = k.frame / WorkspaceController.fps;
    final props = <({String name, double value, String easing})>[];
    final names = property != null ? [property] : m.moving(t);
    for (final n in names) {
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

/// Packs a list of (from, to) moves into the tab-delimited format that the
/// engine's "slide_keys" call reads, and sends it in one FFI call.
Iterable<int> _slideKeysPacked(
  Motolii m,
  List<SlideEntry> cache,
  List<double> fromTimes,
  List<double> toTimes,
) {
  final buf = StringBuffer();
  var i = 0;
  for (final e in cache) {
    for (final p in e.props) {
      buf.write(
        '${e.layer}\t${p.name}\t${fromTimes[i]}\t${toTimes[i]}\t${p.value}',
      );
      if (p.easing.isNotEmpty) buf.write('\t${p.easing}');
      buf.writeln();
    }
    i++;
  }
  m.later('slide_keys', word: buf.toString());
  return {for (final e in cache) e.layer};
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
  final dur = WorkspaceController.duration, fps = WorkspaceController.fps;
  return _slideKeysPacked(
    m,
    cache,
    [for (final e in cache) (e.frame + slid).clamp(0, dur) / fps],
    [for (final e in cache) (e.frame + by).clamp(0, dur) / fps],
  );
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
  final dur = WorkspaceController.duration, fps = WorkspaceController.fps;
  final n = cache.length - 1;
  return _slideKeysPacked(
    m,
    cache,
    [
      for (var i = 0; i < cache.length; i++)
        (cache[i].frame + (slid?[i] ?? 0)).clamp(0, dur) / fps,
    ],
    [
      for (var i = 0; i < cache.length; i++)
        (cache[i].frame + (by * i / n).round()).clamp(0, dur) / fps,
    ],
  );
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
  final dur = WorkspaceController.duration, fps = WorkspaceController.fps;
  return _slideKeysPacked(
    m,
    cache,
    [for (final e in cache) (e.frame + slid).clamp(0, dur) / fps],
    [
      for (final e in cache)
        (anchor + ((e.frame - anchor) * scale).round()).clamp(0, dur) / fps,
    ],
  );
}

/// The writes that slide [keys] by [by] frames, for [WorkspaceController.live] to apply at each step of a drag.
LiveWrites slideWritesOf(Iterable<SelectedKeyframe> keys, int by) =>
    (m) => slideWrites(m, keys, by);

/// Writes the move of [slideWritesOf] and returns the layers it changed.
/// Uses the engine's slide_keys batch call: one FFI crossing for all entries.
Iterable<int> slideWrites(Motolii m, Iterable<SelectedKeyframe> keys, int by) {
  if (by == 0) return const [];
  final buf = StringBuffer();
  final layers = <int>{};
  final fps = WorkspaceController.fps, dur = WorkspaceController.duration;
  for (final k in keys) {
    final t = k.layer;
    final at = k.frame / fps;
    final to = (k.frame + by).clamp(0, dur) / fps;
    for (final n in m.moving(t)) {
      if (!m.keyTimes(t, n).any((s) => (s - at).abs() < .5 / fps)) continue;
      buf.write('$t\t$n\t$at\t$to\t${m.value(t, n, at) ?? 0}');
      final way = m.easingOf(t, n, at);
      if (way.isNotEmpty) buf.write('\t$way');
      buf.writeln();
      layers.add(t);
    }
  }
  if (layers.isEmpty) return const [];
  m.later('slide_keys', word: buf.toString());
  return layers;
}

/// Queues the removal of the keyframes [keys], and of the other properties'
/// keyframes at the same times, in one FFI call. The undo step is begun and
/// ended by the caller (see [groupBegin] and [groupEnd]).
/// Removes the keyframes at both ends of each stretch, for that property only.
void unkeyStretches(WorkspaceController ws, Iterable<StretchPicked> stretches) {
  final m = ws.inside!;
  final buf = StringBuffer();
  final fps = WorkspaceController.fps;
  for (final s in stretches) {
    buf.writeln('${s.layer}\t${s.name}\t${s.from / fps}');
    buf.writeln('${s.layer}\t${s.name}\t${s.to / fps}');
  }
  if (buf.isNotEmpty) m.later('unkey_batch', word: buf.toString());
}

void unkeyAtKeyframes(WorkspaceController ws, Iterable<SelectedKeyframe> keys) {
  final m = ws.inside!;
  final buf = StringBuffer();
  final fps = WorkspaceController.fps;
  for (final k in keys) {
    final t = k.layer;
    final at = k.frame / fps;
    for (final n in m.moving(t)) {
      if (m.keyTimes(t, n).any((s) => (s - at).abs() < .5 / fps)) {
        buf.writeln('$t\t$n\t$at');
      }
    }
  }
  if (buf.isNotEmpty) m.later('unkey_batch', word: buf.toString());
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
      for (final n in m.moving(k.layer))
        if (m
            .keyTimes(k.layer, n)
            .any(
              (s) =>
                  (s - k.frame / WorkspaceController.fps).abs() <
                  .5 / WorkspaceController.fps,
            ))
          (
            n,
            k.frame - first,
            m.value(k.layer, n, k.frame / WorkspaceController.fps) ?? 0,
            m.easingOf(k.layer, n, k.frame / WorkspaceController.fps),
          ),
  ];
}

/// Queues [copies] on layer [t], the first at the playhead, in one FFI call.
/// Returns the ticket that closes the undo step.
int pasteKeyframeCopies(
  WorkspaceController ws,
  int t,
  List<(String, int, double, String)> copies,
) {
  final m = ws.inside!;
  groupBegin(ws);
  final buf = StringBuffer();
  final fps = WorkspaceController.fps;
  for (final (n, after, v, way) in copies) {
    final at = (ws.frame + after) / fps;
    buf.write('$t\t$n\t$at\t$v');
    if (way.isNotEmpty) buf.write('\t$way');
    buf.writeln();
  }
  if (buf.isNotEmpty) m.later('paste_keys', word: buf.toString());
  return groupEnd(ws);
}
