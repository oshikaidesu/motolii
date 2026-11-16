// What the panels may ask of the engine without calling it: whether a project is open, and the folders the engine
// and the app keep their files in. The calls themselves are made in the state services beside this.
import 'package:motolii/bridge/engine_paths.dart'
    show motoliiDir, motoliiOwn, motoliiShelves;
import 'package:motolii/storage/shelf_meta.dart' show loadAllShelfMeta;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Whether a project is open in the engine.
bool projectOpen(WorkspaceController ws) => ws.inside != null;

/// The user's own folder: its shelves, its agents and its programs.
String ownFolder() => motoliiOwn;

/// The engine's folder (engine/), with its third-party files.
String engineFolder() => motoliiDir;

/// The shelves that ship with Motolii. Also loads all meta.yaml files the first time it is called.
String shelvesFolder() {
  loadAllShelfMeta(motoliiShelves);
  return motoliiShelves;
}
