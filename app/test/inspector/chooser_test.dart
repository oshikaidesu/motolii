// Chooser: a long list of options for one value. The value is the option's index, kept once, in numbers (as a segmented
// control keeps it), so a pick is one change and not a word plus a number the two of which must be kept in step. Needs no engine.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/chooser.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';

import '../main_tests_only.dart';

const _options = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta'];

Future<InspectorValues> _show(WidgetTester tester, {double? at}) async {
  final doc = InspectorValues(Kind.shape);
  addTearDown(doc.dispose);
  if (at != null) doc.numbers['v_mode'] = at;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (_, _) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => InspectorScope(
              doc: doc,
              tick: 0,
              // Something under the whole window, as an app's panels are: a press on nothing reaches no region.
              child: const ColoredBox(
                color: Color(0xFF000000),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: Chooser(id: 'v_mode', options: _options),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return doc;
}

void main() {
  if (skipUnlessEveryTest()) return;
  testWidgets('the field shows the option whose index the value holds', (
    tester,
  ) async {
    await _show(tester, at: 2);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('with no value yet, the first option is shown', (tester) async {
    await _show(tester);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets(
    'picking an option writes its index to numbers and no word to strings',
    (tester) async {
      final doc = await _show(tester, at: 0);
      var told = 0;
      doc.addListener(() => told++);
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.text('Delta'));
      await tester.pump();
      expect(doc.numbers['v_mode'], 3);
      expect(doc.strings, isEmpty);
      expect(told, 1);
    },
  );

  // The keys are those of a select in the W3C ARIA Authoring Practices, which every menu and select on macOS and Windows follows.
  testWidgets('the arrow keys move through the open list and Return picks', (
    tester,
  ) async {
    final doc = await _show(tester, at: 0);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(doc.numbers['v_mode'], isNot(0));
    expect(find.text('Zeta'), findsNothing, reason: 'the list closed');
  });

  testWidgets('Esc closes the list and keeps the value', (tester) async {
    final doc = await _show(tester, at: 1);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Zeta'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Zeta'), findsNothing);
    expect(doc.numbers['v_mode'], 1);
  });

  testWidgets('a press outside closes the list', (tester) async {
    await _show(tester, at: 1);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(find.text('Zeta'), findsNothing);
  });
}
