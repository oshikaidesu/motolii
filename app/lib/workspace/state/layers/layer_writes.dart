// Writes to one layer. Each is one undo step, as the engine makes it: a word said, a value dragged, a layer moved.
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Says [word] for [name] on [layer] (its blend mode, for one). Nothing happens when not connected.
void sayLayer(WorkspaceController ws, int layer, String name, String word) {
  final m = ws.inside;
  if (m == null) return;
  ws.after(m.later('say', layer: layer, name: name, word: word));
}

/// Starts a drag on [layer] and sends [name] at [value] into it, as a drag on the stage does. [endDrag] closes it.
void dragLayerValue(
  WorkspaceController ws,
  int layer,
  String name,
  double value,
) {
  final m = ws.inside!;
  m.take(layer);
  m.dragUpdate(name, value);
}

/// Ends the drag in progress, which makes it one undo step.
void endDrag(WorkspaceController ws) {
  ws.after(ws.inside!.later('drag_end', number: 1));
}

/// Cancels the drag in progress: the engine discards the change and nothing is left in undo.
void cancelDrag(WorkspaceController ws) {
  ws.after(ws.inside!.later('drag_end', number: 0));
}

/// Moves [layer] by ([dx], [dy]) canvas points as a drag on the stage, one undo step. [then] hears whether the engine kept it.
void moveLayerBy(
  WorkspaceController ws,
  int layer,
  double dx,
  double dy,
  void Function(bool done, String why) then,
) {
  final m = ws.inside;
  if (m == null) return;
  // Moves the layer like a drag on the stage, without waiting for the engine.
  m.later('drag_start', layer: layer);
  m.dragUpdate('place', dx, dy);
  ws.after(m.later('drag_end', number: 1), then);
}
