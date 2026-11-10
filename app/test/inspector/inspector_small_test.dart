// fmt: a number as a field shows it. The expected values are what the code gave when this was written, so a move that
// changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/inspector_small.dart';

void main() {
  test('fmt writes a number with the decimals asked for, or with none when tight', () {
    expect(fmt(5, 0), '5');
    expect(fmt(5, 2), '5.00');
    expect(fmt(12.34, 1), '12.3');
    expect(fmt(12.36, 1), '12.4');
    expect(fmt(12.34, 2, tight: true), '12');
    expect(fmt(0, 1), '0.0');
  });

  test('fmt never shows a number that is not zero as zero: it adds decimals, four at most', () {
    expect(fmt(.04, 0), '0.04');
    expect(fmt(.004, 1), '0.004');
    expect(fmt(-.4, 0), '-0.4');
    expect(fmt(-.04, 2, tight: true), '-0.04');
    expect(fmt(.00004, 0), '0.0000');
  });

  test('fmt writes minus zero as 0', () {
    expect(fmt(-0.0, 0), '0');
  });
}
