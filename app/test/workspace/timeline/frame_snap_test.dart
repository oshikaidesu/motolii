// characterization: FrameSnap, which frame a dragged bar end, keyframe or playhead snaps to.
// Each expected value is worked out by hand from the rule the class documents, and the arithmetic is written beside
// it. Needs no engine.
//
// A stop catches a frame when it is at most 8 px away on screen. Most tests draw a frame 4 px wide, so a stop catches
// from 8 / 4 = 2 frames away on either side.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';

import '../../main_tests_only.dart';

/// Snapping to [stops] where a frame is [pixelsPerFrame] px wide, with an optional beat grid.
FrameSnap snapTo(
  Iterable<int> stops, {
  double pixelsPerFrame = 4,
  Beats? beats,
}) => FrameSnap(stops: stops, beats: beats, pixelsPerFrame: pixelsPerFrame);

void main() {
  if (skipUnlessEveryTest()) return;
  test('the default skin gives the 8 px reach these tests count with', () {
    expect(FrameSnap.reach, 8);
  });

  group('nearest', () {
    test('gives a stop that is at most 8 px away', () {
      final snap = snapTo({30, 60});
      expect(snap.nearest(30), 30); // on the stop
      expect(snap.nearest(31), 30); // 1 frame = 4 px
      expect(snap.nearest(32), 30); // 2 frames = 8 px, the reach itself
      expect(snap.nearest(28), 30); // 2 frames before it
      expect(snap.nearest(58), 60); // 2 frames before the other stop
    });

    test('gives null when every stop is further than 8 px', () {
      final snap = snapTo({30, 60});
      expect(snap.nearest(33), isNull); // 3 frames = 12 px
      expect(snap.nearest(27), isNull); // 3 frames before
      expect(snap.nearest(45), isNull); // 15 frames from both
      expect(snapTo(const {}).nearest(30), isNull);
    });

    test('gives the nearer of two stops within reach', () {
      expect(snapTo({28, 31}).nearest(30), 31); // 2 frames against 1
      expect(snapTo({29, 32}).nearest(30), 29); // 1 frame against 2
    });

    test('gives the stop met first when two are equally near', () {
      expect(snapTo({28, 32}).nearest(30), 28); // both 2 frames away
      expect(snapTo({32, 28}).nearest(30), 32);
    });

    test('reaches fewer frames when zoomed in and more when zoomed out', () {
      // A frame 16 px wide: 8 / 16 = half a frame, so only the stop itself.
      final near = snapTo({30}, pixelsPerFrame: 16);
      expect(near.nearest(30), 30);
      expect(near.nearest(31), isNull); // 16 px
      // A frame 1 px wide: 8 / 1 = 8 frames.
      final far = snapTo({30}, pixelsPerFrame: 1);
      expect(far.nearest(38), 30); // 8 px
      expect(far.nearest(39), isNull); // 9 px
    });

    test('takes the beat nearest to the frame as a stop too', () {
      // A beat every 15 frames from frame 0: 0, 15, 30, 45...
      final snap = snapTo(const {}, beats: const Beats(0, 15));
      expect(snap.nearest(31), 30); // the beat at 30 is 1 frame = 4 px away
      expect(snap.nearest(44), 45); // the beat at 45 is 1 frame away
      // The nearest beat to 37 is 30 (7 frames against 8 to 45): 28 px.
      expect(snap.nearest(37), isNull);
    });

    test('weighs a stop against the beat like any two stops', () {
      const beats = Beats(0, 15);
      // From 31 the stop at 33 is 2 frames away and the beat at 30 is 1.
      expect(snapTo({33}, beats: beats).nearest(31), 30);
      // From 31 the stop at 32 and the beat at 30 are both 1 frame away;
      // the stops are met before the beat.
      expect(snapTo({32}, beats: beats).nearest(31), 32);
    });
  });

  group('snap', () {
    test('lengthens or shortens the drag so the dragged frame lands on a '
        'stop', () {
      final snap = snapTo({30});
      // A frame at 10 dragged by 19 would land on 29, 1 frame from the stop:
      // dragged by 30 - 10 = 20 it lands on it.
      expect(snap.snap(19, [10]), (by: 20, at: 30));
      // Dragged by 22 it would land on 32, 2 frames past the stop.
      expect(snap.snap(22, [10]), (by: 20, at: 30));
      // A frame at 50 dragged back by 19 would land on 31.
      expect(snap.snap(-19, [50]), (by: -20, at: 30)); // 30 - 50
    });

    test('returns the drag as it was when nothing is near', () {
      final snap = snapTo({30});
      expect(snap.snap(5, [10]), (by: 5, at: null)); // lands on 15
      expect(snap.snap(23, [10]), (by: 23, at: null)); // lands on 33: 12 px
      expect(snap.snap(7, const []), (by: 7, at: null)); // nothing dragged
    });

    test('snaps a bar by whichever of its two ends is nearer to a stop', () {
      // A bar from 10 to 50 dragged by 20 would lie from 30 to 70.
      // Its head is 2 frames from the stop at 32, its tail 1 frame from the
      // stop at 71, so the tail wins: 71 - 50 = 21.
      expect(snapTo({32, 71}).snap(20, [10, 50]), (by: 21, at: 71));
      // Here the head is 1 frame from 31 and the tail 2 frames from 72, so
      // the head wins: 31 - 10 = 21.
      expect(snapTo({31, 72}).snap(20, [10, 50]), (by: 21, at: 31));
    });

    test('snaps a bar by the end listed first when both are equally near', () {
      // The head is 1 frame before 31 and the tail 1 frame after 69.
      expect(snapTo({31, 69}).snap(20, [10, 50]), (by: 21, at: 31));
      expect(snapTo({31, 69}).snap(20, [50, 10]), (by: 19, at: 69)); // 69 - 50
    });

    test('snaps a bar by its one end that is near a stop', () {
      expect(snapTo({71}).snap(20, [10, 50]), (by: 21, at: 71)); // the tail
      expect(snapTo({29}).snap(20, [10, 50]), (by: 19, at: 29)); // the head
    });

    test('measures every end from the drag as the pointer made it', () {
      // The head would land on 30 and snaps 2 frames on to 32. The tail is
      // then judged at 50 + 20 = 70, not at 72: the stop at 73 is 3 frames
      // from 70 and does not catch it.
      expect(snapTo({32, 73}).snap(20, [10, 50]), (by: 22, at: 32));
    });
  });
}
