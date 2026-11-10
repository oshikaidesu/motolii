// Snapping for the end of a bar, a keyframe or the playhead.
//
// It snaps to the nearest stop within 8 points, and a bar snaps by whichever end is nearer. A line is drawn where it lands.
// The beat grid is also a stop while the project has a tempo.
// This follows Alight Motion's snapFrame and moveTarget (Timeline.kt) and Ableton Live's grid (manual, 6.7 and 6.10).
import 'package:flutter/foundation.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/beats.dart';

/// The frames a drag can snap to, at one zoom of the timeline.
@immutable
class FrameSnap {
  /// Snapping to [stops] and to [beats], where one frame is [pixelsPerFrame] wide on screen.
  const FrameSnap({
    required this.stops,
    required this.beats,
    required this.pixelsPerFrame,
  });

  /// The frames that can be snapped to, such as the ends and keyframes of the other layers.
  final Iterable<int> stops;

  /// The project's beat grid, or null when the project has no tempo. The beat nearest to a frame is a stop for it.
  final Beats? beats;

  /// The width of one frame on screen, which decides how many frames away a stop still catches.
  final double pixelsPerFrame;

  /// How near a stop must be on screen to catch a dragged frame, in pixels.
  static double get reach => Shape.z(8);

  /// The stop nearest to frame [f] among those within [reach], or null when none is that near.
  int? nearest(int f) {
    int? best;
    for (final s in stops.followedBy([if (beats case final b?) b.nearest(f)])) {
      if ((s - f).abs() * pixelsPerFrame <= reach &&
          (best == null || (s - f).abs() < (best - f).abs())) {
        best = s;
      }
    }
    return best;
  }

  /// The drag distance [by] adjusted so that the nearest of [ends] lands on a stop, and the stop it landed on.
  ///
  /// [ends] are the dragged frames before the drag: both ends of a bar that slides, or the one end being trimmed.
  /// When no end comes near a stop, `by` is returned as it was and `at` is null.
  ({int by, int? at}) snap(int by, List<int> ends) {
    var went = by;
    int? restAt;
    for (final e in ends) {
      final s = nearest(e + by);
      if (s != null &&
          (restAt == null || (s - e - by).abs() < (went - by).abs())) {
        went = s - e;
        restAt = s;
      }
    }
    return (by: went, at: restAt);
  }
}
