// Parameter.typed and Parameter.scrubbed: how far a number may go, in one place for the field, the dial, the pad and the stepper.
// The rule is After Effects' PF_FloatSliderDef (slider range and valid range) and Houdini's non-strict range. Needs no engine.
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';

Parameter _p(String field) =>
    infer(parseWgsl('struct Params {\n$field\n}').single);

void main() {
  test('a typed number stops at the slider range when the effect declares no wider one', () {
    final p = _p('amount: f32, // @range(0, 10)');
    expect(p.typed(20), 10);
    expect(p.typed(-5), 0);
    expect(p.typed(4), 4);
  });

  test('@valid widens what may be typed, and @open frees it except below a minimum of zero', () {
    expect(_p('amount: f32, // @range(0, 10) @valid(-100, 100)').typed(50), 50);
    expect(
      _p('amount: f32, // @range(0, 10) @valid(-100, 100)').typed(500),
      100,
    );
    expect(_p('amount: f32, // @range(-1, 1) @open').typed(-30), -30);
    expect(_p('amount: f32, // @range(0, 1) @open').typed(30), 30);
    expect(_p('amount: f32, // @range(0, 1) @open').typed(-30), 0);
  });

  test('a number with no range goes anywhere', () {
    final p = _p('amount: f32,');
    expect(p.typed(1e12), 1e12);
    expect(p.typed(-1e12), -1e12);
  });

  test('a drag stops at the slider ends, or stays where it is when already beyond them', () {
    final p = _p('amount: f32, // @range(0, 10) @valid(-100, 100)');
    expect(p.scrubbed(30, 5, past: false), 10);
    expect(p.scrubbed(30, 12, past: false), 12);
    expect(p.scrubbed(3, 12, past: false), 3);
    expect(p.scrubbed(30, 5, past: true), 30);
  });

  test('a drag of a number with no valid range and no @open is held by the typed range itself', () {
    expect(
      _p('amount: f32, // @range(0, 10)').scrubbed(30, 5, past: false),
      10,
    );
  });
}
