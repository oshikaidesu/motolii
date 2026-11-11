// Who owns the pointer while it is down on the stage. A drag belongs to one of five: the brush, the lasso, a drawing tool, a guide being
// pulled out of a ruler, or the layer, handle or camera gizmo that was under it. The owner is chosen once, in this order, and start,
// update, end and cancel each go to it; StageView only hands the pointer events over.
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/stage/camera_gestures.dart';
import 'package:motolii/workspace/stage/draw_tools.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';
import 'package:motolii/workspace/stage/stage_tool.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class StagePointer {
  StagePointer({
    required this.drag,
    required this.camera,
    required this.draw,
    required this.tool,
    required this.ws,
    required this.hit,
    required this.cursor,
  });

  final StageDrag drag;
  final CameraGestures camera;
  final DrawTools draw;

  /// The active tool and the workspace, read when a drag starts.
  final StageTool Function() tool;
  final WorkspaceController Function() ws;

  /// The layer under a point of the view, or null.
  final String? Function(StageViewport v, Offset local) hit;

  /// The pointer in composition px, which the HUD and the rulers read.
  final ValueNotifier<Offset?> cursor;

  /// The last position the drag was carried to, for the owners that need where it ended.
  Offset? last;

  /// Decides what a drag starting at [local] grabs, in order: the active tool's action, a handle of the selected layer,
  /// a camera gizmo, a guide, a layer, and otherwise a lasso.
  void start(StageViewport v, Offset local) {
    last = local;
    if (tool().make == 'camera') return camera.orbitDragStart(local);
    if (tool().make == 'brush') {
      draw.brushDragStart(local);
      return;
    }
    if (tool().make != null) {
      draw.drawDragStart(local);
      return;
    }
    final w = ws(), m = w.inside;
    if (drag.handleDragStart(v, local)) return;
    if (m != null && camera.gizmoDragStart(v, local, inside: false)) return;
    // Guides come after the handles, which lie over everything else.
    if (drag.guideDragStart(v, local)) return;
    final id = m == null ? null : hit(v, local), t = int.tryParse(id ?? '');
    // Layers are tested first, then the camera frames they lie in.
    if (m != null &&
        t == null &&
        camera.gizmoDragStart(v, local, inside: true)) {
      return;
    }
    if (m != null && t == null) {
      // Nothing under the pointer: draw a lasso.
      w.select(null);
      draw.lassoDragStart(local);
      return;
    }
    if (m == null || t == null) return;
    drag.layerDragStart(id!, local);
  }

  /// Carries the drag on to [local].
  void update(StageViewport v, Offset local) {
    if (draw.brush != null) return draw.brushDragUpdate(local);
    if (draw.lasso != null) return draw.lassoDragUpdate(local);
    last = local; // Record the pointer position for every other owner, not only the pen.
    if (draw.drawFrom != null) return draw.drawDragUpdate(local);
    if (drag.isPullingGuide) {
      cursor.value = v.toComposition(local);
      return;
    }
    // The camera's drag, when it is one, else the layer's or the handle's.
    if (camera.dragUpdate(local)) return;
    drag.dragUpdate(v, local);
  }

  /// Ends the drag. A drag that did not move is discarded by the engine.
  void end(StageViewport v) {
    if (draw.brush != null) return draw.brushDragEnd(v);
    if (draw.lasso != null) return draw.lassoDragEnd(v);
    if (draw.drawFrom != null) {
      final from = draw.drawFrom!;
      return tool().make == 'pen'
          ? draw.pen(v, from, last ?? from)
          : draw.drawDragEnd(v, last ?? from);
    }
    if (drag.isPullingGuide) return drag.guideDragEnd(v, last!);
    camera.dragEnd();
    drag.dragEnd();
  }

  /// Gives the drag up: whatever it changed is discarded.
  void cancel() {
    if (draw.brush != null) return draw.brushDragCancel();
    if (draw.lasso != null) return draw.lassoDragCancel();
    if (draw.drawFrom != null) return draw.drawDragCancel();
    if (drag.isPullingGuide) return drag.guideDragCancel();
    camera.dragEnd();
    drag.dragEnd(keep: false);
  }
}
