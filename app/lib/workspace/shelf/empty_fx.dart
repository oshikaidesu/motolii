// An empty effect, or an empty expression, put on the picked thing with its code open on its card: somewhere to paste
// code found on the net (an ISF effect; a .js with each(), doc_expressions.h). Written once a press, in the maker's
// programs where a thing's own copy is (fx_code.dart): the thing's alone from the first, so what is typed is its.
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../style/tokens.dart';
import 'effect_tiles.dart' show EffectTiles;
import 'fx_code.dart' show FxCode;
import '../ws.dart';

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
/// on a new board, as the shelf's others go. [told] why it is not taken, or '' once it is.
void emptyPut(Ws ws, {required bool expression, void Function(String why)? told}) {
  if (ws.inside == null) return;
  final dir = '${EffectTiles.own}/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      file = '$dir/${expression ? 'empty.js' : 'Empty.fs'}';
  Directory(dir).createSync(recursive: true);
  File(file).writeAsStringSync(expression ? _js : _isf);
  fxPut(ws, file, expression: expression, told: told, open: true);
}

/// An effect file ([expression]: an expression's) put on the picked thing; [open], its card's code open. Nothing picked:
/// on a new board, as the shelf's others go (an effect on an Adjustment board, Ws.screenToggle; an expression on a
/// board of its own, Ws.motionToggle). [told] why it is not taken, or '' once it is.
void fxPut(Ws ws, String file, {required bool expression, void Function(String why)? told, bool open = false}) {
  final m = ws.inside;
  if (m == null) return;
  final t = int.tryParse(ws.selected ?? '');
  final (word, title) = _said(t == null ? '' : m.word(t, 'fx'), file);
  if (open) ws.view['inspector.v.$title.code'] = true; // (its card's Code fold, as a hand opens it: workspace_values.dart _flag)
  if (t == null) return expression ? ws.whole('rect', (m) => m.later('fx_file', thing: -1, word: word)) : ws.adjustment(word);
  ws.after(m.later('fx_file', thing: t, word: word), (done, why) {
    told?.call(done ? '' : why);
    ws.reread();
  });
}

/// The word that says the file among the thing's effects [fx], and its card's title. One there already of its name (the
/// same file, or an empty effect beside an empty expression: both are titled Empty) is said again as the engine's
/// Duplicate says one ("Empty~2.fs", doc_fx_duplicate): its values its own, its title its own (the eye, the bin and
/// the stack find a card by its title: doc_fx_eye); fx_file would take the same word out.
(String, String) _said(String fx, String file) {
  final title = FxCode.titleOf(file), stem = EffectTiles.knobStem(file).toLowerCase();
  final stems = {for (final w in Ws.fxFiles(fx)) EffectTiles.knobStem(w).toLowerCase()};
  if (!stems.contains(stem)) return (file, title);
  var n = 2;
  while (stems.contains('${stem}_$n')) {
    n++;
  }
  final dot = file.lastIndexOf('.');
  return ('${file.substring(0, dot)}~$n${file.substring(dot)}', '$title $n');
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
