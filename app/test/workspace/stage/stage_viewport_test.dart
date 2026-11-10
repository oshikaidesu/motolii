// StageViewport: where the composition lies in the stage's pane, and the conversion between composition pixels and
// screen pixels. Every expected value is worked out by hand from the geometry and written as the arithmetic that
// gives it. Needs no engine.
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';

void main() {
  // A full HD composition in a pane of 1032 × 672 with a 16 px ruler along the top and the left. The area the
  // composition is shown in is what the rulers leave: 1032 − 16 = 1016 wide and 672 − 16 = 656 high.
  const pane = Size(1032, 672), composition = Size(1920, 1080);
  const area = Rect.fromLTRB(16, 16, 1032, 672);
  StageViewport viewport({int zoom = 0, Offset pan = Offset.zero}) =>
      StageViewport.of(
        pane,
        composition: composition,
        zoom: zoom,
        pan: pan,
        ruler: 16,
        margin: 28,
      );

  test('the area is the pane without its rulers', () {
    expect(viewport().area, area);
    expect(viewport().composition, composition);
  });

  test('Fit scales the composition to the area less its margins', () {
    // The 28 px margin on each side leaves 1016 − 56 = 960 across and 656 − 56 = 600 down.
    // 960 / 1920 = 0.5 and 600 / 1080 = 0.555…: the smaller scale fits both ways.
    expect(viewport().scale, 960 / 1920);
  });

  test('Fit centres the composition in the area', () {
    // At 0.5 the composition is drawn 960 × 540. Centred, (1016 − 960) / 2 = 28 is free on its left and
    // (656 − 540) / 2 = 58 above it; the area itself starts 16 in from the pane's corner.
    expect(viewport().origin, const Offset(16 + 28, 16 + 58));
    expect(
      viewport().compositionRect,
      const Rect.fromLTWH(16 + 28, 16 + 58, 960, 540),
    );
  });

  test('Fit is limited by the height in a wide pane', () {
    // Pane 2016 × 672: the area less its margins is 2016 − 16 − 56 = 1944 across and 600 down.
    // 1944 / 1920 = 1.0125 and 600 / 1080 = 0.555…: the height decides.
    final v = StageViewport.of(
      const Size(2016, 672),
      composition: composition,
      zoom: 0,
      pan: Offset.zero,
      ruler: 16,
      margin: 28,
    );
    expect(v.scale, 600 / 1080);
  });

  test('Fit never draws the composition below a fiftieth of its size', () {
    // Pane 60 × 60: the area is 44 × 44 and the margins take 56, so nothing is left to fit into.
    final v = StageViewport.of(
      const Size(60, 60),
      composition: composition,
      zoom: 0,
      pan: Offset.zero,
      ruler: 16,
      margin: 28,
    );
    expect(v.scale, 1 / 50);
  });

  test('the fixed steps draw at 50% and 100%, centred', () {
    // The area's centre is (16 + 1016 / 2, 16 + 656 / 2) = (524, 344).
    // At 50% half the drawn composition is (480, 270); at 100% it is (960, 540).
    expect(viewport(zoom: 1).scale, 0.5);
    expect(viewport(zoom: 1).origin, const Offset(524 - 480, 344 - 270));
    expect(viewport(zoom: 2).scale, 1.0);
    expect(viewport(zoom: 2).origin, const Offset(524 - 960, 344 - 540));
    expect(stageZooms, ['Fit', '50%', '100%']);
  });

  test('a pan moves the composition by that many screen pixels', () {
    expect(
      viewport(zoom: 2, pan: const Offset(30, -12)).origin,
      const Offset(524 - 960 + 30, 344 - 540 - 12),
    );
    expect(viewport(zoom: 2, pan: const Offset(30, -12)).scale, 1.0);
  });

  test('composition pixels and screen pixels convert both ways', () {
    // Fit: the origin is (44, 74) and one composition pixel is half a screen pixel.
    final v = viewport();
    expect(
      v.toScreen(const Offset(100, 200)),
      const Offset(44 + 100 * 0.5, 74 + 200 * 0.5),
    );
    expect(
      v.toComposition(const Offset(94, 174)),
      const Offset((94 - 44) / 0.5, (174 - 74) / 0.5),
    );
    expect(v.toScreen(Offset.zero), v.compositionRect.topLeft);
    expect(v.toScreen(const Offset(1920, 1080)), v.compositionRect.bottomRight);
    expect(v.toComposition(v.toScreen(const Offset(7, 9))), const Offset(7, 9));
  });

  test(
    'a pan is clamped so that 60 px of the composition stay in the area',
    () {
      // At 100% half the composition is 960 × 540 and half the area is 508 × 328. With the centres
      // 960 + 508 − 60 = 1408 apart across, or 540 + 328 − 60 = 808 down, 60 px of it are still inside.
      final v = viewport(zoom: 2);
      expect(v.clampPan(const Offset(100, -200)), const Offset(100, -200));
      expect(v.clampPan(const Offset(2000, 0)), const Offset(1408, 0));
      expect(v.clampPan(const Offset(-2000, 0)), const Offset(-1408, 0));
      expect(v.clampPan(const Offset(0, 900)), const Offset(0, 808));
      expect(v.clampPan(const Offset(5000, -5000)), const Offset(1408, -808));
      // Panned to the limit, the composition's left edge is 60 px inside the area's right edge.
      final far = viewport(zoom: 2, pan: v.clampPan(const Offset(5000, 0)));
      expect(far.compositionRect.left, area.right - 60);
    },
  );

  test('two viewports are equal when all four parts are', () {
    expect(viewport(), viewport());
    expect(viewport().hashCode, viewport().hashCode);
    expect(viewport(), isNot(viewport(pan: const Offset(1, 0))));
    expect(viewport(zoom: 1), isNot(viewport(zoom: 2)));
    final v = viewport();
    expect(
      StageViewport(v.origin, v.scale, v.area, const Size(1280, 720)),
      isNot(v),
    );
    expect(
      StageViewport(v.origin, v.scale, v.area.inflate(1), v.composition),
      isNot(v),
    );
  });
}
