// Pointer handling on the track area: hover cursors, clicks, and dragging a bar, a keyframe or a selection box.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout;
import 'package:flutter/services.dart';

import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/edits/make_relation.dart' show clickLayer;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/keyframe_moves.dart'
    show SlideEntry, cachedSlideWrites, staggerSlideWrites, stretchSlideWrites;
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// Pointer handling on the track area: bar/keyframe drags, selection box, snap guides.
class TrackDrag extends ChangeNotifier {
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
  final FrameSnap? Function(List<SnapTarget> targets) _snapTo;

  WorkspaceController? get workspace => _workspaceOf();

  // Bar drag. The engine decides what a move does; the timeline only records grab point and delta.
  ({int id, String part, double grab, bool moved})? _bar;
  // The typed snap targets, collected when the drag starts.
  List<SnapTarget> _targets = const [];

  /// Current snap target (for guide line + indicator), or null.
  SnapTarget? get snappedAt => _restAt;
  SnapTarget? _restAt;

  int _snapped(int by, List<int> ends) {
    final snapped = _snapTo(_targets)?.snap(by, ends);
    _restAt = snapped?.caught;
    return snapped?.by ?? by;
  }

  // Bar's in/out at drag start. A trim stops 1 frame short so the bar never vanishes.
  int _barIn = 0, _barOut = 0;

  /// Cursor reflecting what a drag from here would do.
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor = MouseCursor.defer;

  // Keyframe slide.
  ({List<SelectedKeyframe> keys, int grab, int by})? _slide;
  // Cached at drag start so each step only issues writes.
  List<SlideEntry> _slideCache = const [];
  // Stagger mode offsets, or null.
  List<int>? _staggerSlid;
  // Frames written so far in the current slide.
  int _slid = 0;
  // Stretch-handle drag: scales keyframes proportionally about an anchor.
  ({int anchor, int from, int to, double grab})? _stretch;

  /// Stretch handles when ≥2 keyframes are selected, or null.
  (int, int)? get stretchHandles {
    final ws = workspace;
    if (ws == null || ws.keys.length < 2) return null;
    int lo = WorkspaceController.duration, hi = 0;
    for (final k in ws.keys) {
      if (k.frame < lo) lo = k.frame;
      if (k.frame > hi) hi = k.frame;
    }
    return lo < hi ? (lo, hi) : null;
  }

  // Double-click detection.
  DateTime? _lanePressed;
  Offset _laneAt = Offset.zero;

  /// Selection box in track coordinates, or null. Selects keyframes inside, or bars it touches.
  (Offset, Offset)? get selectionBox => _selectionBox;
  (Offset, Offset)? _selectionBox;

  /// Hover: update cursor.
  void hover(Offset p) {
    final c = cursorAt(p);
    if (c != _cursor) {
      _cursor = c;
      notifyListeners();
    }
  }

  static const _edgeMargin = 40.0;
  static const _edgeSpeed = 8.0;

  void _edgeScroll(double x) {
    final w = _viewport.trackWidth;
    if (x < _edgeMargin) {
      _viewport.scrollBy(-_edgeSpeed * (1 - x / _edgeMargin));
    } else if (x > w - _edgeMargin) {
      _viewport.scrollBy(_edgeSpeed * (1 - (w - x) / _edgeMargin));
    }
  }

  /// Drag start: bar, keyframe, or selection box.
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
    final keys = <SelectedKeyframe>[], things = <int>[];
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

  /// Drag update.
  void move(Offset p) {
    _edgeScroll(p.dx);
    if (_selectionBox case (final from, _)?) {
      _selectionBox = (from, p);
      notifyListeners();
      return;
    }
    if (_stretch case final st?) {
      final f = _viewport.view.frameAt(p.dx).round();
      final ws = workspace!;
      final span = st.to - st.from;
      if (span <= 0) return;
      ws.live.move((m) {
        final newEdge = f.clamp(0, WorkspaceController.duration);
        final newSpan = (newEdge - st.anchor).abs().clamp(
          1,
          WorkspaceController.duration,
        );
        final scale = newSpan / span;
        final changed = stretchSlideWrites(
          m,
          _slideCache,
          st.anchor,
          scale,
          _slid,
        );
        _slid = 0;
        return changed;
      }, keysOnly: true);
      notifyListeners();
      return;
    }
    if (_slide case final s?) {
      final by = _snapped(_viewport.view.frameAt(p.dx).round() - s.grab, [
        s.grab,
      ]);
      _slide = (keys: s.keys, grab: s.grab, by: by);
      final ws = workspace!;
      final stagger =
          HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isAltPressed;
      ws.live.move((m) {
        final Iterable<int> changed;
        if (stagger && _slideCache.length >= 2) {
          changed = staggerSlideWrites(m, _slideCache, _staggerSlid, by);
          _staggerSlid = [
            for (var i = 0; i < _slideCache.length; i++)
              (by * i / (_slideCache.length - 1)).round(),
          ];
        } else {
          changed = cachedSlideWrites(m, _slideCache, _slid, by);
          _staggerSlid = null;
        }
        _slid = by;
        return changed;
      }, keysOnly: true);
      notifyListeners();
      return;
    }
    final h = _bar, ws = workspace!;
    if (h == null || !timeline_service.isConnected(ws)) return;
    // Whole-frame steps.
    var by = (_viewport.view.frameAt(p.dx) - h.grab).round();
    if (h.part == 'slip') {
      _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
      return _slip.slipBy(ws, h.id, by, barIn: _barIn, barOut: _barOut);
    }
    by = _snapped(by, [
      if (h.part != 'tail') _barIn,
      if (h.part != 'head') _barOut,
    ]);
    if (h.part == 'tail') by = math.max(by, _barIn + 1 - _barOut);
    if (h.part == 'head') by = math.min(by, _barOut - 1 - _barIn);
    timeline_service.dragBarPart(ws, h.part, by / WorkspaceController.fps);
    _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
    ws.respan(h.id);
  }

  /// Drag end. [keep] false = cancelled; the engine discards the change.
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
    if (_stretch != null) {
      _stretch = null;
      _slideCache = const [];
      _slid = 0;
      final ws = workspace!;
      keep ? ws.live.done(null, (_) => ws.reread()) : ws.live.cancel();
      return;
    }
    if (_slide != null) {
      _slide = null;
      _slideCache = const [];
      _staggerSlid = null;
      _slid = 0;
      final ws = workspace!;
      keep ? ws.live.done(null, (_) => ws.reread()) : ws.live.cancel();
      return;
    }
    final h = _bar, ws = workspace!;
    _bar = null;
    if (h == null || !timeline_service.isConnected(ws)) return;
    ws.live.letGo(keep: keep && h.moved);
  }

  /// Click on a property lane: select keyframe, select span between two, or double-click to add.
  void tapUp(Offset p) {
    final ws = workspace!, r = _rows.rowAt(p.dy), v = _viewport.view;
    if (!timeline_service.isConnected(ws) ||
        r == null ||
        r.value == null ||
        RowFlags(ws).isLocked(r.l.id)) {
      return;
    }
    final name = r.value!,
        row = _rows.laneRow(r.l, name),
        pts = row.lane ?? const [];
    if (pts.isEmpty) return;
    // Closest keyframe within the hit radius.
    final lane = r.l.lanes.where((a) => a.name == name).firstOrNull;
    int? pickFrame;
    double pickDx = TimelineMetrics.keyPicked + 2;
    if (lane != null) {
      for (final k in lane.at) {
        final frame = (k * WorkspaceController.fps).round();
        final dx = (v.x(frame) - p.dx).abs();
        if (dx <= pickDx) {
          pickDx = dx;
          pickFrame = frame;
        }
      }
    }
    if (pickFrame case final frame?) {
      ws.pickKeys([(layer: r.l.id, frame: frame)]);
      return;
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
        timeline_service.addKeyframe(
          ws,
          r.l.id,
          name,
          f.round().clamp(0, WorkspaceController.duration) /
              WorkspaceController.fps,
        ),
      );
    }
    final from = pts.where((q) => q.$1 <= f).lastOrNull?.$1,
        between = from != null && pts.any((q) => q.$1 > f);
    if (between) {
      final add =
          HardwareKeyboard.instance.isShiftPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      ws.pickStretch(r.l.id, name, from, add: add);
    } else {
      ws.clearKeys();
    }
  }

  /// Press: select keyframe or layer, or clear.
  void tapDown(Offset p) {
    final ws = workspace!, v = _viewport.view;
    final r = _rows.rowAt(p.dy);
    if (r == null) {
      // Below the rows: clear selection (inspector shows the project).
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
        // Cmd/Shift toggles (picks.dart).
        final SelectedKeyframe key = (layer: l.id, frame: best);
        final k = clickKeys();
        return k.add || k.span
            ? ws.pickKeys(
                pickOnClick<SelectedKeyframe>(
                  now: ws.keys,
                  lead: null,
                  id: key,
                  add: true,
                ).picked,
              )
            : ws.pickKey(key);
      }
    }
    final f = v.frameAt(p.dx);
    if (f >= l.inF && f <= l.outF) {
      clickLayer(ws, l.id, order: [for (final k in ws.layers) k.id]);
    } else {
      ws.clearKeys();
    }
  }

  bool _onPale(WorkspaceController ws, Layer l, Offset p) {
    final w = _slip.wholeOf(ws, l);
    final v = _viewport.view;
    return w != null && p.dx >= v.x(w.$1) && p.dx <= v.x(w.$2);
  }

  /// Cursor for the pointer at [p].
  MouseCursor cursorAt(Offset p) {
    final ws = workspace!, v = _viewport.view;
    if (stretchHandles case (final lo, final hi)?) {
      final lx = v.x(lo), hx = v.x(hi);
      if ((p.dx - lx).abs() <= 6 || (p.dx - hx).abs() <= 6) {
        return SystemMouseCursors.resizeLeftRight;
      }
    }
    final r = _rows.rowAt(p.dy);
    if (r == null) return MouseCursor.defer;
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    if (r.value case final n?) {
      final at = timeline_service.keyframeTimes(ws, l.id, n),
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
    final ws = workspace!, v = _viewport.view;
    final r = _rows.rowAt(p.dy);
    if (!timeline_service.isConnected(ws) || r == null) return false;
    // Stretch handles: near the left/right ends of a multi-key selection.
    if (stretchHandles case (final lo, final hi)?) {
      final lx = v.x(lo), hx = v.x(hi);
      if ((p.dx - lx).abs() <= 6) {
        _stretch = (anchor: hi, from: lo, to: hi, grab: v.frameAt(p.dx));
        _slideCache = timeline_service.cacheSelectedSlide(ws, ws.keys.toList());
        _targets = ws.snapTargets(skip: {for (final k in ws.keys) k.layer});
        if (ws.playing) ws.playing = false;
        return true;
      }
      if ((p.dx - hx).abs() <= 6) {
        _stretch = (anchor: lo, from: lo, to: hi, grab: v.frameAt(p.dx));
        _slideCache = timeline_service.cacheSelectedSlide(ws, ws.keys.toList());
        _targets = ws.snapTargets(skip: {for (final k in ws.keys) k.layer});
        if (ws.playing) ws.playing = false;
        return true;
      }
    }
    // Lane keyframes can be dragged in time.
    if (r.value != null) {
      final name = r.value!;
      if (RowFlags(ws).isLocked(r.l.id)) return true;
      final lane = r.l.lanes.where((a) => a.name == name).firstOrNull;
      int? pickFrame;
      double pickDx = TimelineMetrics.keyPicked + 2;
      if (lane != null) {
        for (final k in lane.at) {
          final frame = (k * WorkspaceController.fps).round();
          final dx = (v.x(frame) - p.dx).abs();
          if (dx <= pickDx) {
            pickDx = dx;
            pickFrame = frame;
          }
        }
      }
      if (pickFrame case final frame?) {
        final held = (layer: r.l.id, frame: frame),
            all = ws.keys.contains(held) ? ws.keys.toList() : [held];
        if (!ws.keys.contains(held)) ws.pickKey(held);
        if (ws.playing) ws.playing = false;
        _slide = (keys: all, grab: frame, by: 0);
        _slideCache = timeline_service.cacheSelectedSlide(ws, all);
        _targets = ws.snapTargets(skip: {r.l.id});
        return true;
      }
      // Inside a selected stretch: slide both boundary keyframes together.
      if (ws.stretches
              .where((s) => s.layer == r.l.id && s.name == name)
              .firstOrNull
          case final s?) {
        final f = v.frameAt(p.dx);
        if (f >= s.from && f <= s.to) {
          final both = [
            (layer: r.l.id, frame: s.from),
            (layer: r.l.id, frame: s.to),
          ];
          if (ws.playing) ws.playing = false;
          _slide = (keys: both, grab: f.round(), by: 0);
          _slideCache = timeline_service.cacheSelectedSlide(ws, both);
          _targets = ws.snapTargets(skip: {r.l.id});
          return true;
        }
      }
      return true;
    }
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    final off = p.dx < a - 6 || p.dx > b + 6;
    if (RowFlags(workspace!).isLocked(l.id) || (off && !_onPale(ws, l, p))) {
      return false;
    }
    // Closest key within hit radius (not first-wins, which grabs wrong at dense zoom).
    int? pickK;
    double pickDx = TimelineMetrics.keyPicked + 2;
    for (final k in l.keys) {
      final dx = (v.x(k) - p.dx).abs();
      if (dx <= pickDx) {
        pickDx = dx;
        pickK = k;
      }
    }
    if (pickK case final k?) {
      final held = (layer: l.id, frame: k),
          all = ws.keys.contains(held) ? ws.keys.toList() : [held];
      if (!ws.keys.contains(held)) ws.pickKey(held);
      if (ws.playing) ws.playing = false;
      _slide = (keys: all, grab: k, by: 0);
      _slideCache = timeline_service.cacheSelectedSlide(ws, all);
      _targets = ws.snapTargets(skip: {l.id});
      return true;
    }
    ws.live.hold(l.id);
    ws.select(l.id);
    if (ws.playing) ws.playing = false;
    _barIn = l.inF;
    _barOut = l.outF;
    _targets = ws.snapTargets(skip: {l.id, ...ws.many});
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
