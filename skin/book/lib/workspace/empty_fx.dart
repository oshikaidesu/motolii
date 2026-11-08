// An empty effect, or an empty expression, put on the picked thing with its code open on its card: somewhere to paste
// code found on the net (an ISF effect; a .js with each(), doc_expressions.h). Written once a press, in the maker's
// programs where a thing's own copy is (fx_code.dart): the thing's alone from the first, so what is typed is its.
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../tokens.dart';
import 'effect_tiles.dart' show EffectTiles;
import 'ws.dart';

// (as it comes it changes nothing)
const _isf = '''/*{
	"DESCRIPTION": "Empty: the picture as it is. Paste an ISF effect over this",
	"ISFVSN": "2",
	"CATEGORIES": ["Custom"],
	"INPUTS": [
		{ "NAME": "inputImage", "TYPE": "image" }
	]
}*/

void main() {
	gl_FragColor = IMG_THIS_PIXEL(inputImage);
}
''';

const _js = '''// Empty: the copies where they are. Write where each goes in each(), or paste an expression over this

// i: this copy (0 first), n: how many, t: seconds, k: its knobs. Return what changes: x y z size rotate opacity…
function each(i, n, t, k) { return {}; }
''';

/// An empty effect ([expression]: an empty expression) put on the picked thing, its card's code open. Nothing picked:
/// on a new board, as the shelf's others go (an effect on an Adjustment board, Ws.screenToggle; an expression on a
/// board of its own, Ws.motionToggle). [told] why it is not taken, or '' once it is.
void emptyPut(Ws ws, {required bool expression, void Function(String why)? told}) {
  final m = ws.inside;
  if (m == null) return;
  final t = int.tryParse(ws.selected ?? '');
  final (word, title) = _written(t == null ? '' : m.word(t, 'fx'), expression);
  ws.view['inspector.v.$title.code'] = true;   // (its card's Code fold, as a hand opens it: workspace_values.dart _flag)
  if (t == null) return expression ? ws.whole('rect', (m) => m.later('fx_file', thing: -1, word: word)) : ws.adjustment(word);
  ws.after(m.later('fx_file', thing: t, word: word), (done, why) {
    told?.call(done ? '' : why);
    ws.reread();
  });
}

/// Its file written anew, and the word that says it among the thing's effects [fx] with its card's title. A second
/// on one thing is said as the engine's Duplicate says one ("Empty~2.fs", doc_fx_duplicate): its values its own.
(String, String) _written(String fx, bool expression) {
  final name = expression ? 'empty.js' : 'Empty.fs', dot = name.indexOf('.'), stem = name.substring(0, dot);
  final dir = '${EffectTiles.own}/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
  Directory(dir).createSync(recursive: true);
  File('$dir/$name').writeAsStringSync(expression ? _js : _isf);
  // (an empty effect and an empty expression are both titled Empty: counted as one, so their cards' titles differ, as
  //  the eye, the bin and the stack find a card by its title: doc_fx_eye)
  final stems = {for (final w in Ws.fxFiles(fx)) EffectTiles.knobStem(w).toLowerCase()};
  if (!stems.contains('empty')) return ('$dir/$name', 'Empty');
  var n = 2;
  while (stems.contains('empty_$n')) {
    n++;
  }
  return ('$dir/$stem~$n${name.substring(dot)}', 'Empty $n');
}

/// The "+" on its tile.
class EmptyLook extends CustomPainter {
  const EmptyLook();
  @override
  void paint(Canvas c, Size s) {
    final ink = Paint()
      ..color = Grey.g76
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(s.width / 2, s.height * .2), Offset(s.width / 2, s.height * .8), ink);
    c.drawLine(Offset(s.width / 2 - s.height * .3, s.height / 2), Offset(s.width / 2 + s.height * .3, s.height / 2), ink);
  }

  @override
  bool shouldRepaint(EmptyLook old) => false;
}
