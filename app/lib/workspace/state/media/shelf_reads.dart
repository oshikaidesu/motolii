// What the shelves list from the engine: the create scripts, elements, motions, relations, looks, layer effects and
// stage effects, each as a name and a file, and the search that orders them. Panels read them from here.
import 'package:motolii/bridge/motolii.dart' show ShelfItem;
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

export 'package:motolii/bridge/motolii.dart' show ShelfItem;

/// The engine's create scripts, each a name and what it makes. None when no project is open.
List<(String, String)> createScriptsOf(WorkspaceController ws) =>
    ws.inside?.createScripts ?? const [];

/// The elements saved in the project's shelf, each a name and file.
List<(String, String)> elementsOf(WorkspaceController ws) =>
    ws.inside?.elements ?? const [];

/// The looks saved from layers, each a name and file.
List<(String, String)> presetsOf(WorkspaceController ws) =>
    ws.inside?.presets ?? const [];

/// The motions a layer can be given, each a name and file.
List<(String, String)> animatorsOf(WorkspaceController ws) =>
    ws.inside?.animators ?? const [];

/// The relations stored as files, each a name and file.
List<(String, String)> relationsOf(WorkspaceController ws) =>
    ws.inside?.relations ?? const [];

/// The effects a layer can be given, each a name and the value that turns it on.
List<(String, String)> layerEffectsOf(WorkspaceController ws) =>
    ws.inside?.layerEffects ?? const [];

/// The value that turns layer effect [name] on. Throws if there is no such effect.
String layerEffectValue(WorkspaceController ws, String name) =>
    ws.inside!.layerEffects.firstWhere((e) => e.$1 == name).$2;

/// The shelf items in the listing [from] (screen, thing, look, motion or relation), in the engine's order.
List<ShelfItem> itemsOf(WorkspaceController ws, String from) =>
    ws.inside?.items(from) ?? const [];

/// The shelf item with this name or file, or null if there is none.
ShelfItem? itemOf(WorkspaceController ws, String id) => ws.inside?.item(id);

/// The ids of [items] that match [words], best first, keeping those that score at least [least] (the engine's find).
List<String> findIn(
  WorkspaceController ws,
  String words,
  Iterable<(String, String, String)> items, {
  double least = 0,
}) => ws.inside?.find(words, items, least: least) ?? const [];
