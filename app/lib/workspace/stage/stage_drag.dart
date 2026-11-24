// Dragging on the stage: layer/handle/crop grabs, edge snapping, and guides.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/services.dart' show HardwareKeyboard;

import 'package:motolii/widgets/gestures.dart';
import 'package:motolii/workspace/stage/selection_handles.dart';
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';

/// `by`: the handle name, or null for a whole-layer move.
typedef StageHold = ({Offset from, bool moved, String? by});

/// An equal-spacing smart guide between two neighboring bounds along one axis.
typedef SnapGap = ({
  bool horizontal,
  double from,
  double to,
  double at,
  double size,
});

class StageDrag extends ChangeNotifier {
  StageDrag(this._stage);

  final StageContext _stage;

  StageHold? held;

  String? get heldGrip => _heldGrip;
  String? _heldGrip;

  // Edges/centre and equal-spacing targets collected on drag start so holding ⌘
  // mid-drag activates snapping immediately.
  ({
    Rect box,
    List<(double, double)> xs,
    List<(double, double)> ys,
    List<Rect> others,
  })?
  _snapTo;

  (double?, double?) get met => _met;
  (double?, double?) _met = (null, null);

  List<SnapGap> get gaps => _gaps;
  List<SnapGap> _gaps = const [];

  // A guide pulled from a ruler or dragged. Released over its ruler → deleted.
  ({String axis, double? was})? _pulling;

  bool get isPullingGuide => _pulling != null;

  Rect _bounds(ArtBox b) {
    final p = b.corners;
    return p
        .skip(1)
        .fold(
          Rect.fromPoints(p[0], p[0]),
          (r, q) => r.expandToInclude(Rect.fromPoints(q, q)),
        );
  }

  /// Collects snap targets. Layers in the same parent chain are excluded.
  void _snapFrom(int id) {
    final boxes = _stage.scene.boxes, ws = _stage.workspace;
    final grabbed = boxes[id];
    if (grabbed == null || !stageConnected(ws)) {
      return _snapTo = null;
    }
    final mine = stageOutermost(ws, id), c = ArtGeometry.comp;
    final xs = <(double, double)>[(0, c.width)],
        ys = <(double, double)>[(0, c.height)];
    final others = <Rect>[];
    for (final g in _stage.scene.guidesX) {
      xs.add((g, g));
    }
    for (final g in _stage.scene.guidesY) {
      ys.add((g, g));
    }
    for (final MapEntry(:key, :value) in boxes.entries) {
      if (stageOutermost(ws, key) == mine) continue;
      final r = _bounds(value);
      others.add(r);
      xs.add((r.left, r.right));
      ys.add((r.top, r.bottom));
    }
    _snapTo = (box: _bounds(grabbed), xs: xs, ys: ys, others: others);
  }

  /// Snaps [by] to edges/centres and equal-spacing gaps when magnet is active
  /// (⌘+drag by default; ⌘ temporarily inverts when Snap option is toggled on).
  Offset _snapped(Offset by, double s) {
    final to = _snapTo;
    final keys = HardwareKeyboard.instance;
    final cmd = keys.isMetaPressed || keys.isControlPressed;
    final active = _stage.tool.snap ? !cmd : cmd;
    if (to == null || !active) {
      _met = (null, null);
      _gaps = const [];
      return by;
    }
    final tol = Gestures.snapStage / s;

    (double, double?, List<SnapGap>) snapAxis({
      required bool horizontal,
      required double d,
      required Rect moved,
      required List<(double, double)> lines,
    }) {
      final lo = horizontal ? to.box.left : to.box.top;
      final size = horizontal ? to.box.width : to.box.height;
      double? bestDiff;
      double? bestLine;
      List<SnapGap> bestGaps = const [];

      for (final (a, b) in lines) {
        for (final line in [a, (a + b) / 2, b]) {
          for (final mine in [lo + d, lo + d + size / 2, lo + d + size]) {
            final diff = line - mine;
            if (diff.abs() <= tol &&
                (bestDiff == null || diff.abs() < bestDiff.abs())) {
              bestDiff = diff;
              bestLine = line;
              bestGaps = const [];
            }
          }
        }
      }

      // Equal-spacing (distribution) smart guides along this axis, filtering
      // peers that overlap along the perpendicular band (or all if none do).
      double pLo(Rect r) => horizontal ? r.top : r.left;
      double pHi(Rect r) => horizontal ? r.bottom : r.right;
      double aLo(Rect r) => horizontal ? r.left : r.top;
      double aHi(Rect r) => horizontal ? r.right : r.bottom;
      bool overlapsPerp(Rect a, Rect b) =>
          math.min(pHi(a), pHi(b)) - math.max(pLo(a), pLo(b)) > -24.0;
      double midPerp(Rect a, Rect b) {
        final o0 = math.max(pLo(a), pLo(b));
        final o1 = math.min(pHi(a), pHi(b));
        return o1 >= o0
            ? (o0 + o1) / 2
            : (pLo(a) + pHi(a) + pLo(b) + pHi(b)) / 4;
      }

      final peers = [
        for (final r in to.others)
          if (overlapsPerp(r, moved)) r,
      ]..sort((a, b) => aLo(a).compareTo(aLo(b)));

      if (peers.length >= 2) {
        final mLo = lo + d, mHi = lo + d + size;
        // 1. Center between two neighboring peers (equal left & right gaps).
        for (var i = 0; i + 1 < peers.length; i++) {
          final a = peers[i], b = peers[i + 1];
          final span = aLo(b) - aHi(a);
          if (span < size + 2) continue;
          if (mLo < aHi(a) - tol || mHi > aLo(b) + tol) continue;
          final gap = (span - size) / 2;
          final targetLo = aHi(a) + gap;
          final diff = targetLo - mLo;
          if (diff.abs() <= tol &&
              (bestDiff == null || diff.abs() < bestDiff.abs())) {
            final snappedRect = horizontal
                ? Rect.fromLTWH(targetLo, moved.top, size, moved.height)
                : Rect.fromLTWH(moved.left, targetLo, moved.width, size);
            bestDiff = diff;
            bestLine = null;
            bestGaps = [
              (
                horizontal: horizontal,
                from: aHi(a),
                to: targetLo,
                at: midPerp(a, snappedRect),
                size: gap,
              ),
              (
                horizontal: horizontal,
                from: targetLo + size,
                to: aLo(b),
                at: midPerp(snappedRect, b),
                size: gap,
              ),
            ];
          }
        }
        // 2. Duplicate an existing gap between an adjacent peer pair (A, B).
        for (var i = 0; i + 1 < peers.length; i++) {
          final a = peers[i], b = peers[i + 1];
          final gap = aLo(b) - aHi(a);
          if (gap <= 1) continue;
          // Place dragged object immediately after B by `gap`.
          final afterLo = aHi(b) + gap;
          final afterDiff = afterLo - mLo;
          if (afterDiff.abs() <= tol &&
              (bestDiff == null || afterDiff.abs() < bestDiff.abs())) {
            final snappedRect = horizontal
                ? Rect.fromLTWH(afterLo, moved.top, size, moved.height)
                : Rect.fromLTWH(moved.left, afterLo, moved.width, size);
            bestDiff = afterDiff;
            bestLine = null;
            bestGaps = [
              (
                horizontal: horizontal,
                from: aHi(a),
                to: aLo(b),
                at: midPerp(a, b),
                size: gap,
              ),
              (
                horizontal: horizontal,
                from: aHi(b),
                to: afterLo,
                at: midPerp(b, snappedRect),
                size: gap,
              ),
            ];
          }
          // Place dragged object immediately before A by `gap`.
          final beforeLo = aLo(a) - gap - size;
          final beforeDiff = beforeLo - mLo;
          if (beforeDiff.abs() <= tol &&
              (bestDiff == null || beforeDiff.abs() < bestDiff.abs())) {
            final snappedRect = horizontal
                ? Rect.fromLTWH(beforeLo, moved.top, size, moved.height)
                : Rect.fromLTWH(moved.left, beforeLo, moved.width, size);
            bestDiff = beforeDiff;
            bestLine = null;
            bestGaps = [
              (
                horizontal: horizontal,
                from: beforeLo + size,
                to: aLo(a),
                at: midPerp(snappedRect, a),
                size: gap,
              ),
              (
                horizontal: horizontal,
                from: aHi(a),
                to: aLo(b),
                at: midPerp(a, b),
                size: gap,
              ),
            ];
          }
        }
      }

      return bestDiff == null
          ? (d, null, const [])
          : (d + bestDiff, bestLine, bestGaps);
    }

    final moved = to.box.shift(by);
    final (x, mx, gx) = _stage.tool.axis == 2
        ? (by.dx, null, const <SnapGap>[])
        : snapAxis(horizontal: true, d: by.dx, moved: moved, lines: to.xs);
    final movedX = to.box.shift(Offset(x, by.dy));
    final (y, my, gy) = _stage.tool.axis == 1
        ? (by.dy, null, const <SnapGap>[])
        : snapAxis(horizontal: false, d: by.dy, moved: movedX, lines: to.ys);
    _met = (mx, my);
    _gaps = [...gx, ...gy];
    return Offset(x, y);
  }

  /// Starts pulling a guide from a ruler or grabbing an existing one.
  bool guideDragStart(StageViewport v, Offset local) {
    final ws = _stage.workspace;
    if (!stageConnected(ws)) return false;
    final at = v.toComposition(local), tol = 4 / v.scale;
    if (local.dy < StageTokens.ruler || local.dx < StageTokens.ruler) {
      _pulling = (axis: local.dy < StageTokens.ruler ? 'y' : 'x', was: null);
      return true;
    }
    for (final (axis, g) in stageGuides(ws)) {
      if (((axis == 'x' ? at.dx : at.dy) - g).abs() > tol) continue;
      _pulling = (axis: axis, was: g);
      return true;
    }
    return false;
  }

  /// Releases a guide. Dropped on the ruler → deleted; on the canvas → saved.
  void guideDragEnd(StageViewport v, Offset local) {
    final p = _pulling, ws = _stage.workspace;
    _pulling = null;
    if (p == null || !stageConnected(ws)) return;
    final over = p.axis == 'y'
            ? local.dy < StageTokens.ruler
            : local.dx < StageTokens.ruler,
        at = v.toComposition(local);
    // Group the guide changes into one undo step.
    stageBeginUndoStep(ws);
    if (p.was != null) {
      stageGuide(ws, axis: p.axis, number: p.was!, word: 'off');
    }
    if (!over) {
      stageGuide(
        ws,
        axis: p.axis,
        number: ((p.axis == 'x' ? at.dx : at.dy)).roundToDouble(),
      );
    }
    ws.after(stageEndUndoStep(ws));
  }

  void guideDragCancel() {
    _pulling = null;
  }

  /// Grabs a handle or path point near [local]. Returns whether one was found.
  bool handleDragStart(StageViewport v, Offset local) {
    final ws = _stage.workspace;
    final picked = _stage.selected;
    if (stageConnected(ws) && picked != null) {
      String? by, grip;
      var near = 8.0;
      for (final MapEntry(:key, :value) in _stage.handles.entries) {
        final d = (value - local).distance;
        if (d > near) continue;
        near = d;
        by = switch (key.split(' ').first) {
          'corner' => 'scale',
          'side' => 'edge',
          'turn' => 'turn',
          'anchor' => 'pivot',
          'crop' => key,
          _ => null,
        };
        grip = key;
      }
      for (final p in [
        ...stagePathPoints(ws, picked),
        for (final (h, _) in stagePathHandles(ws, picked)) h,
      ]) {
        final d = (v.toScreen(p) - local).distance;
        if (d > near) continue;
        near = d;
        by = 'point';
        grip = null;
      }
      // Just outside a corner the drag rotates (14.58 px zone).
      for (
        var i = 0;
        by == null && _stage.handles.containsKey('turn') && i < 4;
        i++
      ) {
        final (c, a, b) = (
          _stage.handles['corner $i'],
          _stage.handles['corner ${(i + 1) % 4}'],
          _stage.handles['corner ${(i + 3) % 4}'],
        );
        if (c == null ||
            a == null ||
            b == null ||
            (c - a).distance < 1 ||
            (c - b).distance < 1) {
          continue;
        }
        final p = local - c,
            u = (c - a) / (c - a).distance,
            w = (c - b) / (c - b).distance,
            s = p.dx * u.dx + p.dy * u.dy,
            r = p.dx * w.dx + p.dy * w.dy;
        if (s >= 0 && r >= 0 && s <= 14.58 && r <= 14.58) {
          (by, grip) = ('turn', 'turn');
        }
      }
      if (by != null) {
        ws.live.hold(picked);
        // Canvas coordinates, which is what the engine expects.
        final at = v.toComposition(local);
        stageUpdateDrag(ws, 'grip', at.dx, at.dy);
        if (ws.playing) ws.playing = false;
        held = (from: local, moved: false, by: by);
        if (grip != _heldGrip) {
          _heldGrip = grip;
          notifyListeners();
        }
        return true;
      }
    }
    return false;
  }

  /// Grabs the whole layer and selects it.
  void layerDragStart(int id, Offset local) {
    final ws = _stage.workspace;
    if (!stageConnected(ws)) return;
    ws.live.hold(id);
    ws.select(id);
    if (ws.playing) ws.playing = false;
    held = (from: local, moved: false, by: null);
    _snapFrom(id);
  }

  void dragUpdate(StageViewport v, Offset local) {
    final h = held, ws = _stage.workspace;
    if (h == null || !stageConnected(ws)) return;
    final all = (local - h.from) / v.scale; // Screen pixels to canvas points.
    if (h.by case final way? when way.startsWith('crop c')) {
      // A crop corner moves its two sides at once.
      final corner =
              int.parse(
                way.substring(6),
              ), // 0..3: top-left, top-right, bottom-right, bottom-left
          c = [
            for (var i = 0; i < 4; i++)
              _stage.handles['corner $i'] ?? Offset.zero,
          ],
          crop = _stage.crop;
      if (crop.length == 4) {
        final w = c[1] - c[0],
            hgt = c[3] - c[0],
            wlen = math.max(1.0, w.distance),
            hlen = math.max(1.0, hgt.distance),
            wdir = w / wlen,
            hdir = hgt / hlen,
            at = _stage.handles[way] ?? h.from,
            overW =
                ((local - at).dx * wdir.dx + (local - at).dy * wdir.dy) / wlen,
            overH =
                ((local - at).dx * hdir.dx + (local - at).dy * hdir.dy) / hlen,
            leftSide = corner == 0 || corner == 3,
            topSide = corner == 0 || corner == 1,
            hIdx = leftSide ? 0 : 2,
            vIdx = topSide ? 1 : 3;
        stageUpdateDrag(
          ws,
          cropSides[hIdx],
          (crop[hIdx] + (leftSide ? overW : -overW)).clamp(
            0.0,
            .95 - crop[(hIdx + 2) % 4],
          ),
        );
        stageUpdateDrag(
          ws,
          cropSides[vIdx],
          (crop[vIdx] + (topSide ? overH : -overH)).clamp(
            0.0,
            .95 - crop[(vIdx + 2) % 4],
          ),
        );
      }
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    if (h.by case final way? when way.startsWith('crop ')) {
      final side = int.parse(way.substring(5)),
          c = [
            for (var i = 0; i < 4; i++)
              _stage.handles['corner $i'] ?? Offset.zero,
          ],
          crop = _stage.crop;
      final across = side.isEven ? c[1] - c[0] : c[3] - c[0],
          len = math.max(1.0, across.distance),
          dir = across / len * (side < 2 ? 1.0 : -1.0);
      final at = _stage.handles[way] ?? h.from,
          inBy = ((local - at).dx * dir.dx + (local - at).dy * dir.dy) / len;
      if (crop.length == 4) {
        stageUpdateDrag(
          ws,
          cropSides[side],
          (crop[side] + inBy).clamp(0.0, .95 - crop[(side + 2) % 4]),
        );
      }
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    if (h.by case final way?) {
      var gone = v.toComposition(local) - v.toComposition(h.from);
      // Corner: free resize from opposite side. Side: one axis. Shift: constrain. Alt: from centre.
      final keys = HardwareKeyboard.instance,
          sized = way == 'scale' || way == 'edge',
          even = keys.isShiftPressed && (sized || way == 'turn') ? 'even_' : '';
      if (_heldGrip case final g? when way == 'edge') {
        final at = _stage.handles[g],
            across =
                _stage.handles['side ${(int.parse(g.substring(5)) + 2) % 4}'];
        if (at != null && across != null && (at - across).distance > 1) {
          final n = (at - across) / (at - across).distance;
          gone = n * (gone.dx * n.dx + gone.dy * n.dy);
        }
      }
      stageUpdateDrag(
        ws,
        '$even${sized ? (keys.isAltPressed ? 'scale' : 'side') : way}',
        gone.dx,
        gone.dy,
      );
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    // Shift locks to the axis the pointer has gone further along.
    final axis =
        _stage.tool.axis == 0 && HardwareKeyboard.instance.isShiftPressed
        ? (all.dx.abs() >= all.dy.abs() ? 1 : 2)
        : _stage.tool.axis;
    final by = _snapped(switch (axis) {
      1 => Offset(all.dx, 0),
      2 => Offset(0, all.dy),
      _ => all,
    }, v.scale);
    stageUpdateDrag(ws, 'place', by.dx, by.dy);
    held = (from: h.from, moved: true, by: null);
    notifyListeners();
  }

  /// Ends the drag. With [keep] false or nothing moved, the change is discarded.
  void dragEnd({bool keep = true}) {
    final h = held,
        ws = _stage.workspace,
        free = h?.by == 'orbit' && ws.freeEye;
    held = null;
    _snapTo = null;
    if (_heldGrip != null) {
      _heldGrip = null;
      notifyListeners();
    }
    if (_met != (null, null) || _gaps.isNotEmpty) {
      _met = (null, null);
      _gaps = const [];
      notifyListeners();
    }
    if (h == null || !stageConnected(ws) || free) return;
    ws.live.letGo(keep: keep && h.moved);
  }

  /// Readout for the current drag: position, size, rotation or anchor.
  String? heldSays(String? by) {
    final ws = _stage.workspace, t = _stage.selected;
    final f = t == null ? null : stageBounds(ws, t);
    if (f == null) return null;
    return switch (by) {
      null => '${f[0].round()}, ${f[1].round()}',
      'scale' => '${f[2].round()} × ${f[3].round()}',
      'turn' => '${(f[4] % 360).round()}°',
      'pivot' => '${f[5].round()}, ${f[6].round()}',
      _ => null,
    };
  }
}
