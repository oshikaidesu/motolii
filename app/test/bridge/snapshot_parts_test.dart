// The readers of the engine's snapshots (bridge/snapshot_parts.dart): the bytes decoded as the engine writes them
// (UTF-8 JSON), and each part parsed once for as long as its snapshot is held. The expected values follow the
// formats engine/entry/snapshot.cpp writes.
import 'dart:convert';
import 'dart:typed_data';

import 'package:motolii/bridge/snapshot_parts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

  group('snapshotOf', () {
    test('reads what jsonDecode reads, names outside ASCII included', () {
      const text =
          '{"document":{"seconds":2.5,"layers":[1,2]},"tables":null,'
          '"layer":{"1":{"word":{"name":"レイヤー 1 – é"}}}}';
      expect(snapshotOf(bytes(text)), jsonDecode(text));
    });

    test('bytes that are not JSON are a FormatException', () {
      expect(() => snapshotOf(bytes('{"layer":')), throwsFormatException);
      expect(
        () => snapshotOf(Uint8List.fromList([0x7b, 0x22, 0xff, 0x22, 0x7d])),
        throwsFormatException,
      );
    });
  });

  group('parsedOnce', () {
    test('parses on the first read only, each part by itself', () {
      final snapshot = <String, dynamic>{'moving': 'x y'};
      var parses = 0;
      List<String> read(String what) => parsedOnce(snapshot, what, () {
        parses++;
        return spaced(snapshot['moving']);
      });
      expect(read('moving'), ['x', 'y']);
      expect(identical(read('moving'), read('moving')), isTrue);
      expect(parses, 1);
      read('another part');
      expect(parses, 2);
    });

    test('a snapshot that replaces another is parsed again', () {
      var parses = 0;
      int read(Map<String, dynamic> snapshot) =>
          parsedOnce(snapshot, 'keys', () => ++parses);
      final first = <String, dynamic>{'keys': 1},
          second = <String, dynamic>{'keys': 1};
      expect(read(first), 1);
      expect(read(second), 2);
      expect(read(first), 1);
    });

    test('the layer that is not there (a const map) can be read too', () {
      expect(parsedOnce(const {}, 'moving', () => spaced(null)), isEmpty);
    });
  });

  group('merged', () {
    test('the parts handed over replace their own, the others stay', () {
      final held = <String, dynamic>{
        'moving': 'x y',
        'value': {'x': 1},
        'lasts': 5,
      };
      final next = merged(held, {
        'value': {'x': 2},
      });
      expect(next, {
        'moving': 'x y',
        'value': {'x': 2},
        'lasts': 5,
      });
      expect(identical(next['moving'], held['moving']), isTrue);
      expect(held['value'], {'x': 1}, reason: 'what was held is not changed');
    });

    test('a part that is null is gone', () {
      expect(
        merged(
          {
            'keys': <num>[1, 2],
            'lasts': 5,
          },
          {'keys': null},
        ),
        {'lasts': 5},
      );
    });

    test('no parts: the same snapshot, so identical still says unchanged', () {
      final held = <String, dynamic>{'moving': 'x'};
      expect(identical(merged(held, const {}), held), isTrue);
    });

    test('a layer not held yet is made of its parts', () {
      expect(merged(const {}, {'moving': 'x'}), {'moving': 'x'});
    });

    test('what was parsed is carried for the parts that stay only', () {
      final held = <String, dynamic>{'moving': 'x y', 'values': 'x y z'};
      var parses = 0;
      List<String> read(Map<String, dynamic> snapshot, String part) =>
          parsedOnce(snapshot, part, () {
            parses++;
            return spaced(snapshot[part]);
          });
      Set<String> readSet(Map<String, dynamic> snapshot) =>
          parsedOnce(snapshot, 'moving', () {
            parses++;
            return spaced(snapshot['moving']).toSet();
          }, as: 'set');
      read(held, 'moving');
      readSet(held);
      read(held, 'values');
      expect(parses, 3);

      final next = merged(held, {'moving': 'x'});
      expect(identical(read(next, 'values'), read(held, 'values')), isTrue);
      expect(parses, 3, reason: 'values stayed: not parsed again');
      expect(read(next, 'moving'), ['x']);
      expect(readSet(next), {'x'});
      expect(parses, 5, reason: 'both forms of the part that came');
      expect(read(held, 'moving'), [
        'x',
        'y',
      ], reason: 'the old one is as it was');
    });
  });

  test('reads of the document snapshot as the engine writes them', () {
    // The texts engine/base/json_parts_test.cpp expects of the engine, inside motolii_snapshot's frame.
    Map<String, dynamic> read(String text) => snapshotOf(bytes(text));
    final first = read(
      '{"document":{"layers":[1],"seconds":30},'
      '"layer":{"1":{"keys":[0,2],"moving":"x y","value":{"x":1.5}}}}',
    );
    var document = merged(const {}, first['document'] as Map<String, dynamic>),
        layer = merged(
          const {},
          (first['layer'] as Map<String, dynamic>)['1'] as Map<String, dynamic>,
        );
    expect(document, {
      'layers': [1],
      'seconds': 30,
    });

    // A value dragged: one part of one layer, nothing of the document.
    final second = read('{"document":{},"layer":{"1":{"value":{"x":2}}}}');
    final sameDocument = merged(
      document,
      second['document'] as Map<String, dynamic>,
    );
    expect(identical(sameDocument, document), isTrue);
    layer = merged(
      layer,
      (second['layer'] as Map<String, dynamic>)['1'] as Map<String, dynamic>,
    );
    expect(layer, {
      'keys': [0, 2],
      'moving': 'x y',
      'value': {'x': 2},
    });

    // Its last keyframe removed: the part is gone. No layer changed in the read after: none is named.
    final third = read('{"document":{},"layer":{"1":{"keys":null}}}');
    layer = merged(
      layer,
      (third['layer'] as Map<String, dynamic>)['1'] as Map<String, dynamic>,
    );
    expect(layer.containsKey('keys'), isFalse);
    expect(read('{"document":{},"layer":{}}')['layer'], isEmpty);
    document = sameDocument;
  });

  group('structure', () {
    test('a value dragged or a keyframe moved brings numbers alone', () {
      expect(
        hasStructure({
          'value': {'x': 2},
        }),
        isFalse,
      );
      expect(
        hasStructure({
          'lasts': 5,
          'stretches': '',
          'keys': <num>[],
          'value': <String, dynamic>{},
          'keyTimes': <String, dynamic>{},
          'keyValues': <String, dynamic>{},
          'keyEasings': <String, dynamic>{},
        }),
        isFalse,
      );
      expect(hasStructure(const {}), isFalse);
    });

    test('a word, a card or a range among them is structure', () {
      for (final part in [
        'word',
        'cards',
        'more',
        'fx',
        'values',
        'moving',
        'range',
        'words',
        'reading',
        'shown',
      ]) {
        expect(
          hasStructure({'value': <String, dynamic>{}, part: ''}),
          isTrue,
          reason: part,
        );
      }
    });

    test(
      'the document: its account of the change is not structure, the rest is',
      () {
        expect(
          hasDocumentStructure({'changes': '3 x\n', 'edited': 12.5}),
          isFalse,
        );
        expect(hasDocumentStructure(const {}), isFalse);
        for (final part in [
          'seconds',
          'size',
          'layers',
          'marks',
          'easingNames',
        ]) {
          expect(
            hasDocumentStructure({'changes': '', part: 0}),
            isTrue,
            reason: part,
          );
        }
      },
    );
  });

  test('spaced: the words, empty ones left out', () {
    expect(spaced('x  y scale_x '), ['x', 'y', 'scale_x']);
    expect(spaced(''), isEmpty);
    expect(spaced(null), isEmpty);
    expect(() => spaced('x').add('y'), throwsUnsupportedError);
  });

  test('numbers: a JSON array as doubles', () {
    expect(numbers([0, 1.5, 2]), [0.0, 1.5, 2.0]);
    expect(numbers(null), isEmpty);
    expect(() => numbers([1]).add(2), throwsUnsupportedError);
  });

  test('named: each line cut at its first space only', () {
    expect(named('1.5 intro part\n3 x\nlayers\n\n 4'), [
      ('1.5', 'intro part'),
      ('3', 'x'),
    ]);
    expect(named(null), isEmpty);
  });

  test('cardsIn: titles and their names; a card may have none', () {
    final cards = cardsIn('Transform: x y; Glow: ; Fill: fill');
    expect(
      [for (final (title, _) in cards) title],
      ['Transform', 'Glow', 'Fill'],
    );
    expect(
      [for (final (_, names) in cards) names],
      [
        ['x', 'y'],
        <String>[],
        ['fill'],
      ],
    );
    expect(cardsIn(''), isEmpty);
    expect(cardsIn(null), isEmpty);
  });
}
