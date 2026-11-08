// A group's Copies card on the real window (docs/notes/GROUP_FOCUS_new.md, インスペクターと TL ビューの分担, 11/8): there
// from ⌘G with How many (as many as it holds) and the things it holds listed, each with its picture and its ratio; no
// picture of the copies, and no lay card unasked.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart' show CopiesDrawing;
import 'package:lab_book/workspace/desk_kit.dart' show DeskScrub;
import 'package:lab_book/workspace/timeline_paint.dart' show WtThumb;
import 'package:lab_book/workspace/workspace.dart' show WsGroupCopies;

import 'door.dart';

void main() {
  testWidgets('a group: Copies with its count and its things listed, the lay only when asked', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final circles = [for (var i = 0; i < 3; i++) m.add('shape', 'circle')];
    for (final (i, c) in circles.indexed) {
      expect(m.set(c, 'x', -.4 + .4 * i), isTrue, reason: m.trouble);
    }
    final group = m.add('shape', 'null');
    for (final c in circles) {
      expect(m.set(c, 'parent', group.toDouble()), isTrue, reason: m.trouble);
    }
    expect(m.set(group, 'copies', 3), isTrue, reason: m.trouble);   // (as ⌘G sets it: as many as it holds)
    ws
      ..reread()
      ..select('$group');
    await t.pumpAndSettle();
    List<String> titles() => [for (final (title, _) in m.cards(group)) title];
    expect(titles(), contains('Copies'), reason: 'there from when the group is made');
    expect(titles(), isNot(contains('Arrange')), reason: 'where the copies go is no card of the group unasked');

    final card = find.byType(WsGroupCopies);
    await seen(t, card);
    expect(card, findsOneWidget, reason: 'the window\'s own card for a group');
    expect(find.descendant(of: card, matching: find.byType(CopiesDrawing)), findsNothing, reason: 'no picture of the copies (the user, 11/8)');
    expect(find.descendant(of: card, matching: find.byType(WtThumb)), findsNWidgets(3), reason: 'each thing with its picture, the timeline\'s');
    expect(find.descendant(of: card, matching: find.byType(DeskScrub)), findsNWidgets(3), reason: 'each with its ratio');
    expect(find.descendant(of: card, matching: find.text('×1')), findsNWidgets(3), reason: 'one of a turn each, as it comes');

    // (the count raised past the things: still nothing more on the card)
    expect(m.set(group, 'copies', 8), isTrue, reason: m.trouble);
    ws.reread();
    await t.pumpAndSettle();
    expect(titles(), isNot(contains('Arrange')), reason: 'a count past the things brings no lay of itself');

    // (a ratio said: the card shows it)
    expect(m.set(circles[0], 'ratio', 2), isTrue, reason: m.trouble);
    ws.reread();
    await t.pumpAndSettle();
    expect(find.descendant(of: card, matching: find.text('×2')), findsOneWidget, reason: 'the first takes two of a turn');
    expect(t.takeException(), isNull);
    await closeWorkspace(t);
  });
}
