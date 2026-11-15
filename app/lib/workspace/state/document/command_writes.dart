// The engine calls the workspace commands make on the selected layers: arrange, time, layer, group and edit. Each is one
// request to the engine, returning its ticket for WorkspaceController.after. The commands in workspace/commands/ call these.
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/window_paths.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Aligns the layers [layers] (in the order selected) by [how]: left, top, across and the rest.
int alignPicked(WorkspaceController ws, String how, List<int> layers) =>
    ws.inside!.later('align', word: '$how ${layers.join(' ')}');

/// Fits layer [layer] to the canvas by [how]: `fit`, `fill` or `stretch`.
int fitLayer(WorkspaceController ws, int layer, String how) =>
    ws.inside!.later('fit', layer: layer, word: how);

/// Flips layer [layer] along [axis], `x` or `y`.
int flipLayer(WorkspaceController ws, int layer, String axis) =>
    ws.inside!.later('flip', layer: layer, word: axis);

/// Aligns the timing of the layers [layers] by [how] at [seconds] (the playhead).
int timeAlignPicked(
  WorkspaceController ws,
  String how,
  List<int> layers,
  double seconds,
) => ws.inside!.later(
  'time_align',
  word: '$how ${layers.join(' ')}',
  number: seconds,
);

/// Removes layer [layer].
int removeLayer(WorkspaceController ws, int layer) =>
    ws.inside!.later('remove', layer: layer);

/// Duplicates layer [layer]. Returns the ticket; the copy's id is the answer.
int duplicateLayer(WorkspaceController ws, int layer) =>
    ws.inside!.later('duplicate', layer: layer);

/// Makes layer [layer] a path of the outline it shows, whose points then belong to the pen tool.
int outlineLayer(WorkspaceController ws, int layer) =>
    ws.inside!.later('outline', layer: layer);

/// Moves the sound of the video [layer] to a layer of its own and mutes the video.
int extractSoundOf(WorkspaceController ws, int layer) =>
    ws.inside!.later('extract_sound', layer: layer);

/// Splits layer [layer] at [seconds]; the part after it is the new layer.
int splitLayerAt(WorkspaceController ws, int layer, double seconds) =>
    ws.inside!.later('split', layer: layer, number: seconds);

/// Places the layers one after another, in the order they were made.
int sequenceLayers(WorkspaceController ws) => ws.inside!.later('sequence');

/// Lowers the video [layer] under the sound of the other layers.
int duckLayer(WorkspaceController ws, int layer) =>
    ws.inside!.later('duck', layer: layer);

/// Sets the easing of the stretch of property [name] on layer [layer] that starts at [at] seconds to Linear.
int resetEasing(WorkspaceController ws, int layer, String name, double at) => ws
    .inside!
    .later('easing', layer: layer, name: name, number: at, word: 'Linear');

/// Makes layer [layer] follow the group it is parented to, which was the last one added.
int followLastAdded(WorkspaceController ws, int layer) =>
    ws.inside!.later('set', layer: layer, name: 'parent', word: 'last_added');

/// Copies layer [layer] to the clipboard file, as the Edit menu's copy does.
int copyLayerThing(WorkspaceController ws, int layer) =>
    ws.inside!.later('copy', layer: layer, word: clipboardFile('thing'));

/// Copies the style of layer [layer] to the clipboard file.
int copyLayerStyle(WorkspaceController ws, int layer) =>
    ws.inside!.later('copy_style', layer: layer, word: clipboardFile('style'));

/// Pastes the layer in the clipboard file at [seconds], as the playhead's layer.
int pasteLayer(WorkspaceController ws, double seconds) =>
    ws.inside!.later('paste', word: clipboardFile('thing'), number: seconds);

/// Pastes the style in the clipboard file onto layer [layer].
int pasteStyleTo(WorkspaceController ws, int layer) =>
    ws.inside!.later('paste_style', layer: layer, word: clipboardFile('style'));

/// Removes the work area and closes the gap it leaves.
int extractWorkArea(WorkspaceController ws) => ws.inside!.later('extract');

/// Saves layer [layer] as a look on the Effects shelf, named [name]. [then] hears whether the engine kept it. The engine's
/// folders are read again first, so the shelf shows the new look.
void keepLook(
  WorkspaceController ws,
  int layer,
  String name,
  void Function(bool done, String why) then,
) {
  final m = ws.inside!;
  ws.after(m.later('keep_preset', layer: layer, word: name), (done, why) {
    m.forgetFolders();
    then(done, why);
  });
}

/// Saves layer [layer] with its contents among the elements on the Create shelf, named [name]. [then] hears whether the
/// engine kept it. The engine's folders are read again first.
void keepElement(
  WorkspaceController ws,
  int layer,
  String name,
  void Function(bool done, String why) then,
) {
  final m = ws.inside!;
  ws.after(m.later('keep_element', layer: layer, word: name), (done, why) {
    m.forgetFolders();
    then(done, why);
  });
}
