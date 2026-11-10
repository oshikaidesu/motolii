// Snapping for the end of a bar, a keyframe or the playhead.
//
// It snaps to the nearest stop within 8 points, and a bar snaps by whichever end is nearer. A line is drawn where it lands.
// The beat grid is also a stop while the project has a tempo. Holding Cmd turns snapping off.
// This follows Alight Motion's snapFrame and moveTarget (Timeline.kt) and Ableton Live's grid (manual, 6.7 and 6.10).
import 'package:flutter/services.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';

extension TimelinePaneSnap on TimelinePaneState {
  int? restOn(int f) {
    if (HardwareKeyboard.instance.isMetaPressed) return null;
    int? best;
    for (final s in stops.followedBy([
      if (workspace!.beats case final b?) b.nearest(f),
    ])) {
      if ((s - f).abs() * view.ppf <= Shape.z(8) &&
          (best == null || (s - f).abs() < (best - f).abs())) {
        best = s;
      }
    }
    return best;
  }

  /// Returns the drag distance [by] adjusted so that the nearest of [ends] lands on a snap stop, if one is close enough.
  int rested(int by, List<int> ends) {
    var went = by;
    restAt = null;
    for (final e in ends) {
      final s = restOn(e + by);
      if (s != null &&
          (restAt == null || (s - e - by).abs() < (went - by).abs())) {
        went = s - e;
        restAt = s;
      }
    }
    return went;
  }
}
