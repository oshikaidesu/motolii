// js_returned.dart: an expression's each() as the inside reads it (motolii_js_returned, engine/js_returned.cpp): a row
// for each property it returns, and the numbers and knobs that make it, as places in the code. The inside counts in
// UTF-8 bytes, a Dart String in UTF-16 code units: the places are turned here, so a comment in Japanese or an emoji
// before a number moves nothing. A change goes into the code at that place alone (Processing's Tweak Mode): the code
// is the one thing kept.
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../motolii_bindings.dart' as c;

/// What makes a row's value: a number, or a knob (k.Name, k["Name"]). [start] and [end] are the String's indices.
sealed class JsPart {
  const JsPart(this.start, this.end);
  final int start, end;
}

class JsNumber extends JsPart {
  const JsNumber(super.start, super.end);
  @override
  String toString() => 'JsNumber($start, $end)';
}

class JsKnob extends JsPart {
  const JsKnob(this.name, int start, int end) : super(start, end);
  final String name;
  @override
  String toString() => 'JsKnob($name, $start, $end)';
}

/// A property each() returns: its name, where its value is written, and what makes it, in the order they stand (a name
/// in the value followed to what each() says of it: a part may lie outside [start]..[end]).
class JsRow {
  const JsRow(this.name, this.start, this.end, this.parts);
  final String name;
  final int start, end;
  final List<JsPart> parts;
  @override
  String toString() => 'JsRow($name, $start, $end, $parts)';
}

/// The rows of [src]'s each(), asked of the inside at [libPath] (Motolii.libPath); none: no each() returning an object.
List<JsRow> jsReturned(String libPath, String src) {
  final said = src.toNativeUtf8();
  try {
    return jsRows(src, c.MotoliiBindings(DynamicLibrary.open(libPath)).motolii_js_returned(said).toDartString());
  } finally {
    malloc.free(said);
  }
}

/// The inside's answer for [src] ("name\tstart\tend\tparts" a line) as rows, its UTF-8 bytes made [src]'s indices. A
/// line or a part that cannot be read is left out, the others kept.
List<JsRow> jsRows(String src, String said) {
  final at = _utf16At(src);
  int? place(String bytes) => switch (int.tryParse(bytes)) { final b? when b >= 0 && b < at.length => at[b], _ => null };
  final rows = <JsRow>[];
  for (final line in const LineSplitter().convert(said)) {
    final f = line.split('\t');
    if (f.length < 3) continue;
    final start = place(f[1]), end = place(f[2]);
    if (start == null || end == null) continue;
    final parts = <JsPart>[
      // (n:start:end, k:Name:start:end; a knob's name may hold a space or a colon: the two numbers end it)
      for (final m in _part.allMatches(f.length > 3 ? f.sublist(3).join('\t') : ''))
        if ((place(m[3]!), place(m[4]!)) case (final a?, final b?)) m[1] == 'n' ? JsNumber(a, b) : JsKnob(m[2]!, a, b),
    ];
    rows.add(JsRow(f[0], start, end, parts));
  }
  return rows;
}

final _part = RegExp(r'(?:^| )(n|k:(.*?)):(\d+):(\d+)(?= |$)');

/// [src] with [p]'s place written as [text], and nothing else changed.
String withNumber(String src, JsPart p, String text) => src.replaceRange(p.start, p.end, text);

/// For each byte of [src] as UTF-8 (as toNativeUtf8 makes it), the index in [src] of the character it is part of; one
/// more at the end, [src]'s length. A lone surrogate is three bytes, as utf8.encode writes it (U+FFFD).
List<int> _utf16At(String src) {
  final at = <int>[];
  var i = 0;
  for (final r in src.runes) {
    final bytes = r < 0x80 ? 1 : r < 0x800 ? 2 : r < 0x10000 ? 3 : 4;
    for (var k = 0; k < bytes; k++) {
      at.add(i);
    }
    i += r >= 0x10000 ? 2 : 1;
  }
  at.add(i);
  assert(at.length == utf8.encode(src).length + 1);
  return at;
}
