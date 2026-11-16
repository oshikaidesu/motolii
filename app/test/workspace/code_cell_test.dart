// A cell of the Code tab (CodeField.fit), as a page of editors behaves (GitHub's, a notebook's):
// the wheel scrolls the page until a cell's code is pressed, then the code; a press elsewhere gives the wheel back;
// the strip under the code is dragged to make the cell taller, and pressed twice to make it as tall as its code.
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes test/workspace/code_cell_test.dart
import 'dart:io' show Directory, File;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/shelf/code_field.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  late String file;
  setUp(() {
    final dir = Directory.systemTemp.createTempSync('code_cell_test_');
    file = '${dir.path}/long.js';
    File(file).writeAsStringSync(
      [for (var i = 0; i < 60; i++) 'const line$i = $i;'].join('\n'),
    );
  });

  Future<(ScrollController, List<double?>)> page(WidgetTester t) async {
    final outer = ScrollController();
    final heights = <double?>[];
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TapRegionSurface(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              height: 300,
              child: SingleChildScrollView(
                controller: outer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CodeField(
                      file,
                      (_) {},
                      fit: true,
                      height: 120,
                      onHeight: heights.add,
                    ),
                    const SizedBox(key: ValueKey('rest'), height: 600),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    return (outer, heights);
  }

  // code_forge starts work in real time (its highlighter), which a test's own clock never ends; it is given real
  // time to end before the test does, as taking a golden image gives it.
  Future<void> leave(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pump();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  }

  Future<void> wheel(WidgetTester t, Offset at, double by) async {
    final mouse = TestPointer(1, PointerDeviceKind.mouse)..hover(at);
    await t.sendEventToBinding(mouse.scroll(Offset(0, by)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the wheel scrolls the page until the code is pressed', (
    t,
  ) async {
    final (outer, _) = await page(t);
    const inCode = Offset(300, 60), below = Offset(300, 250);
    expect(t.getSize(find.byType(CodeField)).height, greaterThan(120));

    await wheel(t, inCode, 40);
    expect(outer.offset, 40, reason: 'not pressed yet: the page scrolls');

    outer.jumpTo(0);
    await t.pump();
    await t.tapAt(inCode);
    await t.pump(const Duration(milliseconds: 100));
    await wheel(t, inCode, 40);
    expect(outer.offset, 0, reason: 'pressed: the code scrolls, not the page');

    await t.tapAt(below);
    await t.pump(const Duration(milliseconds: 100));
    await wheel(t, inCode, 40);
    expect(outer.offset, 40, reason: 'a press elsewhere gives the wheel back');
    expect(t.takeException(), isNull);
    await leave(t);
  });

  testWidgets('the strip under the code is dragged to size the cell', (
    t,
  ) async {
    final (_, heights) = await page(t);
    final strip = find.byKey(const ValueKey('code-cell-size'));
    expect(strip, findsOneWidget);

    // (the first part of a drag is what tells it from a press, and does not move the cell)
    await t.drag(strip, const Offset(0, 50));
    await t.pump();
    expect(heights.last, closeTo(170, 20));

    await t.tap(strip);
    await t.pump(kDoubleTapMinTime);
    await t.tap(strip);
    await t.pump(const Duration(milliseconds: 400));
    expect(heights.last, isNull, reason: 'pressed twice: as tall as its code');
    expect(t.takeException(), isNull);
    await leave(t);
  });
}
