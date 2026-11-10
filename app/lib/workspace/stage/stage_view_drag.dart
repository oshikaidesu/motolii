// Dragging on the stage: what a press grabs (a layer, a handle, a crop edge), snapping to edges and centres, pulling
// guides out of the rulers, and what is committed when the pointer is released.
//
// setState is called from an extension on the State itself, which the analyzer allows only in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show MotoliiDocument, MotoliiMoment, MotoliiWrites;
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/stage/stage_view_camera.dart';
import 'package:motolii/workspace/stage/stage_view_state.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

extension StageViewDrag on StageViewState {
  /// The axis-aligned rectangle that contains the corners of [b].
  Rect _bounds(ArtBox b) {
    final p = b.corners;
    return p.skip(1).fold(Rect.fromPoints(p[0], p[0]), (r, q) => r.expandToInclude(Rect.fromPoints(q, q)));
  }

  /// Collects the lines that dragging layer [id] snaps to: the canvas, the guides and the other layers' bounds.
  /// Layers in the same parent chain as [id] are left out.
  void _snapFrom(String id) {
    final boxes = widget.scene.boxes, m = WsScope.read(context).inside;
    final held = boxes[id];
    if (!widget.snap || held == null || m == null) return snapTo = null;
    int top(int t) {
      for (var p = (m.value(t, 'parent', 0) ?? 0).round(), n = 0; p > 0 && n < 64; p = (m.value(t, 'parent', 0) ?? 0).round(), n++) {
        t = p;
      }
      return t;
    }

    final mine = top(int.parse(id)), c = WsArt.comp;
    final xs = <(double, double)>[(0, c.width)], ys = <(double, double)>[(0, c.height)];
    for (final g in widget.scene.guidesX) {
      xs.add((g, g));
    }
    for (final g in widget.scene.guidesY) {
      ys.add((g, g));
    }
    for (final MapEntry(:key, :value) in boxes.entries) {
      if (top(int.parse(key)) == mine) continue;
      final r = _bounds(value);
      xs.add((r.left, r.right));
      ys.add((r.top, r.bottom));
    }
    snapTo = (box: _bounds(held), xs: xs, ys: ys);
  }

  /// Adjusts the drag offset [by] so the dragged layer's edges or centre land on a snap line within 6 screen pixels.
  /// [s] is the view scale. It also records which lines were met so the painter can draw them.
  Offset snapped(Offset by, double s) {
    final to = snapTo;
    if (to == null) return by;
    (double, double?) one(double lo, double size, double d, List<(double, double)> lines) {
      (double, double)? best;
      for (final (a, b) in lines) {
        for (final line in [a, (a + b) / 2, b]) {
          for (final mine in [lo + d, lo + d + size / 2, lo + d + size]) {
            final diff = line - mine;
            if (diff.abs() <= 6 / s && (best == null || diff.abs() < best.$1.abs())) best = (diff, line);
          }
        }
      }
      return best == null ? (d, null) : (d + best.$1, best.$2);
    }

    final (x, mx) = widget.axis == 2 ? (by.dx, null) : one(to.box.left, to.box.width, by.dx, to.xs);
    final (y, my) = widget.axis == 1 ? (by.dy, null) : one(to.box.top, to.box.height, by.dy, to.ys);
    met = (mx, my);
    return Offset(x, y);
  }

  /// Starts pulling a guide, either out of a ruler or by grabbing an existing guide. Returns whether one was taken.
  bool _pull(StageViewport v, Offset local) {
    final ws = WsScope.read(context), m = ws.inside;
    if (m == null) return false;
    final at = v.toComp(local), tol = 4 / v.s;
    if (local.dy < StageTokens.ruler || local.dx < StageTokens.ruler) {
      pulling = (axis: local.dy < StageTokens.ruler ? 'y' : 'x', was: null);
      return true;
    }
    for (final (axis, g) in m.guides) {
      if (((axis == 'x' ? at.dx : at.dy) - g).abs() > tol) continue;
      pulling = (axis: axis, was: g);
      return true;
    }
    return false;
  }

  /// Releases a pulled guide: removes the old one if it was moved, and adds a new one unless it was dropped on the ruler.
  void pullDragEnd(StageViewport v, Offset local) {
    final p = pulling, ws = WsScope.read(context), m = ws.inside;
    pulling = null;
    if (p == null || m == null) return;
    final over = p.axis == 'y' ? local.dy < StageTokens.ruler : local.dx < StageTokens.ruler, at = v.toComp(local);
    // Group the guide changes into one undo step.
    m.later('together', number: 1);
    if (p.was != null) m.later('guide', name: p.axis, number: p.was!, word: 'off');
    if (!over) m.later('guide', name: p.axis, number: ((p.axis == 'x' ? at.dx : at.dy)).roundToDouble());
    ws.after(m.later('together'));
  }

  /// Decides what a drag starting at [local] grabs, in order: the active tool's action, a handle of the selected layer,
  /// a camera gizmo, a guide, a layer, and otherwise a lasso.
  void dragStart(StageViewport v, Offset local) {
    if (widget.make == 'camera') {
      // As with After Effects' Unified Camera tool, dragging orbits the camera around its point of interest.
      final ws = WsScope.read(context), m = ws.inside, cam = cameraOf(ws);
      if (m == null || cam == null) {
        ws.notice = 'No camera: add one from Create › Layers';
        return;
      }
      if (ws.freeEye) {
        orbitFrom = (x: ws.eye[1], y: ws.eye[0]);
        drag = (from: local, moved: false, by: 'orbit');
        return;
      }
      final at = ws.frame / Ws.fps;
      m.take(cam);
      if (ws.playing) ws.playing = false;
      orbitFrom = (x: m.value(cam, 'rotate_x', at) ?? 0, y: m.value(cam, 'rotate_y', at) ?? 0);
      drag = (from: local, moved: false, by: 'orbit');
      return;
    }
    if (widget.make == 'brush') {
      setState(() => brush = [local]);
      return;
    }
    if (widget.make != null) {
      if (widget.make == 'pen') penWay = [local];
      setState(() => drawFrom = local);
      return;
    }
    final ws = WsScope.read(context), m = ws.inside;
    // Dragging a handle of the selected layer. The engine works out the change from where the drag started.
    final picked = int.tryParse(widget.selected ?? '');
    if (m != null && picked != null) {
      String? by, grip;
      var near = 8.0;
      for (final MapEntry(:key, :value) in handles.entries) {
        final d = (value - local).distance;
        if (d > near) continue;
        near = d;
        by = switch (key.split(' ').first) {
          'corner' => 'scale',
          'side' => 'edge',
          'turn' => 'turn',
          'anchor' => 'pivot',
          'round' => 'round',
          'points' => 'points',
          'crop' => key,
          _ => null,
        };
        grip = key;
      }
      for (final p in [...m.points(picked), for (final (h, _) in m.handles(picked)) h]) {
        // A path point (moved with its handles) or a bezier handle alone. The engine picks the nearest one.
        final d = (v.toScreen(p) - local).distance;
        if (d > near) continue;
        near = d;
        by = 'point';
        grip = null;
      }
      // Just outside a corner, the drag rotates. Figma does this when hovering just outside a layer's bounds.
      // The zone is a square 2 × 1.62 × 4.5 px out from each corner, as in tldraw's rotate corners
      // (SelectionForegroundOverlayUtil.ts).
      for (var i = 0; by == null && handles.containsKey('turn') && i < 4; i++) {
        final (c, a, b) = (handles['corner $i'], handles['corner ${(i + 1) % 4}'], handles['corner ${(i + 3) % 4}']);
        if (c == null || a == null || b == null || (c - a).distance < 1 || (c - b).distance < 1) continue;
        final p = local - c, u = (c - a) / (c - a).distance, w = (c - b) / (c - b).distance, s = p.dx * u.dx + p.dy * u.dy, r = p.dx * w.dx + p.dy * w.dy;
        if (s >= 0 && r >= 0 && s <= 14.58 && r <= 14.58) (by, grip) = ('turn', 'turn');
      }
      if (by != null) {
        m.take(picked);
        // Canvas coordinates, which is what the engine expects.
        final at = v.toComp(local);
        m.dragUpdate('grip', at.dx, at.dy);
        if (ws.playing) ws.playing = false;
        drag = (from: local, moved: false, by: by);
        if (grip != heldGrip) setState(() => heldGrip = grip);
        return;
      }
    }
    if (m != null && gizmoDragStart(v, local, inside: false)) return;
    // Guides come after the handles, which lie over everything else.
    if (_pull(v, local)) return;
    final id = m == null ? null : hitLocal(v, local), t = int.tryParse(id ?? '');
    // Layers are tested first, then the camera frames they lie in.
    if (m != null && t == null && gizmoDragStart(v, local, inside: true)) return;
    if (m != null && t == null) {
      // Nothing under the pointer: draw a lasso.
      ws.select(null);
      setState(() => lasso = [local]);
      return;
    }
    if (m == null || t == null) return;
    m.take(t);
    ws.select(id);
    // Grabbing a layer stops playback.
    if (ws.playing) ws.playing = false;
    drag = (from: local, moved: false, by: null);
    _snapFrom(id!);
  }

  /// Ends the current drag. With [keep] false, or when nothing moved, the engine discards the change.
  void dragEnd({bool keep = true}) {
    final h = drag, ws = WsScope.read(context), m = ws.inside, free = h?.by == 'orbit' && ws.freeEye;
    drag = null;
    orbitFrom = null;
    lensFrom = null;
    snapTo = null;
    if (heldGrip != null) setState(() => heldGrip = null);
    if (met != (null, null)) setState(() => met = (null, null));
    if (h == null || m == null || free) return;
    // Queue the release without waiting, then reread the project once the engine has applied it.
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0));
  }

  /// The id of the selected layer's parent, or null if it has none.
  String? parentOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    final p = m == null || t == null ? 0 : (m.value(t, 'parent', 0) ?? 0).round();
    return p > 0 ? '$p' : null;
  }

  /// The readout for the value a drag is changing, as the stage shows it now: position, size, rotation or anchor point.
  /// [by] is the drag kind. Distances are in canvas pixels and angles in degrees, clockwise as seen.
  String? heldSays(String? by) {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    final f = m == null || t == null ? null : m.bounds(t);
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
