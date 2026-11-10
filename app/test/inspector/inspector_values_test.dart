// InspectorValues, the values the inspector's cards edit: what each call changes and who hears of it (the InspectorValues's own listeners,
// counted here, and the per-field counters of InspectorValues.watch). The expected values are what the code gave when this was
// written, so a move or a split that changes one fails here. Needs no engine.
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/inspector_card.dart' show CardDeclaration;
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';

// Two cards. The fields of the first, in order: v_amount, v_center.x, v_center.y, v_mode, v_x (a colour has no number).
const _first = '''
struct First {
  amount: f32, // @range(0, 10) @default(4)
  center: vec2f, // @default(0.5, 0.25)
  tint: vec3f, // @default(1, 0.5, 0)
  mode: i32, // @enum(Low, Med, High) @default(1)
  x: f32,
}
''';
const _second = '''
struct Second {
  radius: f32,
  angle: f32,
}
''';

Color _tone() => const Color(0xFF000000);

InspectorValues _doc() {
  final doc = InspectorValues(
    Kind.shape,
    cards: [
      CardDeclaration('First', _first, toneOf: _tone),
      CardDeclaration('Second', _second, toneOf: _tone),
    ],
  );
  addTearDown(doc.dispose);
  return doc;
}

void main() {
  test('a new InspectorValues starts from the defaults its cards declare', () {
    final doc = _doc();
    expect(doc.v, {
      'v_amount': 4,
      'v_center.x': .5,
      'v_center.y': .25,
      'v_mode': 1,
      'v_x': 0,
      'v_radius': 0,
      'v_angle': 0,
    });
    expect(doc.d, doc.v);
    expect(doc.s2, {'v_tint': '#FF8000', 'v_mode': 'Med'});
    expect(doc.keys, isEmpty);
    expect(doc.b, isEmpty);
    expect(doc.fields.picked, isEmpty);
    expect(doc.inGesture, isFalse);
  });

  test('set, setMany and delta each notify once, and leave the defaults and the field counters alone', () {
    final doc = _doc(), amount = doc.watch('v_amount');
    var told = 0;
    doc.addListener(() => told++);
    doc.set('v_amount', 2);
    expect((doc.get('v_amount'), doc.d['v_amount'], told), (2, 4, 1));
    doc.set('v_amount', 2); // The same value still notifies.
    expect(told, 2);
    doc.setMany({'v_amount': 3, 'v_x': 8});
    expect((doc.v['v_amount'], doc.v['v_x'], told), (3, 8, 3));
    doc.delta('v_x', -1.5);
    doc.delta('v_new', 2); // A value that is not there yet counts from 0.
    expect((doc.v['v_x'], doc.v['v_new'], told), (6.5, 2, 5));
    expect(amount.value, 0);
  });

  test('str, flag and poke each notify once', () {
    final doc = _doc();
    var told = 0;
    doc.addListener(() => told++);
    doc.str('v_mode', 'High');
    doc.flag('lit', true);
    doc.poke();
    expect((doc.s2['v_mode'], doc.b['lit'], told), ('High', true, 3));
  });

  test('a drag notifies once when it ends, with ending set, and only then bumps the counters of the values it changed', () {
    final doc = _doc(), amount = doc.watch('v_amount'), x = doc.watch('v_x');
    final heard = <(bool, bool, int)>[];
    doc.beginGesture();
    expect(doc.inGesture, isTrue);
    doc.delta('v_amount', 1);
    doc.addListener(() => heard.add((doc.ending, doc.inGesture, amount.value)));
    doc.endGesture();
    expect(heard, [(true, false, 0)]);
    expect(
      (doc.ending, doc.inGesture, amount.value, x.value),
      (false, false, 1, 0),
    );
  });

  test('beginGesture does not notify, and a second one keeps the values the drag began from', () {
    final doc = _doc(), amount = doc.watch('v_amount');
    var told = 0;
    doc.addListener(() => told++);
    doc.beginGesture();
    expect(told, 0);
    doc.delta('v_amount', 1);
    doc.beginGesture();
    doc.delta('v_amount', -1);
    doc.endGesture();
    expect(
      (told, amount.value),
      (3, 0),
    ); // Back where the drag began: no value changed.
  });

  test('watch gives one counter per id, starting at 0', () {
    final doc = _doc();
    expect(doc.watch('v_amount'), same(doc.watch('v_amount')));
    expect(doc.watch('v_amount'), isNot(same(doc.watch('key:v_amount'))));
    expect(doc.watch('v_amount').value, 0);
  });

  test('showAt bumps only the counters of what changed, notifies no listener, and says when a changed value has no counter', () {
    final doc = _doc(),
        amount = doc.watch('v_amount'),
        mark = doc.watch('key:v_amount');
    var told = 0;
    doc.addListener(() => told++);
    expect(
      doc.showAt({'v_amount': 7, 'v_x': 0}, {'v_amount': KeyframeState.at}),
      isFalse,
    );
    expect(
      (doc.v['v_amount'], doc.keys['v_amount'], amount.value, mark.value),
      (7, KeyframeState.at, 1, 1),
    );
    expect(
      doc.showAt({'v_amount': 7}, {'v_amount': KeyframeState.at}),
      isFalse,
    );
    expect((amount.value, mark.value), (1, 1));
    expect(doc.showAt({'v_x': 3}, {}), isTrue);
    expect((doc.v['v_x'], told), (3, 0));
  });

  test(
    'setKey sets the mark of a property, bumps its counter and notifies',
    () {
      final doc = _doc(), mark = doc.watch('key:v_position');
      var told = 0;
      doc.addListener(() => told++);
      doc.setKey('v_position', KeyframeState.anim);
      expect(
        (doc.keys['v_position'], mark.value, told),
        (KeyframeState.anim, 1, 1),
      );
    },
  );

  test('resetIds writes the defaults and notifies once', () {
    final doc = _doc();
    doc.setMany({'v_amount': 9, 'v_x': 5});
    var told = 0;
    doc.addListener(() => told++);
    doc.resetIds(['v_amount', 'v_x', 'v_undeclared']);
    expect(
      (doc.v['v_amount'], doc.v['v_x'], doc.v['v_undeclared'], told),
      (4, 0, 0, 1),
    );
    expect(doc.keys, isEmpty);
  });

  test('resetIds puts a key at the playhead on a property that is animated, or on every one while animateAll is on', () {
    final doc = _doc();
    doc.keys['v_position'] = KeyframeState.anim;
    doc.resetIds([
      'v_x',
      'v_amount',
    ]); // v_x is a value of the position property.
    expect(doc.keys, {'v_position': KeyframeState.at});
    doc.animateAll = true;
    doc.resetIds(['v_amount']);
    expect(doc.keys, {
      'v_position': KeyframeState.at,
      'v_amount': KeyframeState.at,
    });
  });

  group('pick', () {
    test('one field picked alone shows nothing and does not notify', () {
      final doc = _doc();
      var told = 0;
      doc.addListener(() => told++);
      doc.fields.pick('v_amount');
      expect(doc.fields.picked, {'v_amount'});
      expect((doc.fields.isPicked('v_amount'), told), (false, 0));
    });

    test('a span picks the rectangle from the field picked first to this one, one row per card', () {
      final doc = _doc();
      var told = 0;
      doc.addListener(() => told++);
      doc.fields.pick('v_amount');
      doc.fields.pick('v_mode', span: true);
      expect(doc.fields.picked, {
        'v_amount',
        'v_center.x',
        'v_center.y',
        'v_mode',
      });
      expect(
        (doc.fields.isPicked('v_mode'), doc.fields.isPicked('v_x'), told),
        (true, false, 1),
      );
      doc.fields.pick(
        'v_angle',
        span: true,
      ); // Still from v_amount: the first two fields of both cards.
      expect(doc.fields.picked, {
        'v_amount',
        'v_center.x',
        'v_radius',
        'v_angle',
      });
      expect(told, 2);
    });

    test('a span across cards stops at the end of a shorter row', () {
      final doc = _doc();
      doc.fields.pick('v_x');
      doc.fields.pick('v_radius', span: true);
      expect(doc.fields.picked, {
        'v_amount',
        'v_center.x',
        'v_center.y',
        'v_mode',
        'v_x',
        'v_radius',
        'v_angle',
      });
    });

    test('a span with no field picked first, or to a field no card has, picks that field alone', () {
      final doc = _doc();
      var told = 0;
      doc.addListener(() => told++);
      doc.fields.pick('v_mode', span: true);
      expect(doc.fields.picked, {'v_mode'});
      doc.fields.pick('v_elsewhere', span: true);
      expect(doc.fields.picked, {'v_elsewhere'});
      expect(told, 0);
    });

    test('picking one field after several notifies, because a selection was showing', () {
      final doc = _doc();
      doc.fields.pick('v_amount');
      doc.fields.pick('v_mode', span: true);
      var told = 0;
      doc.addListener(() => told++);
      doc.fields.pick('v_x');
      expect(doc.fields.picked, {'v_x'});
      expect((doc.fields.isPicked('v_x'), told), (false, 1));
    });

    test('unpick clears and notifies, unless nothing was picked', () {
      final doc = _doc();
      var told = 0;
      doc.addListener(() => told++);
      doc.fields.unpick();
      expect(told, 0);
      doc.fields.pick('v_amount');
      doc.fields.unpick();
      expect(doc.fields.picked, isEmpty);
      expect(told, 1);
    });
  });

  test('dispose shuts the field counters too', () {
    final doc = InspectorValues(Kind.shape), amount = doc.watch('v_amount');
    doc.dispose();
    expect(() => amount.addListener(() {}), throwsFlutterError);
  });
}
