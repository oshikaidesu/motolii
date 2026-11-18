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
