// The right-click menu behaves as the menus of macOS and Windows do (UAT 152-162), the same on every system.
// The expected behaviour comes from those systems' menus, not from this code. Needs no engine.
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/widgets/context_menu.dart';

final _menu = GlobalKey<ContextMenuState>();
final _ran = <String>[];
var _under = 0;

// A window with a button under the menu's area and a long list that scrolls.
Widget _window() => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (_, _) =>
      Overlay(initialEntries: [OverlayEntry(builder: (_) => _content())]),
);

Widget _content() => ContextMenu(
  key: _menu,
  child: Stack(
    children: [
      Positioned(
        left: 600,
        top: 400,
        width: 100,
        height: 100,
        child: GestureDetector(
          key: const ValueKey('under'),
          onTap: () => _under++,
          onSecondaryTapDown: (d) => _open(const Offset(620, 420)),
          child: const ColoredBox(color: Color(0xFF333333)),
        ),
      ),
      Positioned(
        left: 0,
        top: 400,
        width: 100,
        height: 100,
        child: ListView(
          key: const ValueKey('list'),
          children: [for (var i = 0; i < 40; i++) SizedBox(height: 30)],
        ),
      ),
    ],
  ),
);

void _open(Offset at) => _menu.currentState!.show(at, [
  ContextMenuItem('One', () => _ran.add('One')),
  ContextMenuItem('Two', () => _ran.add('Two')),
  ContextMenuItem('Three', () => _ran.add('Three')),
]);

Finder _row(String label) => find.byKey(ValueKey('ws-menu-$label'));

void main() {
  setUp(() {
    _ran.clear();
    _under = 0;
  });

  testWidgets('152 153: a press outside closes it and does nothing else', (
    tester,
  ) async {
    await tester.pumpWidget(_window());
    _open(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(_row('One'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('under')));
    await tester.pumpAndSettle();
    expect(_row('One'), findsNothing);
    expect(_under, 0, reason: 'the closing press must not reach the button');
  });

  testWidgets('155: the arrow keys move between rows and Return runs one', (
    tester,
  ) async {
    await tester.pumpWidget(_window());
    _open(const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_ran, ['Two']);
    expect(_row('One'), findsNothing);
  });

  testWidgets('159: a right-click elsewhere opens the menu there instead', (
    tester,
  ) async {
    await tester.pumpWidget(_window());
    _open(const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('under')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(_row('One'), findsOneWidget);
    // At the new place, pushed inside the window's right edge (156).
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('ws-menu'))).dx,
      greaterThan(500),
    );
  });

  testWidgets('160: a right press held and let go over a row runs it', (
    tester,
  ) async {
    await tester.pumpWidget(_window());
    final hand = await tester.startGesture(
      const Offset(620, 420),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(_row('One'), findsOneWidget);
    await hand.moveTo(tester.getCenter(_row('Three')));
    await tester.pump();
    await hand.up();
    await tester.pumpAndSettle();
    expect(_ran, ['Three']);
  });

  testWidgets('160: a plain right-click leaves it open', (tester) async {
    await tester.pumpWidget(_window());
    await tester.tap(
      find.byKey(const ValueKey('under')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(_row('One'), findsOneWidget);
    expect(_ran, isEmpty);
  });

  testWidgets('161: scrolling what it was opened on closes it', (tester) async {
    await tester.pumpWidget(_window());
    _open(const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('list')), const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(_row('One'), findsNothing);
  });

  testWidgets('161: the window going to the back closes it', (tester) async {
    await tester.pumpWidget(_window());
    _open(const Offset(100, 100));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(_row('One'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
