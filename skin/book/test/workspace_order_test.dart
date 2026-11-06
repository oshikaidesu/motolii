// The order's figure on the Copies card (lib/sets/inspector/inspector_order.dart), driven as a hand would drive it on
// the window joined to the real inside: a swipe, a press, a pull of the cross, a shake, a double press each says its
// order to the document, one step each (docs/notes/GROUP_INSPECTOR.md §7). Where the inside is not built the window
// part is skipped.
import 'dart:io';
import 'dart:ui' as ui show ImageByteFormat;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/motolii.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart' show Ctx, OrderDrawing, OrderFigure, OrderTouch, orderSwiped, orderTouch;

import 'door.dart';

// (SHOT=folder: the window as it is then, written there, for an eye to look at: flutter test --dart-define=SHOT=...)
Future<void> _shot(WidgetTester t, String name) async {
  const folder = String.fromEnvironment('SHOT');
  if (folder.isEmpty) return;
  final root = t.binding.renderViews.first.layer! as OffsetLayer, size = t.view.physicalSize / t.view.devicePixelRatio;
  final png = await t.runAsync(() async => (await root.toImage(Offset.zero & size, pixelRatio: t.view.devicePixelRatio)).toByteData(format: ui.ImageByteFormat.png));
  File('$folder/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  final box = t.getRect(find.byType(OrderDrawing));
  File('$folder/$name.txt').writeAsStringSync('${box.left} ${box.top} ${box.width} ${box.height} ${t.view.devicePixelRatio}');
}

// (the members as the inside reads them: asked as the figure asks, off the window's thread)
Future<List<double>> _members(WidgetTester t, Finder fig) async => (await t.runAsync(() => Ctx.read(t.element(fig)).doc.onMembers!()))!;

// (a hand over the figure, left there: it opens, as it does under a hand)
Future<void> _over(WidgetTester t, Finder fig) async {
  final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: t.getRect(fig).centerLeft + const Offset(4, 0));
  await t.pump();
  await t.pump(const Duration(milliseconds: 200));
}

void main() {
  test('a swipe says its order by where it begins and where it ends', () {
    expect([orderSwiped(0, 6, 7), orderSwiped(6, 0, 7), orderSwiped(3, 6, 7), orderSwiped(3, 0, 7), orderSwiped(0, 3, 7), orderSwiped(6, 3, 7)], ['start', 'end', 'centre', 'centre', 'edges', 'edges']);
    expect([orderSwiped(0, 1, 2), orderSwiped(1, 0, 2)], ['start', 'end'], reason: 'two: no middle to begin in');
    expect([orderSwiped(2, 6, 7), orderSwiped(4, 0, 7), orderSwiped(0, 2, 7)], ['start', 'end', 'start'], reason: 'begun or ended beside the middle: its way along them');
    expect([orderSwiped(4, 9, 10), orderSwiped(5, 0, 10), orderSwiped(0, 9, 10)], ['centre', 'centre', 'start'], reason: 'ten: the middle two');
  });

  test('a press hardly moves, a swipe goes, a shake turns three times', () {
    expect(orderTouch(const [Offset(10, 10), Offset(12, 11)]), OrderTouch.press);
    expect(orderTouch(const [Offset(10, 10), Offset(60, 12)]), OrderTouch.swipe);
    expect(orderTouch(const [Offset(50, 10), Offset(70, 10), Offset(50, 10), Offset(70, 10), Offset(50, 10)]), OrderTouch.shake);
    expect(orderTouch(const [Offset(50, 10), Offset(52, 10), Offset(50, 10), Offset(52, 10), Offset(50, 10)]), OrderTouch.press, reason: 'a hand trembling is no shake');
    expect(orderTouch(const [Offset(0, 10), Offset(20, 10), Offset(19, 10), Offset(40, 10), Offset(39, 10), Offset(60, 10), Offset(59, 10)]), OrderTouch.swipe, reason: 'a swipe trembling on its way is no shake');
    expect(orderTouch(const [Offset(50, 10), Offset(50, 30), Offset(50, 10), Offset(50, 30), Offset(50, 10)]), OrderTouch.shake, reason: 'up and down too');
  });

  test('depth is drawn up and to the right: a row going deeper stays a row, and fits', () {
    final f = OrderFigure(const [0, 0, 0, 0, 0, 0, -1, 0, 0, 0, -2, 0], const Size(300, 72));
    expect([f.at(0).dx < f.at(1).dx && f.at(1).dx < f.at(2).dx, f.at(0).dy > f.at(1).dy && f.at(1).dy > f.at(2).dy, f.deep], [true, true, true]);
    for (var i = 0; i < 3; i++) {
      expect(f.area.inflate(.01).contains(f.at(i)) && f.at(i).dx > OrderFigure.words, isTrue, reason: 'right of the words, inside');
    }
    expect([OrderFigure([for (var i = 0; i < 100; i++) ...[i.toDouble(), 0, 0, 0]], const Size(300, 72)).dot, OrderFigure(const [0, 0, 0, 0, 1, 0, 0, 0], const Size(300, 72)).dot], [1.5, 4], reason: 'a hundred in a row as small as they go; two, as large');
  });

  testWidgets('the order figure: a swipe from the middle out, then back from the end; a press on a letter and its cross pulled to another; a shake, again; a double press all together; each one step', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final text = m.add('text', '$motoliiDir/out/arial_black.ttf');
    expect([m.say(text, 'text', 'MOTOLII'), m.say(text, 'split', 'letters')], [true, true], reason: m.trouble);
    ws
      ..reread()
      ..select('$text');
    await settled(t, ws);
    final fig = find.byType(OrderDrawing);
    await seen(t, fig);
    expect(fig, findsOneWidget, reason: 'a split text has its order on its Copies card');
    expect(t.getRect(fig).height, closeTo(OrderDrawing.low + 6, 1), reason: 'low until a hand comes over it');
    await _over(t, fig);
    expect(t.getRect(fig).height, closeTo(OrderDrawing.high + 6, 1), reason: 'opened under the hand');
    var laid = await _members(t, fig);
    Offset at(int i) {
      final box = t.getRect(fig);
      return box.topLeft + OrderFigure(laid, Size(box.width, OrderDrawing.high)).at(i);
    }
    Future<List<double>> members() async => laid = await _members(t, fig);

    Future<void> hand(List<Offset> path) async {
      final g = await t.startGesture(path.first, kind: PointerDeviceKind.mouse);
      for (final p in path.skip(1)) {
        await g.moveTo(p);
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 400));   // (a press waits for a second before it is one)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));   // (what it said asked of the inside, without the window waiting: let it be asked)
      await settled(t, ws);
      ws.reread();   // (the window's reading of the document, after the inside has taken it)
      await settled(t, ws);
    }

    String from() => m.word(text, 'stagger_from');
    double stagger() => m.value(text, 'stagger', 0) ?? -1;
    expect(laid.length ~/ 4, 7, reason: 'MOTOLII: seven letters');

    await hand([at(3), (at(3) + at(5)) / 2, at(5), at(6)]);
    expect([from(), stagger()], ['centre', .5], reason: 'from the middle out, given half a second as they moved together');
    final early = await members();
    await _shot(t, 'letters_centre');
    expect(early[4 * 3 + 3], 0, reason: 'the middle letter first');

    await hand([at(6), at(3), at(0)]);
    expect(from(), 'end');
    expect(m.undo(), isTrue);
    ws.reread();
    await settled(t, ws);
    expect(from(), 'centre', reason: 'a swipe is one step');

    await hand([at(1)]);
    final one = await members();
    expect([from(), m.value(text, 'stagger_x', 0), one[4 * 1 + 3]], ['point', closeTo(one[4], 1e-6), 0], reason: 'from the letter pressed');
    await hand([at(1), (at(1) + at(5)) / 2, at(5)]);
    final five = await members();
    expect([from(), m.value(text, 'stagger_x', 0), five[4 * 5 + 3]], ['point', closeTo(five[4 * 5], 1e-6), 0], reason: 'its cross pulled to another letter');

    final c = at(3);
    await hand([c, c + const Offset(24, 0), c, c + const Offset(24, 0), c, c + const Offset(24, 0), c]);
    expect(from(), 'random');
    final seed = m.value(text, 'seed', 0) ?? 0;
    await hand([c, c + const Offset(24, 0), c, c + const Offset(24, 0), c, c + const Offset(24, 0), c]);
    expect([from(), m.value(text, 'seed', 0)], ['random', seed + 1], reason: 'shaken again: another order');

    final g = await t.startGesture(at(2), kind: PointerDeviceKind.mouse);
    await g.up();
    await t.pump(const Duration(milliseconds: 100));
    await hand([at(2)]);
    expect(stagger(), 0, reason: 'a double press: all together');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  }, skip: !insideBuilt);

  testWidgets('in depth: ten copies going right and deeper, a press on the far one: the point is where that one lies, depth too, and the far ones move first', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final rect = m.add('shape', 'rect');
    expect(m.say(rect, 'space', '3d'), isTrue, reason: m.trouble);
    for (final (n, v) in const [('size', .06), ('copies', 10.0), ('copy_x', .09), ('copy_z', -.15), ('stagger', 1.0)]) {
      expect(m.set(rect, n, v), isTrue, reason: m.trouble);
    }
    ws
      ..reread()
      ..select('$rect');
    await settled(t, ws);
    final fig = find.byType(OrderDrawing);
    await seen(t, fig);
    await _over(t, fig);
    final box = t.getRect(fig), f = OrderFigure(await _members(t, fig), Size(box.width, OrderDrawing.high));
    expect(f.at(9).dy < f.at(0).dy, isTrue, reason: 'the deeper ones drawn higher');
    final g = await t.startGesture(box.topLeft + f.at(9), kind: PointerDeviceKind.mouse);
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    await settled(t, ws);
    final laid = await _members(t, fig);
    await _shot(t, 'deep_far');
    expect([m.word(rect, 'stagger_from'), m.value(rect, 'stagger_z', 0)], ['point', closeTo(laid[4 * 9 + 2], 1e-6)]);
    expect([for (var i = 0; i < 10; i++) laid[4 * i + 3]], orderedEquals([for (var i = 0; i < 10; i++) laid[4 * i + 3]]..sort((a, b) => b.compareTo(a))), reason: 'the further the later... from the far end: the near ones last');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  }, skip: !insideBuilt);
}
