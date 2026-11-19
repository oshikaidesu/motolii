// InspectorSync with an owner that takes a step some time after it is told (InspectorEdits.whenTaken): until it has,
// what it shows of the numbers in that step is from before the step, and the inspector keeps showing its own; once
// it has, they follow the owner again, starting from what it last showed. The expected values follow that contract.

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/inspector_snapshot.dart';

import 'inspector_sync_fixture.dart';

void main() {
  InspectorSnapshot says(Map<String, double> numbers) =>
      InspectorSnapshot(numbers: numbers);

  test('a number told and not taken yet is not put back by what the owner still shows', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    final amount = doc.watch('v_amount');
    doc.set('v_amount', 7);
    expect(owner.untaken, hasLength(1));
    final before = amount.value;
    expect(
      sync.show(doc, says({'v_amount': 4}), owner.edits, previous: syncNothing),
      isFalse,
    );
    expect((doc.numbers['v_amount'], amount.value), (7, before));
  });

  test('nor by what the owner shows at a new time', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    final amount = doc.watch('v_amount');
    doc.set('v_amount', 7);
    final before = amount.value;
    expect(sync.showAt(doc, {'v_amount': 4}, const {}), isFalse);
    expect((doc.numbers['v_amount'], amount.value), (7, before));
  });

  test('the other numbers follow the owner meanwhile', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    final x = doc.watch('v_x');
    doc.set('v_amount', 7);
    final before = x.value;
    sync.show(
      doc,
      says({'v_amount': 4, 'v_x': 3}),
      owner.edits,
      previous: syncNothing,
    );
    expect(
      (doc.numbers['v_amount'], doc.numbers['v_x'], x.value),
      (7, 3, before + 1),
    );
  });

  test('once taken, the number shows what the owner last showed of it', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    final amount = doc.watch('v_amount');
    doc.set('v_amount', 70);
    sync.show(doc, says({'v_amount': 4}), owner.edits, previous: syncNothing);
    // The owner took it and made 10 of it (the top of its range).
    sync.showAt(doc, {'v_amount': 10}, const {});
    final before = amount.value;
    owner.takeStep();
    expect((doc.numbers['v_amount'], amount.value), (10, before + 1));
    owner.take();
    doc.poke();
    expect(owner.take(), [
      '{',
      '}',
    ], reason: 'what the owner showed is not told back to it');
  });

  test('once taken, it follows the owner again', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    doc.set('v_amount', 7);
    owner.takeStep();
    sync.show(doc, says({'v_amount': 5}), owner.edits, previous: syncNothing);
    expect(doc.numbers['v_amount'], 5);
  });

  test('taken as it was told, with nothing shown meanwhile: it stays', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    final amount = doc.watch('v_amount');
    var rebuilds = 0;
    sync.onUnwatched = () => rebuilds++;
    doc.set('v_amount', 7);
    final before = amount.value;
    owner.takeStep();
    expect((doc.numbers['v_amount'], amount.value, rebuilds), (7, before, 0));
  });

  test('a number told again waits for the later telling', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    doc.set('v_amount', 7);
    doc.set('v_amount', 8);
    expect(owner.untaken, hasLength(2));
    owner.takeStep();
    sync.show(doc, says({'v_amount': 7}), owner.edits, previous: syncNothing);
    expect(
      doc.numbers['v_amount'],
      8,
      reason: 'the first step taken: the second is still on its way',
    );
    owner.takeStep();
    expect(
      doc.numbers['v_amount'],
      7,
      reason: 'both taken: what the owner last showed',
    );
  });

  test('a later step of another number does not hold an earlier one back', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    doc.set('v_amount', 7);
    doc.set('v_x', 1);
    owner.takeStep();
    sync.show(
      doc,
      says({'v_amount': 6, 'v_x': 9}),
      owner.edits,
      previous: syncNothing,
    );
    expect((doc.numbers['v_amount'], doc.numbers['v_x']), (6, 1));
  });

  test('taken during a drag: nothing is shown', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    doc.set('v_amount', 7);
    sync.show(doc, says({'v_amount': 4}), owner.edits, previous: syncNothing);
    doc.beginGesture();
    owner.takeStep();
    expect(doc.numbers['v_amount'], 7);
    doc.endGesture();
  });

  test('a number no field watches, shown once taken, asks for a rebuild', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    var rebuilds = 0;
    sync.onUnwatched = () => rebuilds++;
    doc.set('v_x', 2);
    sync.show(doc, says({'v_x': 5}), owner.edits, previous: syncNothing);
    expect(rebuilds, 0);
    owner.takeStep();
    expect((doc.numbers['v_x'], rebuilds), (5, 1));
  });

  test('a step that told no number asks nothing of the owner', () {
    final (doc, _, owner) = syncStarted(takesLater: true);
    doc.poke();
    expect(owner.take(), ['{', '}']);
    expect(owner.untaken, isEmpty);
  });

  test('a drag asks only when it ends', () {
    final (doc, _, owner) = syncStarted(takesLater: true);
    doc.beginGesture();
    doc.delta('v_amount', 1);
    expect(owner.untaken, isEmpty);
    doc.endGesture();
    expect(owner.untaken, hasLength(1));
  });

  test('a new document forgets what was on its way', () {
    final (doc, sync, owner) = syncStarted(takesLater: true);
    doc.set('v_amount', 7);
    sync.show(doc, says({'v_amount': 4}), owner.edits, previous: syncNothing);
    sync.start(doc, says({'v_amount': 3}));
    sync.show(doc, says({'v_amount': 2}), owner.edits, previous: syncNothing);
    expect(doc.numbers['v_amount'], 2);
    owner.takeStep();
    expect(
      doc.numbers['v_amount'],
      2,
      reason: 'the old step taken shows nothing of before the new start',
    );
  });

  test('an owner that takes a step at once is followed at once', () {
    final (doc, sync, owner) = syncStarted();
    doc.set('v_amount', 7);
    sync.show(doc, says({'v_amount': 4}), owner.edits, previous: syncNothing);
    expect(doc.numbers['v_amount'], 4);
  });
}
