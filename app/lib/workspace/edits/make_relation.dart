// Relations between layers selected together (WorkspaceController.many).
//
// Making a relation adds a behaviour layer written as a file in relations/*.js and puts the selected layers in it as
// they look now: their order, and what each was in before. A file that has a Leader makes the first layer selected its
// leader, when the layers were selected one by one.
// It is one undo step, and the new behaviour is selected once it exists.
import 'package:motolii/widgets/picks.dart';
import 'package:motolii/workspace/edits/group_moves.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart' show layerWord;
import 'package:motolii/workspace/state/layers/relation_reads.dart';
import 'package:motolii/workspace/state/layers/relation_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The label of a relation file, as its row and card are named.
String relationLabel(String kind) {
  final name = kind.endsWith('Group.js')
      ? 'Move in'
      : kind.split('/').last.replaceAll('.js', '');
  return name[0].toUpperCase() + name.substring(1);
}

/// The selected layers a relation can hold. A relation that is selected with them, as Select All does, is left out.
List<int> relatableLayers(WorkspaceController ws) => [
  for (final t in ws.many)
    if (layerWord(ws, t, 'kind') != 'behaviour') t,
];

/// The layers an expression goes on as a row: the layers selected together, or the layers in the picked group.
///
/// Fewer than two means none: the expression goes on the picked layer, as a card of its own.
List<int> expressionRow(WorkspaceController ws) {
  final picked = ws.selected;
  if (relatableLayers(ws) case final many when many.length >= 2) return many;
  if (!projectOpen(ws) ||
      picked == null ||
      layerWord(ws, picked, 'shape') != 'null') {
    return const [];
  }
  final children = [for (final t in layersParentedTo(ws, picked)) t];
  return children.length >= 2 ? children : const [];
}

/// Makes a relation of [kind] from the layers selected together, or from [of] when given.
///
/// [kind] is a file in relations/*.js, or any file with each(i, n, t, k): layer i of the row is then copy i of n.
void makeRelation(WorkspaceController ws, String kind, {List<int>? of}) {
  final who = of ?? relatableLayers(ws), ordered = of == null && ws.manyInOrder;
  if (!projectOpen(ws) || who.length < 2) return;
  if (kind.endsWith('Group.js')) {
    return makeGroupMove(
      ws,
      who,
      (ws.frame / WorkspaceController.fps * 10).round() / 10,
    ); // A group is a move: it comes in at the playhead from where the group says.
  }
  queueRelation(ws, kind, relationLabel(kind), who, ordered);
}

/// What a click on layer [id] does to the layers selected together, by the one rule of every selection (picks.dart):
/// a plain click selects it alone, Command (Ctrl) adds or removes it, Shift takes the rows from the last one picked to it.
/// [order] is the rows in reading order; leave it empty where there are no rows (the stage), and Shift adds like Command.
/// A layer that was selected alone joins what is picked.
void clickLayer(WorkspaceController ws, int id, {List<int> order = const []}) {
  final (:add, :span) = clickKeys();
  if (!add && !span) return ws.select(id);
  final alone = ws.selected;
  final now = ws.many.isNotEmpty
      ? {...ws.many}
      : {if (alone != null && !relationMembersOf(ws).contains(alone)) alone};
  final r = pickOnClick(
    now: now,
    lead: ws.selection.lead ?? (ws.many.isNotEmpty ? ws.many.last : alone),
    id: id,
    order: order,
    add: add,
    span: span,
  );
  ws.pickMany(r.picked, inOrder: true, lead: r.lead);
}
