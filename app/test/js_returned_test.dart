// js_returned.dart against the inside's own answer (engine/out/libmotolii.dylib, built by engine/edit.sh): a number
// changed at its place alone, the Repeater's x row reaching its knob, and places past Japanese and an emoji.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/js_returned.dart';

final engine = '${Directory.current.path}/../../engine';
final lib = '$engine/out/libmotolii.dylib';

/// [after] is [before] with [from]..[to] of it written as [text], and the same everywhere else.
void changedOnlyAt(String before, String after, int from, int to, String text) {
  expect(after.substring(0, from), before.substring(0, from));
  expect(after.substring(from, from + text.length), text);
  expect(after.substring(from + text.length), before.substring(to));
}

void main() {
  test('a Repeater-shaped each(): x\'s 0.3 becomes 0.6, nothing else', () {
    const src = '''function each(i, n, t, k) {
  const along = i - (n - 1) / 2;
  return {
    x: along * 0.3,   // Step X
    y: along * 0, z: along * 0, rotate: 0, rotate_x: i * 0, rotate_y: i * 0,
    size: Math.pow(1, i), scale_x: n > 1 ? Math.pow(1, i / (n - 1)) : 1,
  };
}
''';
    final rows = jsReturned(lib, src);
    expect(rows.map((r) => r.name), ['x', 'y', 'z', 'rotate', 'rotate_x', 'rotate_y', 'size', 'scale_x']);
    final x = rows.first;
    expect(src.substring(x.start, x.end), 'along * 0.3');
    final numbers = x.parts.whereType<JsNumber>().toList();
    expect([for (final p in numbers) src.substring(p.start, p.end)], ['1', '2', '0.3']);   // (along's, followed, then x's own)
    final p = numbers.last;
    final changed = withNumber(src, p, '0.6');
    changedOnlyAt(src, changed, p.start, p.end, '0.6');
    expect(changed.replaceFirst('0.6', '0.3'), src);
  });

  test('the Repeater itself: x reaches k.StepX, k.ScatterX and k.DriftX', () {
    final src = File('$engine/recipes/repeater.js').readAsStringSync();
    final rows = jsReturned(lib, src);
    final x = rows.firstWhere((r) => r.name == 'x');
    expect(src.substring(x.start, x.end), 'x');
    final knobs = x.parts.whereType<JsKnob>().toList();
    expect(knobs.map((k) => k.name), containsAll(['StepX', 'ScatterX', 'DriftX']));
    for (final k in knobs) {
      expect(src.substring(k.start, k.end), 'k.${k.name}');
    }
    for (final n in x.parts.whereType<JsNumber>()) {
      expect(double.tryParse(src.substring(n.start, n.end)), isNotNull);
    }
  });

  test('places past Japanese and an emoji are the String\'s own', () {
    const src = '''// 横に並べる 🎉 (an emoji is two UTF-16 units and four UTF-8 bytes)
function each(i, n, t, k) {
  const 幅 = "広い🌊"; // 日本語のコメント
  return { x: i * 0.25 + k["ステップ"], y: Math.sin(t * 3) * 0.4, "size": 1.5 };
}
''';
    final rows = jsReturned(lib, src);
    expect(rows.map((r) => r.name), ['x', 'y', 'size']);
    expect([for (final r in rows) src.substring(r.start, r.end)], ['i * 0.25 + k["ステップ"]', 'Math.sin(t * 3) * 0.4', '1.5']);
    final x = rows[0], y = rows[1];
    expect([for (final p in x.parts) src.substring(p.start, p.end)], ['0.25', 'k["ステップ"]']);
    expect((x.parts[1] as JsKnob).name, 'ステップ');
    expect([for (final p in y.parts) src.substring(p.start, p.end)], ['3', '0.4']);
    final changed = withNumber(src, y.parts[1], '0.85');
    changedOnlyAt(src, changed, y.parts[1].start, y.parts[1].end, '0.85');
    expect(jsReturned(lib, changed)[1].parts.map((p) => changed.substring(p.start, p.end)), ['3', '0.85']);
  });

  test('what cannot be read is left out, never thrown', () {
    expect(jsReturned(lib, ''), isEmpty);
    expect(jsReturned(lib, 'function each(i, n, t, k) { return { x: i * 0.3, y: '), isA<List<JsRow>>());
    expect(jsRows('ab', 'x\t0\t999\tn:0:1\nbroken\ny\t0\t1\tn:x:y k:A B:0:1'), [isA<JsRow>().having((r) => r.parts.length, 'parts', 1)]);
  });
}
