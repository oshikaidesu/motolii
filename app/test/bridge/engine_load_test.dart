// EngineLoad (bridge/engine_load.dart): the frames' times as parts of one frame's time at 60 frames a second,
// since the last look. The expected values follow the contract written there.
import 'package:motolii/bridge/engine_load.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const beat = EngineLoad.beat;

  test('no frame drawn: at rest', () {
    expect(EngineLoad().take(), isNull);
  });

  test('the render thread: the mean and the most; the GPU: the latest', () {
    final load = EngineLoad()
      ..add(beat * .25, beat * .5)
      ..add(beat * .75, beat * .25);
    final taken = load.take()!;
    expect(taken.cpu, closeTo(.5, 1e-9));
    expect(taken.cpuMost, closeTo(.75, 1e-9));
    expect(taken.gpu, closeTo(.25, 1e-9));
  });

  test('a look starts again: frames before it are not counted twice', () {
    final load = EngineLoad()..add(beat, beat);
    load.take();
    expect(load.take(), isNull);
    load.add(beat * .5, 0);
    final taken = load.take()!;
    expect(taken.cpu, closeTo(.5, 1e-9));
    expect(taken.cpuMost, closeTo(.5, 1e-9));
    expect(taken.gpu, 0);
  });

  test('a frame over its time is over 1', () {
    final load = EngineLoad()..add(beat * 2, beat * 1.5);
    final taken = load.take()!;
    expect(taken.cpu, closeTo(2, 1e-9));
    expect(taken.gpu, closeTo(1.5, 1e-9));
  });
}
