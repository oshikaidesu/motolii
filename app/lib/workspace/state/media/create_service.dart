// What the Create shelf asks of the engine when a tile runs: a create script, a layer, an element and a pasted code file.
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/script_files.dart' show folderTwoUp;
import 'package:motolii/workspace/state/media/shelf_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Whether the engine has a create script called [name].
bool hasScript(WorkspaceController ws, String name) =>
    createScriptsOf(ws).any((r) => r.$1 == name);

/// Whether the project has a saved element called [name].
bool hasElement(WorkspaceController ws, String name) =>
    elementsOf(ws).any((e) => e.$1 == name);

/// The file of the saved element called [name], or null if there is none.
String? elementFile(WorkspaceController ws, String name) =>
    elementsOf(ws).where((e) => e.$1 == name).firstOrNull?.$2;

/// The folder that holds the engine's recipes, where the motion previews of the scripts are made.
String recipeHome(WorkspaceController ws) => folderTwoUp(ws.inside!.libPath);

/// Runs create script [name] at the playhead, as one undo step. Returns its ticket.
int makeRecipe(WorkspaceController ws, String name) =>
    ws.inside!.later('create', word: name);

/// Adds a layer named [name] from [word] (its kind or file). Returns its ticket.
int addLayer(WorkspaceController ws, String name, String word) =>
    ws.inside!.later('add', name: name, word: word);

/// Adds the saved element in [file] at [at] seconds. Returns its ticket.
int addElement(WorkspaceController ws, String file, double at) =>
    ws.inside!.later('element', word: file, number: at);

/// Makes a layer from the code in [file] through the adapter of what it was written for, with [layer] (the picked layer,
/// or 0 for none) as the layer it is made from. Returns its ticket.
int adaptCode(WorkspaceController ws, int layer, String file) =>
    ws.inside!.later('adapter', layer: layer, word: file);
