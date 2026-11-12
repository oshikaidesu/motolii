// propOf: the property a value belongs to, whose one key mark all its values share. The expected values are what the
// code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/inspector_state.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;
  test('x, y and z are values of the position', () {
    expect([
      propOf('v_x'),
      propOf('v_y'),
      propOf('v_z'),
    ], everyElement('v_position'));
  });

  test(
    'a value ending in _x, _y or _z belongs to the property named before it',
    () {
      expect(propOf('v_scale_x'), 'v_scale');
      expect(propOf('v_rotate_y'), 'v_rotate');
      expect(propOf('v_anchor_z'), 'v_anchor');
    },
  );

  test('any other value is its own property', () {
    expect(propOf('v_rotate'), 'v_rotate');
    expect(propOf('v_opacity'), 'v_opacity');
    expect(propOf('v_blur_radius'), 'v_blur_radius');
    expect(propOf('v_center.x'), 'v_center.x');
  });
}
