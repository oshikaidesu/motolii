// formatNumber: a number as a field shows it. The expected values are what the code gave when this was written, so a move that
// changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/widgets/number_format.dart';

void main() {
  test('formatNumber writes a number with the decimals asked for, or with none when tight', () {
    expect(formatNumber(5, 0), '5');
    expect(formatNumber(5, 2), '5.00');
    expect(formatNumber(12.34, 1), '12.3');
    expect(formatNumber(12.36, 1), '12.4');
    expect(formatNumber(12.34, 2, tight: true), '12');
    expect(formatNumber(0, 1), '0.0');
  });

  test('formatNumber never shows a number that is not zero as zero: it adds decimals, four at most', () {
    expect(formatNumber(.04, 0), '0.04');
    expect(formatNumber(.004, 1), '0.004');
    expect(formatNumber(-.4, 0), '-0.4');
    expect(formatNumber(-.04, 2, tight: true), '-0.04');
    expect(formatNumber(.00004, 0), '0.0000');
  });

  test('formatNumber writes minus zero as 0', () {
    expect(formatNumber(-0.0, 0), '0');
  });
}
