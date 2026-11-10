// infer and its helpers: the control guessed for each field of an effect's struct, and the defaults a parameter starts from.
// The expected values are what the code gave when this was written, so a move or a split that changes one fails here.
// Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/controls/inspector_param_controls.dart' show paramColor, paramDefaults;
import 'package:motolii/inspector/controls/param_infer.dart';

/// One field as an effect writes it, such as `amount: f32, // @range(0, 10)`, read from a struct of its own.
Decl _decl(String field) => parseWgsl('struct Params {\n$field\n}').single;
Param _infer(String field) => infer(_decl(field));

void main() {
  test('paramWords splits a field name into words and spells the short forms out', () {
    expect(paramWords('blurRadius'), ['blur', 'radius']);
    expect(paramWords('blur_radius'), ['blur', 'radius']);
    expect(paramWords('glowCol'), ['glow', 'colour']);
    expect(paramWords('dx'), ['offset', 'x']);
    expect(paramWords('rot'), ['rotation']);
    expect(paramWords(''), isEmpty);
  });

  test('paramLabel writes the words as a label: the first capitalised, a single letter as a capital', () {
    expect(paramLabel(['blur', 'radius']), 'Blur radius');
    expect(paramLabel(['offset', 'x']), 'Offset X');
    expect(paramLabel(['x']), 'X');
    expect(paramLabel([]), '');
  });

  test('angleLabel knows an angle by its name, and a speed of turning is not one', () {
    for (final angle in ['angle', 'Rotation', 'rot', 'Hue', 'direction', '角度', '回転', '向き']) {
      expect(angleLabel(angle), isTrue, reason: angle);
    }
    for (final other in ['Blur', 'Saturation', 'Spin speed', 'Rotation rate', '回転速度']) {
      expect(angleLabel(other), isFalse, reason: other);
    }
  });

  group('infer', () {
    test('guesses the look, the range and the unit of each kind of field', () {
      const cases = <(String, List<Object?>)>[
        // What the declaration says outright.
        ('mode: i32, // @enum(Low, Med, High)', [ParamLook.choice, 0, 2, '']),
        ('amount: f32, // @ui(bar) @range(0, 10)', [ParamLook.bar, 0, 10, '']),
        ('amount: f32, // @ui(angle) @range(0, 90)', [ParamLook.angle, 0, 90, '']),
        ('amount: f32, // @ui(nonsense)', [ParamLook.scrub, null, null, '']),
        // On or off.
        ('on: bool,', [ParamLook.toggle, 0, 1, '']),
        ('strength: f32, // @toggle', [ParamLook.toggle, 0, 1, '']),
        ('invert: u32,', [ParamLook.toggle, 0, 1, '']),
        ('invert: u32, // @range(0, 3)', [ParamLook.stepper, 0, 3, '']),
        ('invert: f32,', [ParamLook.scrub, null, null, '']),
        // The type.
        ('tint: vec3f,', [ParamLook.color, null, null, '']),
        ('glow: vec4f,', [ParamLook.color, null, null, '']),
        ('boxSize: vec2f,', [ParamLook.size, 0, null, 'px']),
        ('scale: vec2f,', [ParamLook.size, 0, null, '']),
        ('center: vec2f,', [ParamLook.point, 0, 1, '']),
        ('offset: vec2f,', [ParamLook.point, -1, 1, '']),
        ('offset: vec2f, // @range(-5, 5)', [ParamLook.point, -5, 5, '']),
        // The name and the unit.
        ('seed: f32,', [ParamLook.seed, 0, 9999, '']),
        ('angle: f32,', [ParamLook.angle, -180, 180, '°']),
        ('turn: f32, // @unit(deg) @range(0, 90)', [ParamLook.angle, 0, 90, '°']),
        ('phase: f32, // @unit(rad)', [ParamLook.angle, -180, 180, '°']),
        ('mix: f32, // @range(0, 1)', [ParamLook.percent, 0, 100, '%']),
        ('mix: f32, // @range(0, 2)', [ParamLook.bar, 0, 2, '']),
        ('gain: f32, // @unit(%)', [ParamLook.percent, 0, 100, '%']),
        ('gain: f32, // @unit(%) @range(-50, 50)', [ParamLook.percent, -50, 50, '%']),
        ('count: i32, // @range(1, 8)', [ParamLook.stepper, 1, 8, '']),
        ('count: i32, // @range(0, 100)', [ParamLook.bar, 0, 100, '']),
        ('blurRadius: f32, // @range(0, 200)', [ParamLook.bar, 0, 200, 'px']),
        ('offsetY: f32,', [ParamLook.vertical, null, null, 'px']),
        ('drop: f32,', [ParamLook.vertical, null, null, '']),
        ('dx: f32,', [ParamLook.horizontal, null, null, 'px']),
        ('width: f32,', [ParamLook.horizontal, null, null, 'px']),
        // The shape of the range.
        ('pan: f32, // @range(-1, 1)', [ParamLook.bipolar, -1, 1, '']),
        ('pan: f32, // @range(-1, 10)', [ParamLook.bar, -1, 10, '']),
        ('gain: f32,', [ParamLook.scrub, null, null, '']),
      ];
      for (final (field, want) in cases) {
        final p = _infer(field);
        expect([p.look, p.min, p.max, p.unit], want, reason: field);
      }
    });

    test('a vertical amount that names a fall grows downwards', () {
      expect(_infer('offsetY: f32,').upIncreases, isTrue);
      expect(_infer('drop: f32,').upIncreases, isFalse);
    });

    test('a choice lists its options', () {
      expect(_infer('mode: i32, // @enum(Low, Med, High)').options, ['Low', 'Med', 'High']);
    });

    test('@default gives the value a field starts from, and a second number for its Y', () {
      expect(_infer('gain: f32,').def, 0);
      expect(_infer('gain: f32, // @default(12)').def, 12);
      final one = _infer('center: vec2f, // @default(0.5)'), two = _infer('center: vec2f, // @default(0.5, 0.25)');
      expect((one.def, one.defY), (.5, .5));
      expect((two.def, two.defY), (.5, .25));
    });

    test('radians are shown as degrees and a 0 to 1 share as a percentage, defaults included', () {
      final twist = _infer('twist: f32, // @range(-3.14159, 3.14159) @default(1.5708)');
      expect((twist.look, twist.unit, twist.dec), (ParamLook.angle, '°', 0));
      expect(twist.min, closeTo(-180, .01));
      expect(twist.max, closeTo(180, .01));
      expect(twist.def, closeTo(90, .01));
      final mix = _infer('mix: f32, // @range(0, 1) @default(0.5)');
      expect(mix.def, closeTo(50, 1e-9));
      expect(mix.dec, 0);
    });

    test('the decimals shown follow the type, @step, the unit, then the width of the range', () {
      const cases = [
        ('count: i32, // @range(0, 3)', 0),
        ('gain: f32, // @step(0.01)', 2),
        ('gain: f32, // @step(0.5)', 1),
        ('gain: f32, // @step(1)', 0),
        ('gain: f32, // @unit(s)', 1),
        ('gain: f32, // @unit(×)', 1),
        ('blurRadius: f32, // @range(0, 2)', 0), // A pixel amount known by its name has no decimals, however narrow its range.
        ('gain: f32, // @range(0, 1)', 2),
        ('gain: f32, // @range(0, 10)', 1),
        ('gain: f32, // @range(0, 100)', 0),
        ('gain: f32,', 0),
      ];
      for (final (field, want) in cases) {
        expect(_infer(field).dec, want, reason: field);
      }
    });

    test('the label, the typed limits, the weight and the fold are carried over', () {
      final p = _infer('// @advanced(Each copy)\ngain: f32, // @label(Output, gain) @open @valid(-10, 10) @weight(7) @range(0, 1)');
      expect((p.id, p.label, p.open, p.validMin, p.validMax, p.weight, p.advanced, p.fold), ('gain', 'Output, gain', true, -10, 10, 7, true, 'Each copy'));
      final plain = _infer('blurRadius: f32,');
      expect(
        (plain.label, plain.open, plain.validMin, plain.validMax, plain.weight, plain.advanced, plain.fold),
        ('Blur radius', false, null, null, null, false, null),
      );
    });
  });

  test('a Param steps by its last decimal, and a drag crosses a known range in 200 px', () {
    const ranged = Param(id: 'a', label: 'A', look: ParamLook.bar, min: 0, max: 200, dec: 2);
    expect((ranged.bounded, ranged.perPx), (true, 1));
    expect(ranged.step, closeTo(.01, 1e-12));
    const whole = Param(id: 'a', label: 'A', look: ParamLook.scrub);
    expect((whole.bounded, whole.step, whole.perPx), (false, 1, 1));
    const fine = Param(id: 'a', label: 'A', look: ParamLook.scrub, dec: 2);
    expect(fine.perPx, closeTo(.1, 1e-12));
  });

  test('paramDefaults names every value a parameter owns: two for a point or a size, none for a colour', () {
    expect(paramDefaults(_infer('center: vec2f, // @default(0.5, 0.25)')), {'v_center.x': .5, 'v_center.y': .25});
    expect(paramDefaults(_infer('boxSize: vec2f,')), {'v_boxSize.x': 0, 'v_boxSize.y': 0});
    expect(paramDefaults(_infer('tint: vec3f,')), isEmpty);
    expect(paramDefaults(_infer('amount: f32, // @default(4)')), {'v_amount': 4});
  });

  test('paramColor writes a colour default as #RRGGBB: white with none, each part kept inside 0 to 1', () {
    expect(paramColor(_decl('tint: vec3f, // @default(1, 0.5, 0)')), '#FF8000');
    expect(paramColor(_decl('tint: vec3f,')), '#FFFFFF');
    expect(paramColor(_decl('tint: vec3f, // @default(2, -1, 0.2)')), '#FF0033');
    expect(paramColor(_decl('glow: vec4f, // @default(0, 0, 0, 0.5)')), '#000000');
  });
}
