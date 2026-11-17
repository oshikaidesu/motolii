// Writes of the Ease tool: an easing put on stretches of the document, as one undo step (while the pointer is down the
// gesture stays open, see LiveEdit), and the steps an end drag makes.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/workspace/state/layers/keyframe_moves.dart'
    show slideWrites;
import 'package:motolii/workspace/state/workspace_controller.dart';

// Defines the easing in the document, so that the stretches can name it.
void _define(Motolii m, String word) {
  for (final (name, goes) in easeDefines(word)) {
    m.later('define', name: name, word: goes);
  }
}

// Defines the easing in the document and puts it on each of the stretches (layer, property, time).
void _send(Motolii m, String to, List<(int, String, double)> stretches) {
  _define(m, to);
  for (final (t, name, at) in stretches) {
    m.later('easing', layer: t, name: name, number: at, word: to);
  }
  _define(m, to);
}

/// Puts [e] on each of [stretches] while the pointer is down. The step is open, so the canvas and the bars follow it.
void liveEase(
  WorkspaceController ws,
  Ease e,
  List<(int, String, double)> stretches,
) {
  ws.live.move((m) {
    _define(m, said(e));
    for (final (t, name, at) in stretches) {
      m.later('easing', layer: t, name: name, number: at, word: said(e));
    }
    return {for (final (t, _, _) in stretches) t};
  });
}

/// Ends the pointer-down gesture with the easing [to] on [stretches], as one undo step. [then] hears why it was refused.
void settleEase(
  WorkspaceController ws,
  String to,
  List<(int, String, double)> stretches,
  void Function(String?) then,
) {
  ws.live.done((m) {
    _send(m, to, stretches);
    return const [];
  }, then);
}

/// Puts [e] on every keyframe in [stretches], as one undo step. [then] hears why it was refused.
void everyKeyEase(
  WorkspaceController ws,
  Ease e,
  List<(int, String, double)> stretches,
  void Function(String?) then,
) {
  ws.live.done((m) {
    _define(m, said(e));
    for (final (t, name, at) in stretches) {
      m.later('easing', layer: t, name: name, number: at, word: said(e));
    }
    return const [];
  }, then);
}

/// Opens the undo step that an end drag writes its keys into.
void openEaseStep(WorkspaceController ws) {
  ws.inside!.later('together', number: 1);
}

/// Keys [name] of [layer] with the value [number] at the time [word] (seconds), as one drag step.
void keyEaseProperty(
  WorkspaceController ws,
  int layer,
  String name,
  String word,
  double number,
) {
  ws.inside!.later('key', layer: layer, name: name, word: word, number: number);
}

/// Closes the undo step an end drag wrote into. [then] hears whether the engine kept it.
void closeEaseStep(
  WorkspaceController ws,
  void Function(bool done, String why) then,
) {
  ws.after(ws.inside!.later('together'), then);
}

/// Slides the keyframe at [frame] on [layer] by [step] frames, as one step of a LiveEdit gesture.
/// Returns the layers that changed, for the caller to show.
Iterable<int> trimEaseSpan(
  WorkspaceController ws,
  String layer,
  int frame,
  int step,
) {
  final m = ws.inside!;
  final key = [(layer: layer, frame: frame)];
  return slideWrites(m, key, step);
}

/// Waits until the engine shows [layer] again, then calls [then].
void showEaseLayer(
  WorkspaceController ws,
  int layer,
  void Function(bool done, String why) then,
) {
  ws.after(ws.inside!.later('show', layer: layer), then);
}
