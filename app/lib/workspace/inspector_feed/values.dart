// The inspector's flags, which are view state and not the document. The engine's reads and writes of values are in
// state/inspector_values.dart; layerPlacement is re-exported here because the stage's options read it from this file.
import 'package:motolii/workspace/state/inspector/inspector_values.dart'
    show tellRefusal;
import 'package:motolii/workspace/state/workspace_controller.dart';

export 'package:motolii/workspace/state/inspector/inspector_values.dart'
    show layerPlacement;

/// How the inspector is displayed, such as its folds and whether an effect's Advanced section is open.
/// This is part of the app's view, not the document.
Map<String, bool> layerFlags(WorkspaceController ws, int? id) => {
  for (final e in ws.view.entries)
    if (e.key.startsWith('inspector.') && e.value is bool)
      e.key.substring(10): e.value as bool,
};

bool writeFlags(WorkspaceController ws, int? id, Map<String, bool> changed) {
  // The suffixes mean: .past is a card allowed past its ends (PastRange), and .code is a script's code open under its parameters (effect_code.dart).
  bool looked(String k) =>
      k.endsWith('.open') ||
      k.endsWith('.adv') ||
      k.endsWith('.code') ||
      k.endsWith('.past') ||
      k.startsWith('fold.');
  for (final e in changed.entries) {
    if (looked(e.key)) ws.view['inspector.${e.key}'] = e.value;
  }
  final other = changed.keys.where((k) => !looked(k)).firstOrNull;
  if (other == null) return true;
  // The .on flag is an effect switched off, which the document keeps as bypass.
  tellRefusal(
    ws,
    'the document has no ${other.endsWith('.on') ? 'bypass' : other}: ',
  );
  return false;
}
