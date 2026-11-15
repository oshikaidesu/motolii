// The Depth tool's model: the lens settings shown in the diagram, and one slab per layer for the diagram to draw.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

const depthZMax = 3000.0;

/// The lens settings shown in the diagram. One is kept per document, so the values survive leaving the tool panel and coming back.
class DepthLens {
  double focal = 50, focus = 1120, fstop = 2.8;
  String? target;

  // Matches engine/document/evaluate/camera.cpp: 24 mm sensor height, half = 12 mm.
  double get fov => 2 * math.atan(12 / focal);

  /// The thin-lens depth of field, taking one canvas pixel as 4 mm and a circle of confusion of 0.03 mm.
  ({double near, double far}) get dof {
    const c = .03, k = 4.0;
    final s = focus * k, h = focal * focal / (fstop * c) + focal;
    final near = s * (h - focal) / (h + s - 2 * focal),
        far = s >= h ? double.infinity : s * (h - focal) / (h - s);
    return (near: near / k, far: far / k);
  }
}

final depthLenses = Expando<DepthLens>();

/// Reads the first camera layer of the document into [lens] and returns its layer id and its distance from the eye.
///
/// The focus is stored in canvas points measured from the eye. When the camera has no focus value, the focus is the eye distance.
/// Returns null when the document has no camera.
({int camera, double eye})? depthLensOf(
  WorkspaceController ws,
  DepthLens lens,
) {
  final cam = ws.layers.where((l) => l.kind == LayerKind.camera).firstOrNull;
  if (!isConnected(ws) || cam == null) return null;
  final t = int.parse(cam.id),
      at = documentNow(ws) ?? 0.0,
      p = documentPoint(ws) ?? 1.0,
          // The working camera orbits at kStageBack (6.0) units along +Z by default.
          eye =
          6.0 * p;
  final stop = layerValue(ws, t, 'aperture', at) ?? 0,
      focus = layerValue(ws, t, 'focus', at) ?? 0;
  lens
    ..focal = layerValue(ws, t, 'focal_length', at) ?? 45.0
    ..fstop = stop > 0
        ? stop
        // An aperture of 0 means everything is sharp, which is shown as the narrowest f-stop of the tool panel.
        : 22
    ..focus = focus > 0 ? focus * p : eye;
  return (camera: t, eye: eye);
}

typedef DepthSlab = ({
  String id,
  String name,
  Color tone,
  double x,
  double z,
  double w,
});

/// Returns one slab per layer, except cameras: its horizontal position and its distance from the eye.
List<DepthSlab> depthSlabsOf(WorkspaceController ws) {
  final eye = depthLensOf(ws, DepthLens())?.eye;
  final p = documentPoint(ws) ?? 1.0;
  return [
    for (final l in ws.layers)
      if (eye != null && l.kind != LayerKind.camera)
        (
          id: l.id,
          name: l.name,
          tone: layerKindColor(l.kind),
          x: (layerValue(ws, int.parse(l.id), 'x', 0) ?? 0.0) * p,
          z: eye - (layerValue(ws, int.parse(l.id), 'z', 0) ?? 0.0) * p,
          w: layerBounds(ws, int.parse(l.id))?[2] ?? 200,
        ),
  ];
}
