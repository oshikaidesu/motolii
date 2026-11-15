// Whether a document is open in the engine, and what the engine says of a layer. Panels ask here, not the engine.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

bool documentOpen(WorkspaceController ws) => ws.inside != null;

String layerWord(WorkspaceController ws, int layer, String name) =>
    ws.inside?.word(layer, name) ?? '';
