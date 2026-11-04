import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart';
import 'package:lab_book/sets/inspector/inspector_studies.dart';

/// An effect's knob as the window's card gives it: its slider 0 to 200 (what it vouches for), more taken typed (open).
Future<Doc> mount(WidgetTester tester, {bool card = false}) async {
  final doc = Doc(Kind.shape)..set('a', 80);
  if (card) doc.flag('c.past', true);
  await tester.pumpWidget(WidgetsApp(
    color: const Color(0xFF000000),
    builder: (c, _) => Ctx(
      cfg: const Cfg(mod: ModRule.shiftFine),
      doc: doc,
      child: Overlay.wrap(child: Center(child: SizedBox(width: 160, child: PastRange(flag: 'c.past', child: const NumField(id: 'a', min: 0, max: 200, open: true, perPx: 1))))),
    ),
  ));
  return doc;
}

Future<void> scrub(WidgetTester tester, double dx) async {
  final g = await tester.startGesture(tester.getCenter(find.byType(NumField)));
  for (var i = 0; i < 20; i++) {
    await g.moveBy(Offset(dx / 20, 0));
    await tester.pump();
  }
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a scrub stops at what the effect vouches for; Option held, or its card let past, it goes on', (tester) async {
    var doc = await mount(tester);
    await scrub(tester, 400);
    expect(doc.get('a'), 200);
    expect(find.byType(ColorFiltered), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft, physicalKey: PhysicalKeyboardKey.altLeft);
    await scrub(tester, 400);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft, physicalKey: PhysicalKeyboardKey.altLeft);
    expect(doc.get('a'), greaterThan(400));
    expect(find.byType(ColorFiltered), findsOneWidget, reason: 'past what it vouches for: drawn the other way about');

    await scrub(tester, -2000);
    expect(doc.get('a'), 0, reason: 'a low of 0 is a floor still');

    doc = await mount(tester, card: true);
    await scrub(tester, 400);
    expect(doc.get('a'), greaterThan(400));
  });

  testWidgets('a right click on a number lets its whole card past, and back', (tester) async {
    final doc = await mount(tester);
    final g = await tester.startGesture(tester.getCenter(find.byType(NumField)), buttons: 2);
    await g.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go Past Range Ends'));
    await tester.pumpAndSettle();
    expect(doc.b['c.past'], isTrue);
    final h = await tester.startGesture(tester.getCenter(find.byType(NumField)), buttons: 2);
    await h.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop at Range Ends'));
    await tester.pumpAndSettle();
    expect(doc.b['c.past'], isFalse);
  });

  testWidgets('Cmd and Ctrl are one key: ten times, as Live\'s manual pairs them', (tester) async {
    const cfg = Cfg(mod: ModRule.shiftFine);
    expect(cfg.mult(), 1);
    for (final (l, p) in [(LogicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaLeft), (LogicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlLeft)]) {
      await tester.sendKeyDownEvent(l, physicalKey: p);
      expect(cfg.mult(), 10, reason: '$l');
      await tester.sendKeyUpEvent(l, physicalKey: p);
    }
  });
}
