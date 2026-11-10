// ColorTheme.parse: the colour roles of a skin's theme.xml. The expected values are what the code gave when this was
// written, so a move that changes one fails here. Reads no file and needs no engine.
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/theme.dart';

void main() {
  test('parse reads every role whose value is #rrggbb or #rrggbbaa, and no other role', () {
    final roles = ColorTheme.parse('''
<Motolii><Theme>
  <ChosenDefault Value="#b3c66b"/>
  <Grey07 Value="#13131380" />
  <Shade Value="light"/>
  <Corner Value="3"/>
  <TooShort Value="#fff"/>
  <OddLength Value="#1234567"/>
</Theme></Motolii>
''');
    expect(roles, {'ChosenDefault': const Color(0xFFB3C66B), 'Grey07': const Color(0x80131313)});
  });

  test('parse keeps the last value of a role written twice', () {
    expect(ColorTheme.parse('<Alert Value="#ff0000"/><Alert Value="#00ff00"/>'), {'Alert': const Color(0xFF00FF00)});
  });

  test('parse gives no roles for a text with none', () {
    expect(ColorTheme.parse(''), isEmpty);
    expect(ColorTheme.parse('<Motolii><Theme></Theme></Motolii>'), isEmpty);
  });
}
