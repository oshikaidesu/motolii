// gridColumns and gridCellWidth: how many cells fit across a panel, and how wide each is. The expected values are what the code
// gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/widgets/grid_columns.dart';

import '../../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;
  test('gridColumns counts the cells of a least width that fit, with the window gutter of 2 between them', () {
    expect(gridColumns(298, 98), 3);
    expect(gridColumns(297, 98), 2);
    expect(gridColumns(300, 96, gap: 4), 3);
  });

  test('gridColumns stays between 1 and 8 unless told otherwise', () {
    expect(gridColumns(50, 98), 1);
    expect(gridColumns(5000, 98), 8);
    expect(gridColumns(5000, 98, max: 12), 12);
    expect(gridColumns(50, 98, min: 2), 2);
  });

  test('gridCellWidth shares the width among the cells, less the gaps between them', () {
    expect(gridCellWidth(298, 3), 98);
    expect(gridCellWidth(100, 1), 100);
    expect(gridCellWidth(304, 4, gap: 8), 70);
    expect(gridCellWidth(300, 3), closeTo(98.667, .001));
  });
}
