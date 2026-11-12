// characterization: InspectorHost, the widget that owns the inspector's values: when it makes new values, when what is
// under it is built again, and that it uses what its caller gives as it is now. The expected values are what the code
// gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_scope.dart' show InspectorScope;
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';

import '../main_tests_only.dart';

// One card: v_amount (default 4) and v_x (default 0). The second text differs from the first only in a default,
// the third declares one more value.
const _card = '''
struct First {
  amount: f32, // @range(0, 10) @default(4)
  x: f32,
}
''';
const _cardOtherDefault = '''
struct First {
  amount: f32, // @range(0, 10) @default(6)
  x: f32,
}
''';
const _cardOneMore = '''
struct First {
  amount: f32, // @range(0, 10) @default(4)
  x: f32,
  y: f32,
}
''';

InspectedLayer _layer({
  Kind kind = Kind.shape,
  String wgsl = _card,
  String? title,
  String? kindWord,
  List<String> cardsOff = const [],
}) => InspectedLayer(
  kind: kind,
  title: title,
  kindWord: kindWord,
  cardsOff: cardsOff,
  cards: [
    CardDeclaration('First', wgsl, toneOf: () => const Color(0xFF000000)),
  ],
);

typedef _Live =
    ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>;

_Live _newLive() {
  final live = _Live((const {}, const {}));
  addTearDown(live.dispose);
  return live;
}

/// Stands where the Inspector's panel stands. It keeps the values it was last built with and counts its builds.
class _Probe extends StatelessWidget {
  const _Probe(this.seen);
  final _Seen seen;
  @override
  Widget build(BuildContext context) {
    seen
      ..doc = InspectorScope.of(context).doc
      ..builds += 1;
    return const SizedBox.shrink();
  }
}

class _Seen {
  late InspectorValues doc;
  int builds = 0;
}

/// The owner of the values. It writes down what it is told, in order; '{' and '}' are the ends of one undo step.
class _Owner {
  final told = <Object>[];
  late final edits = InspectorEdits(
    onValues: (changed, {required live}) =>
        told.add([live ? 'values, live' : 'values', Map.of(changed)]),
    onDrop: () => told.add('drop'),
    onKey: (prop, mark) => told.add(['key', prop, mark]),
    onWords: (changed) {
      told.add(['words', Map.of(changed)]);
      return true;
    },
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

/// One host in the tester, built again with whatever a test changes. The widget under it is the same one every time,
/// so that widget is built again only when the host says so.
class _Bench {
  _Bench(this.tester) : live = _newLive();
  final WidgetTester tester;
  final seen = _Seen();
  late final _probe = _Probe(seen);
  final owner = _Owner();
  _Live live;

  Future<void> pump({
    InspectedLayer? layer,
    InspectorSnapshot snapshot = const InspectorSnapshot(),
    CardActions actions = const CardActions(),
    InspectorEdits? edits,
  }) => tester.pumpWidget(
    InspectorHost(
      layer: layer ?? _layer(),
      snapshot: snapshot,
      actions: actions,
      edits: edits ?? owner.edits,
      live: live,
      child: _probe,
    ),
  );
}

void main() {
  if (skipUnlessEveryTest()) return;
  testWidgets(
    'the first build makes the values from the layer and the snapshot, and hands them the layer and the actions',
    (tester) async {
      final bench = _Bench(tester), layer = _layer(title: 'Blob');
      const actions = CardActions();
      await bench.pump(
        layer: layer,
        snapshot: const InspectorSnapshot(numbers: {'v_amount': 7}),
        actions: actions,
      );
      final doc = bench.seen.doc;
      expect(bench.seen.builds, 1);
      expect(
        (doc.kind, doc.name, doc.numbers['v_amount'], doc.numbers['v_x']),
        (Kind.shape, 'Blob', 7, 0),
      );
      expect(doc.layer, same(layer));
      expect(doc.actions, same(actions));
      expect(bench.owner.told, isEmpty);
    },
  );

  testWidgets(
    'built again with nothing new, it keeps the values and builds nothing under it, and still hands over the new actions',
    (tester) async {
      final bench = _Bench(tester);
      await bench.pump();
      final doc = bench.seen.doc, actions = CardActions(onCardPaste: () {});
      await bench.pump(actions: actions);
      expect(bench.seen.doc, same(doc));
      expect(bench.seen.builds, 1);
      expect(doc.actions, same(actions));
    },
  );

  testWidgets(
    'cards declared differently, or another kind, make new values and dispose of the old; another default alone does not',
    (tester) async {
      final bench = _Bench(tester);
      await bench.pump();
      final first = bench.seen.doc;
      await bench.pump(layer: _layer(wgsl: _cardOtherDefault));
      expect(bench.seen.doc, same(first));
      expect(bench.seen.builds, 1);
      expect((first.cards.single.wgsl, first.numbers['v_amount']), (_card, 4));

      await bench.pump(layer: _layer(wgsl: _cardOneMore));
      final second = bench.seen.doc;
      expect(second, isNot(same(first)));
      expect(bench.seen.builds, 2);
      expect(second.numbers.containsKey('v_y'), isTrue);
      expect(() => first.addListener(() {}), throwsFlutterError);

      await bench.pump(
        layer: _layer(kind: Kind.text, wgsl: _cardOneMore),
      );
      expect(bench.seen.doc, isNot(same(second)));
      expect((bench.seen.doc.kind, bench.seen.builds), (Kind.text, 3));
      expect(() => second.addListener(() {}), throwsFlutterError);
    },
  );

  testWidgets(
    'a new name, word for the kind, or list of effects that are off builds again what is under it, with the same values',
    (tester) async {
      final bench = _Bench(tester);
      await bench.pump(layer: _layer(title: 'A'));
      final doc = bench.seen.doc;
      await bench.pump(layer: _layer(title: 'B'));
      expect((doc.name, bench.seen.builds), ('B', 2));
      await bench.pump(
        layer: _layer(title: 'B', kindWord: 'Film'),
      );
      expect((doc.layer.kindWord, bench.seen.builds), ('Film', 3));
      await bench.pump(
        layer: _layer(title: 'B', kindWord: 'Film', cardsOff: ['First']),
      );
      expect(doc.layer.cardsOff, ['First']);
      expect(bench.seen.builds, 4);
      await bench.pump(
        layer: _layer(title: 'B', kindWord: 'Film', cardsOff: ['First']),
      );
      expect(bench.seen.builds, 4);
      expect(bench.seen.doc, same(doc));
    },
  );

  testWidgets(
    'the owner\'s new number goes to the field that watches it and builds nothing; one no field watches builds again',
    (tester) async {
      final bench = _Bench(tester);
      await bench.pump();
      final doc = bench.seen.doc, amount = doc.watch('v_amount');
      await bench.pump(
        snapshot: const InspectorSnapshot(numbers: {'v_amount': 9}),
      );
      expect(
        (doc.numbers['v_amount'], amount.value, bench.seen.builds),
        (9, 1, 1),
      );
      await bench.pump(
        snapshot: const InspectorSnapshot(numbers: {'v_amount': 9, 'v_x': 2}),
      );
      expect((doc.numbers['v_x'], amount.value, bench.seen.builds), (2, 1, 2));
      expect(bench.owner.told, isEmpty);
    },
  );

  testWidgets(
    'an edit is told to the callbacks the host has now and builds again what is under it, but not during a drag',
    (tester) async {
      final bench = _Bench(tester), before = _Owner();
      await bench.pump(edits: before.edits);
      await bench.pump();
      final doc = bench.seen.doc;
      doc.set('v_amount', 2);
      await tester.pump();
      expect(before.told, isEmpty);
      expect(bench.owner.told, [
        '{',
        [
          'values',
          {'v_amount': 2},
        ],
        '}',
      ]);
      expect(bench.seen.builds, 2);

      bench.owner.told.clear();
      doc.beginGesture();
      doc.delta('v_amount', 1);
      await tester.pump();
      doc.endGesture();
      await tester.pump();
      expect(bench.owner.told, [
        [
          'values, live',
          {'v_amount': 3},
        ],
        '{',
        [
          'values',
          {'v_amount': 3},
        ],
        '}',
      ]);
      expect(bench.seen.builds, 2);
    },
  );

  testWidgets(
    'a panel link is passed on after the report, as an aim and then a route, and taken out of the values',
    (tester) async {
      final bench = _Bench(tester);
      await bench.pump();
      final doc = bench.seen.doc;
      doc.strings['route.at'] = 'v_tint';
      doc.str('route', 'Colors');
      expect(bench.owner.told, [
        '{',
        '}',
        ['aim', 'v_tint'],
        ['route', 'Colors'],
      ]);
      expect(doc.strings, isEmpty);
      bench.owner.told.clear();
      doc.str('route', 'Ease');
      expect(bench.owner.told, [
        '{',
        '}',
        ['aim', ''],
        ['route', 'Ease'],
      ]);
    },
  );

  testWidgets(
    'values at a new time are shown without being told back, from the listenable the host has now',
    (tester) async {
      final bench = _Bench(tester), first = bench.live;
      await bench.pump();
      final doc = bench.seen.doc, amount = doc.watch('v_amount');
      first.value = ({'v_amount': 5}, const {});
      await tester.pump();
      expect(
        (doc.numbers['v_amount'], amount.value, bench.seen.builds),
        (5, 1, 1),
      );
      first.value = ({'v_x': 3}, const {});
      await tester.pump();
      expect((doc.numbers['v_x'], bench.seen.builds), (3, 2));

      bench.live = _newLive();
      await bench.pump();
      first.value = ({'v_x': 5}, const {});
      expect(doc.numbers['v_x'], 3);
      bench.live.value = ({'v_x': 7}, const {});
      await tester.pump();
      expect((doc.numbers['v_x'], bench.seen.builds), (7, 3));
      expect(bench.owner.told, isEmpty);
    },
  );

  testWidgets('taken out of the tree, it disposes of the values', (
    tester,
  ) async {
    final bench = _Bench(tester);
    await bench.pump();
    final doc = bench.seen.doc;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(() => doc.addListener(() {}), throwsFlutterError);
  });
}
