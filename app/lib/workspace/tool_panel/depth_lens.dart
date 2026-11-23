// World-space top-down (XZ) radar model for the Depth panel: camera pose, FOV/DOF, Boxcam frame, and 3D slabs.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Default reach of the focus slider and radar distance readout, in canvas points.
const depthZMax = 3000.0;

/// Stage-unit distance from camera eye to Boxcam frame when `distance == 1` (matches kStageBack in camera.cpp).
const _stageBack = 6.0;

/// Active camera optics and world-space XZ pose read from the document.
class DepthLens {
  double focal = 45, focus = 1120, fstop = 22;
  double eyeX = 0, eyeZ = _stageBack;
  double lookX = 0, lookZ = 0;
  double yaw = 0, pitch = 0, distance = 1.0, point = 1.0;
  bool autoFocus = true;
  int? target;
  int? lockTarget;

  // Matches engine/document/evaluate/camera.cpp: 24 mm sensor height, half = 12 mm.
  double get fov => 2 * math.atan(12 / math.max(focal, 1.0));

  /// Forward unit vector in XZ (from eye toward look).
  (double, double) get forward => (-math.sin(yaw), -math.cos(yaw));

  /// Right unit vector in XZ (perpendicular to forward).
  (double, double) get right => (math.cos(yaw), -math.sin(yaw));

  /// Camera-to-frame distance in stage units.
  double get frameDepth => _stageBack * distance;

  /// Focus distance in stage units along the view direction.
  double get focusUnits => point > 0 ? focus / point : _stageBack;

  /// Thin-lens depth of field in canvas points (1 canvas px = 4 mm, CoC = 0.03 mm).
  ({double near, double far}) get dof {
    const c = .03, k = 4.0;
    final f = math.max(focal, 1.0);
    final s = focus * k, h = f * f / (fstop * c) + f;
    final near = s * (h - f) / (h + s - 2 * f),
        far = s >= h ? double.infinity : s * (h - f) / (h - s);
    return (near: near / k, far: far / k);
  }
}

final depthLenses = Expando<DepthLens>();

/// Active camera layer for the Depth radar: selected camera if one is selected, else the first camera.
Layer? activeDepthCamera(WorkspaceController ws) {
  final picked = ws.selected;
  if (picked != null) {
    final l = ws.layers.where((e) => e.id == picked).firstOrNull;
    if (l?.kind == LayerKind.camera) return l;
  }
  return ws.layers.where((l) => l.kind == LayerKind.camera).firstOrNull;
}

/// Reads the active camera's world-space XZ pose and lens optics at the current playhead time into [lens].
/// Returns null when the document has no camera.
({int camera, double eye, double point})? depthLensOf(
  WorkspaceController ws,
  DepthLens lens,
) {
  final cam = activeDepthCamera(ws);
  if (!isConnected(ws) || cam == null) return null;
  final t = cam.id,
      at = ws.frame / WorkspaceController.fps,
      p = documentPoint(ws) ?? 1.0;

  final lockId = (layerValue(ws, t, 'target', at) ?? 0).round();
  double tx = 0, tz = 0;
  if (lockId > 0 && lockId != t && layerWord(ws, lockId, 'kind').isNotEmpty) {
    tx = layerValue(ws, lockId, 'x', at) ?? 0;
    tz = layerValue(ws, lockId, 'z', at) ?? 0;
  }
  final lx = tx + (layerValue(ws, t, 'x', at) ?? 0),
      lz = tz + (layerValue(ws, t, 'z', at) ?? 0),
      dist = (layerValue(ws, t, 'distance', at) ?? 1.0).clamp(0.05, 100.0),
      yawRad = (layerValue(ws, t, 'rotate_y', at) ?? 0.0) * math.pi / 180.0,
      pitchRad = (layerValue(ws, t, 'rotate_x', at) ?? 0.0) * math.pi / 180.0;

  // Matches doc_view_camera_of: eye = look + R_y(yaw) * R_x(pitch) * (0, 0, kStageBack * dist).
  final horiz = _stageBack * dist * math.cos(pitchRad);
  final ex = lx + horiz * math.sin(yawRad), ez = lz + horiz * math.cos(yawRad);

  final eyePx = _stageBack * dist * p;
  final rawFocal = layerValue(ws, t, 'focal_length', at) ?? 45.0;
  final stop = layerValue(ws, t, 'aperture', at) ?? 0;
  final rawFocus = layerValue(ws, t, 'focus', at) ?? 0;

  lens
    ..point = p
    ..eyeX = ex
    ..eyeZ = ez
    ..lookX = lx
    ..lookZ = lz
    ..yaw = yawRad
    ..pitch = pitchRad
    ..distance = dist
    ..lockTarget = lockId > 0 ? lockId : null
    ..focal = rawFocal > 0 ? rawFocal : 45.0
    ..fstop = stop > 0 ? stop : 22
    ..autoFocus = rawFocus <= 0
    ..focus = rawFocus > 0 ? rawFocus * p : eyePx;
  return (camera: t, eye: eyePx, point: p);
}

/// One spatial (3D / 2.5D) layer plotted on the world XZ radar.
typedef DepthSlab = ({
  int id,
  String name,
  Color tone,
  double x,
  double z,
  double yaw,
  double widthUnits,
  double depthPx,
});

/// Returns world-space XZ slabs for all spatial (non-2D, non-camera, non-audio) layers at the current playhead time.
List<DepthSlab> depthSlabsOf(WorkspaceController ws, DepthLens lens) {
  if (!isConnected(ws)) return const [];
  final at = ws.frame / WorkspaceController.fps, p = documentPoint(ws) ?? 1.0;
  final (fx, fz) = lens.forward;
  final out = <DepthSlab>[];
  for (final l in ws.layers) {
    if (l.kind == LayerKind.camera || l.kind == LayerKind.audio) continue;
    final kind = layerWord(ws, l.id, 'kind');
    if (kind == 'behaviour' || kind == 'camera' || kind == 'audio') continue;
    // 2D layers always stick to the viewing camera and have no fixed world position on the radar.
    if (layerWord(ws, l.id, 'space') == '2d') continue;
    final x = layerValue(ws, l.id, 'x', at) ?? 0.0;
    final z = layerValue(ws, l.id, 'z', at) ?? 0.0;
    final yaw = (layerValue(ws, l.id, 'rotate_y', at) ?? 0.0) * math.pi / 180.0;
    final scaleX = (layerValue(ws, l.id, 'scale_x', at) ?? 1.0).abs();
    final widthUnits = math.max(0.35, scaleX * 1.4);
    final depthUnits = (x - lens.eyeX) * fx + (z - lens.eyeZ) * fz;
    out.add((
      id: l.id,
      name: l.name,
      tone: layerKindColor(l.kind),
      x: x,
      z: z,
      yaw: yaw,
      widthUnits: widthUnits,
      depthPx: depthUnits * p,
    ));
  }
  return out;
}
