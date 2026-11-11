// characterization: InspectorSync, the exchange between the values the inspector edits and the owner of those values:
// what the owner is told and in which order, what it is not told again, and what goes back when it refuses.
// Here: what the owner shows back (show, and showAt).

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/inspector_snapshot.dart';

import 'inspector_sync_fixture.dart';

void main() {
  group('show', () {
    test('a number a field watches goes to that field: no rebuild, and it is not told back', () {
      final (doc, sync, owner) = syncStarted();
      final amount = doc.watch('v_amount');
      expect(
        sync.show(
          doc,
          const InspectorSnapshot(numbers: {'v_amount': 9}),
          owner.edits,
          previous: syncNothing,
        ),
        isFalse,
      );
      expect((doc.numbers['v_amount'], amount.value), (9, 1));
      expect(owner.take(), isEmpty);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a number no field watches asks for a rebuild, once', () {
      final (doc, sync, owner) = syncStarted();
      const next = InspectorSnapshot(numbers: {'v_x': 2});
      expect(sync.show(doc, next, owner.edits, previous: syncNothing), isTrue);
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
    });

    test('an edit the owner did not take goes back to what the owner says', () {
      final (doc, sync, owner) = syncStarted();
      doc.set('v_amount', 2);
      owner.take();
      const still = InspectorSnapshot(numbers: {'v_amount': 4});
      expect(sync.show(doc, still, owner.edits, previous: still), isTrue);
      expect(doc.numbers['v_amount'], 4);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a value being dragged is not overwritten, and is still told when the drag ends; strings are taken meanwhile', () {
      final (doc, sync, owner) = syncStarted();
      doc.beginGesture();
      doc.delta('v_amount', 1);
      owner.take();
      expect(
        sync.show(
          doc,
          const InspectorSnapshot(
            numbers: {'v_amount': 0},
            words: {'name': 'Blob'},
          ),
          owner.edits,
          previous: syncNothing,
        ),
        isTrue,
      );
      expect((doc.numbers['v_amount'], doc.strings['name']), (5, 'Blob'));
      doc.endGesture();
      expect(owner.take(), [
        '{',
        [
          'values',
          {'v_amount': 5},
        ],
        '}',
      ]);
    });

    test('a string that differs is taken, asks for a rebuild, and is not told back', () {
      final (doc, sync, owner) = syncStarted();
      const next = InspectorSnapshot(words: {'v_mode': 'High'});
      expect(sync.show(doc, next, owner.edits, previous: syncNothing), isTrue);
      expect(doc.strings['v_mode'], 'High');
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a switch that differs is taken, asks for a rebuild, and is not told back', () {
      final (doc, sync, owner) = syncStarted();
      const next = InspectorSnapshot(flags: {'clip': true});
      expect(sync.show(doc, next, owner.edits, previous: syncNothing), isTrue);
      expect(doc.flags['clip'], isTrue);
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('switches are not taken from an owner that hears of none', () {
      final (doc, sync, owner) = syncStarted(hearsFlags: false);
      expect(
        sync.show(
          doc,
          const InspectorSnapshot(flags: {'clip': true}),
          owner.edits,
          previous: syncNothing,
        ),
        isFalse,
      );
      expect(doc.flags, isEmpty);
    });

    test('a key mark goes to the field that draws it: no rebuild, and it is not told back', () {
      final (doc, sync, owner) = syncStarted();
      final mark = doc.watch('key:v_position');
      const next = InspectorSnapshot(keyMarks: {'v_position': syncAnim});
      expect(sync.show(doc, next, owner.edits, previous: syncNothing), isFalse);
      expect((doc.keys['v_position'], mark.value), (syncAnim, 1));
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      expect(mark.value, 1);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a key mark pressed here and undone by the owner goes back, though the owner\'s marks did not change', () {
      const marks = InspectorSnapshot(keyMarks: {'v_position': syncAnim});
      final (doc, sync, owner) = syncStarted(snapshot: marks);
      final mark = doc.watch('key:v_position');
      doc.setKey('v_position', syncAt);
      expect(owner.take(), [
        '{',
        ['key', 'v_position', syncAt],
        '}',
      ]);
      expect(sync.show(doc, marks, owner.edits, previous: marks), isFalse);
      expect((doc.keys['v_position'], mark.value), (syncAnim, 2));
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('the owner\'s Animate all is shown, asks for a rebuild, and is not told back', () {
      final (doc, sync, owner) = syncStarted();
      const on = InspectorSnapshot(animating: true);
      expect(sync.show(doc, on, owner.edits, previous: syncNothing), isTrue);
      expect(doc.animateAll, isTrue);
      expect(sync.show(doc, on, owner.edits, previous: on), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('showAt', () {
    test('values and key marks at a new time go to the fields that watch them and are not told back', () {
      final (doc, sync, owner) = syncStarted();
      final amount = doc.watch('v_amount'), mark = doc.watch('key:v_amount');
      expect(sync.showAt(doc, {'v_amount': 8}, {'v_amount': syncAt}), isFalse);
      expect(
        (
          doc.numbers['v_amount'],
          doc.keys['v_amount'],
          amount.value,
          mark.value,
        ),
        (8, syncAt, 1, 1),
      );
      expect(owner.take(), isEmpty);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a value no field watches asks for a rebuild', () {
      final (doc, sync, _) = syncStarted();
      expect(sync.showAt(doc, {'v_x': 1}, const {}), isTrue);
    });

    test('nothing is shown during a drag', () {
      final (doc, sync, _) = syncStarted();
      doc.beginGesture();
      expect(sync.showAt(doc, {'v_x': 1}, {'v_x': syncAt}), isFalse);
      expect(doc.numbers['v_x'], 0);
      expect(doc.keys, isEmpty);
    });
  });
}
