// ModalCard and ChipGroup: the dialog over the window that the size box and the render box are made of. A press on the dimmed scrim
// closes it, the card shows its title and what it holds, and a group of chips shows its label above them. Needs no engine.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/widgets/modal_card.dart';

import '../main_tests_only.dart';

Widget _around(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox(width: 800, height: 600, child: child),
);

void main() {
  if (skipUnlessEveryTest()) return;
  testWidgets('the card shows its title and what it holds', (tester) async {
    await tester.pumpWidget(
      _around(
        ModalCard(
          title: 'Document',
          onClose: () {},
          cardKey: const ValueKey('card'),
          children: const [Text('inside')],
        ),
      ),
    );
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('inside'), findsOneWidget);
    expect(find.byKey(const ValueKey('card')), findsOneWidget);
  });

  testWidgets('a press on the scrim closes it, a press on the card does not', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      _around(
        ModalCard(
          title: 'Render',
          onClose: () => closed++,
          children: const [Text('inside')],
        ),
      ),
    );
    await tester.tapAt(const Offset(5, 5));
    expect(closed, 1);
    await tester.tap(find.text('inside'));
    expect(closed, 1);
  });

  testWidgets('a group puts its label above its chips', (tester) async {
    await tester.pumpWidget(
      _around(const ChipGroup('Shape', [Text('16:9'), Text('9:16')])),
    );
    expect(find.text('Shape'), findsOneWidget);
    final label = tester.getTopLeft(find.text('Shape')).dy;
    expect(tester.getTopLeft(find.text('16:9')).dy, greaterThan(label));
    expect(find.text('9:16'), findsOneWidget);
  });
}
