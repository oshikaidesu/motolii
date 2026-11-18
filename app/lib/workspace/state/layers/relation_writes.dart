// Writes that make or change relations between layers: a relation made from the layers selected together, and a layer
// taken out of one.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd, sayWord, setNumber;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Queues a relation of [kind] over the layers [who] as one undo step. [label] names it on its row and card. The new
/// behaviour is selected once it exists. When [ordered], the first of [who] leads it, if the file has a leader.
void queueRelation(
  WorkspaceController ws,
  String kind,
  String label,
  List<int> who,
  bool ordered,
) {
  final m = ws.inside!;
  groupBegin(ws); // One undo step, queued without waiting; the behaviour is the layer that add creates.
  int? made;
  // Selected as soon as it exists, which shows its card and its row.
  ws.after(m.later('add', name: 'behaviour', word: 'relate'), null, (b) {
    made = b;
    ws.select(b);
  });
  sayWord(ws, -1, 'script', kind);
  sayWord(
    ws,
    -1,
    'name',
    label,
  ); // The row and the card show which relation it is.
  setNumber(
    ws,
    -1,
    'strength',
    1,
  ); // Set explicitly so the card shows it as it works.
  m.later('relate', layer: -1, word: who.join(' '));
  ws.after(groupEnd(ws), (_, _) {
    ws.reread(); // Whether or not it was made, the app shows what the document holds.
    // The layers were selected one by one, so the first one selected leads, if the file has a leader.
    final b = made;
    if (ordered &&
        b != null &&
        ws.inside?.values(b).contains('js_leader') == true) {
      ws.after(
        m.later('lead', layer: b, number: who.first.toDouble()),
        (_, _) => ws.reread(),
      );
    }
  });
}

/// Takes layer [layer] out of the relation [relation], as one undo step.
void freeFromRelation(WorkspaceController ws, int layer, int relation) =>
    ws.after(
      ws.inside!.later('free', layer: layer, number: relation.toDouble()),
      (_, _) => ws.reread(),
    );
