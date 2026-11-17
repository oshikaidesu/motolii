// characterization: FrameSnap, which frame a dragged bar end, keyframe or playhead snaps to.
// Each expected value is worked out by hand from the rule the class documents, and the arithmetic is written beside
// it. Needs no engine.
//
// A stop catches a frame when it is at most 12 px away on screen. Most tests draw a frame 4 px wide, so a stop catches
// from 12 / 4 = 3 frames away on either side.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';

import '../../main_tests_only.dart';

List<SnapTarget> _t(Iterable<int> frames) => [
  for (final f in frames) SnapTarget(f, SnapKind.keyframe),
];

FrameSnap snapTo(
  Iterable<int> stops, {
  double pixelsPerFrame = 4,
  Beats? beats,
}) =>
    FrameSnap(targets: _t(stops), beats: beats, pixelsPerFrame: pixelsPerFrame);

void main() {
  if (skipUnlessEveryTest()) return;
  test('the default skin gives the 12 px reach these tests count with', () {
    expect(FrameSnap.reach, 12);
  });

  group('nearest', () {
    test('gives a stop that is at most 12 px away', () {
      final snap = snapTo({30, 60});
      expect(snap.nearest(30)?.frame, 30);
      expect(snap.nearest(31)?.frame, 30); // 1 frame = 4 px
      expect(snap.nearest(33)?.frame, 30); // 3 frames = 12 px, the reach
      expect(snap.nearest(27)?.frame, 30); // 3 frames before
      expect(snap.nearest(57)?.frame, 60); // 3 frames before the other
    });

    test('gives null when every stop is further than 12 px', () {
      final snap = snapTo({30, 60});
      expect(snap.nearest(34), isNull); // 4 frames = 16 px
      expect(snap.nearest(26), isNull); // 4 frames before
      expect(snap.nearest(45), isNull); // 15 frames from both
      expect(snapTo(const {}).nearest(30), isNull);
    });

    test('gives the nearer of two stops within reach', () {
      expect(snapTo({27, 32}).nearest(30)?.frame, 32); // 3 frames against 2
      expect(snapTo({29, 34}).nearest(30)?.frame, 29); // 1 frame against 4
    });

    test('gives the stop met first when two are equally near', () {
      expect(snapTo({28, 32}).nearest(30)?.frame, 28); // both 2 frames
      expect(snapTo({32, 28}).nearest(30)?.frame, 32);
    });

    test('reaches fewer frames when zoomed in and more when zoomed out', () {
      final near = snapTo({30}, pixelsPerFrame: 16);
      expect(near.nearest(30)?.frame, 30);
      expect(near.nearest(31), isNull); // 16 px > 12
      final far = snapTo({30}, pixelsPerFrame: 1);
      expect(far.nearest(42)?.frame, 30); // 12 px
      expect(far.nearest(43), isNull); // 13 px
    });

    test('takes the beat nearest to the frame as a stop too', () {
      final snap = snapTo(const {}, beats: const Beats(0, 15));
      expect(snap.nearest(31)?.frame, 30);
      expect(snap.nearest(44)?.frame, 45);
      expect(snap.nearest(33)?.frame, 30); // 3 frames = 12 px, the reach
      expect(snap.nearest(34), isNull); // 4 frames = 16 px > 12
    });

    test('weighs a stop against the beat like any two stops', () {
      const beats = Beats(0, 15);
      expect(snapTo({33}, beats: beats).nearest(31)?.frame, 30);
      expect(snapTo({32}, beats: beats).nearest(31)?.frame, 32);
    });
  });

  group('snap', () {
    test('lengthens or shortens the drag so the dragged frame lands on a '
        'stop', () {
      final snap = snapTo({30});
      expect(snap.snap(19, [10]).by, 20);
      expect(snap.snap(19, [10]).caught?.frame, 30);
      expect(snap.snap(22, [10]).by, 20);
      expect(snap.snap(-19, [50]).by, -20);
    });

    test('returns the drag as it was when nothing is near', () {
      final snap = snapTo({30});
      expect(snap.snap(5, [10]).caught, isNull); // lands on 15
      expect(snap.snap(24, [10]).caught, isNull); // lands on 34: 16 px away
    });

    test('snaps a bar by whichever of its two ends is nearer to a stop', () {
      expect(snapTo({32, 71}).snap(20, [10, 50]).caught?.frame, 71);
      expect(snapTo({31, 72}).snap(20, [10, 50]).caught?.frame, 31);
    });

    test('snaps a bar by the end listed first when both are equally near', () {
      expect(snapTo({31, 69}).snap(20, [10, 50]).caught?.frame, 31);
      expect(snapTo({31, 69}).snap(20, [50, 10]).caught?.frame, 69);
    });

    test('snaps a bar by its one end that is near a stop', () {
      expect(snapTo({71}).snap(20, [10, 50]).caught?.frame, 71);
      expect(snapTo({29}).snap(20, [10, 50]).caught?.frame, 29);
    });

    test('measures every end from the drag as the pointer made it', () {
      expect(snapTo({32, 73}).snap(20, [10, 50]).caught?.frame, 32);
    });
  });
}
