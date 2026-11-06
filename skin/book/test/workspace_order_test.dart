// The order's figure on the Relation card (lib/sets/inspector/inspector_order.dart), driven as a hand would drive it on
// the window joined to the real inside: a group made of things picked together (Cmd+G), a split text and copies alike
// show it; a press, or a hand drawn across, puts the place it starts from, anywhere, caught by a member near it, one step
// each; counted in their order the place is a member's; a way chosen while they move together gives them a spread; the
// order's name read off what it is (reports/group_relation_guide.md). Where the inside is not built the window part is
// skipped.
import 'dart:io';
import 'dart:ui' as ui show ImageByteFormat;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/motolii.dart';
import 'package:lab_book/parts/controls.dart' show Segmented;
import 'package:lab_book/sets/inspector/inspector_parts.dart' show Ctx, OrderDrawing, OrderFigure;

import 'door.dart';

// (SHOT=folder: the window as it is then, written there, for an eye to look at: flutter test --dart-define=SHOT=...)
Future<void> _shot(WidgetTester t, String name) async {
  const folder = String.fromEnvironment('SHOT');
  if (folder.isEmpty) return;
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));   // (the figure's own asking answered and drawn)
  await t.pump();
  final root = t.binding.renderViews.first.layer! as OffsetLayer, size = t.view.physicalSize / t.view.devicePixelRatio;
  final png = await t.runAsync(() async => (await root.toImage(Offset.zero & size, pixelRatio: t.view.devicePixelRatio)).toByteData(format: ui.ImageByteFormat.png));
  File('$folder/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  final box = t.getRect(find.byType(OrderDrawing));
  File('$folder/$name.txt').writeAsStringSync('${box.left} ${box.top} ${box.width} ${box.height} ${t.view.devicePixelRatio}');
}

// (the members as the inside reads them: asked as the figure asks, off the window's thread)
Future<List<double>> _members(WidgetTester t, Finder fig) async => (await t.runAsync(() => Ctx.read(t.element(fig)).doc.onMembers!()))!;

void main() {
  test('depth is drawn up and to the right: a row going deeper stays a row, and fits', () {
    final f = OrderFigure(const [0, 0, 0, 0, 0, 0, -1, 0, 0, 0, -2, 0], const Size(300, 72));
    expect([f.at(0).dx < f.at(1).dx && f.at(1).dx < f.at(2).dx, f.at(0).dy > f.at(1).dy && f.at(1).dy > f.at(2).dy, f.deep], [true, true, true]);
    for (var i = 0; i < 3; i++) {
      expect(f.area.inflate(.01).contains(f.at(i)) && f.at(i).dx > OrderFigure.words, isTrue, reason: 'right of the words, inside');
    }
    expect([OrderFigure([for (var i = 0; i < 100; i++) ...[i.toDouble(), 0, 0, 0]], const Size(300, 72)).dot, OrderFigure(const [0, 0, 0, 0, 1, 0, 0, 0], const Size(300, 72)).dot], [1.5, 4], reason: 'a hundred in a row as small as they go; two, as large');
  });

  test('the place is put anywhere, caught by a member or the middle near it; the name is read off the order, as the Anchor\'s is', () {
    final row = [for (var i = 0; i < 5; i++) ...[i * .2 - .4, 0.0, 0.0, 0.0]];
    final f = OrderFigure(row, const Size(320, 72));
    expect(f.placeAt(f.at(3) + const Offset(3, 2)), (row[12], 0.0, 0.0), reason: 'near a member: its place');
    final free = f.placeAt((f.at(0) + f.at(1)) / 2)!;
    expect([free.$1, free.$2, free.$3], [closeTo(-.3, 1e-6), closeTo(0, 1e-6), 0], reason: 'between two: the place between, not a member');
    expect(f.placeAt(f.at(2) + const Offset(0, 20))!.$2, closeTo(-20 / ((f.at(1) - f.at(0)).dx / .2), 1e-6), reason: 'off the row: off it, as far');
    expect([
      f.name('order', const [0, .25, .5, .75, 1], 1, (0, 0, 0)),
      f.name('order', const [0, .5, 1, .5, 0], -1, (0, 0, 0)),
      f.name('order', const [0, .5, 1, .5, 0], 1, (0, 0, 0)),
      f.name('order', const [.75, .5, .25, 0, .25], 1, (0, 0, 0)),
      f.name('place', const [.5, .25, 0, .25, .5], 1, f.middle),
      f.name('place', const [.1, .1, .3, .5, .7], 1, (-.3, 0, 0)),
      f.name('place', const [0, .2, .4, .6, .8], -1, (row[0], 0, 0)),
      f.name('order', const [0, 0, 0, 0, 0], 0, (0, 0, 0)),
    ], ['From the first', 'Toward the middle', 'From the ends', 'From this one', 'From the middle', 'From here', 'Toward the first', 'Together']);
  });

  // (the window's reading of the document after a hand: what it said asked of the inside, without the window waiting)
  Future<void> after(WidgetTester t, Ws ws) async {
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settled(t, ws);
    ws.reread();
    await settled(t, ws);
  }

  Future<void> hand(WidgetTester t, Ws ws, List<Offset> path) async {
    final g = await t.startGesture(path.first, kind: PointerDeviceKind.mouse);
    for (final p in path.skip(1)) {
      await g.moveTo(p);
    }
    await g.up();
    await after(t, ws);
  }

  testWidgets('a split text: its Relation card draws its letters, always as high; a press puts the place there, caught by a letter, a hand drawn across where it is let go, one step each, between two both first; counted in their order the place is a letter\'s; a way chosen while they move together gives them a spread', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final text = m.add('text', '$motoliiDir/out/arial_black.ttf');
    expect([m.say(text, 'text', 'MOTOLII'), m.say(text, 'split', 'letters')], [true, true], reason: m.trouble);
    ws
      ..reread()
      ..select('$text');
    await settled(t, ws);
    final fig = find.byType(OrderDrawing);
    await seen(t, fig);
    expect(fig, findsOneWidget, reason: 'a split text has its order on its Relation card');
    expect([for (final c in m.cards(text)) c.$1].take(2), ['Transform', 'Relation'], reason: 'right under the moves it orders');
    expect([for (final c in m.cards(text)) c.$1], isNot(contains('Copies')), reason: 'letters are not copies');
    expect(t.getRect(fig).height, closeTo(OrderDrawing.high + 6, 1), reason: 'as high as it ever is, no hand over it');
    var laid = await _members(t, fig);
    Offset at(int i) {
      final box = t.getRect(fig);
      return box.topLeft + OrderFigure(laid, Size(box.width, OrderDrawing.high)).at(i);
    }
    Future<List<double>> members() async => laid = await _members(t, fig);
    String from() => m.word(text, 'stagger_from');
    double stagger() => m.value(text, 'stagger', 0) ?? -1;
    expect(laid.length ~/ 4, 7, reason: 'MOTOLII: seven letters');

    await hand(t, ws, [at(3)]);
    final middle = await members();
    expect([from(), m.value(text, 'stagger_x', 0), stagger(), middle[4 * 3 + 3]], ['place', closeTo(middle[4 * 3], 1e-6), .5, 0], reason: 'from the letter pressed, by place, given half a second as they moved together and nothing is keyed');
    await _shot(t, 'letters_middle');

    await hand(t, ws, [at(1), (at(1) + at(5)) / 2, at(5)]);
    final five = await members();
    expect([from(), m.value(text, 'stagger_x', 0), five[4 * 5 + 3]], ['place', closeTo(five[4 * 5], 1e-6), 0], reason: 'drawn across: from the one let go over');
    expect(m.undo(), isTrue);
    ws.reread();
    await settled(t, ws);
    expect(m.value(text, 'stagger_x', 0), closeTo(middle[4 * 3], 1e-6), reason: 'drawn across them is one step');

    await members();
    await hand(t, ws, [(at(1) + at(2)) / 2]);
    final between = await members();
    expect([m.value(text, 'stagger_x', 0), between[4 * 1 + 3], between[4 * 2 + 3]], [closeTo((between[4] + between[8]) / 2, 1e-3), closeTo(0, 1e-9), closeTo(0, 1e-9)], reason: 'put between two letters, not on one: both first');
    await _shot(t, 'letters_between');

    final doc0 = Ctx.read(t.element(fig)).doc;
    doc0.s2['v_stagger_from'] = 'order';   // (as the By chooser says a word)
    doc0.set('v_stagger_from', 0);
    await after(t, ws);
    await members();
    await hand(t, ws, [at(4) + const Offset(0, 14)]);
    final counted = await members();
    expect([from(), m.value(text, 'stagger_x', 0), counted[4 * 4 + 3]], ['order', closeTo(counted[4 * 4], 1e-6), 0], reason: 'counted in their order: the place is the letter nearest, from it');

    expect(m.set(text, 'stagger', 0), isTrue);
    expect(m.set(text, 'y', 0) && m.key(text, 'y', 0, .3) && m.key(text, 'y', .8, 0), isTrue, reason: m.trouble);
    ws.reread();
    await after(t, ws);
    final doc = Ctx.read(t.element(fig)).doc;
    doc.s2['v_stagger_from'] = 'random';   // (as the By chooser says a word)
    doc.set('v_stagger_from', 2);
    await after(t, ws);
    expect([from(), stagger()], ['random', closeTo(.8, 1e-6)], reason: 'a way chosen while they moved together: spread over as long as its keys run');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  }, skip: !insideBuilt);

  testWidgets('things picked together and grouped (Cmd+G): the group shows a Relation card, its things drawn where they lie; a press on the left one: it moves first, the right one last', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final right = m.add('shape', 'rect'), left = m.add('shape', 'circle'), middle = m.add('shape', 'star');
    for (final (s, x) in [(right, .6), (left, -.6), (middle, 0.0)]) {
      expect(m.set(s, 'size', .1) && m.set(s, 'x', x), isTrue, reason: m.trouble);
    }
    ws
      ..reread()
      ..pickMany(['$right', '$left', '$middle']);
    await settled(t, ws);
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyG);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await settled(t, ws);
    final g = int.parse(ws.selected!);
    expect([m.word(g, 'shape'), for (final s in [right, left, middle]) m.value(s, 'parent', 0)], ['null', g, g, g], reason: m.trouble);
    expect([for (final c in m.cards(g)) c.$1].take(2), ['Transform', 'Relation'], reason: 'a group of things has the relation a split text has');
    final fig = find.byType(OrderDrawing);
    await seen(t, fig);
    final laid = await _members(t, fig);
    expect([for (var i = 0; i < laid.length; i += 4) laid[i]], [closeTo(-.6, 1e-6), closeTo(0, 1e-6), closeTo(.6, 1e-6)], reason: 'read where they lie, left to right, though made right first');
    final box = t.getRect(fig), f = OrderFigure(laid, Size(box.width, OrderDrawing.high));
    expect(f.at(0).dx < f.at(1).dx && f.at(1).dx < f.at(2).dx, isTrue, reason: 'drawn where they lie');
    final press = await t.startGesture(box.topLeft + f.at(0), kind: PointerDeviceKind.mouse);   // (as a hand on the real window: nothing read again by hand after it)
    await press.up();
    for (var i = 0; i < 15; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
    final shown0 = Ctx.read(t.element(fig)).doc;
    final by = t.widget<Segmented>(find.descendant(of: find.byKey(const ValueKey('choice:v_stagger_from')), matching: find.byType(Segmented)));
    expect([m.word(g, 'stagger_from'), shown0.s2['v_stagger_from'], shown0.get('v_stagger_from'), by.items[by.index]], ['place', 'place', 1, 'place'], reason: 'the By row lights what the document says (golf 3, player 2: ORDER stayed lit after the first press gave a place)');
    await after(t, ws);
    final now = await _members(t, fig);
    await _shot(t, 'group_left');
    expect([m.word(g, 'stagger_from'), now[3], now[4 + 3] < now[8 + 3], now[8 + 3] > 0], ['place', 0, true, true], reason: 'from the left one: it first, the right one last');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  }, skip: !insideBuilt);

  testWidgets('in depth: ten copies going right and deeper, already in order, a press on the far one: counted from it, the place where it lies, depth too, the far ones first', (t) async {
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
    final box = t.getRect(fig), f = OrderFigure(await _members(t, fig), Size(box.width, OrderDrawing.high));
    expect(f.at(9).dy < f.at(0).dy, isTrue, reason: 'the deeper ones drawn higher');
    await hand(t, ws, [box.topLeft + f.at(9)]);
    final laid = await _members(t, fig);
    await _shot(t, 'deep_far');
    expect([m.word(rect, 'stagger_from'), m.value(rect, 'stagger_z', 0)], [isIn(['', 'order']), closeTo(laid[4 * 9 + 2], 1e-6)], reason: 'an order given before, in their order: the place is the member\'s, depth and all');
    expect([for (var i = 0; i < 10; i++) laid[4 * i + 3]], orderedEquals([for (var i = 0; i < 10; i++) laid[4 * i + 3]]..sort((a, b) => b.compareTo(a))), reason: 'the further the later... from the far end: the near ones last');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  }, skip: !insideBuilt);
}
