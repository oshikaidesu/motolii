// The timeline's clock: advancing, playing and stepping the playhead.
import 'dart:developer' show Timeline;

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline.dart';

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
}
