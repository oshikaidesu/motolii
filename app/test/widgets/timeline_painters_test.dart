// tpMajor and tpFine: how many frames apart the timeline ruler draws its ticks at a zoom. The expected values are what
// the code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/widgets/timeline_painters.dart';

void main() {
  test('tpMajor takes the first round step of frames that is at least 70 px wide', () {
    expect(tpMajor(70, 30), 1);
    expect(tpMajor(10, 30), 10);
    expect(tpMajor(2, 30), 60);
    expect(tpMajor(1, 30), 150);
    expect(tpMajor(3, 24), 24);
  });

  test('tpMajor ends at a minute of frames, however far the ruler is zoomed out', () {
    expect(tpMajor(.01, 30), 1800);
  });

  test('tpFine takes the step dividing the major one that comes nearest to 30 px, and never under 12 px', () {
    expect(tpFine(10, 30, 10), 2);
    expect(tpFine(2, 30, 60), 15);
    expect(tpFine(1, 30, 150), 30);
    expect(tpFine(3, 24, 24), 12);
  });

  test('tpFine is the major step itself when no smaller one fits', () {
    expect(tpFine(70, 30, 1), 1);
  });
}
