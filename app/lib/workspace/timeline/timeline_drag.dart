// Pointer handling on the track area: hover cursors, clicks, and picking up a bar or a keyframe.
import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout;
import 'package:flutter/services.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_slip.dart';

extension TimelinePaneDrag on TimelinePaneState {
  // ---------------------------------------------------------------- input

  /// The row at vertical position [y]: its index, its layer, and the property it shows.
  /// The property is null for the layer's own row.
  ({int i, Layer l, String? value})? rowAt(double y) {
    final i = ((y + viewport.verticalScroll) / TimelineMetrics.row).floor();
    if (i < 0 || i >= order.length) return null;
    return (i: i, l: workspace!.layers[order[i].layer], value: order[i].value);
  }

  // A click on a property lane.
  // - On a keyframe it deletes it, as on Ableton's envelope (Live 12 manual 25.5.2).
  // - Between two keyframes it selects that span, as Theatre.js does. Live cannot select a span.
  // - A second click in the same place adds a keyframe there, as a double-click off the line does in Live.
  void laneTap(Offset p) {
    final ws = workspace!, m = ws.inside, r = rowAt(p.dy), v = viewport.view;
    if (m == null ||
        r == null ||
        r.value == null ||
        RowFlags(ws).isLocked(r.l.id)) {
      return;
    }
    final t = int.parse(r.l.id),
        name = r.value!,
        row = laneRow(ws, r.l, name),
        pts = row.lane ?? const [];
    if (pts.isEmpty) return;
    for (final k in m.keyTimes(t, name)) {
      if ((v.x((k * WorkspaceController.fps).round()) - p.dx).abs() <=
          TimelineMetrics.keyPicked + 2) {
        return ws.after(m.later('unkey', layer: t, name: name, number: k));
      }
    }
    final now = DateTime.now(),
        twice =
            lanePressed != null &&
            now.difference(lanePressed!) < kDoubleTapTimeout &&
            (p - laneAt).distance < kDoubleTapSlop;
    lanePressed = twice ? null : now;
    laneAt = p;
    final f = v.frameAt(p.dx);
    if (twice) {
      return ws.after(
        m.later(
          'key_here',
          layer: t,
          name: name,
          number:
              f.round().clamp(0, WorkspaceController.duration) /
              WorkspaceController.fps,
        ),
      );
    }
    final from = pts.where((q) => q.$1 <= f).lastOrNull?.$1,
        inside = from != null && pts.any((q) => q.$1 > f);
    inside ? ws.pickStretch(r.l.id, name, from) : ws.clearKeys();
  }

  void trackDown(Offset p) {
    final ws = workspace!, v = viewport.view;
    final r = rowAt(p.dy);
    if (r == null) {
      // Below the rows nothing is selected, as in After Effects. The inspector then shows the whole project.
      ws.clearKeys();
      ws.select(null);
      return;
    }
    // A lane handles its own click, on pointer up.
    if (r.value != null) return;
    final i = r.i, l = r.l;
    final cy =
        i * TimelineMetrics.row -
        viewport.verticalScroll +
        TimelineMetrics.row / 2;
    if (!RowFlags(ws).isLocked(l.id) &&
        (p.dy - cy).abs() <= TimelineMetrics.bar / 2 + 2) {
      int? best;
      var bd = TimelineMetrics.keyPicked + 2;
      for (final k in l.keys) {
        final d = (v.x(k) - p.dx).abs();
        if (d <= bd) {
          bd = d;
          best = k;
        }
      }
      if (best != null) {
        return ws.pickKey((
          layer: l.id,
          frame: best,
        ), add: HardwareKeyboard.instance.isShiftPressed);
      }
    }
    final f = v.frameAt(p.dx);
    if (f >= l.inF && f <= l.outF) {
      ws.select(l.id);
    } else {
      ws.clearKeys();
    }
  }

  bool _onPale(WorkspaceController ws, Layer l, Offset p) {
    final w = wholeOf(ws, l);
    final v = viewport.view;
    return w != null && p.dx >= v.x(w.$1) && p.dx <= v.x(w.$2);
  }

  MouseCursor cursorAt(Offset p) {
    final ws = workspace!, v = viewport.view, r = rowAt(p.dy);
    if (r == null) return MouseCursor.defer;
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    if (r.value case final n?) {
      // On a lane, a click on a keyframe deletes it.
      final t = int.parse(l.id);
      final at = ws.inside!.keyTimes(t, n),
          f = v.frameAt(p.dx) / WorkspaceController.fps;
      return at.any(
                (k) =>
                    (v.x((k * WorkspaceController.fps).round()) - p.dx).abs() <=
                    TimelineMetrics.keyPicked + 2,
              ) ||
              (at.isNotEmpty && f > at.first && f < at.last)
          ? SystemMouseCursors.click
          : SystemMouseCursors.precise;
    }
    if (RowFlags(ws).isLocked(l.id) || p.dx < a - 6 || p.dx > b + 6) {
      return _onPale(ws, l, p)
          ? SystemMouseCursors.grab
          : SystemMouseCursors.precise;
    }
    if (l.keys.any(
      (k) => (v.x(k) - p.dx).abs() <= TimelineMetrics.keyPicked + 2,
    )) {
      return SystemMouseCursors.click;
    }
    return (p.dx - a).abs() <= 6 || (p.dx - b).abs() <= 6
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.grab;
  }

  bool grab(Offset p) {
    final ws = workspace!, v = viewport.view, m = ws.inside;
    final r = rowAt(p.dy);
    if (m == null || r == null) return false;
    // A lane has nothing to drag and starts no selection box.
    if (r.value != null) return true;
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    final off = p.dx < a - 6 || p.dx > b + 6;
    if (RowFlags(workspace!).isLocked(l.id) || (off && !_onPale(ws, l, p))) {
      return false;
    }
    for (final k in l.keys) {
      if ((v.x(k) - p.dx).abs() > TimelineMetrics.keyPicked + 2) continue;
      final held = (layer: l.id, frame: k),
          all = ws.keys.contains(held) ? ws.keys.toList() : [held];
      if (!ws.keys.contains(held)) ws.pickKey(held);
      if (ws.playing) ws.playing = false;
      slide = (keys: all, grab: k, by: 0);
      stops = ws.stops(skip: {l.id})..add(ws.frame);
      return true;
    }
    m.take(int.parse(l.id));
    ws.select(l.id);
    if (ws.playing) ws.playing = false;
    barIn = l.inF;
    barOut = l.outF;
    stops = ws.stops(skip: {l.id, ...ws.many})..add(ws.frame);
    barWhole = wholeOf(ws, l);
    if (off && (ws.frame < l.inF || ws.frame >= l.outF)) ws.frame = l.inF;
    bar = (
      id: l.id,
      part: off
          ? 'slip'
          : (p.dx - b).abs() <= 6
          ? 'tail'
          : ((p.dx - a).abs() <= 6 ? 'head' : 'bar'),
      grab: v.frameAt(p.dx),
      moved: false,
    );
    return true;
  }
}
