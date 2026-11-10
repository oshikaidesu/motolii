// The timeline's clock and view: advancing, playing and stepping the playhead, and how much of the project is shown (fit, zoom, scroll).
import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

extension TimelinePaneView on TimelinePaneState {
  // ---------------------------------------------------------------- play

  void changed() {
    final ws = workspace!;
    if (ws.playing && !ticker.isActive) {
      ticker.start();
      lastFrame = -1;
      if (ws.frame >= WorkspaceController.duration) ws.frame = 0;
    } else if (!ws.playing && ticker.isActive) {
      ticker.stop();
    }
    follow(ws.frame);
  }

  // The tick is wrapped in a named span so it shows up in Flutter's timeline.
  void tick(Duration e) => Timeline.timeSync('ws tick', () => _tickNow(e));

  void _tickNow(Duration e) {
    final ws = workspace!;
    // The engine keeps the clock. The playhead shows the time of the last frame it drew.
    lastFrame = (ws.inside!.now * WorkspaceController.fps).round().clamp(
      0,
      WorkspaceController.duration,
    );
    ws.frame = lastFrame;
  }

  void toggle() {
    final ws = workspace!;
    ws.playing = !ws.playing;
  }

  void step(int d) {
    final ws = workspace!;
    ws.playing = false;
    ws.frame = ws.frame + d;
  }

  // ---------------------------------------------------------------- view

  double get fit => math.max(
    .1,
    (trackW - TimelineMetrics.padL - TimelineMetrics.padR) /
        WorkspaceController.duration,
  );

  TimelineView get view => TimelineView(fit * zoom, scroll);

  double get visible => WorkspaceController.duration / zoom;

  double clampScroll(double s) => s
      .clamp(0.0, math.max(0.0, WorkspaceController.duration - visible))
      .toDouble();

  double clampV(int rows) => vscroll
      .clamp(0.0, math.max(0.0, rows * TimelineMetrics.row - rowsH))
      .toDouble();
}
