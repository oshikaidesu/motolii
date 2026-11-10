// parseWgsl: what it reads from an effect's uniform struct. The expected values are what the code gave when this was
// written, so a move or a split that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';

List<Object?> _read(FieldDeclaration d) => [
  d.name,
  d.type,
  d.attrs,
  d.advanced,
  d.fold,
];

void main() {
  test('a text with no struct has no fields', () {
    expect(parseWgsl('fn main() {}'), isEmpty);
  });

  test('the fields of the first struct are read in order, each with its type, and a type with no control is left out', () {
    final decls = parseWgsl('''
struct Params {
  a: f32,
  b: f16,
  c: i32,
  d: u32,
  e: bool,
  f: vec2f,
  g: vec2<f32>,
  h: vec3h,
  i: vec4f,
  left_out: mat4x4f,
  last: vec4<f32>
}
struct Other { ignored: f32 }
''');
    expect(
      [for (final d in decls) (d.name, d.type)],
      const [
        ('a', WgslType.f32),
        ('b', WgslType.f32),
        ('c', WgslType.i32),
        ('d', WgslType.u32),
        ('e', WgslType.boolean),
        ('f', WgslType.vec2),
        ('g', WgslType.vec2),
        ('h', WgslType.vec3),
        ('i', WgslType.vec4),
        ('last', WgslType.vec4),
      ],
    );
  });

  test('attributes come from the lines above a field, from before its name and from the comment after it', () {
    final decls = parseWgsl('''
struct Params {
  /// @range(0, 200) @unit(px)
  /// @default(12)
  blurRadius: f32,
  mode: i32, // @enum(Low, Med, High)
  @size(4) flip: u32, // @toggle
  plain: f32,
}
''');
    expect(decls.map(_read), [
      [
        'blurRadius',
        WgslType.f32,
        {
          'range': ['0', '200'],
          'unit': ['px'],
          'default': ['12'],
        },
        false,
        null,
      ],
      [
        'mode',
        WgslType.i32,
        {
          'enum': ['Low', 'Med', 'High'],
        },
        false,
        null,
      ],
      [
        'flip',
        WgslType.u32,
        {
          'size': ['4'],
          'toggle': <String>[],
        },
        false,
        null,
      ],
      ['plain', WgslType.f32, <String, List<String>>{}, false, null],
    ]);
  });

  test('the comment after a field wins over the lines above it', () {
    final d = parseWgsl(
      'struct P {\n/// @default(1)\nx: f32, // @default(2)\n}',
    ).single;
    expect(d.attrs['default'], ['2']);
  });

  test(
    'a // @advanced line marks every field after it, and may name the fold',
    () {
      final decls = parseWgsl('''
struct Params {
  first: f32,
  // @advanced
  second: f32,
  // @advanced(Each copy)
  third: f32,
  fourth: f32,
}
''');
      expect(
        [for (final d in decls) (d.name, d.advanced, d.fold)],
        const [
          ('first', false, null),
          ('second', true, null),
          ('third', true, 'Each copy'),
          ('fourth', true, 'Each copy'),
        ],
      );
    },
  );

  test('@advanced written on a field marks that field only', () {
    final decls = parseWgsl('''
struct Params {
  /// @advanced
  first: f32,
  second: f32, // @advanced @range(0, 1)
  third: f32,
}
''');
    expect(
      [for (final d in decls) (d.name, d.advanced, d.fold)],
      const [
        ('first', true, null),
        ('second', true, null),
        ('third', false, null),
      ],
    );
  });
}
