// wsCols and wsCell: how many cells fit across a panel, and how wide each is. The expected values are what the code
// gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/state/state.dart';

void main() {
  test('wsCols counts the cells of a least width that fit, with the window gutter of 2 between them', () {
    expect(wsCols(298, 98), 3);
    expect(wsCols(297, 98), 2);
    expect(wsCols(300, 96, gap: 4), 3);
  });

  test('wsCols stays between 1 and 8 unless told otherwise', () {
    expect(wsCols(50, 98), 1);
    expect(wsCols(5000, 98), 8);
    expect(wsCols(5000, 98, max: 12), 12);
    expect(wsCols(50, 98, min: 2), 2);
  });

  test('wsCell shares the width among the cells, less the gaps between them', () {
    expect(wsCell(298, 3), 98);
    expect(wsCell(100, 1), 100);
    expect(wsCell(304, 4, gap: 8), 70);
    expect(wsCell(300, 3), closeTo(98.667, .001));
  });
}
