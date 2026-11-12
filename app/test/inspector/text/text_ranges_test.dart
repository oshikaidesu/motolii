// The text layer's text_styles value: one range of characters per line, "start count declarations", start and count in
// characters as After Effects' style.setFontSize(value, startIndex, numOfCharacters) counts them, the declarations in
// CSS. Where ranges overlap the later line wins, as a later CSS rule does. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/text/text_ranges.dart';

/// The ranges [styles] holds, as lists, so the matcher compares the maps by content and not by the order of their keys.
List<List<Object>> _read(String styles) => [
  for (final r in readRanges(styles)) [r.start, r.count, r.sets],
];

void main() {
  test('reads one range per line, its declarations split on ; and : with the spaces trimmed', () {
    expect(
      _read('0 5 color: #ff8a3d; font-size: 150%\n7 2   font-weight :bold ;'),
      [
        [
          0,
          5,
          {'color': '#ff8a3d', 'font-size': '150%'},
        ],
        [
          7,
          2,
          {'font-weight': 'bold'},
        ],
      ],
    );
  });

  test('skips lines that do not start with two whole numbers', () {
    expect(
      _read(
        'color: red\n3 color: red\nx 2 color: red\n1.5 2 color: red\n\n4 1 color: blue',
      ),
      [
        [
          4,
          1,
          {'color': 'blue'},
        ],
      ],
    );
  });

  test('writes one line per range and reads back the same ranges', () {
    final ranges = <TextRange>[
      (start: 0, count: 5, sets: {'color': '#ff8a3d', 'font-size': '150%'}),
      (start: 7, count: 2, sets: {'font-weight': 'bold'}),
    ];
    final written = writeRanges(ranges);
    expect(
      written,
      '0 5 color: #ff8a3d; font-size: 150%\n7 2 font-weight: bold',
    );
    expect(_read(written), [
      for (final r in ranges) [r.start, r.count, r.sets],
    ]);
  });

  test('leaves out ranges of no characters and ranges that set nothing', () {
    expect(
      writeRanges([
        (start: 0, count: 0, sets: {'color': 'red'}),
        (start: 1, count: 2, sets: {}),
        (start: 3, count: 1, sets: {'color': 'blue'}),
      ]),
      '3 1 color: blue',
    );
  });

  test('a span no range has yet is appended as a new last line', () {
    expect(_read(styleRange('0 5 color: red', 6, 3, 'font-size', '150%')), [
      [
        0,
        5,
        {'color': 'red'},
      ],
      [
        6,
        3,
        {'font-size': '150%'},
      ],
    ]);
    expect(_read(styleRange('', 0, 4, 'color', 'red')), [
      [
        0,
        4,
        {'color': 'red'},
      ],
    ]);
  });

  test('the same span keeps its other declarations, takes the new one, and moves to the end so it wins', () {
    final styles = '2 3 color: red; font-size: 150%\n0 10 color: blue';
    expect(_read(styleRange(styles, 2, 3, 'color', 'green')), [
      [
        0,
        10,
        {'color': 'blue'},
      ],
      [
        2,
        3,
        {'color': 'green', 'font-size': '150%'},
      ],
    ]);
    expect(_read(styleRange(styles, 2, 3, 'font-weight', 'bold')), [
      [
        0,
        10,
        {'color': 'blue'},
      ],
      [
        2,
        3,
        {'color': 'red', 'font-size': '150%', 'font-weight': 'bold'},
      ],
    ]);
  });

  test('a range wholly inside the span loses the property and keeps its others; one left with nothing is dropped', () {
    final styles =
        '2 2 color: red; font-size: 150%\n5 1 color: blue\n12 1 color: gray';
    expect(_read(styleRange(styles, 0, 10, 'color', 'green')), [
      [
        2,
        2,
        {'font-size': '150%'},
      ],
      [
        12,
        1,
        {'color': 'gray'},
      ],
      [
        0,
        10,
        {'color': 'green'},
      ],
    ]);
  });

  test('a range only partly inside the span is left alone', () {
    final styles = '3 5 color: red\n0 2 color: blue';
    expect(_read(styleRange(styles, 1, 4, 'color', 'green')), [
      [
        3,
        5,
        {'color': 'red'},
      ],
      [
        0,
        2,
        {'color': 'blue'},
      ],
      [
        1,
        4,
        {'color': 'green'},
      ],
    ]);
  });

  test('a null value removes the property, drops the ranges left with nothing, and adds no line', () {
    final styles =
        '0 4 color: red; font-size: 150%\n1 1 color: blue\n6 2 color: gray';
    // Where the emptied same-span line ends up is not in the format's rules, so the order is not checked.
    expect(
      _read(styleRange(styles, 0, 4, 'color', null)),
      unorderedEquals([
        [
          6,
          2,
          {'color': 'gray'},
        ],
        [
          0,
          4,
          {'font-size': '150%'},
        ],
      ]),
    );
    expect(_read(styleRange('1 1 color: blue', 0, 4, 'color', null)), isEmpty);
  });

  test('rangeValue gives the value every character shares, and null when they disagree', () {
    const styles = '0 4 color: red\n4 4 color: red\n8 2 color: blue';
    expect(rangeValue(styles, 0, 8, 'color'), 'red');
    expect(rangeValue(styles, 2, 4, 'color'), 'red');
    expect(rangeValue(styles, 6, 4, 'color'), isNull);
    expect(rangeValue(styles, 8, 2, 'color'), 'blue');
  });

  test(
    'rangeValue is null when any character has no range setting the property',
    () {
      const styles = '0 4 color: red\n4 4 font-size: 150%';
      expect(rangeValue(styles, 0, 4, 'color'), 'red');
      expect(rangeValue(styles, 0, 6, 'color'), isNull);
      expect(rangeValue(styles, 0, 2, 'font-size'), isNull);
      expect(rangeValue('', 0, 1, 'color'), isNull);
    },
  );

  test('rangeValue takes the last range covering each character that sets the property', () {
    const styles = '0 10 color: red\n2 3 color: blue\n0 10 font-size: 150%';
    expect(rangeValue(styles, 2, 3, 'color'), 'blue');
    expect(rangeValue(styles, 0, 2, 'color'), 'red');
    expect(rangeValue(styles, 0, 5, 'color'), isNull);
    // A later range that sets something else does not hide the earlier color.
    expect(rangeValue(styles, 5, 5, 'color'), 'red');
    expect(
      rangeValue('2 3 color: blue\n0 10 color: red', 2, 3, 'color'),
      'red',
    );
  });

  group('rangeValue with otherwise', () {
    test('characters no range sets take otherwise, so a span no range covers gives otherwise', () {
      expect(rangeValue('', 0, 4, 'color', otherwise: 'white'), 'white');
      expect(
        rangeValue('0 4 font-size: 150%', 0, 4, 'color', otherwise: 'white'),
        'white',
      );
    });

    test('half covered by a range of another value is null; of the same value, that value', () {
      expect(
        rangeValue('0 2 color: red', 0, 4, 'color', otherwise: 'white'),
        isNull,
      );
      expect(
        rangeValue('0 2 color: white', 0, 4, 'color', otherwise: 'white'),
        'white',
      );
    });

    test('characters set by ranges that disagree are still null, and covered ones ignore otherwise', () {
      const styles = '0 2 color: red\n2 2 color: blue';
      expect(rangeValue(styles, 0, 4, 'color', otherwise: 'red'), isNull);
      expect(rangeValue(styles, 2, 2, 'color', otherwise: 'red'), 'blue');
    });
  });

  group('shiftRanges keeps each range on its letters after an edit', () {
    test('a range wholly before the edit is untouched', () {
      expect(_read(shiftRanges('0 3 color: red', 5, 1, 2)), [
        [
          0,
          3,
          {'color': 'red'},
        ],
      ]);
    });

    test('a range wholly after the edit moves by inserted minus removed, its declarations kept', () {
      expect(
        shiftRanges('6 2 color: red; font-size: 150%', 2, 1, 3),
        '8 2 color: red; font-size: 150%',
      );
      expect(_read(shiftRanges('6 2 color: red', 2, 3, 1)), [
        [
          4,
          2,
          {'color': 'red'},
        ],
      ]);
    });

    test(
      'a range around the edit grows or shrinks by inserted minus removed',
      () {
        expect(_read(shiftRanges('0 10 color: red', 3, 2, 5)), [
          [
            0,
            13,
            {'color': 'red'},
          ],
        ]);
        expect(_read(shiftRanges('0 10 color: red', 3, 4, 1)), [
          [
            0,
            7,
            {'color': 'red'},
          ],
        ]);
      },
    );

    test("typing right at a range's end takes the new letters in", () {
      expect(_read(shiftRanges('2 3 color: red', 5, 0, 2)), [
        [
          2,
          5,
          {'color': 'red'},
        ],
      ]);
    });

    test("typing right at a range's start takes the new letters in and keeps the start", () {
      expect(_read(shiftRanges('2 3 color: red', 2, 0, 2)), [
        [
          2,
          5,
          {'color': 'red'},
        ],
      ]);
    });

    test('a range whose letters are all removed is dropped', () {
      expect(shiftRanges('3 2 color: red', 2, 4, 1), '');
      expect(_read(shiftRanges('3 2 color: red\n0 1 color: blue', 2, 4, 1)), [
        [
          0,
          1,
          {'color': 'blue'},
        ],
      ]);
    });

    test('a range ending inside the removed span is clipped, its end at the end of the inserted letters', () {
      expect(_read(shiftRanges('0 4 color: red', 2, 4, 0)), [
        [
          0,
          2,
          {'color': 'red'},
        ],
      ]);
      expect(_read(shiftRanges('0 4 color: red', 2, 4, 1)), [
        [
          0,
          3,
          {'color': 'red'},
        ],
      ]);
    });

    test('a range starting inside the removed span loses its removed letters and keeps the rest', () {
      // Letters 4..9; 2..5 are replaced by one letter, so 6..9 remain and land at 3..6.
      expect(_read(shiftRanges('4 6 color: red', 2, 4, 1)), [
        [
          3,
          4,
          {'color': 'red'},
        ],
      ]);
    });

    test('several ranges move at once and keep their order', () {
      expect(
        _read(
          shiftRanges(
            '0 2 color: red\n4 2 color: blue\n0 8 font-size: 150%',
            3,
            0,
            1,
          ),
        ),
        [
          [
            0,
            2,
            {'color': 'red'},
          ],
          [
            5,
            2,
            {'color': 'blue'},
          ],
          [
            0,
            9,
            {'font-size': '150%'},
          ],
        ],
      );
    });
  });
}
