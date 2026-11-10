// halfWidth and colorOfHex: typed text made plain, and a hex colour as the project and the theme file write it.
// The expected values are what the code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';

void main() {
  test('halfWidth turns full-width letters, digits and signs into plain ones and leaves the rest', () {
    expect(halfWidth('１２８：３０'), '128:30');
    expect(halfWidth('ＡＢＣ　ａｂｃ！～'), 'ABC　abc!~');
    expect(halfWidth('abc 123 かな'), 'abc 123 かな');
  });

  test('colorOfHex reads rrggbb as an opaque colour, with or without #', () {
    expect(colorOfHex('ff8000'), const Color(0xFFFF8000));
    expect(colorOfHex('#FF8000'), const Color(0xFFFF8000));
  });

  test('colorOfHex reads rrggbbaa with the alpha last', () {
    expect(colorOfHex('#ff800080'), const Color(0x80FF8000));
    expect(colorOfHex('00000000'), const Color(0x00000000));
  });

  test('colorOfHex gives null for anything else', () {
    for (final word in ['', '#', 'fff', '#ff80', 'ff80001', 'gggggg', 'red']) {
      expect(colorOfHex(word), isNull, reason: '"$word"');
    }
  });
}
