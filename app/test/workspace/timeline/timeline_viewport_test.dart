// characterization: TimelineView and TimelineViewport, the timeline's frame-to-pixel mapping and its zoom and scroll.
// Each expected value is worked out by hand from the formulas the classes document, and the arithmetic is written
// beside it. Needs no engine.
//
// With the default skin the track area has 10 px of padding at the left and 14 px at the right, and a row is 24 px
// high. A track area 984 px wide over a project of 240 frames therefore gives (984 - 10 - 14) / 240 = 4 px per frame.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

import '../../main_tests_only.dart';

/// A viewport over 240 frames whose track area is 984 px wide and whose rows have 100 px, holding [rows] rows.
TimelineViewport viewportOf({int rows = 10}) =>
    TimelineViewport(() => 240)
      ..layout(trackWidth: 984, rowsHeight: 100, rows: rows);

void main() {
  if (skipUnlessEveryTest()) return;
  test('the default skin gives the sizes these tests count with', () {
    expect(TimelineMetrics.padL, 10);
    expect(TimelineMetrics.padR, 14);
    expect(TimelineMetrics.row, 24);
    expect(TimelineMetrics.maxZoom, 16);
  });

  group('TimelineView', () {
    test('x puts the scrolled-to frame just after the left padding', () {
      const view = TimelineView(4, 30);
      expect(view.x(30), 10); // 10 + (30 - 30) * 4
      expect(view.x(40), 50); // 10 + (40 - 30) * 4
      expect(view.x(0), -110); // 10 + (0 - 30) * 4
      expect(view.x(30.5), 12); // 10 + 0.5 * 4
    });

    test('frameAt is the inverse of x and keeps the fraction', () {
      const view = TimelineView(4, 30);
      expect(view.frameAt(10), 30); // (10 - 10) / 4 + 30
      expect(view.frameAt(50), 40); // (50 - 10) / 4 + 30
      expect(view.frameAt(13), 30.75); // (13 - 10) / 4 + 30
      expect(view.frameAt(view.x(123)), 123);
    });

    test('two views are equal when their scale and scroll are', () {
      expect(const TimelineView(4, 30), const TimelineView(4, 30));
      expect(const TimelineView(4, 30), isNot(const TimelineView(8, 30)));
      expect(const TimelineView(4, 30), isNot(const TimelineView(4, 31)));
    });
  });

  group('TimelineViewport', () {
    test('starts at zoom 1 with nothing scrolled', () {
      final viewport = TimelineViewport(() => 240);
      expect(viewport.zoom, 1);
      expect(viewport.scroll, 0);
      expect(viewport.verticalScroll, 0);
    });

    test('fit is the frame width at which the whole project fills the '
        'track area between its paddings', () {
      final viewport = viewportOf();
      expect(viewport.fit, 4); // (984 - 10 - 14) / 240
      expect(viewport.view, const TimelineView(4, 0));
      expect(viewport.view.x(0), 10);
      expect(viewport.view.x(240), 970); // 10 + 240 * 4 = 984 - 14
    });

    test('fit is never under a tenth of a pixel per frame', () {
      final viewport = TimelineViewport(() => 240)
        ..layout(trackWidth: 30, rowsHeight: 100, rows: 1);
      expect(viewport.fit, .1); // (30 - 10 - 14) / 240 = 0.025, raised to 0.1
    });

    test('the project length is read each time it is needed', () {
      var frames = 240;
      final viewport = TimelineViewport(() => frames)
        ..layout(trackWidth: 984, rowsHeight: 100, rows: 1);
      expect(viewport.fit, 4); // 960 / 240
      frames = 480;
      expect(viewport.duration, 480);
      expect(viewport.fit, 2); // 960 / 480
    });

    test('visible is the number of frames shown at the present zoom', () {
      final viewport = viewportOf();
      expect(viewport.visible, 240); // 240 / 1
      viewport.setZoom(4, anchor: 0);
      expect(viewport.visible, 60); // 240 / 4
    });

    test('setZoom keeps the anchor frame where it is on screen', () {
      final viewport = viewportOf();
      expect(viewport.view.x(120), 490); // 10 + 120 * 4
      viewport.setZoom(2, anchor: 120);
      expect(viewport.zoom, 2);
      // A frame is now 4 * 2 = 8 px wide, so frame 120 stays at 490 when
      // the scroll is 120 - (490 - 10) / 8 = 60.
      expect(viewport.scroll, 60);
      expect(viewport.view, const TimelineView(8, 60));
      expect(viewport.view.x(120), 490); // 10 + (120 - 60) * 8
    });

    test('setZoom keeps the scroll inside the project at either end', () {
      final start = viewportOf()..setZoom(2, anchor: 0);
      expect(start.scroll, 0); // 0 - (10 - 10) / 8
      final end = viewportOf()..setZoom(2, anchor: 240);
      // Frame 240 is at 10 + 240 * 4 = 970; 240 - (970 - 10) / 8 = 120,
      // which is also the furthest scroll: 240 - 240 / 2.
      expect(end.scroll, 120);
    });

    test('setZoom keeps the zoom between 1 and the largest zoom', () {
      final viewport = viewportOf();
      viewport.setZoom(100, anchor: 0);
      expect(viewport.zoom, 16);
      viewport.setZoom(.25, anchor: 0);
      expect(viewport.zoom, 1);
    });

    test('zooming out to 1 brings the scroll back to the start', () {
      final viewport = viewportOf()..setZoom(4, anchor: 120);
      // 16 px per frame: 120 - (490 - 10) / 16 = 90.
      expect(viewport.scroll, 90);
      viewport.setZoom(1, anchor: 120);
      // 120 - (490 - 10) / 4 = 0, and at zoom 1 nothing can be scrolled.
      expect(viewport.scroll, 0);
    });

    test('clampScroll keeps a scroll between the start and the last full '
        'view', () {
      final viewport = viewportOf();
      expect(viewport.clampScroll(50), 0); // zoom 1: 240 - 240 = 0 at most
      viewport.setZoom(4, anchor: 0);
      // Zoom 4 shows 60 frames, so the furthest scroll is 240 - 60 = 180.
      expect(viewport.clampScroll(-5), 0);
      expect(viewport.clampScroll(90), 90);
      expect(viewport.clampScroll(200), 180);
    });

    test('scrollTo scrolls to a frame, kept inside the project', () {
      final viewport = viewportOf()..setZoom(4, anchor: 0);
      viewport.scrollTo(42.5);
      expect(viewport.scroll, 42.5);
      viewport.scrollTo(999);
      expect(viewport.scroll, 180); // 240 - 240 / 4
      viewport.scrollTo(-1);
      expect(viewport.scroll, 0);
    });

    test('scrollBy turns pixels of track into frames', () {
      final viewport = viewportOf()..setZoom(4, anchor: 0);
      viewport.scrollBy(32);
      expect(viewport.scroll, 2); // 32 px / (4 * 4 px per frame)
      viewport.scrollBy(-8);
      expect(viewport.scroll, 1.5); // 2 - 8 / 16
      viewport.scrollBy(-1000);
      expect(viewport.scroll, 0);
    });

    test('follow pages the view along when the frame is off either edge', () {
      final viewport = viewportOf()..setZoom(4, anchor: 0);
      // Frame 100 is at 10 + 100 * 16 = 1610, past the right edge at
      // 984 - 14 = 970. The view moves so the frame is a tenth of the
      // visible 60 frames in: 100 - 60 * 0.1 = 94.
      viewport.follow(100);
      expect(viewport.scroll, 94);
      // Frame 50 is now at 10 + (50 - 94) * 16 = -694, left of the edge:
      // 50 - 6 = 44.
      viewport.follow(50);
      expect(viewport.scroll, 44);
    });

    test('follow leaves the view alone while the frame is in sight', () {
      final viewport = viewportOf()..setZoom(4, anchor: 0);
      viewport.follow(59); // at 10 + 59 * 16 = 954, inside 0..970
      expect(viewport.scroll, 0);
      viewport.follow(60); // at exactly 970, the right edge itself
      expect(viewport.scroll, 0);
      viewport.follow(61); // at 986, off the edge: 61 - 6 = 55
      expect(viewport.scroll, 55);
    });

    test('follow does nothing at zoom 1, where everything is in sight', () {
      final viewport = TimelineViewport(() => 240)
        ..layout(trackWidth: 100, rowsHeight: 100, rows: 1);
      var told = 0;
      viewport.addListener(() => told++);
      viewport.follow(240);
      expect(viewport.scroll, 0);
      expect(told, 0);
    });

    test('scrollRowsBy scrolls freely and the next layout keeps it inside '
        'the rows', () {
      final viewport = viewportOf();
      viewport.scrollRowsBy(500);
      expect(viewport.verticalScroll, 500);
      // 10 rows of 24 px are 240 px high and 100 px show: 140 at most.
      expect(viewport.clampVerticalScroll(10), 140);
      viewport.layout(trackWidth: 984, rowsHeight: 100, rows: 10);
      expect(viewport.verticalScroll, 140);
      viewport.scrollRowsBy(-500);
      viewport.layout(trackWidth: 984, rowsHeight: 100, rows: 10);
      expect(viewport.verticalScroll, 0);
    });

    test('rows that all fit cannot be scrolled', () {
      final viewport = viewportOf(rows: 3)..scrollRowsBy(50);
      // 3 rows are 72 px high, less than the 100 px there is.
      expect(viewport.clampVerticalScroll(3), 0);
    });

    test('layout keeps the scroll inside a project that became shorter', () {
      var frames = 240;
      final viewport = TimelineViewport(() => frames)
        ..layout(trackWidth: 984, rowsHeight: 100, rows: 1)
        ..setZoom(4, anchor: 0)
        ..scrollTo(180);
      frames = 120;
      viewport.layout(trackWidth: 984, rowsHeight: 100, rows: 1);
      expect(viewport.scroll, 90); // 120 - 120 / 4
    });

    test('a gesture tells the listeners once, laying out does not', () {
      final viewport = TimelineViewport(() => 240);
      var told = 0;
      viewport.addListener(() => told++);
      viewport.layout(trackWidth: 984, rowsHeight: 100, rows: 10);
      expect(told, 0);
      viewport.setZoom(4, anchor: 0);
      expect(told, 1);
      viewport.scrollTo(10);
      expect(told, 2);
      viewport.scrollBy(16);
      expect(told, 3);
      viewport.scrollRowsBy(5);
      expect(told, 4);
      viewport.follow(200); // off the right edge
      expect(told, 5);
      viewport.follow(200); // now in sight
      expect(told, 5);
    });
  });
}
