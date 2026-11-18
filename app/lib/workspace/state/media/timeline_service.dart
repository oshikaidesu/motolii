// The engine calls the timeline makes: its layers' switches, keys, markers, work area, tempo and drags, and the media
// it reads for the rows. The timeline panels call these with the workspace and get plain values back, so the engine
// handle stays in the state.
import 'package:motolii/bridge/motolii.dart' show mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart' show slideWrites;
import 'package:motolii/workspace/state/layers/keyframe_moves.dart'
    show SlideEntry, cacheSlide;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Whether the window is connected to the engine's document. A panel checks this before it asks for an operation.
bool isConnected(WorkspaceController ws) => ws.inside != null;

/// The engine's clock in seconds, as the playhead follows it while playing.
double clockSeconds(WorkspaceController ws) => ws.inside!.now;

/// Whether the document loops playback.
bool isLooping(WorkspaceController ws) => ws.inside!.looping;

/// Turns looping on or off.
void toggleLooping(WorkspaceController ws) {
  final m = ws.inside!;
  m.looping = !m.looping;
}

/// The value of property [name] of layer [layer] at [at] seconds, or null when the engine has none.
double? layerValue(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside!.value(layer, name, at);

/// The times in seconds of the keyframes of property [name] of layer [layer].
List<double> keyframeTimes(WorkspaceController ws, int layer, String name) =>
    ws.inside!.keyTimes(layer, name);

/// Adds a keyframe to property [name] of layer [layer] at [seconds]. Returns the ticket of the change.
int addKeyframe(
  WorkspaceController ws,
  int layer,
  String name,
  double seconds,
) => ws.inside!.later('key_here', layer: layer, name: name, number: seconds);

/// Removes the keyframe at [seconds] of property [name] of layer [layer]. Returns the ticket of the change.
int removeKeyframe(
  WorkspaceController ws,
  int layer,
  String name,
  double seconds,
) => ws.inside!.later('unkey', layer: layer, name: name, number: seconds);

/// Shows or hides layer [layer], which is hidden by setting its visible property to 0.
int setLayerVisible(WorkspaceController ws, int layer, bool visible) => ws
    .inside!
    .later('set', layer: layer, name: 'visible', number: visible ? 1 : 0);

/// Clips layer [layer] to the layer below it, or removes the clip.
int setLayerClipped(WorkspaceController ws, int layer, bool clipped) => ws
    .inside!
    .later('set', layer: layer, name: 'clip', number: clipped ? 1 : 0);

/// Turns the switch [name] (`solo` or `lock`, as the project spells it) of layer [layer] on or off.
int setLayerSwitch(WorkspaceController ws, int layer, String name, bool on) =>
    ws.inside!.later('set', layer: layer, name: name, number: on ? 1 : 0);

/// Moves layer [layer] by [places] layers in the stack; a negative number lowers it.
int reorderLayer(WorkspaceController ws, int layer, double places) =>
    ws.inside!.later('raise', layer: layer, number: places);

/// Gives layer [layer] the name [name].
int renameLayer(WorkspaceController ws, int layer, String name) =>
    ws.inside!.later('say', layer: layer, name: 'name', word: name);

/// Sets the document's tempo in beats per minute.
int setTempo(WorkspaceController ws, double bpm) =>
    ws.inside!.later('set', layer: 0, name: 'bpm', number: bpm);

/// Sets the time, in seconds, where the first bar of the beat grid starts.
int setBeatGridStart(WorkspaceController ws, double seconds) =>
    ws.inside!.later('set', layer: 0, name: 'bpm_from', number: seconds);

/// Adds a marker named [name] at [seconds].
int addMarker(WorkspaceController ws, double seconds, String name) =>
    ws.inside!.later('mark', number: seconds, word: name);

/// Renames the marker at [seconds].
int renameMarker(WorkspaceController ws, double seconds, String name) =>
    ws.inside!.later('mark', number: seconds, word: name);

/// Removes the marker at [seconds].
int removeMarker(WorkspaceController ws, double seconds) =>
    ws.inside!.later('mark', number: seconds);

/// Gives the marker at [seconds] the label colour [colour], counted from 1 as the engine does.
int recolourMarker(WorkspaceController ws, double seconds, int colour) =>
    ws.inside!.later('mark_colour', number: seconds, word: '$colour');

/// Moves the marker at [from] seconds to [to] seconds and keeps its name and colour, as one undo step. Returns the
/// ticket that closes the step.
int moveMarker(WorkspaceController ws, double from, double to, String name) {
  final m = ws.inside!;
  m.later('together', number: 1);
  m.later('mark', number: from);
  m.later('mark', number: to, word: name);
  if (ws.markColors[from] case final k?) {
    m.later('mark_colour', number: to, word: '$k');
  }
  return m.later('together');
}

/// Sets the work area from [from] to [to] seconds.
int setWorkArea(WorkspaceController ws, double from, double to) =>
    ws.inside!.later('work', number: from, word: '$to');

/// Drags part [part] of a bar (`head`, `tail`, `bar`, or `begin` for a video's source) to [seconds] from where it was.
void dragBarPart(WorkspaceController ws, String part, double seconds) {
  ws.inside!.dragUpdate(part, seconds);
}

/// Ends a bar drag. [kept] says whether the engine keeps what the drag changed, or takes it back.
int endBarDrag(WorkspaceController ws, bool kept) =>
    ws.inside!.later('drag_end', number: kept ? 1 : 0);

/// Starts a drag of layer [layer]'s bar.
void grabLayer(WorkspaceController ws, int layer) => ws.inside!.take(layer);

/// The writes that slide [keys] by [by] frames, for [WorkspaceController.live] to apply at each step of a drag.
Iterable<int> slideKeyframeWrites(
  WorkspaceController ws,
  Iterable<SelectedKeyframe> keys,
  int by,
) => slideWrites(ws.inside!, keys, by);

/// Snapshots which properties each selected keyframe carries, for a cached
/// drag. Called once at drag start through the state boundary.
List<SlideEntry> cacheSelectedSlide(
  WorkspaceController ws,
  List<SelectedKeyframe> keys,
) => cacheSlide(ws.inside!, keys);

/// The length of the video [file] in seconds, read on another isolate. 0 for an image or an unreadable file.
Future<double> filmSeconds(WorkspaceController ws, String file) =>
    mediaSecondsOf(ws.inside!.libPath, file);

/// The PNG the engine made of the frame of [file] at [seconds], or null when it has none there.
Future<String?> videoFrame(
  WorkspaceController ws,
  String file,
  double seconds,
) => ws.inside!.videoFrame(file, seconds);

/// The frames where layer [layer]'s sound has a strike at [rise] loudness, in seconds.
Future<List<double>> strikesOf(
  WorkspaceController ws,
  int layer,
  double rise,
) => ws.inside!.strikes(layer, rise);

/// The loudness of layer [layer] between [from] and [to] seconds in [n] steps, or null when it is not known yet.
Future<List<double>?> loudnessOver(
  WorkspaceController ws,
  int layer,
  double from,
  double to,
  int n,
) => ws.inside!.loudnessOver(layer, from, to, n);

/// The loudness of every frame of layer [layer], read in full.
Future<List<double>> loudnessOf(WorkspaceController ws, int layer) =>
    ws.inside!.loudness(layer);
