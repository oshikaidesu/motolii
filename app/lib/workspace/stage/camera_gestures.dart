// The camera on the stage: Boxcam frame gizmo (pan, resize distance, roll),
// Camera tool drag (orbit / Shift-pan), Match View angle alignment, Z-target lock-on/release, and wheel dolly.
import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:ui' show Offset, Path;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/services.dart' show HardwareKeyboard;

import 'package:motolii/widgets/gestures.dart';
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Creates and selects a camera layer immediately when none exists yet.
void ensureCameraLayer(WorkspaceController ws) {
  if (!stageConnected(ws) || ws.hasCamera) return;
  stageBeginUndoStep(ws);
  var made = 0;
  ws.after(
    stageAddLayer(ws, name: 'camera', word: 'camera'),
    null,
    (t) => made = t,
  );
  ws.after(stageEndUndoStep(ws), (done, _) {
    if (done && made > 0) ws.select(made);
  });
}

/// Roll handle position extending from the top midpoint of a 4-corner camera frame.
Offset? cameraFrameRollKnob(List<Offset> frame) {
  if (frame.length != 4) return null;
  final topMid = (frame[0] + frame[1]) * .5;
  final botMid = (frame[3] + frame[2]) * .5;
  final up = topMid - botMid;
  final len = up.distance;
  if (len < 12) return null;
  return topMid + (up / len) * 20;
}

/// The layer ID camera [cam] is currently locked onto, or null when free.
int? cameraTargetOf(WorkspaceController ws, int cam) {
  if (!stageConnected(ws)) return null;
  final at = ws.frame / WorkspaceController.fps;
  final id = (stageValue(ws, cam, 'target', at) ?? 0).round();
  return id > 0 ? id : null;
}

/// Locks camera [cam] onto [targetId] (Z-target), resetting frame offset so the subject sits centered.
void cameraLockTarget(WorkspaceController ws, int cam, int targetId) {
  if (!stageConnected(ws) || cam == targetId) return;
  stageBeginUndoStep(ws);
  stageSetValue(ws, layer: cam, name: 'target', number: targetId.toDouble());
  stageSetValue(ws, layer: cam, name: 'x', number: 0);
  stageSetValue(ws, layer: cam, name: 'y', number: 0);
  stageSetValue(ws, layer: cam, name: 'z', number: 0);
  ws.after(stageEndUndoStep(ws));
}

/// Releases Z-target on [cam] without jumping by baking the target's current position into the camera frame.
void cameraReleaseTarget(WorkspaceController ws, int cam) {
  if (!stageConnected(ws)) return;
  final targetId = cameraTargetOf(ws, cam);
  if (targetId == null) return;
  final at = ws.frame / WorkspaceController.fps;
  final tx = stageValue(ws, targetId, 'x', at) ?? 0;
  final ty = stageValue(ws, targetId, 'y', at) ?? 0;
  final tz = stageValue(ws, targetId, 'z', at) ?? 0;
  final cx = stageValue(ws, cam, 'x', at) ?? 0;
  final cy = stageValue(ws, cam, 'y', at) ?? 0;
  final cz = stageValue(ws, cam, 'z', at) ?? 0;
  stageBeginUndoStep(ws);
  stageSetValue(ws, layer: cam, name: 'x', number: tx + cx);
  stageSetValue(ws, layer: cam, name: 'y', number: ty + cy);
  stageSetValue(ws, layer: cam, name: 'z', number: tz + cz);
  stageSetValue(ws, layer: cam, name: 'target', number: 0);
  ws.after(stageEndUndoStep(ws));
}

/// Resets 3D look-in tilt/pan back to flat 0°/0° (pure Boxcam view).
void cameraResetTilt(WorkspaceController ws, int cam) {
  if (!stageConnected(ws)) return;
  stageBeginUndoStep(ws);
  stageSetValue(ws, layer: cam, name: 'rotate_x', number: 0);
  stageSetValue(ws, layer: cam, name: 'rotate_y', number: 0);
  ws.after(stageEndUndoStep(ws));
}

/// Aligns camera [cam]'s look-in angle (`rotate_y`, `rotate_x`) to face the current
/// 3D View angle squarely, keeping frame size and position/Z-target intact, and
/// records keyframes at the playhead (preserving the initial value at t=0 if unkeyed).
void cameraAlignToView(WorkspaceController ws, int cam) {
  if (!stageConnected(ws) || !ws.freeEye) return;
  final yaw = ws.eye[0];
  final pitch = ws.eye[1].clamp(-89.0, 89.0);
  final now = ws.frame / WorkspaceController.fps;
  stageBeginUndoStep(ws);
  for (final (prop, target) in [('rotate_y', yaw), ('rotate_x', pitch)]) {
    // `doc_key` drops a static t=0 value on first keyframe at t>0, so anchor t=0 first.
    if (now > 0 && stageKeyTimes(ws, cam, prop).isEmpty) {
      stageKeyValue(
        ws,
        layer: cam,
        name: prop,
        seconds: 0,
        number: stageValue(ws, cam, prop, 0) ?? 0,
      );
    }
    stageKeyValue(ws, layer: cam, name: prop, seconds: now, number: target);
  }
  ws.after(stageEndUndoStep(ws));
  ws.notice = 'Aligned frame to view (${yaw.round()}°, ${pitch.round()}°)';
}

/// The gestures that move a camera on the stage: the Camera tool's drag, a drag on a camera's gizmo, and the wheel.
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

  ({double distance, double reach, Offset middle})? _frameFrom; // Boxcam frame distance, reach and centre when corner resize started.
  ({double rotate, double angle, Offset middle})?
  _rollFrom; // Boxcam frame roll angle and centre when roll knob drag started.

  /// The camera the Camera tool acts on: the selected one, else the project's first.
  int? _cameraOf(WorkspaceController ws) =>
      stageCameraLayer(ws, _stage.selected);

  /// Click on a layer while using the Camera tool: locks onto it (Z-target), or releases if already locked onto it.
  void tapLayer(int? hitId) {
    final ws = _stage.workspace, cam = _cameraOf(ws);
    if (cam == null) {
      ws.notice = 'No camera: add one from Create › Layers';
      return;
    }
    if (hitId == null || hitId == cam) return;
    if (cameraTargetOf(ws, cam) == hitId) {
      cameraReleaseTarget(ws, cam);
      ws.notice = 'Camera target released';
    } else {
      cameraLockTarget(ws, cam, hitId);
      final name = ws.layers.where((l) => l.id == hitId).firstOrNull?.name;
      if (name != null) ws.notice = 'Camera locked on $name';
    }
  }

  /// Releases the active camera's target when Escape is pressed. Returns true if a target was released.
  bool releaseIfLocked() {
    final ws = _stage.workspace, cam = _cameraOf(ws);
    if (cam == null || cameraTargetOf(ws, cam) == null) return false;
    cameraReleaseTarget(ws, cam);
    ws.notice = 'Camera target released';
    return true;
  }

  /// Moves the camera nearer to or further from its frame centre by a multiplicative
  /// pinch [ratio] (> 1 zooms in / decreases distance, < 1 zooms out).
  void dollyPinch(double ratio) {
    if (ratio <= 0 || (ratio - 1).abs() < 1e-4) return;
    dolly(-math.log(ratio) / .002);
  }

  /// Moves the camera nearer to or further from its frame centre (Boxcam zoom / dolly).
  /// All wheel turns until the wheel rests for 300 ms form one undo step.
  void dolly(double by) {
    final ws = _stage.workspace, cam = _cameraOf(ws);
    if (cam == null) return;
    if (ws.freeEye) {
      // In overview mode, the wheel dollies the overview eye, not the camera layer.
      return ws.setView('stage.eye', [
        ws.eye[0],
        ws.eye[1],
        (ws.eye[2] * math.exp(by * .002)).clamp(.05, 100.0),
      ]);
    }
    if (_dollyAt == null) {
      ws.live.hold(cam);
      _dollyAt =
          stageValue(ws, cam, 'distance', ws.frame / WorkspaceController.fps) ??
          1;
    }
    _dollyAt = (_dollyAt! * math.exp(by * .002)).clamp(.05, 100.0);
    stageUpdateDrag(ws, 'distance', _dollyAt!);
    _dollyRest?.cancel();
    _dollyRest = Timer(Gestures.burstRest, () {
      _dollyAt = null;
      ws.live.letGo(keep: true);
    });
  }

  /// Starts the Camera tool's drag at [local]: orbits around the frame (or pans it when Shift is held).
  /// With no camera in the project, nothing is held and a notice says so.
  void orbitDragStart(Offset local) {
    final ws = _stage.workspace, cam = _cameraOf(ws);
    if (cam == null) {
      ws.notice = 'No camera: add one from Create › Layers';
      return;
    }
    if (ws.freeEye) {
      _orbitFrom = (x: ws.eye[1], y: ws.eye[0]);
      _drag.held = (from: local, moved: false, by: 'orbit');
      return;
    }
    final at = ws.frame / WorkspaceController.fps;
    ws.live.hold(cam);
    if (ws.playing) ws.playing = false;
    final pan =
        (_stage.tool.cameraDrag == 1) !=
        HardwareKeyboard.instance.isShiftPressed;
    if (pan) {
      // Pans the Boxcam frame directly in screen space.
      _drag.held = (from: local, moved: false, by: null);
      return;
    }
    _orbitFrom = (
      x: stageValue(ws, cam, 'rotate_x', at) ?? 0,
      y: stageValue(ws, cam, 'rotate_y', at) ?? 0,
    );
    _drag.held = (from: local, moved: false, by: 'orbit');
  }

  /// Starts a drag on a camera's Boxcam frame gizmo in 3D View and returns whether one was hit.
  /// - The top roll knob rotates the frame (roll).
  /// - A corner of the frame resizes the frame (sets distance, like Boxcam).
  /// - The frame centre (g[4]) or interior pans the frame.
  /// [wholeFrame] makes any point in the frame count as a hit, not only its handles.
  bool gizmoDragStart(
    StageViewport v,
    Offset local, {
    required bool wholeFrame,
  }) {
    final ws = _stage.workspace,
        scene = _stage.scene,
        at = ws.frame / WorkspaceController.fps;
    for (final id in scene.gizmos.keys) {
      final g = [
            for (final p in scene.gizmo(id)) p == null ? null : v.toScreen(p),
          ],
          cam = id;
      if (g.length < 5) continue;
      final frame = [g[0], g[1], g[2], g[3]].nonNulls.toList();
      final rollKnob = cameraFrameRollKnob(frame);
      bool on(Offset? p, double reach) =>
          p != null && (p - local).distance <= reach;
      final String by;
      if (_stage.selected == id && on(rollKnob, 14) && g[4] != null) {
        by = 'gizmo roll';
        final delta = local - g[4]!;
        _rollFrom = (
          rotate: stageValue(ws, cam, 'rotate', at) ?? 0,
          angle: math.atan2(delta.dy, delta.dx),
          middle: g[4]!,
        );
      } else if (_stage.selected == id &&
          frame.any((p) => on(p, 14)) &&
          g[4] != null) {
        by = 'gizmo frame';
        _frameFrom = (
          distance: stageValue(ws, cam, 'distance', at) ?? 1,
          reach: math.max((local - g[4]!).distance, 1.0),
          middle: g[4]!,
        );
      } else if (on(g[4], 12) ||
          (wholeFrame &&
              frame.length == 4 &&
              (Path()..addPolygon(frame, true)).contains(local))) {
        by = 'place';
      } else {
        continue;
      }
      ws.live.hold(cam);
      ws.select(id);
      if (ws.playing) ws.playing = false;
      _drag.held = (from: local, moved: false, by: by == 'place' ? null : by);
      return true;
    }
    return false;
  }

  /// Carries a camera drag on to [local].
  /// Returns false, having done nothing, when the drag in progress is not an orbit or a gizmo's.
  bool dragUpdate(Offset local) {
    final h = _drag.held, ws = _stage.workspace;
    if (h == null || !stageConnected(ws)) return false;
    if (h.by == 'gizmo roll' && _rollFrom != null) {
      final r = _rollFrom!;
      final now = local - r.middle;
      final deltaDeg = (math.atan2(now.dy, now.dx) - r.angle) * 180 / math.pi;
      stageUpdateDrag(ws, 'rotate', r.rotate - deltaDeg);
      _drag.held = (from: h.from, moved: true, by: h.by);
      return true;
    }
    if (h.by == 'gizmo frame' && _frameFrom != null) {
      // Larger Boxcam frame = larger distance (zoom out); smaller frame = smaller distance (zoom in).
      final f = _frameFrom!;
      final next = (f.distance * (local - f.middle).distance / f.reach).clamp(
        .05,
        100.0,
      );
      stageUpdateDrag(ws, 'distance', next);
      _drag.held = (from: h.from, moved: true, by: h.by);
      return true;
    }
    if (h.by == 'orbit' && _orbitFrom != null) {
      final d = local - h.from, o = _orbitFrom!;
      if (ws.freeEye) {
        ws.setView('stage.eye', [
          o.y - d.dx * .25,
          (o.x - d.dy * .25).clamp(-89.0, 89.0),
          ws.eye[2],
        ]);
        return true;
      }
      stageUpdateDrag(ws, 'rotate_y', o.y - d.dx * .25);
      stageUpdateDrag(ws, 'rotate_x', (o.x - d.dy * .25).clamp(-89.0, 89.0));
      _drag.held = (from: h.from, moved: true, by: 'orbit');
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Forgets where the camera stood when the drag began, once the drag is over.
  void dragEnd() {
    _orbitFrom = null;
    _frameFrom = null;
    _rollFrom = null;
  }

  @override
  void dispose() {
    _dollyRest?.cancel();
    super.dispose();
  }
}
