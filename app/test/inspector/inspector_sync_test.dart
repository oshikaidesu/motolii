// characterization: InspectorSync, the exchange between the values the inspector edits and the owner of those values:
// what the owner is told and in which order, what it is not told again, and what goes back when it refuses.
// The expected values are what the code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_sync.dart';
import 'package:motolii/inspector/inspector_values.dart';

// One card. Its fields: v_amount (default 4), v_mode (default 1, shown as the word Med) and v_x (default 0).
const _card = '''
struct First {
  amount: f32, // @range(0, 10) @default(4)
  mode: i32, // @enum(Low, Med, High) @default(1)
  x: f32,
}
''';

Color _tone() => const Color(0xFF000000);

/// The owner of the values. It writes down everything it is told, in order; '{' and '}' are the ends of one undo step.
class _Owner {
  _Owner({required bool hearsFlags}) {
    edits = InspectorEdits(
      onValues: (changed, {required live}) =>
          told.add([live ? 'values, live' : 'values', Map.of(changed)]),
      onDrop: () => told.add('drop'),
      onKey: (prop, mark) => told.add(['key', prop, mark]),
      onWords: (changed) {
        told.add(['words', Map.of(changed)]);
        return takesWords;
      },
      onFlags: hearsFlags
          ? (changed) {
              told.add(['flags', Map.of(changed)]);
              return takesFlags;
            }
          : null,
      onAnimateAll: (on) => told.add(['animate all', on]),
      together: (tells) {
        told.add('{');
        tells();
        told.add('}');
      },
      onRoute: (panel) => told.add(['route', panel]),
      onAim: (slot) => told.add(['aim', slot]),
    );
  }

  final told = <Object>[];
  bool takesWords = true, takesFlags = true;
  late final InspectorEdits edits;

  /// What it was told since the last call.
  List<Object> take() {
    final all = [...told];
    told.clear();
    return all;
  }
}

InspectorValues _doc() {
  final doc = InspectorValues(
    Kind.shape,
    cards: [CardDeclaration('First', _card, toneOf: _tone)],
  );
  addTearDown(doc.dispose);
  return doc;
}

/// A document filled from [snapshot] whose every notification is reported to an owner, as the Inspector's host does.
(InspectorValues, InspectorSync, _Owner) _started({
  InspectorSnapshot snapshot = const InspectorSnapshot(),
  bool hearsFlags = true,
}) {
  final doc = _doc(),
      sync = InspectorSync()..start(doc, snapshot),
      owner = _Owner(hearsFlags: hearsFlags);
  doc.addListener(() => sync.report(doc, owner.edits));
  return (doc, sync, owner);
}

const _nothing = InspectorSnapshot();
const _at = KeyframeState.at, _anim = KeyframeState.anim;

void main() {
  group('start', () {
    test('fills the document with what the owner gave, over the defaults of its cards', () {
      final (doc, _, _) = _started(
        snapshot: const InspectorSnapshot(
          numbers: {'v_amount': 7, 'v_y': 3},
          words: {'name': 'Blob'},
          flags: {'clip': true},
          keyMarks: {'v_position': _anim},
          animating: true,
        ),
      );
      expect(doc.numbers, {'v_amount': 7, 'v_mode': 1, 'v_x': 0, 'v_y': 3});
      expect(doc.strings, {'v_mode': 'Med', 'name': 'Blob'});
      expect(doc.flags, {'clip': true});
      expect(doc.keys, {'v_position': _anim});
      expect(doc.animateAll, isTrue);
    });

    test('nothing the document starts with is told to the owner, defaults included; the undo step is still made', () {
      final (doc, _, owner) = _started(
        snapshot: const InspectorSnapshot(
          numbers: {'v_amount': 7},
          words: {'name': 'Blob'},
          flags: {'clip': true},
          keyMarks: {'v_position': _anim},
          animating: true,
        ),
      );
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a new document forgets what the one before was told, but a drag that was being told is dropped at the next report', () {
      final (doc, sync, owner) = _started();
      doc.beginGesture();
      doc.delta('v_amount', 1);
      expect(owner.take(), [
        [
          'values, live',
          {'v_amount': 5},
        ],
      ]);
      final next = _doc();
      sync.start(next, _nothing);
      next.addListener(() => sync.report(next, owner.edits));
      next.poke();
      expect(owner.take(), ['{', 'drop', '}']);
      next.poke();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('report, numbers', () {
    test('an edit is told once, inside one undo step', () {
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
      doc.beginGesture();
      doc.endGesture();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('report, key marks', () {
    test('a key mark is told once', () {
      final (doc, _, owner) = _started();
      doc.setKey('v_position', _at);
      expect(owner.take(), [
        '{',
        ['key', 'v_position', _at],
        '}',
      ]);
      doc.setKey('v_position', _at);
      expect(owner.take(), ['{', '}']);
    });

    test('a key mark set during a drag is told when the drag ends', () {
      final (doc, _, owner) = _started();
      doc.beginGesture();
      doc.setKey('v_amount', _at);
      expect(owner.take(), isEmpty);
      doc.endGesture();
      expect(owner.take(), [
        '{',
        'drop',
        ['key', 'v_amount', _at],
        '}',
      ]);
    });

    test('a reset while Animate all is on tells the value, then its key, in one undo step', () {
      final (doc, _, owner) = _started();
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
        ['key', 'v_amount', _at],
        '}',
      ]);
    });
  });

  group('report, strings', () {
    test('a string is told once', () {
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
      owner.takesWords = false;
      doc.str('v_mode', 'Low');
      expect(owner.take(), [
        '{',
        [
          'words',
          {'v_mode': 'Low'},
        ],
        '}',
      ]);
      expect(doc.strings['v_mode'], 'Med');
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
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started(
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
        final (doc, _, owner) = _started(hearsFlags: false);
        doc.flag('clip', true);
        expect(owner.take(), ['{', '}']);
        expect(doc.flags['clip'], isTrue);
      },
    );
  });

  group('report, Animate all', () {
    test('a change of Animate all is told once', () {
      final (doc, _, owner) = _started();
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
      final (doc, _, owner) = _started();
      doc.animateAll = true;
      doc.numbers['v_x'] = 5;
      doc.keys['v_x'] = _at;
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
        ['key', 'v_x', _at],
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

  group('show', () {
    test('a number a field watches goes to that field: no rebuild, and it is not told back', () {
      final (doc, sync, owner) = _started();
      final amount = doc.watch('v_amount');
      expect(
        sync.show(
          doc,
          const InspectorSnapshot(numbers: {'v_amount': 9}),
          owner.edits,
          previous: _nothing,
        ),
        isFalse,
      );
      expect((doc.numbers['v_amount'], amount.value), (9, 1));
      expect(owner.take(), isEmpty);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a number no field watches asks for a rebuild, once', () {
      final (doc, sync, owner) = _started();
      const next = InspectorSnapshot(numbers: {'v_x': 2});
      expect(sync.show(doc, next, owner.edits, previous: _nothing), isTrue);
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
    });

    test('an edit the owner did not take goes back to what the owner says', () {
      final (doc, sync, owner) = _started();
      doc.set('v_amount', 2);
      owner.take();
      const still = InspectorSnapshot(numbers: {'v_amount': 4});
      expect(sync.show(doc, still, owner.edits, previous: still), isTrue);
      expect(doc.numbers['v_amount'], 4);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a value being dragged is not overwritten, and is still told when the drag ends; strings are taken meanwhile', () {
      final (doc, sync, owner) = _started();
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
          previous: _nothing,
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
      final (doc, sync, owner) = _started();
      const next = InspectorSnapshot(words: {'v_mode': 'High'});
      expect(sync.show(doc, next, owner.edits, previous: _nothing), isTrue);
      expect(doc.strings['v_mode'], 'High');
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a switch that differs is taken, asks for a rebuild, and is not told back', () {
      final (doc, sync, owner) = _started();
      const next = InspectorSnapshot(flags: {'clip': true});
      expect(sync.show(doc, next, owner.edits, previous: _nothing), isTrue);
      expect(doc.flags['clip'], isTrue);
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('switches are not taken from an owner that hears of none', () {
      final (doc, sync, owner) = _started(hearsFlags: false);
      expect(
        sync.show(
          doc,
          const InspectorSnapshot(flags: {'clip': true}),
          owner.edits,
          previous: _nothing,
        ),
        isFalse,
      );
      expect(doc.flags, isEmpty);
    });

    test('a key mark goes to the field that draws it: no rebuild, and it is not told back', () {
      final (doc, sync, owner) = _started();
      final mark = doc.watch('key:v_position');
      const next = InspectorSnapshot(keyMarks: {'v_position': _anim});
      expect(sync.show(doc, next, owner.edits, previous: _nothing), isFalse);
      expect((doc.keys['v_position'], mark.value), (_anim, 1));
      expect(sync.show(doc, next, owner.edits, previous: next), isFalse);
      expect(mark.value, 1);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a key mark pressed here and undone by the owner goes back, though the owner\'s marks did not change', () {
      const marks = InspectorSnapshot(keyMarks: {'v_position': _anim});
      final (doc, sync, owner) = _started(snapshot: marks);
      final mark = doc.watch('key:v_position');
      doc.setKey('v_position', _at);
      expect(owner.take(), [
        '{',
        ['key', 'v_position', _at],
        '}',
      ]);
      expect(sync.show(doc, marks, owner.edits, previous: marks), isFalse);
      expect((doc.keys['v_position'], mark.value), (_anim, 2));
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('the owner\'s Animate all is shown, asks for a rebuild, and is not told back', () {
      final (doc, sync, owner) = _started();
      const on = InspectorSnapshot(animating: true);
      expect(sync.show(doc, on, owner.edits, previous: _nothing), isTrue);
      expect(doc.animateAll, isTrue);
      expect(sync.show(doc, on, owner.edits, previous: on), isFalse);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });
  });

  group('showAt', () {
    test('values and key marks at a new time go to the fields that watch them and are not told back', () {
      final (doc, sync, owner) = _started();
      final amount = doc.watch('v_amount'), mark = doc.watch('key:v_amount');
      expect(sync.showAt(doc, {'v_amount': 8}, {'v_amount': _at}), isFalse);
      expect(
        (
          doc.numbers['v_amount'],
          doc.keys['v_amount'],
          amount.value,
          mark.value,
        ),
        (8, _at, 1, 1),
      );
      expect(owner.take(), isEmpty);
      doc.poke();
      expect(owner.take(), ['{', '}']);
    });

    test('a value no field watches asks for a rebuild', () {
      final (doc, sync, _) = _started();
      expect(sync.showAt(doc, {'v_x': 1}, const {}), isTrue);
    });

    test('nothing is shown during a drag', () {
      final (doc, sync, _) = _started();
      doc.beginGesture();
      expect(sync.showAt(doc, {'v_x': 1}, {'v_x': _at}), isFalse);
      expect(doc.numbers['v_x'], 0);
      expect(doc.keys, isEmpty);
    });
  });
}
