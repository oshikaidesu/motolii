// Writes to the document as a whole: undo and redo, and the settings of the stage (layer 0).
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Undoes or redoes the last change. [then] hears whether it was done and why not. Nothing happens when not connected.
void requestUndo(
  WorkspaceController ws, {
  required bool redo,
  void Function(bool done, String why)? then,
}) {
  final m = ws.inside;
  if (m == null) return;
  ws.after(m.later(redo ? 'redo' : 'undo'), then);
}

/// Sets a number on the stage (layer 0) as one undo step. [then] hears whether the engine kept it.
void setDocumentNumber(
  WorkspaceController ws,
  String name,
  double number, [
  void Function(bool done, String why)? then,
]) {
  final m = ws.inside!;
  ws.after(m.later('set', layer: 0, name: name, number: number), then);
}

/// Sets the stage's background to [hex] (empty for transparent, which is exported clear), as one undo step.
void setBackground(WorkspaceController ws, String hex) {
  final m = ws.inside!;
  m.later('together', number: 1);
  m.later('say', layer: 0, name: 'background', word: hex);
  m.later('set', layer: 0, name: 'render_alpha', number: hex.isEmpty ? 1 : 0);
  ws.after(m.later('together'), (_, _) => ws.reread());
}
