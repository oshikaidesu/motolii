// majorTickSpacing and fineTickSpacing: how many frames apart the timeline ruler draws its ticks at a zoom. The expected values are what
// the code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/widgets/timeline_painters.dart';

void main() {
  test('majorTickSpacing takes the first round step of frames that is at least 70 px wide', () {
    expect(majorTickSpacing(70, 30), 1);
    expect(majorTickSpacing(10, 30), 10);
    expect(majorTickSpacing(2, 30), 60);
    expect(majorTickSpacing(1, 30), 150);
    expect(majorTickSpacing(3, 24), 24);
  });

  test('majorTickSpacing ends at a minute of frames, however far the ruler is zoomed out', () {
    expect(majorTickSpacing(.01, 30), 1800);
  });

  test('fineTickSpacing takes the step dividing the major one that comes nearest to 30 px, and never under 12 px', () {
    expect(fineTickSpacing(10, 30, 10), 2);
    expect(fineTickSpacing(2, 30, 60), 15);
    expect(fineTickSpacing(1, 30, 150), 30);
    expect(fineTickSpacing(3, 24, 24), 12);
  });

  test('fineTickSpacing is the major step itself when no smaller one fits', () {
    expect(fineTickSpacing(70, 30, 1), 1);
  });
}
