import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/widgets/picks.dart';

const order = ['a', 'b', 'c', 'd', 'e'];

void main() {
  group('plain click', () {
    test('replaces the selection with the clicked item', () {
      final r = pickOnClick(now: {'a', 'b'}, lead: 'a', id: 'd', order: order);
      expect(r.picked.toList(), ['d']);
    });

    test('the clicked item becomes the lead', () {
      final r = pickOnClick(now: {'a', 'b'}, lead: 'a', id: 'd', order: order);
      expect(r.lead, 'd');
    });

    test('clicking from an empty selection picks only the item', () {
      final r = pickOnClick<String>(now: {}, lead: null, id: 'c');
      expect(r.picked.toList(), ['c']);
      expect(r.lead, 'c');
    });

    test('clicking the only picked item keeps it picked', () {
      final r = pickOnClick(now: {'b'}, lead: 'b', id: 'b', order: order);
      expect(r.picked.toList(), ['b']);
      expect(r.lead, 'b');
    });

    test('works without an order', () {
      final r = pickOnClick(now: {'a', 'b'}, lead: 'a', id: 'c');
      expect(r.picked.toList(), ['c']);
      expect(r.lead, 'c');
    });
  });

  group('add', () {
    test('adds an item that was not picked', () {
      final r = pickOnClick(now: {'a'}, lead: 'a', id: 'c', add: true);
      expect(r.picked.toList(), ['a', 'c']);
    });

    test('an added item becomes the lead', () {
      final r = pickOnClick(now: {'a'}, lead: 'a', id: 'c', add: true);
      expect(r.lead, 'c');
    });

    test('adds to an empty selection', () {
      final r = pickOnClick<String>(now: {}, lead: null, id: 'c', add: true);
      expect(r.picked.toList(), ['c']);
      expect(r.lead, 'c');
    });

    test('removes an item that was picked', () {
      final r = pickOnClick(
        now: {'a', 'b', 'c'},
        lead: 'c',
        id: 'b',
        add: true,
      );
      expect(r.picked.toList(), ['a', 'c']);
    });

    test('removing a non-lead item leaves the lead where it was', () {
      final r = pickOnClick(
        now: {'a', 'b', 'c'},
        lead: 'c',
        id: 'b',
        add: true,
      );
      expect(r.lead, 'c');
    });

    test('removing the lead makes the last item still picked the lead', () {
      final r = pickOnClick(
        now: {'a', 'b', 'c'},
        lead: 'b',
        id: 'b',
        add: true,
      );
      expect(r.picked.toList(), ['a', 'c']);
      expect(r.lead, 'c');
    });

    test(
      'removing the lead picks the last in pick order, not reading order',
      () {
        final r = pickOnClick(
          now: {'d', 'a', 'c'},
          lead: 'c',
          id: 'c',
          order: order,
          add: true,
        );
        expect(r.picked.toList(), ['d', 'a']);
        expect(r.lead, 'a');
      },
    );

    test('removing the last picked item leaves a null lead', () {
      final r = pickOnClick(now: {'a'}, lead: 'a', id: 'a', add: true);
      expect(r.picked, isEmpty);
      expect(r.lead, isNull);
    });

    test('adding keeps pick order, new item last', () {
      final r = pickOnClick(
        now: {'d', 'a'},
        lead: 'a',
        id: 'b',
        order: order,
        add: true,
      );
      expect(r.picked.toList(), ['d', 'a', 'b']);
    });
  });

  group('span', () {
    test('takes the range from the lead to the id, both ends included', () {
      final r = pickOnClick(
        now: {'b'},
        lead: 'b',
        id: 'd',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['b', 'c', 'd']);
    });

    test('lists from the lead toward the id going forward', () {
      final r = pickOnClick(
        now: {'a'},
        lead: 'a',
        id: 'c',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['a', 'b', 'c']);
    });

    test('lists from the lead toward the id going backward', () {
      final r = pickOnClick(
        now: {'d'},
        lead: 'd',
        id: 'b',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['d', 'c', 'b']);
    });

    test('replaces the selection', () {
      final r = pickOnClick(
        now: {'a', 'e', 'b'},
        lead: 'b',
        id: 'c',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['b', 'c']);
    });

    test('keeps the lead', () {
      final r = pickOnClick(
        now: {'b'},
        lead: 'b',
        id: 'e',
        order: order,
        span: true,
      );
      expect(r.lead, 'b');
    });

    test('a second span extends from the same lead', () {
      final first = pickOnClick(
        now: {'b'},
        lead: 'b',
        id: 'c',
        order: order,
        span: true,
      );
      final second = pickOnClick(
        now: first.picked,
        lead: first.lead,
        id: 'e',
        order: order,
        span: true,
      );
      expect(second.picked.toList(), ['b', 'c', 'd', 'e']);
      expect(second.lead, 'b');
    });

    test('a span back across the lead flips direction', () {
      final r = pickOnClick(
        now: {'c', 'd', 'e'},
        lead: 'c',
        id: 'a',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['c', 'b', 'a']);
      expect(r.lead, 'c');
    });

    test('span onto the lead picks just the lead', () {
      final r = pickOnClick(
        now: {'b', 'c'},
        lead: 'b',
        id: 'b',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['b']);
      expect(r.lead, 'b');
    });

    test('works on non-string items', () {
      final r = pickOnClick(
        now: {2},
        lead: 2,
        id: 4,
        order: const [1, 2, 3, 4, 5],
        span: true,
      );
      expect(r.picked.toList(), [2, 3, 4]);
      expect(r.lead, 2);
    });
  });

  group('span that cannot be a range acts as add', () {
    test('no lead adds the id', () {
      final r = pickOnClick(
        now: {'a'},
        lead: null,
        id: 'c',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['a', 'c']);
      expect(r.lead, 'c');
    });

    test('empty order adds the id', () {
      final r = pickOnClick(now: {'a'}, lead: 'a', id: 'c', span: true);
      expect(r.picked.toList(), ['a', 'c']);
      expect(r.lead, 'c');
    });

    test('lead not in order adds the id', () {
      final r = pickOnClick(
        now: {'x'},
        lead: 'x',
        id: 'c',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['x', 'c']);
      expect(r.lead, 'c');
    });

    test('id not in order adds the id', () {
      final r = pickOnClick(
        now: {'a'},
        lead: 'a',
        id: 'z',
        order: order,
        span: true,
      );
      expect(r.picked.toList(), ['a', 'z']);
      expect(r.lead, 'z');
    });

    test('with an empty selection and no lead picks the id', () {
      final r = pickOnClick<String>(now: {}, lead: null, id: 'b', span: true);
      expect(r.picked.toList(), ['b']);
      expect(r.lead, 'b');
    });
  });

  group('add and span together', () {
    test('adds the range and keeps what was picked', () {
      final r = pickOnClick(
        now: {'a', 'c'},
        lead: 'c',
        id: 'e',
        order: order,
        add: true,
        span: true,
      );
      expect(r.picked.toList(), ['a', 'c', 'd', 'e']);
    });

    test('keeps items outside the range', () {
      final r = pickOnClick(
        now: {'a', 'd'},
        lead: 'd',
        id: 'e',
        order: order,
        add: true,
        span: true,
      );
      expect(r.picked, containsAll(['a', 'd', 'e']));
      expect(r.picked.length, 3);
    });

    test('does not drop the selection the way a plain span does', () {
      final plain = pickOnClick(
        now: {'a', 'c'},
        lead: 'c',
        id: 'd',
        order: order,
        span: true,
      );
      final added = pickOnClick(
        now: {'a', 'c'},
        lead: 'c',
        id: 'd',
        order: order,
        add: true,
        span: true,
      );
      expect(plain.picked, isNot(contains('a')));
      expect(added.picked, contains('a'));
    });

    test(
      'new items come after what was picked, in range order from the lead',
      () {
        final r = pickOnClick(
          now: {'e', 'd'},
          lead: 'd',
          id: 'b',
          order: order,
          add: true,
          span: true,
        );
        expect(r.picked.toList(), ['e', 'd', 'c', 'b']);
      },
    );

    test('an item already picked is not listed twice', () {
      final r = pickOnClick(
        now: {'b', 'c'},
        lead: 'b',
        id: 'd',
        order: order,
        add: true,
        span: true,
      );
      expect(r.picked.toList(), ['b', 'c', 'd']);
    });
  });

  group('inputs', () {
    test('now is not changed by a plain click', () {
      final now = {'a', 'b'};
      pickOnClick(now: now, lead: 'a', id: 'c', order: order);
      expect(now.toList(), ['a', 'b']);
    });

    test('now is not changed by add', () {
      final now = {'a', 'b'};
      pickOnClick(now: now, lead: 'a', id: 'c', order: order, add: true);
      pickOnClick(now: now, lead: 'a', id: 'a', order: order, add: true);
      expect(now.toList(), ['a', 'b']);
    });

    test('now is not changed by span', () {
      final now = {'a', 'b'};
      pickOnClick(now: now, lead: 'a', id: 'e', order: order, span: true);
      expect(now.toList(), ['a', 'b']);
    });

    test('now is not changed by add with span', () {
      final now = {'a', 'b'};
      pickOnClick(
        now: now,
        lead: 'b',
        id: 'e',
        order: order,
        add: true,
        span: true,
      );
      expect(now.toList(), ['a', 'b']);
    });

    test('the result is a new set, not now itself', () {
      final now = {'a'};
      final r = pickOnClick(now: now, lead: 'a', id: 'b', add: true);
      expect(identical(r.picked, now), isFalse);
    });
  });
}
