// Reads of the relations between layers, from the engine's document: what a relation is, who leads it, whom it moves,
// and which relations a layer is in.
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/layer.dart' show relationKinds;
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The kind of a relation, or the script file it is written as.
String relationKindOf(WorkspaceController ws, int t) =>
    layerWord(ws, t, 'file') == 'relate'
    ? layerWord(ws, t, 'script')
    : layerWord(ws, t, 'file');

/// The layer a relation leads from: the layer its Leader names, or 0 for none.
int relationLeaderOf(WorkspaceController ws, int t) =>
    (layerValue(ws, t, 'js_leader', 0) ?? 0).round();

/// The layers that [parent] is the parent of, in the engine's order.
List<int> layersParentedTo(WorkspaceController ws, int parent) {
  final m = ws.inside;
  if (m == null) return const [];
  return [
    for (final t in m.layers)
      if ((layerValue(ws, t, 'parent', 0) ?? 0).round() == parent) t,
  ];
}

/// The layers a relation moves, when the selected layer is a relation; otherwise none.
/// A layer counts when any of its properties is connected to the relation. It is read from the app's snapshot of the
/// document, which asks the engine again only after a change.
Set<int> relationMembersOf(WorkspaceController ws) {
  final m = ws.inside, sel = ws.selected;
  if (m == null ||
      sel == null ||
      layerWord(ws, sel, 'kind') != 'behaviour' ||
      !relationKinds.contains(layerWord(ws, sel, 'file'))) {
    return const {};
  }
  return {
    for (final w in layerWord(ws, sel, 'members').split(' '))
      if (int.tryParse(w) case final t? when m.layers.contains(t)) t,
  }; // The relation's own list, in order. A layer it moves through another relation counts too.
}

/// The relation that lies under relation [r] for layer [t]: the one [t] is under in it, or 0 when there is none.
int _below(WorkspaceController ws, int r, int t) {
  final members = layerWord(ws, r, 'members').split(' '),
      under = layerWord(ws, r, 'under').split(' '),
      at = members.indexOf('$t');
  return at >= 0 && at < under.length ? int.tryParse(under[at]) ?? 0 : 0;
}

/// The relation that takes effect for the selected layer: the uppermost one whose visibility is on, or null.
int? relationInEffectOf(WorkspaceController ws) {
  final t = ws.selected;
  if (!projectOpen(ws) || t == null) return null;
  for (
    var r = (layerValue(ws, t, 'x_by', 0) ?? 0).round(), n = 0;
    r > 0 && n < 8 && relationKinds.contains(layerWord(ws, r, 'file'));
    n++
  ) {
    if ((layerValue(ws, r, 'visible', 0) ?? 1) > .5) return r;
    r = _below(ws, r, t);
  }
  return null;
}

/// The relations the selected layer is in, the topmost first: first those it leads, then the chain its position is
/// connected to. They are shown beside the layer, and a click selects one.
List<int> relationsOfSelectedOf(WorkspaceController ws) {
  final m = ws.inside, t = ws.selected;
  if (m == null || t == null || layerWord(ws, t, 'kind') == 'behaviour') {
    return const [];
  }
  final all = <int>[
    for (final r in m.layers)
      if (layerWord(ws, r, 'kind') == 'behaviour' &&
          relationKinds.contains(layerWord(ws, r, 'file')) &&
          relationLeaderOf(ws, r) == t)
        r,
  ];
  for (
    var r = (layerValue(ws, t, 'x_by', 0) ?? 0).round();
    r > 0 &&
        all.length < 8 &&
        !all.contains(r) &&
        relationKinds.contains(layerWord(ws, r, 'file'));
  ) {
    if (!all.contains(r)) all.add(r);
    r = _below(ws, r, t);
  }
  return all;
}
