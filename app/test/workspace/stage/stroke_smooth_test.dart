// Verifies freehand stroke stabilization: jitter reduction increases monotonically
// across Off < Low < Med < High while pinning endpoints and preserving sharp corners.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/stage/stroke_smooth.dart';

double _pathLength(List<Offset> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += (pts[i] - pts[i - 1]).distance;
  }
  return total;
}

void main() {
  test(
    'finishSmooth reduces hand jitter monotonically while pinning endpoints',
    () {
      // Straight horizontal stroke with alternating ±6 px hand tremor.
      final jittery = <Offset>[
        for (var i = 0; i <= 40; i++)
          Offset(
            i * 6.0,
            i == 0 || i == 40 ? 100.0 : 100.0 + (i.isEven ? 6.0 : -6.0),
          ),
      ];
      final l0 = _pathLength(StrokeStabilizer.finishSmooth(jittery, 0));
      final l1 = _pathLength(StrokeStabilizer.finishSmooth(jittery, 1));
      final l2 = _pathLength(StrokeStabilizer.finishSmooth(jittery, 2));
      final l3 = _pathLength(StrokeStabilizer.finishSmooth(jittery, 3));

      expect(l1, lessThan(l0));
      expect(l2, lessThan(l1));
      expect(l3, lessThan(l2));
      // True straight line is 240 px; High smoothing should get very close to 240.
      expect(l3, lessThan(255.0));

      for (var lv = 0; lv <= 3; lv++) {
        final s = StrokeStabilizer.finishSmooth(jittery, lv);
        expect(s.first, jittery.first);
        expect(s.last, jittery.last);
      }
    },
  );

  test('finishSmooth preserves sharp intentional 90-degree corners', () {
    final lShape = <Offset>[
      for (var i = 0; i <= 15; i++) Offset(i * 8.0, 0),
      for (var i = 1; i <= 15; i++) Offset(120.0, i * 8.0),
    ];
    final smoothed = StrokeStabilizer.finishSmooth(lShape, 3);
    // Find the point closest to the true corner (120, 0).
    var minDist = double.infinity;
    for (final p in smoothed) {
      minDist = math.min(minDist, (p - const Offset(120, 0)).distance);
    }
    expect(minDist, lessThan(6.0));
  });

  test(
    'liveSmooth calms live preview strokes and keeps cursor tip attached',
    () {
      final noisy = <Offset>[
        for (var i = 0; i <= 20; i++) Offset(i * 5.0, i.isEven ? 10.0 : 22.0),
      ];
      final liveOff = StrokeStabilizer.liveSmooth(noisy, 0);
      final liveHigh = StrokeStabilizer.liveSmooth(noisy, 3);
      expect(_pathLength(liveHigh), lessThan(_pathLength(liveOff)));
      expect(liveHigh.first, noisy.first);
      expect(liveHigh.last, noisy.last);
    },
  );

  test('brushOptions and curveErrorPx scale with smooth level', () {
    expect(StrokeStabilizer.brushOptions(16, 0).smoothing, 0.0);
    expect(
      StrokeStabilizer.brushOptions(16, 3).smoothing,
      greaterThan(StrokeStabilizer.brushOptions(16, 1).smoothing),
    );
    expect(
      StrokeStabilizer.curveErrorPx(3),
      greaterThan(StrokeStabilizer.curveErrorPx(0)),
    );
  });
}
