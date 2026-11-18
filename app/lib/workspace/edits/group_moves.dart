// Moves of the Move in relation (relations/Group.js): layers animate in or out together.
//
// A move is defined by:
// - which layers it moves, in order;
// - when it runs: two keyframes on the group's strength, with each layer starting one lag after the previous one;
// - where it goes: the relation's own x, y, spread, scatter, size, opacity and rotation are one end, the layers' own
//   positions the other;
// - the easing between the two keyframes.
//
// The move is read from the document and queued on the engine without waiting. The position of a layer at the other
// end is asked of the engine (where it shows at full strength) and is never computed here.
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/layers/group_move_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The name of a move on its row: its direction and its layers, for example 'in · TURN IN TIME'.
String groupMoveName(WorkspaceController ws, Iterable<int> who, bool coming) {
  final names = [
    for (final id in who)
      ws.layers.where((l) => l.id == id).firstOrNull?.name ?? '$id',
  ];
  final all = names.length > 4
      ? '${names.take(3).join(' ')} +${names.length - 3}'
      : names.join(' ');
  return '${coming ? 'in' : 'out'} · $all';
}

/// Makes a move of the layers [who] as one undo step and selects it.
///
/// The layers come in at [start] from a little below, transparent, each a little later than the one before.
/// Layers that already come in through another move go out through this one instead.
/// A move made later in the video leaves the earlier part alone.
void makeGroupMove(WorkspaceController ws, List<int> who, double start) {
  final file = groupRelationFile(ws);
  if (!projectOpen(ws) || file == null || who.isEmpty) return;
  final held = layersHeldByGroups(ws);
  final coming = !who.any(held.contains);
  final closed = queueGroupMove(
    ws,
    file,
    who,
    coming,
    start,
    groupMoveName(ws, who, coming),
  );
  ws.after(closed, (done, why) {
    if (!done) ws.notice = 'No move made: $why'; // The whole undo step is undone; the top bar shows why.
    ws.reread();
  });
}
