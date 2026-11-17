// Snapping for the end of a bar, a keyframe or the playhead.
//
// A drag lands on the nearest target within 12 points, and a bar snaps by
// whichever end is nearer. The kind of the target is reported so the caller
// can show what caught the drag — Lumit's rule that "the target must be
// indicated at the moment of capture".
// The beat grid is also a target while the project has a tempo.
import 'package:flutter/foundation.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/gestures.dart';
import 'package:motolii/workspace/state/beats.dart';

enum SnapKind { layerIn, layerOut, keyframe, marker, playhead, workArea, beat }

@immutable
class SnapTarget {
  const SnapTarget(this.frame, this.kind);
  final int frame;
  final SnapKind kind;

  @override
  bool operator ==(Object other) =>
      other is SnapTarget && other.frame == frame && other.kind == kind;
  @override
  int get hashCode => Object.hash(frame, kind);
}

/// The frames a drag can snap to, at one zoom of the timeline.
@immutable
class FrameSnap {
  const FrameSnap({
    required this.targets,
    required this.beats,
    required this.pixelsPerFrame,
  });

  final List<SnapTarget> targets;
  final Beats? beats;
  final double pixelsPerFrame;

  static double get reach => Shape.z(Gestures.snapTimeline);

  SnapTarget? nearest(int f) {
    SnapTarget? best;
    double bestDist = double.infinity;
    for (final t in targets) {
      final d = (t.frame - f).abs() * pixelsPerFrame;
      if (d <= reach && d < bestDist) {
        bestDist = d;
        best = t;
      }
    }
    if (beats case final b?) {
      final bf = b.nearest(f);
      final d = (bf - f).abs() * pixelsPerFrame;
      if (d <= reach && d < bestDist) {
        best = SnapTarget(bf, SnapKind.beat);
      }
    }
    return best;
  }

  ({int by, SnapTarget? caught}) snap(int by, List<int> ends) {
    var went = by;
    SnapTarget? caught;
    double bestDist = double.infinity;
    for (final e in ends) {
      final t = nearest(e + by);
      if (t != null) {
        final d = (t.frame - e - by).abs().toDouble();
        if (d < bestDist) {
          bestDist = d;
          went = t.frame - e;
          caught = t;
        }
      }
    }
    return (by: went, caught: caught);
  }
}
