// The camera on the stage: which layer is the camera, the Camera tool's drag (orbit), dragging a camera's gizmo (orbit
// it, resize its frame or move it), and the mouse wheel dolly.
import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:ui' show Offset, Path;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The gestures that move a camera on the stage: the Camera tool's drag, a drag on a camera's gizmo, and the wheel.
///
/// A camera drag is a drag on the stage like any other, so it is begun and carried on through the [StageDrag] given
/// here. Listeners are told when a drag has changed what the stage draws.
class CameraGestures extends ChangeNotifier {
  /// The camera gestures of the view [_stage], whose drags are held in [_drag].
  CameraGestures(this._stage, this._drag);

  final StageContext _stage;
  final StageDrag _drag;

  ({double x, double y})?
  _orbitFrom; // The camera's rotation when the drag started.
  double? _dollyAt; // Its distance while the wheel turns.
  Timer? _dollyRest;

  double _orbitRate = .25; // Degrees of rotation per pixel dragged.
  ({double zoom, double reach, Offset middle})?
  _lensFrom; // The frame's zoom, reach and centre when the drag started.

  /// The camera the Camera tool acts on: the selected one, else the project's first.
  int? _cameraOf(WorkspaceController ws) {
    final m = ws.inside, picked = int.tryParse(_stage.selected ?? '');
    if (m == null) return null;
    if (picked != null && m.word(picked, 'kind') == 'camera') return picked;
    for (final l in ws.layers) {
      if (int.tryParse(l.id) case final t? when m.word(t, 'kind') == 'camera') {
        return t;
      }
    }
    return null;
  }

  /// Moves the camera nearer to or further from its point of interest, like the wheel of After Effects' Unified Camera
  /// tool. All wheel turns until the wheel rests for 300 ms form one undo step.
  void dolly(double by) {
    final ws = _stage.workspace, m = ws.inside, cam = _cameraOf(ws);
    if (m == null || cam == null) return;
    if (ws.freeEye) {
      // As in After Effects' custom views, the tool moves the view, not the camera layer.
      return ws.setView('stage.eye', [
        ws.eye[0],
        ws.eye[1],
        (ws.eye[2] * math.exp(by * .002)).clamp(.01, 100.0),
      ]);
    }
    if (_dollyAt == null) {
      m.take(cam);
      _dollyAt =
          m.value(cam, 'distance', ws.frame / WorkspaceController.fps) ?? 1;
    }
    _dollyAt = (_dollyAt! * math.exp(by * .002)).clamp(.01, 100.0);
    m.dragUpdate('distance', _dollyAt!);
    _dollyRest?.cancel();
    _dollyRest = Timer(const Duration(milliseconds: 300), () {
      _dollyAt = null;
      ws.after(m.later('drag_end', number: 1));
    });
  }

  /// Starts the Camera tool's drag at [local], which orbits the camera around its point of interest.
  ///
  /// With no camera in the project, nothing is held and a notice says so.
  void orbitDragStart(Offset local) {
    // As with After Effects' Unified Camera tool, dragging orbits the camera around its point of interest.
    final ws = _stage.workspace, m = ws.inside, cam = _cameraOf(ws);
    if (m == null || cam == null) {
      ws.notice = 'No camera: add one from Create › Layers';
      return;
    }
    if (ws.freeEye) {
      _orbitFrom = (x: ws.eye[1], y: ws.eye[0]);
      _drag.held = (from: local, moved: false, by: 'orbit');
      return;
    }
    final at = ws.frame / WorkspaceController.fps;
    m.take(cam);
    if (ws.playing) ws.playing = false;
    _orbitFrom = (
      x: m.value(cam, 'rotate_x', at) ?? 0,
      y: m.value(cam, 'rotate_y', at) ?? 0,
    );
    _drag.held = (from: local, moved: false, by: 'orbit');
  }

  /// Starts a drag on a camera gizmo in the custom view and returns whether one was hit.
  ///
  /// - The camera's position handle orbits it around its point of interest, as in After Effects.
  /// - A corner of the selected camera's frame resizes the frame, which sets the lens.
  /// - The frame itself or the point of interest moves the camera.
  ///
  /// [inside] makes any point in the frame count as a hit, not only its handles.
  bool gizmoDragStart(StageViewport v, Offset local, {required bool inside}) {
    final ws = _stage.workspace,
        m = ws.inside!,
        scene = _stage.scene,
        at = ws.frame / WorkspaceController.fps;
    for (final id in scene.gizmos.keys) {
      final g = [
            for (final p in scene.gizmo(id)) p == null ? null : v.toScreen(p),
          ],
          cam = int.parse(id);
      if (g.length < 6) continue;
      final frame = [g[0], g[1], g[2], g[3]].nonNulls.toList();
      bool on(Offset? p, double reach) =>
          p != null && (p - local).distance <= reach;
      final String by;
      if (on(g[5], 10)) {
        by = 'gizmo orbit';
        // Degrees per pixel, so the camera turns as far as the pointer travels on the circle it orbits.
        _orbitRate = g[4] == null
            ? .25
            : 180 / math.pi / math.max((g[5]! - g[4]!).distance, 60);
        _orbitFrom = (
          x: m.value(cam, 'rotate_x', at) ?? 0,
          y: m.value(cam, 'rotate_y', at) ?? 0,
        );
      } else if (_stage.selected == id &&
          frame.any((p) => on(p, 8)) &&
          g[4] != null) {
        by = 'gizmo lens';
        _lensFrom = (
          zoom: m.value(cam, 'zoom', at) ?? 1,
          reach: (local - g[4]!).distance,
          middle: g[4]!,
        );
      } else if (on(g[4], 10) ||
          (inside &&
              frame.length == 4 &&
              (Path()..addPolygon(frame, true)).contains(local))) {
        by = 'place';
      } else {
        continue;
      }
      m.take(cam);
      ws.select(id);
      if (ws.playing) ws.playing = false;
      _drag.held = (from: local, moved: false, by: by == 'place' ? null : by);
      return true;
    }
    return false;
  }

  /// Carries a camera drag on to [local].
  ///
  /// Returns false, having done nothing, when the drag in progress is not an orbit or a gizmo's.
  bool dragUpdate(Offset local) {
    final h = _drag.held, ws = _stage.workspace, m = ws.inside;
    if (h == null || m == null) return false;
    if (h.by == 'gizmo orbit' && _orbitFrom != null) {
      final d = (local - h.from) * _orbitRate, o = _orbitFrom!;
      m.dragUpdate('rotate_y', o.y + d.dx);
      m.dragUpdate('rotate_x', (o.x + d.dy).clamp(-89.0, 89.0));
      _drag.held = (from: h.from, moved: true, by: h.by);
      return true;
    }
    if (h.by == 'gizmo lens' && _lensFrom != null) {
      // Compare the pointer's distance from the centre with where the drag began: further out is a larger frame, a wider lens.
      final l = _lensFrom!;
      m.dragUpdate(
        'zoom',
        (l.zoom * l.reach / math.max((local - l.middle).distance, 1)).clamp(
          .01,
          100.0,
        ),
      );
      _drag.held = (from: h.from, moved: true, by: h.by);
      return true;
    }
    if (h.by == 'orbit' && _orbitFrom != null) {
      // Sideways rotates around the layer, up and down rotates over it: a quarter of a degree per pixel.
      final d = local - h.from, o = _orbitFrom!;
      if (ws.freeEye) {
        ws.setView('stage.eye', [
          o.y - d.dx * .25,
          (o.x - d.dy * .25).clamp(-89.0, 89.0),
          ws.eye[2],
        ]);
        return true;
      }
      m.dragUpdate('rotate_y', o.y - d.dx * .25);
      m.dragUpdate('rotate_x', (o.x - d.dy * .25).clamp(-89.0, 89.0));
      _drag.held = (from: h.from, moved: true, by: 'orbit');
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Forgets where the camera stood when the drag began, once the drag is over.
  void dragEnd() {
    _orbitFrom = null;
    _lensFrom = null;
  }

  @override
  void dispose() {
    _dollyRest?.cancel();
    super.dispose();
  }
}
