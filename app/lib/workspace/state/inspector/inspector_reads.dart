// Reads for the inspector from the engine: the cards a layer has, how each value is shown, and which values can take
// keyframes. Each returns plain values, and none of them changes the document.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// How a property is shown on its card: its look, unit, label, slider range, fold, and whether it may go past its range.
typedef ShownFact = ({
  String label,
  String look,
  String unit,
  double low,
  double high,
  String? fold,
  bool open,
});

/// How property [name] is shown (Motolii.shown), or null when the engine has none for it.
ShownFact? shownFactOf(WorkspaceController ws, String name) {
  final s = ws.inside?.shown(name);
  return s == null
      ? null
      : (
          label: s.label,
          look: s.look,
          unit: s.unit,
          low: s.low,
          high: s.high,
          fold: s.fold,
          open: s.open,
        );
}

/// The cards of layer [t], each its title and its property names (Motolii.cards). Empty when no project is open.
List<(String, List<String>)> layerCardsOf(WorkspaceController ws, int t) =>
    ws.inside?.cards(t) ?? const [];

/// The lowest and highest value of a numeric property of layer [t] (Motolii.range), or null when it has none.
(double, double)? layerRangeOf(WorkspaceController ws, int t, String name) =>
    ws.inside?.range(t, name);

/// The layers other than [t] (layers only, not relations or behaviours), keyed by their row number on the timeline and the
/// name shown there. Like After Effects' parent list.
Map<String, int> otherLayers(WorkspaceController ws, int t) {
  final rows = ws.layers.where(
    (l) => l.id != t && layerWord(ws, l.id, 'kind') != 'behaviour',
  );
  return {for (final l in rows) '${ws.layers.indexOf(l) + 1}. ${l.name}': l.id};
}

/// The name of the colour whose first number is [n], or null. The engine stores an ISF colour as three numbers
/// (`base_x`, `base_y`, `base_z`, labelled `… r`, `… g`, `… b` by the shelf); the cards show them as one colour.
String? colourBaseOf(WorkspaceController ws, String n, List<String> names) {
  if (!n.endsWith('_x') || !(shownFactOf(ws, n)?.label ?? '').endsWith(' r')) {
    return null;
  }
  final base = n.substring(0, n.length - 2);
  return names.contains('${base}_y') && names.contains('${base}_z')
      ? base
      : null;
}

/// Whether [n] is one of the three numbers of a colour (see [colourBaseOf]).
bool isColourPartOf(WorkspaceController ws, String n) =>
    RegExp(r'_[xyz]$').hasMatch(n) &&
    RegExp(r' [rgb]$').hasMatch(shownFactOf(ws, n)?.label ?? '');

/// The keyframe state of value [name] of layer [t] at [at], as an index into the inspector's KeyframeState (Motolii.keyed).
int keyedStateAt(WorkspaceController ws, int t, String name, double at) =>
    ws.inside!.keyed(t, name, at);

/// The values on the cards of layer [t] that can take keyframes, mapping the inspector's id to the document's name.
Map<String, String> keyableValuesOf(WorkspaceController ws, int t) {
  final moving = layerMoving(ws, t).toSet();
  return {
    for (final (_, names) in layerCardsOf(ws, t))
      for (final n in names)
        if (moving.contains(n)) 'v_$n': n,
  };
}

/// Whether the stage (layer 0) has any keyframe at all.
bool stageHasKeys(WorkspaceController ws) =>
    layerMoving(ws, 0).any((n) => layerKeyTimes(ws, 0, n).isNotEmpty);

/// The names of the properties that change which cards a layer has (Motolii.shaping). The engine owns this rule.
Set<String> shapingNamesOf(WorkspaceController ws) =>
    ws.inside?.shaping ?? const {};

/// What identifies the open project: a new one differs from the one before, so the panel keeps its cards per project.
Object? openProjectToken(WorkspaceController ws) => ws.inside;

/// Throws when no project is open. The inspector is built only with one, so a missing project is a bug, not a state to show.
void requireProject(WorkspaceController ws) => ws.inside!;
