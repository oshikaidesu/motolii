// A plain-words name for the last undo or redo step, as After Effects' and Premiere Pro's Edit menu show it
// ("Undo Change Warmth"). Reads [WorkspaceController.lastChange].
import 'package:motolii/workspace/state/document/document_reads.dart'
    show isConnected;
import 'package:motolii/workspace/state/layers/layer_reads.dart'
    show propertyLook;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Returns [verb] alone when there is no change to describe (project just opened, not connected), or
/// "[verb]: Stage distance · Layer 1 rotate" and so on when the last change reports layers and values.
String undoStepName(WorkspaceController ws, String verb) {
  final c = ws.lastChange;
  if (c == null || !isConnected(ws)) return verb;
  if (c.layers) return '$verb: things added or taken away';
  final byThing = <int, Set<String>>{};
  for (final (t, n) in c.values) {
    (byThing[t] ??= {}).add(propertyLook(ws, n)?.label ?? n);
  }
  String nameOf(int t) => t == 0
      ? 'Stage'
      : ws.layers.where((l) => l.id == t).firstOrNull?.name ?? 'a thing';
  final said = [
    for (final e in byThing.entries.take(3))
      '${nameOf(e.key)} ${e.value.take(3).join(', ')}${e.value.length > 3 ? '…' : ''}',
  ];
  return said.isEmpty
      ? verb
      : '$verb: ${said.join(' · ')}${byThing.length > 3 ? ' …' : ''}';
}
