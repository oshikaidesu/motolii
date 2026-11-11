// characterization: InspectorSync, the exchange between the values the inspector edits and the owner of those values:
// what the owner is told and in which order, what it is not told again, and what goes back when it refuses.
// Here: what is told to the owner (start, and the reports of numbers, key marks, strings, switches and Animate all).

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/inspector_snapshot.dart';

import 'inspector_sync_fixture.dart';

void main() {
  group('start', () {
    test('fills the document with what the owner gave, over the defaults of its cards', () {
      final (doc, _, _) = syncStarted(
        snapshot: const InspectorSnapshot(
          numbers: {'v_amount': 7, 'v_y': 3},
          words: {'name': 'Blob'},
          flags: {'clip': true},
          keyMarks: {'v_position': syncAnim},
          animating: true,
        ),
      );
      expect(doc.numbers, {'v_amount': 7, 'v_mode': 1, 'v_x': 0, 'v_y': 3});
      // A choice is its index in numbers, so it has no word here.
      expect(doc.strings, {'name': 'Blob'});
      expect(doc.flags, {'clip': true});
      expect(doc.keys, {'v_position': syncAnim});
      expect(doc.animateAll, isTrue);
    });

    test('nothing the document starts with is told to the owner, defaults included; the undo step is still made', () {
      final (doc, _, owner) = syncStarted(
        snapshot: const InspectorSnapshot(
          numbers: {'v_amount': 7},
          words: {'name': 'Blob'},
          flags: {'clip': true},
          keyMarks: {'v_position': syncAnim},
          animating: true,
        ),
      );
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a new document forgets what the one before was told, but a drag that was being told is dropped at the next report', () {
      final (doc, sync, owner) = syncStarted();
      doc.beginGesture();
      doc.delta('v_amount', 1);
      expect(owner.take(), [
        [
          'values, live',
          {'v_amount': 5},
        ],
      ]);
      final next = syncDoc();
      sync.start(next, syncNothing);
      next.addListener(() => sync.report(next, owner.edits));
      next.poke();
      expect(owner.take(), ['{', 'drop', '}']);
      next.poke();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('report, numbers', () {
    test('an edit is told once, inside one undo step', () {
      final (doc, _, owner) = syncStarted();
      doc.set('v_amount', 2);
      expect(owner.take(), [
        '{',
        [
          'values',
          {'v_amount': 2},
        ],
        '}',
      ]);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a drag tells each step as live with no undo step, then its last values once more in one undo step', () {
      final (doc, _, owner) = syncStarted();
      doc.beginGesture();
      expect(owner.take(), isEmpty);
      doc.delta('v_amount', 1);
      doc.delta('v_amount', 1);
      expect(owner.take(), [
        [
          'values, live',
          {'v_amount': 5},
        ],
        [
          'values, live',
          {'v_amount': 6},
        ],
      ]);
      doc.endGesture();
      expect(owner.take(), [
        '{',
        [
          'values',
          {'v_amount': 6},
        ],
        '}',
      ]);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a drag that ends on the values it began from is dropped', () {
      final (doc, _, owner) = syncStarted();
      doc.beginGesture();
      doc.delta('v_amount', 1);
      doc.delta('v_amount', -1); // Back to what the owner has: nothing to tell.
      expect(owner.take(), [
        [
          'values, live',
          {'v_amount': 5},
        ],
      ]);
      doc.endGesture();
      expect(owner.take(), ['{', 'drop', '}']);
    });

    test('a drag during which nothing was reported drops nothing', () {
      final (doc, _, owner) = syncStarted();
      doc.beginGesture();
      doc.endGesture();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('report, key marks', () {
    test('a key mark is told once', () {
      final (doc, _, owner) = syncStarted();
      doc.setKey('v_position', syncAt);
      expect(owner.take(), [
        '{',
        ['key', 'v_position', syncAt],
        '}',
      ]);
      doc.setKey('v_position', syncAt);
      expect(owner.take(), ['{', '}']);
    });

    test('a key mark set during a drag is told when the drag ends', () {
      final (doc, _, owner) = syncStarted();
      doc.beginGesture();
      doc.setKey('v_amount', syncAt);
      expect(owner.take(), isEmpty);
      doc.endGesture();
      expect(owner.take(), [
        '{',
        'drop',
        ['key', 'v_amount', syncAt],
        '}',
      ]);
    });

    test('a reset while Animate all is on tells the value, then its key, in one undo step', () {
      final (doc, _, owner) = syncStarted();
      doc.animateAll = true;
      doc.set('v_amount', 9);
      expect(owner.take(), [
        '{',
        ['animate all', true],
        [
          'values',
          {'v_amount': 9},
        ],
        '}',
      ]);
      doc.resetIds(['v_amount']);
      expect(owner.take(), [
        '{',
        [
          'values',
          {'v_amount': 4},
        ],
        ['key', 'v_amount', syncAt],
        '}',
      ]);
    });
  });

  group('report, strings', () {
    test('a string is told once', () {
      final (doc, _, owner) = syncStarted();
      doc.str('v_mode', 'High');
      expect(owner.take(), [
        '{',
        [
          'words',
          {'v_mode': 'High'},
        ],
        '}',
      ]);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a string the owner refuses goes back to the one it had, or away if it had none', () {
      final (doc, _, owner) = syncStarted(
        snapshot: const InspectorSnapshot(words: {'name': 'Blob'}),
      );
      owner.takesWords = false;
      doc.str('name', 'Low');
      expect(owner.take(), [
        '{',
        [
          'words',
          {'name': 'Low'},
        ],
        '}',
      ]);
      expect(doc.strings['name'], 'Blob');
      doc.str('fresh', 'x');
      expect(owner.take(), [
        '{',
        [
          'words',
          {'fresh': 'x'},
        ],
        '}',
      ]);
      expect(doc.strings.containsKey('fresh'), isFalse);
    });

    test('a panel link is not a string of the owner: route and route.at are never told and stay', () {
      final (doc, _, owner) = syncStarted();
      doc.strings['route.at'] = 'v_tint';
      doc.str('route', 'Colors');
      expect(owner.take(), ['{', '}']);
      expect(
        (doc.strings['route'], doc.strings['route.at']),
        ('Colors', 'v_tint'),
      );
    });
  });

  group('report, switches', () {
    test('a switch is told once', () {
      final (doc, _, owner) = syncStarted();
      doc.flag('clip', true);
      expect(owner.take(), [
        '{',
        [
          'flags',
          {'clip': true},
        ],
        '}',
      ]);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a switch ending in .open counts as on until the owner says otherwise, so only turning it off is news', () {
      final (doc, _, owner) = syncStarted();
      doc.flag('v.First.open', true);
      expect(owner.take(), ['{', '}']);
      doc.flag('v.First.open', false);
      expect(owner.take(), [
        '{',
        [
          'flags',
          {'v.First.open': false},
        ],
        '}',
      ]);
    });

    test('a switch the owner refuses goes back to what it had, or off if it had none', () {
      final (doc, _, owner) = syncStarted(
        snapshot: const InspectorSnapshot(flags: {'clip': true}),
      );
      owner.takesFlags = false;
      doc.flag('clip', false);
      expect(owner.take(), [
        '{',
        [
          'flags',
          {'clip': false},
        ],
        '}',
      ]);
      expect(doc.flags['clip'], isTrue);
      doc.flag('ghost', true);
      expect(owner.take(), [
        '{',
        [
          'flags',
          {'ghost': true},
        ],
        '}',
      ]);
      expect(doc.flags['ghost'], isFalse);
    });

    test(
      'an owner that hears of no switches is told none, and they stay as set',
      () {
        final (doc, _, owner) = syncStarted(hearsFlags: false);
        doc.flag('clip', true);
        expect(owner.take(), ['{', '}']);
        expect(doc.flags['clip'], isTrue);
      },
    );
  });

  group('report, Animate all', () {
    test('a change of Animate all is told once', () {
      final (doc, _, owner) = syncStarted();
      doc.animateAll = true;
      doc.poke();
      expect(owner.take(), [
        '{',
        ['animate all', true],
        '}',
      ]);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });
  });

  test(
    'one report tells Animate all, values, key marks, switches, then strings',
    () {
      final (doc, _, owner) = syncStarted();
      doc.animateAll = true;
      doc.numbers['v_x'] = 5;
      doc.keys['v_x'] = syncAt;
      doc.flags['clip'] = true;
      doc.strings['name'] = 'Blob';
      doc.poke();
      expect(owner.take(), [
        '{',
        ['animate all', true],
        [
          'values',
          {'v_x': 5},
        ],
        ['key', 'v_x', syncAt],
        [
          'flags',
          {'clip': true},
        ],
        [
          'words',
          {'name': 'Blob'},
        ],
        '}',
      ]);
    },
  );
}
