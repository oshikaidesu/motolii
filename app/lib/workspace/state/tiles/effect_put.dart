// Puts an empty effect, or an empty expression, on the selected layer with its code open on its card. It gives the user
// somewhere to paste code found on the net (an ISF effect, or a .js with each(), see engine/document/scripts/expressions.h).
// The file is written fresh on each press, in the user's programs folder where a layer's own copy lives (effect_code_cards.dart),
// so what is typed belongs to that layer alone.
import 'package:motolii/bridge/engine_paths.dart' show motoliiOwn;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/shelf_disk.dart' show makeFolder, writeText;
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart'
    show codeTitleOf, showCodeCell;
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/engine_access.dart' show projectOpen;
import 'package:motolii/workspace/state/tiles/tile_review.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// Left as it is, this effect changes nothing.
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

/// Puts an empty effect on the selected layer, or an empty expression if [expression], with its code open.
/// With no layer selected it goes on a new layer, as the shelf's other effects do. [told] receives the reason it
/// was refused, or '' once it was taken.
void emptyPut(
  WorkspaceController ws, {
  required bool expression,
  void Function(String why)? told,
}) {
  if (!projectOpen(ws)) return;
  final dir =
          '$motoliiOwn/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      file = '$dir/${expression ? 'empty.js' : 'Empty.fs'}';
  makeFolder(dir);
  writeText(file, expression ? _js : _isf);
  putEffectFile(ws, file, expression: expression, told: told, open: true);
}

/// Puts an effect file (an expression file if [expression]) on the selected layer. [open] opens its code in the Code tab.
/// With no layer selected, an effect goes on a new adjustment layer and an expression on a new layer of its own.
/// [told] receives the reason it was refused, or '' once it was taken.
void putEffectFile(
  WorkspaceController ws,
  String file, {
  required bool expression,
  void Function(String why)? told,
  bool open = false,
}) {
  final m = ws.inside;
  if (m == null) return;
  final t = int.tryParse(ws.selected ?? '');
  final (word, title) = _said(t == null ? '' : m.word(t, 'fx'), file);
  if (open) showCodeCell(ws, title); // (its cell in the Code tab)
  if (t == null) {
    return expression
        ? ws.whole('rect', (m) => m.later('fx_file', layer: -1, word: word))
        : ws.adjustment(word);
  }
  ws.after(m.later('fx_file', layer: t, word: word), (done, why) {
    told?.call(done ? '' : why);
    ws.reread();
  });
}

/// Returns the file name to use among the layer's effects [fx], and the title of its card.
///
/// If the layer already has an effect of that name, it is renamed as the engine's Duplicate does ("Empty~2.fs",
/// doc_fx_duplicate). That happens for the same file, and for an empty effect beside an empty expression, which are
/// both titled Empty. Its values and title are then its own, because the engine finds a card by its title
/// (doc_fx_eye), and fx_file would otherwise remove the existing effect of the same name.
(String, String) _said(String fx, String file) {
  final title = codeTitleOf(file),
      stem = TileReview.knobStem(file).toLowerCase();
  final stems = {
    for (final w in WorkspaceController.fxFiles(fx))
      TileReview.knobStem(w).toLowerCase(),
  };
  if (!stems.contains(stem)) return (file, title);
  var n = 2;
  while (stems.contains('${stem}_$n')) {
    n++;
  }
  final dot = file.lastIndexOf('.');
  return ('${file.substring(0, dot)}~$n${file.substring(dot)}', '$title $n');
}
