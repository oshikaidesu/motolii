// The camera on the stage: which layer is the camera, dragging its gizmo (orbit it or resize its frame), and the
// mouse wheel dolly.
import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/stage/stage_view_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

extension StageViewCamera on StageViewState {
  /// The camera the Camera tool acts on: the selected one, else the project's first.
  int? cameraOf(WorkspaceController ws) {
    final m = ws.inside, picked = int.tryParse(widget.selected ?? '');
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
    final ws = WorkspaceScope.read(context), m = ws.inside, cam = cameraOf(ws);
    if (m == null || cam == null) return;
    if (ws.freeEye) {
      // As in After Effects' custom views, the tool moves the view, not the camera layer.
      return ws.setView('stage.eye', [
        ws.eye[0],
        ws.eye[1],
        (ws.eye[2] * math.exp(by * .002)).clamp(.01, 100.0),
      ]);
    }
    if (dollyAt == null) {
      m.take(cam);
      dollyAt =
          m.value(cam, 'distance', ws.frame / WorkspaceController.fps) ?? 1;
    }
    dollyAt = (dollyAt! * math.exp(by * .002)).clamp(.01, 100.0);
    m.dragUpdate('distance', dollyAt!);
    dollyRest?.cancel();
    dollyRest = Timer(const Duration(milliseconds: 300), () {
      dollyAt = null;
      ws.after(m.later('drag_end', number: 1));
    });
  }

  /// Starts a drag on a camera gizmo in the custom view and returns whether one was hit.
  ///
  /// - The camera's position handle orbits it around its point of interest, as in After Effects.
  /// - A corner of the selected camera's frame resizes the frame, which sets the lens.
  /// - The frame itself or the point of interest moves the camera.
  ///
  /// [inside] makes any point in the frame count as a hit, not only its handles.
  bool gizmoDragStart(StageViewport v, Offset local, {required bool inside}) {
    final ws = WorkspaceScope.read(context),
        m = ws.inside!,
        scene = widget.scene,
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
        orbitRate = g[4] == null
            ? .25
            : 180 / math.pi / math.max((g[5]! - g[4]!).distance, 60);
        orbitFrom = (
          x: m.value(cam, 'rotate_x', at) ?? 0,
          y: m.value(cam, 'rotate_y', at) ?? 0,
        );
      } else if (widget.selected == id &&
          frame.any((p) => on(p, 8)) &&
          g[4] != null) {
        by = 'gizmo lens';
        lensFrom = (
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
      drag = (from: local, moved: false, by: by == 'place' ? null : by);
      return true;
    }
    return false;
  }
}
