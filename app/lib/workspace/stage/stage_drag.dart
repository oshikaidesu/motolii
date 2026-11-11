// Dragging on the stage: what a press grabs (a layer, a handle, a crop edge), snapping to edges and centres, pulling
// guides out of the rulers, and what is committed when the pointer is released.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/services.dart' show HardwareKeyboard;

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/stage/selection_handles.dart';
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/art_scene.dart';

/// What the pointer holds during a drag on the stage.
///
/// `from` is where the pointer went down and `moved` whether it has moved since. `by` names the handle that was
/// taken (scale, turn, pivot and so on); null means the layer itself, moved as a whole.
typedef StageHold = ({Offset from, bool moved, String? by});

/// The drag in progress on the stage: a layer, one of the selected layer's handles, or a guide.
///
/// The view decides which of its gestures a press begins and calls the matching start method here. Listeners are
/// told when a drag has changed what the stage draws.
class StageDrag extends ChangeNotifier {
  /// The drags of the view [_stage].
  StageDrag(this._stage);

  final StageContext _stage;

  /// What the pointer holds, or null when no layer or handle is being dragged.
  ///
  /// The stage reports only how far the pointer moved, in composition pixels. The engine decides what that means
  /// for the layer (at its own depth) and for the project.
  StageHold? held;

  /// The handle being dragged. Only it is shown, highlighted, until the drag ends.
  String? get heldGrip => _heldGrip;
  String? _heldGrip;

  // Snapping, as in After Effects: the left, middle and right edges (and top, middle, bottom) of the dragged layer stick to
  // the same lines of every other layer not grouped with it, of the canvas, or to a guide, within six screen points.
  // Holds the lines snapped to and the lines met.
  ({Rect box, List<(double, double)> xs, List<(double, double)> ys})? _snapTo;

  /// The snap lines (x, y) the dragged layer sits on now, or null on an axis with none.
  (double?, double?) get met => _met;
  (double?, double?) _met = (null, null);

  // A guide being pulled out of a ruler (the top ruler gives a horizontal line, the left a vertical one) or an existing guide
  // being dragged. Released over the canvas it is saved in the document; released back over its ruler it is deleted.
  ({String axis, double? was})? _pulling;

  /// Whether a guide is being pulled out of a ruler or moved.
  bool get isPullingGuide => _pulling != null;

  /// The axis-aligned rectangle that contains the corners of [b].
  Rect _bounds(ArtBox b) {
    final p = b.corners;
    return p
        .skip(1)
        .fold(
          Rect.fromPoints(p[0], p[0]),
          (r, q) => r.expandToInclude(Rect.fromPoints(q, q)),
        );
  }

  /// Collects the lines that dragging layer [id] snaps to: the canvas, the guides and the other layers' bounds.
  /// Layers in the same parent chain as [id] are left out.
  void _snapFrom(String id) {
    final boxes = _stage.scene.boxes, m = _stage.workspace.inside;
    final grabbed = boxes[id];
    if (!_stage.tool.snap || grabbed == null || m == null) {
      return _snapTo = null;
    }
    final mine = m.outermost(int.parse(id)), c = ArtGeometry.comp;
    final xs = <(double, double)>[(0, c.width)],
        ys = <(double, double)>[(0, c.height)];
    for (final g in _stage.scene.guidesX) {
      xs.add((g, g));
    }
    for (final g in _stage.scene.guidesY) {
      ys.add((g, g));
    }
    for (final MapEntry(:key, :value) in boxes.entries) {
      if (m.outermost(int.parse(key)) == mine) continue;
      final r = _bounds(value);
      xs.add((r.left, r.right));
      ys.add((r.top, r.bottom));
    }
    _snapTo = (box: _bounds(grabbed), xs: xs, ys: ys);
  }

  /// Adjusts the drag offset [by] so the dragged layer's edges or centre land on a snap line within 6 screen pixels.
  /// [s] is the view scale. It also records which lines were met so the painter can draw them.
  Offset _snapped(Offset by, double s) {
    final to = _snapTo;
    if (to == null) return by;
    (double, double?) one(
      double lo,
      double size,
      double d,
      List<(double, double)> lines,
    ) {
      (double, double)? best;
      for (final (a, b) in lines) {
        for (final line in [a, (a + b) / 2, b]) {
          for (final mine in [lo + d, lo + d + size / 2, lo + d + size]) {
            final diff = line - mine;
            if (diff.abs() <= 6 / s &&
                (best == null || diff.abs() < best.$1.abs())) {
              best = (diff, line);
            }
          }
        }
      }
      return best == null ? (d, null) : (d + best.$1, best.$2);
    }

    final (x, mx) = _stage.tool.axis == 2
        ? (by.dx, null)
        : one(to.box.left, to.box.width, by.dx, to.xs);
    final (y, my) = _stage.tool.axis == 1
        ? (by.dy, null)
        : one(to.box.top, to.box.height, by.dy, to.ys);
    _met = (mx, my);
    return Offset(x, y);
  }

  /// Starts pulling a guide, either out of a ruler or by grabbing an existing guide. Returns whether one was taken.
  bool guideDragStart(StageViewport v, Offset local) {
    final ws = _stage.workspace, m = ws.inside;
    if (m == null) return false;
    final at = v.toComposition(local), tol = 4 / v.scale;
    if (local.dy < StageTokens.ruler || local.dx < StageTokens.ruler) {
      _pulling = (axis: local.dy < StageTokens.ruler ? 'y' : 'x', was: null);
      return true;
    }
    for (final (axis, g) in m.guides) {
      if (((axis == 'x' ? at.dx : at.dy) - g).abs() > tol) continue;
      _pulling = (axis: axis, was: g);
      return true;
    }
    return false;
  }

  /// Releases a pulled guide: removes the old one if it was moved, and adds a new one unless it was dropped on the ruler.
  void guideDragEnd(StageViewport v, Offset local) {
    final p = _pulling, ws = _stage.workspace, m = ws.inside;
    _pulling = null;
    if (p == null || m == null) return;
    final over = p.axis == 'y'
            ? local.dy < StageTokens.ruler
            : local.dx < StageTokens.ruler,
        at = v.toComposition(local);
    // Group the guide changes into one undo step.
    m.later('together', number: 1);
    if (p.was != null) {
      m.later('guide', name: p.axis, number: p.was!, word: 'off');
    }
    if (!over) {
      m.later(
        'guide',
        name: p.axis,
        number: ((p.axis == 'x' ? at.dx : at.dy)).roundToDouble(),
      );
    }
    ws.after(m.later('together'));
  }

  /// Gives up the guide being pulled: nothing is added, moved or removed.
  void guideDragCancel() {
    _pulling = null;
  }

  /// Takes hold of a handle of the selected layer, or of one of its path points, near [local].
  ///
  /// Returns whether one was there.
  bool handleDragStart(StageViewport v, Offset local) {
    final ws = _stage.workspace, m = ws.inside;
    // Dragging a handle of the selected layer. The engine works out the change from where the drag started.
    final picked = int.tryParse(_stage.selected ?? '');
    if (m != null && picked != null) {
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
          'round' => 'round',
          'points' => 'points',
          'crop' => key,
          _ => null,
        };
        grip = key;
      }
      for (final p in [
        ...m.points(picked),
        for (final (h, _) in m.handles(picked)) h,
      ]) {
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
        m.take(picked);
        // Canvas coordinates, which is what the engine expects.
        final at = v.toComposition(local);
        m.dragUpdate('grip', at.dx, at.dy);
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

  /// Takes hold of the layer [id] at [local], to move it as a whole, and selects it.
  void layerDragStart(String id, Offset local) {
    final ws = _stage.workspace, m = ws.inside, t = int.tryParse(id);
    if (m == null || t == null) return;
    m.take(t);
    ws.select(id);
    // Grabbing a layer stops playback.
    if (ws.playing) ws.playing = false;
    held = (from: local, moved: false, by: null);
    _snapFrom(id);
  }

  /// Carries the drag on to [local]: tells the engine how far the pointer has gone, or where the handle is now.
  void dragUpdate(StageViewport v, Offset local) {
    final h = held, ws = _stage.workspace, m = ws.inside;
    if (h == null || m == null) return;
    final all = (local - h.from) / v.scale; // Screen pixels to canvas points.
    if (h.by case final way? when way.startsWith('crop ')) {
      // Move the side in as far as the pointer goes inward from the cut edge, leaving at least some of the image.
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
        m.dragUpdate(
          cropSides[side],
          (crop[side] + inBy).clamp(0.0, .95 - crop[(side + 2) % 4]),
        );
      }
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    if (h.by case final way? when way == 'round' || way == 'points') {
      // Shape handles: corner radius or number of points follows the pointer.
      final c = [
            for (var i = 0; i < 4; i++)
              _stage.handles['corner $i'] ?? Offset.zero,
          ],
          g = gripOf(c),
          t = int.tryParse(_stage.selected ?? '');
      if (way == 'round') m.dragUpdate('round', g.roundOf(local));
      if (way == 'points' && t != null) {
        m.dragUpdate(
          'points',
          ((m.value(t, 'points', 0) ?? 5) +
                  (((local - h.from).dx * g.u.dx +
                              (local - h.from).dy * g.u.dy) /
                          24)
                      .round())
              .clamp(3, 64)
              .toDouble(),
        );
      }
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    if (h.by case final way?) {
      var gone = v.toComposition(local) - v.toComposition(h.from);
      // As in Figma: a corner handle resizes freely in both directions with the opposite side fixed; a side handle resizes that
      // way only. Shift keeps the aspect ratio or rotates in 15 degree steps; Alt scales from the centre.
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
      m.dragUpdate(
        '$even${sized ? (keys.isAltPressed ? 'scale' : 'side') : way}',
        gone.dx,
        gone.dy,
      );
      held = (from: h.from, moved: true, by: way);
      notifyListeners();
      return;
    }
    // The Move tool. Shift locks to horizontal or vertical, whichever the pointer has gone further, as in Illustrator and Figma.
    final axis =
        _stage.tool.axis == 0 && HardwareKeyboard.instance.isShiftPressed
        ? (all.dx.abs() >= all.dy.abs() ? 1 : 2)
        : _stage.tool.axis;
    final by = _snapped(switch (axis) {
      1 => Offset(all.dx, 0),
      2 => Offset(0, all.dy),
      _ => all,
    }, v.scale);
    m.dragUpdate('place', by.dx, by.dy);
    held = (from: h.from, moved: true, by: null);
    notifyListeners();
  }

  /// Ends the current drag. With [keep] false, or when nothing moved, the engine discards the change.
  void dragEnd({bool keep = true}) {
    final h = held,
        ws = _stage.workspace,
        m = ws.inside,
        free = h?.by == 'orbit' && ws.freeEye;
    held = null;
    _snapTo = null;
    if (_heldGrip != null) {
      _heldGrip = null;
      notifyListeners();
    }
    if (_met != (null, null)) {
      _met = (null, null);
      notifyListeners();
    }
    if (h == null || m == null || free) return;
    // Queue the release without waiting, then reread the project once the engine has applied it.
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0));
  }

  /// The readout for the value a drag is changing, as the stage shows it now: position, size, rotation or anchor point.
  /// [by] is the drag kind. Distances are in canvas pixels and angles in degrees, clockwise as seen.
  String? heldSays(String? by) {
    final m = _stage.workspace.inside, t = int.tryParse(_stage.selected ?? '');
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
