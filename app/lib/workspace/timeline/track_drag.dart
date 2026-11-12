// Pointer handling on the track area: hover cursors, clicks, and dragging a bar, a keyframe or a selection box.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout;
import 'package:flutter/services.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// What the pointer is doing on the track area: the bar, the keyframes or the selection box it drags, the clicks it
/// makes, and the cursor that shows what a drag would do.
///
/// It notifies its listeners when what the tracks show changes: the selection box, the snap guide or the cursor.
class TrackDrag extends ChangeNotifier {
  /// Pointer handling over the rows `rows` of the workspace that `workspaceOf` returns, placed by `viewport`.
  ///
  /// `slip` slips a video in its bar. `snapTo` gives the snapping to a set of frames, or null while snapping is off.
  TrackDrag({
    required this._workspaceOf,
    required this._viewport,
    required this._rows,
    required this._slip,
    required this._snapTo,
  });

  final WorkspaceController? Function() _workspaceOf;
  final TimelineViewport _viewport;
  final TimelineRows _rows;
  final SlipEdit _slip;
  final FrameSnap? Function(Set<int> stops) _snapTo;

  /// The workspace the timeline is shown in, read each time it is needed.
  WorkspaceController? get workspace => _workspaceOf();

  // The bar being dragged. Dragging the body slides it, and dragging an end trims it.
  // The timeline only records which part was grabbed and how far the pointer moved.
  // What that does to the layer (its limits, a video's start) is decided by the engine, and the bar is drawn from the engine's answer.
  ({String id, String part, double grab, bool moved})? _bar;
  // The frames the drag can snap to, collected when the drag starts.
  Set<int> _stops = const {};

  /// The frame the drag has snapped to, where a guide line is drawn, or null.
  int? get snappedAt => _restAt;
  int? _restAt;

  // The drag distance [by] adjusted so that the nearest of [ends] lands on a snap stop, if one is close enough.
  // Where it landed is kept in [_restAt].
  int _snapped(int by, List<int> ends) {
    final snapped = _snapTo(_stops)?.snap(by, ends);
    _restAt = snapped?.at;
    return snapped?.by ?? by;
  }

  // The dragged bar's in and out frames when the drag started.
  // A trim stops one frame short of an empty bar, because an empty bar cannot be seen, grabbed again or kept.
  // The project is as long as its longest layer.
  int _barIn = 0, _barOut = 0;

  /// The cursor over the tracks, which shows what a drag would do: an end trims, the body slides, a keyframe slides,
  /// empty space draws a box.
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor = MouseCursor.defer;

  // The keyframe being dragged, together with the other selected keyframes. They slide in time while the playhead shows the position.
  ({List<SelectedKeyframe> keys, int grab, int by})? _slide;
  // How far the slide has been written into the document so far, in frames.
  int _slid = 0;
  // When and where a lane was last clicked, to detect a double-click.
  DateTime? _lanePressed;
  Offset _laneAt = Offset.zero;

  /// The selection box dragged over empty track space, in any direction, or null. Its corners are in track coordinates.
  ///
  /// It selects the keyframes inside it, or else the layers whose bars it touches, like the marquee in Ableton and
  /// After Effects.
  (Offset, Offset)? get selectionBox => _selectionBox;
  (Offset, Offset)? _selectionBox;

  /// The pointer moved to [p] with no button down: shows the cursor for what a drag from there would do.
  void hover(Offset p) {
    final c = cursorAt(p);
    if (c != _cursor) {
      _cursor = c;
      notifyListeners();
    }
  }

  /// A drag starts at [p]: picks up the bar or the keyframe there, or else starts a selection box.
  void down(Offset p) {
    if (!_grab(p)) {
      _selectionBox = (p, p);
      notifyListeners();
    }
  }

  void _boxUp() {
    final b = _selectionBox;
    _selectionBox = null;
    notifyListeners();
    if (b == null) return;
    final ws = workspace!, v = _viewport.view, r = Rect.fromPoints(b.$1, b.$2);
    // A click, not a box: the tap handler has already dealt with it.
    if (r.width < 4 && r.height < 4) return;
    final keys = <SelectedKeyframe>[], things = <String>[];
    for (var i = 0; i < _rows.order.length; i++) {
      // A box does not select points on a lane.
      if (_rows.order[i].value != null) continue;
      final l = ws.layers[_rows.order[i].layer],
          top = i * TimelineMetrics.row - _viewport.verticalScroll;
      if (top + TimelineMetrics.row < r.top ||
          top > r.bottom ||
          RowFlags(ws).isLocked(l.id)) {
        continue;
      }
      for (final k in l.keys) {
        if (v.x(k) >= r.left && v.x(k) <= r.right) {
          keys.add((layer: l.id, frame: k));
        }
      }
      if (v.x(l.outF) >= r.left && v.x(l.inF) <= r.right) things.add(l.id);
    }
    if (keys.isNotEmpty) {
      ws.pickKeys(keys);
    } else if (things.isNotEmpty) {
      ws.clearKeys();
      ws.pickMany(things, inOrder: false);
    }
  }

  /// The pointer moved to [p] during a drag.
  void move(Offset p) {
    if (_selectionBox case (final from, _)?) {
      _selectionBox = (from, p);
      notifyListeners();
      return;
    }
    if (_slide case final s?) {
      final by = _snapped(_viewport.view.frameAt(p.dx).round() - s.grab, [
        s.grab,
      ]);
      _slide = (keys: s.keys, grab: s.grab, by: by);
      // Each step goes into the drag's undo step from where the keyframes now are, so a step skipped on the way
      // loses nothing.
      workspace!.live.move((m) {
        final step = by - _slid;
        final now = [
          for (final k in s.keys) (layer: k.layer, frame: k.frame + _slid),
        ];
        _slid = by;
        return slideWrites(m, now, step);
      });
      notifyListeners();
      workspace!.frame = (s.grab + by).clamp(0, WorkspaceController.duration);
      return;
    }
    final h = _bar, ws = workspace!, m = ws.inside;
    if (h == null || m == null) return;
    // Moves by whole frames.
    var by = (_viewport.view.frameAt(p.dx) - h.grab).round();
    if (h.part == 'slip') {
      _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
      return _slip.slipBy(
        ws,
        int.parse(h.id),
        by,
        barIn: _barIn,
        barOut: _barOut,
      );
    }
    by = _snapped(by, [
      if (h.part != 'tail') _barIn,
      if (h.part != 'head') _barOut,
    ]);
    if (h.part == 'tail') by = math.max(by, _barIn + 1 - _barOut);
    if (h.part == 'head') by = math.min(by, _barOut - 1 - _barIn);
    m.dragUpdate(h.part, by / WorkspaceController.fps);
    _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
    ws.respan(h.id);
  }

  /// The drag ended. With [keep] false it was cancelled, and the engine is told not to keep what it changed.
  void up({bool keep = true}) {
    if (_restAt != null) {
      _restAt = null;
      notifyListeners();
    }
    if (_selectionBox != null) {
      if (keep) return _boxUp();
      _selectionBox = null;
      notifyListeners();
      return;
    }
    if (_slide != null) {
      _slide = null;
      _slid = 0;
      final ws = workspace!;
      keep ? ws.live.done(null, (_) => ws.reread()) : ws.live.cancel();
      return;
    }
    final h = _bar, ws = workspace!, m = ws.inside;
    _bar = null;
    if (h == null || m == null) return;
    // Does not wait for the engine.
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0));
  }

  /// A click on a property lane, at [p].
  ///
  /// - On a keyframe it deletes it, as on Ableton's envelope (Live 12 manual 25.5.2).
  /// - Between two keyframes it selects that span, as Theatre.js does. Live cannot select a span.
  /// - A second click in the same place adds a keyframe there, as a double-click off the line does in Live.
  void tapUp(Offset p) {
    final ws = workspace!,
        m = ws.inside,
        r = _rows.rowAt(p.dy),
        v = _viewport.view;
    if (m == null ||
        r == null ||
        r.value == null ||
        RowFlags(ws).isLocked(r.l.id)) {
      return;
    }
    final t = int.parse(r.l.id),
        name = r.value!,
        row = _rows.laneRow(r.l, name),
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
            _lanePressed != null &&
            now.difference(_lanePressed!) < kDoubleTapTimeout &&
            (p - _laneAt).distance < kDoubleTapSlop;
    _lanePressed = twice ? null : now;
    _laneAt = p;
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

  /// A press on the tracks at [p]: selects the keyframe or the layer there, or clears the selection.
  void tapDown(Offset p) {
    final ws = workspace!, v = _viewport.view;
    final r = _rows.rowAt(p.dy);
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
        _viewport.verticalScroll +
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
    final w = _slip.wholeOf(ws, l);
    final v = _viewport.view;
    return w != null && p.dx >= v.x(w.$1) && p.dx <= v.x(w.$2);
  }

  /// The cursor for the pointer at [p]: what a click or a drag from there would do.
  MouseCursor cursorAt(Offset p) {
    final ws = workspace!, v = _viewport.view, r = _rows.rowAt(p.dy);
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

  bool _grab(Offset p) {
    final ws = workspace!, v = _viewport.view, m = ws.inside;
    final r = _rows.rowAt(p.dy);
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
      _slide = (keys: all, grab: k, by: 0);
      _stops = ws.stops(skip: {l.id})..add(ws.frame);
      return true;
    }
    m.take(int.parse(l.id));
    ws.select(l.id);
    if (ws.playing) ws.playing = false;
    _barIn = l.inF;
    _barOut = l.outF;
    _stops = ws.stops(skip: {l.id, ...ws.many})..add(ws.frame);
    _slip.start(ws, l);
    if (off && (ws.frame < l.inF || ws.frame >= l.outF)) ws.frame = l.inF;
    _bar = (
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
