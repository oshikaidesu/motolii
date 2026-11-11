// The home screen's words about a project: the size, the length, the facts and the day it is filed under. The expected values are the
// examples of the code's own comments (CapCut's "02:13", AbsentMotion's "01:02:13", "9:16" and "1080p").
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/workspace/window/home_project.dart';

HomeProject _project(int wide, int high, double rate) =>
    HomeProject('/a/Film.motolii', DateTime(2026, 11, 11), 0)
      ..facts = (wide: wide, high: high, seconds: 1, rate: rate);

void main() {
  test('a size is given in the unit that keeps it short', () {
    expect(homeBytes(500), '500B');
    expect(homeBytes(1536), '1.5KB');
    expect(homeBytes(254 * 1024 * 1024), '254MB');
  });

  test('a length is minutes and seconds, or hours too from one hour', () {
    expect(homeLength(133), '02:13');
    expect(homeLength(3733), '01:02:13');
  });

  test(
    'a known ratio gives the ratio and the shorter side, any other the size',
    () {
      expect(homeFacts(_project(1920, 1080, 30)), ['16:9', '1080p', '30fps']);
      expect(homeFacts(_project(1080, 1920, 29.97)), [
        '9:16',
        '1080p',
        '29.97fps',
      ]);
      expect(homeFacts(_project(1080, 1350, 24)), ['4:5', '1080p', '24fps']);
      expect(homeFacts(_project(1000, 777, 24)), ['1000x777', '24fps']);
    },
  );

  test('a day is filed as day, month name and year', () {
    expect(homeDay(DateTime(2026, 11, 11)), '11 November 2026');
  });

  test('a project is named by its file without the extension', () {
    expect(_project(1, 1, 1).name, 'Film');
  });
}
