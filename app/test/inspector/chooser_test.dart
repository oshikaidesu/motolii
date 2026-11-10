// Chooser: a long list of options for one value. The value is the option's index, kept once, in numbers (as a segmented
// control keeps it), so a pick is one change and not a word plus a number the two of which must be kept in step. Needs no engine.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/chooser.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';

const _options = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta'];

Future<InspectorValues> _show(WidgetTester tester, {double? at}) async {
  final doc = InspectorValues(Kind.shape);
  addTearDown(doc.dispose);
  if (at != null) doc.numbers['v_mode'] = at;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => InspectorScope(
              doc: doc,
              tick: 0,
              child: const Center(
                child: SizedBox(
                  width: 200,
                  child: Chooser(id: 'v_mode', options: _options),
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
}
