import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/sets/inspector/inspector_param_controls_angle_dial.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart';
import 'package:lab_book/sets/inspector/inspector_studies.dart';

Param one(String field) => readParams('struct P {\n  $field\n}').single;

/// Turns the pointer round the dial's middle [turns] times, a little at a time; what the doc then holds.
Future<double?> turn(WidgetTester tester, Param p, double turns) async {
  final doc = Doc(Kind.shape);
  await tester.pumpWidget(WidgetsApp(color: const Color(0xFF000000), builder: (c, _) => Ctx(cfg: const Cfg(), doc: doc, child: Center(child: AngleDial(id: p.id, p: p)))));
  final o = tester.getCenter(find.byType(AngleDial));
  Offset at(double a) => o + Offset(math.cos(a), math.sin(a)) * 8;
  final g = await tester.startGesture(at(0));
  for (var i = 1; i <= turns * 36; i++) {
    await g.moveTo(at(i * math.pi / 18));
  }
  await g.up();
  return doc.get(p.id);
}

void main() {
  test('an effect\'s knob is an angle by its label, in English or AviUtl\'s Japanese; how fast is not one', () {
    for (final l in ['Angle', 'X Rotation', 'hueShift', '角度', 'X軸回転', '色相']) {
      expect(angleLabel(l), isTrue, reason: l);
    }
    for (final l in ['Amount', '回転速度', 'Spin speed', '強さ']) {
      expect(angleLabel(l), isFalse, reason: l);
    }
  });

  testWidgets('a knob typed past its slider turns past it too, as far as one typed goes', (tester) async {
    expect(await turn(tester, one('rotate: f32, // @ui(angle) @range(-180, 180) @valid(-1000000, 1000000) @unit(°)'), 2), closeTo(720, 1));
  });

  testWidgets('a closed knob of one turn goes round again inside it; a narrower one stops at its end', (tester) async {
    final v = await turn(tester, one('a: f32, // @ui(angle) @range(-180, 180) @unit(°)'), 1.25);
    expect(v, inInclusiveRange(-180, 180));
    expect(v, closeTo(90, 1));
    expect(await turn(tester, one('skew: f32, // @ui(angle) @range(-80, 80) @unit(°)'), 1), 80);
  });
}
