// The ruler's flags: finding, creating, naming and dragging the project's marks.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';

extension TimelinePaneRuler on TimelinePaneState {
  /// The mark whose flag is under the pointer [p], if any.
  (double, String)? flagAt(Offset p) {
    if (p.dy < TimelineMetrics.band + 1 || p.dy > TimelineMetrics.band + 15) return null;
    final xs = [for (final m in workspace!.marks) view.x((m.$1 * WorkspaceController.fps).round()).roundToDouble()];
    for (final m in workspace!.marks.reversed) {
      final x = view.x((m.$1 * WorkspaceController.fps).round()).roundToDouble();
      if (p.dx >= x - 2 && p.dx <= x + markerFlagRoom(m.$2, x, xs)) return m;
    }
    return null;
  }

  void rulerDown(Offset p) {
    final v = view, f = v.frameAt(p.dx);
    workDrag = null;
    if (flagAt(p) case final flag?) {
      markHeld = flag;
      markTo = (flag.$1 * WorkspaceController.fps).round();
      markGrab = f - flag.$1 * WorkspaceController.fps;
      markOff = false;
      return;
    }
    if (p.dy <= TimelineMetrics.band + 2) {
      final a = v.x(workIn), b = v.x(workOut);
      if ((p.dx - a).abs() <= 6) {
        workDrag = 0;
      } else if ((p.dx - b).abs() <= 6) {
        workDrag = 1;
      } else if (p.dx > a && p.dx < b) {
        workDrag = 2;
        workGrab = f - workIn;
      }
    }
    rulerMove(p);
  }

  /// The marks on the ruler, as frame and name. These are the project's named times.
  List<(int, String)> marksOf(WorkspaceController ws) {
    return [
      for (final (at, name) in workspace!.marks)
        if ((at, name) != markHeld)
          ((at * WorkspaceController.fps).round(), name)
        else if (!markOff)
          // The mark being dragged is drawn where the pointer holds it, and disappears when dragged off the ruler.
          (markTo, name),
    ];
  }

  /// The marks' colours by frame. The mark being dragged uses the frame where the pointer holds it.
  Map<int, Color> markColorsOf(WorkspaceController ws) => {
    for (final MapEntry(key: at, value: k) in ws.markColors.entries) (markHeld?.$1 == at ? markTo : (at * WorkspaceController.fps).round()): labelColor(k - 1),
  };
}
