// A button with only a mark on it names itself when the pointer rests on it (UAT 139, 411), as the buttons of macOS and Windows do.
// Needs no engine.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/widgets/controls.dart';

Widget _window(Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (_, _) => Overlay(
    initialEntries: [OverlayEntry(builder: (_) => Center(child: child))],
  ),
);

void main() {
  testWidgets(
    'resting on a button shows its name and its key, and leaving hides them',
    (tester) async {
      await tester.pumpWidget(
        _window(
          IconPress(
            (_) => const SizedBox(width: 10, height: 10),
            onTap: () {},
            tip: 'Play',
            keys: 'Space',
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(IconPress)));
      await tester.pump();
      expect(find.text('Play'), findsNothing, reason: 'not at once');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Play'), findsNothing);
    },
  );

  testWidgets('a button given no name shows nothing', (tester) async {
    await tester.pumpWidget(
      _window(IconPress((_) => const SizedBox(width: 10, height: 10))),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(IconPress)));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('tip')), findsNothing);
  });
}
