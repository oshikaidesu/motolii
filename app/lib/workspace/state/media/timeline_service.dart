// Engine calls the timeline makes: switches, keys, markers, work area, tempo, drags and media reads.
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
import 'package:motolii/workspace/timeline/audio_fade.dart'
    show buildAudioFadeKeys;

/// Whether the window is connected to the engine's document.
bool isConnected(WorkspaceController ws) => ws.inside != null;

/// The engine's clock in seconds.
double clockSeconds(WorkspaceController ws) => ws.inside!.now;

bool isLooping(WorkspaceController ws) => ws.inside!.looping;

void toggleLooping(WorkspaceController ws) {
  final m = ws.inside!;
  m.looping = !m.looping;
}

double? layerValue(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside!.value(layer, name, at);

List<double> keyframeTimes(WorkspaceController ws, int layer, String name) =>
    ws.inside!.keyTimes(layer, name);

/// Returns the ticket of the change.
int addKeyframe(
  WorkspaceController ws,
  int layer,
  String name,
  double seconds,
) => ws.inside!.later('key_here', layer: layer, name: name, number: seconds);

/// Returns the ticket of the change.
int removeKeyframe(
  WorkspaceController ws,
  int layer,
  String name,
  double seconds,
) => ws.inside!.later('unkey', layer: layer, name: name, number: seconds);

/// Sets visible to 0 (hidden) or 1.
int setLayerVisible(WorkspaceController ws, int layer, bool visible) => ws
    .inside!
    .later('set', layer: layer, name: 'visible', number: visible ? 1 : 0);

int setLayerClipped(WorkspaceController ws, int layer, bool clipped) => ws
    .inside!
    .later('set', layer: layer, name: 'clip', number: clipped ? 1 : 0);

/// Turns the switch [name] (`solo` or `lock`) on or off.
int setLayerSwitch(WorkspaceController ws, int layer, String name, bool on) =>
    ws.inside!.later('set', layer: layer, name: name, number: on ? 1 : 0);

int reorderLayer(WorkspaceController ws, int layer, double places) =>
    ws.inside!.later('raise', layer: layer, number: places);

int renameLayer(WorkspaceController ws, int layer, String name) =>
    ws.inside!.later('say', layer: layer, name: 'name', word: name);

int setTempo(WorkspaceController ws, double bpm) =>
    ws.inside!.later('set', layer: 0, name: 'bpm', number: bpm);

int setBeatGridStart(WorkspaceController ws, double seconds) =>
    ws.inside!.later('set', layer: 0, name: 'bpm_from', number: seconds);

int addMarker(WorkspaceController ws, double seconds, String name) =>
    ws.inside!.later('mark', number: seconds, word: name);

int renameMarker(WorkspaceController ws, double seconds, String name) =>
    ws.inside!.later('mark', number: seconds, word: name);

int removeMarker(WorkspaceController ws, double seconds) =>
    ws.inside!.later('mark', number: seconds);

/// [colour] is counted from 1.
int recolourMarker(WorkspaceController ws, double seconds, int colour) =>
    ws.inside!.later('mark_colour', number: seconds, word: '$colour');

/// Moves the marker from [from] to [to] as one undo step.
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

int setWorkArea(WorkspaceController ws, double from, double to) =>
    ws.inside!.later('work', number: from, word: '$to');

/// Drags part [part] of a bar (`head`, `tail`, `bar`, `begin`) by [seconds].
void dragBarPart(WorkspaceController ws, String part, double seconds) {
  ws.inside!.dragUpdate(part, seconds);
}

/// Ends a bar drag. [kept] = false reverts.
int endBarDrag(WorkspaceController ws, bool kept) =>
    ws.inside!.later('drag_end', number: kept ? 1 : 0);

void grabLayer(WorkspaceController ws, int layer) => ws.inside!.take(layer);

/// The writes that slide [keys] by [by] frames.
Iterable<int> slideKeyframeWrites(
  WorkspaceController ws,
  Iterable<SelectedKeyframe> keys,
  int by,
) => slideWrites(ws.inside!, keys, by);

/// Snapshots which properties each selected keyframe carries. Called once at drag start.
/// With [property], only that property is cached (lane stretch drag).
List<SlideEntry> cacheSelectedSlide(
  WorkspaceController ws,
  List<SelectedKeyframe> keys, {
  String? property,
}) => cacheSlide(ws.inside!, keys, property: property);

/// Length of [file] in seconds (0 for images or unreadable files).
Future<double> filmSeconds(WorkspaceController ws, String file) =>
    mediaSecondsOf(ws.inside!.libPath, file);

/// The PNG path of the video frame at [seconds], or null.
Future<String?> videoFrame(
  WorkspaceController ws,
  String file,
  double seconds,
) => ws.inside!.videoFrame(file, seconds);

/// Beat times in seconds at [rise] threshold.
Future<List<double>> strikesOf(
  WorkspaceController ws,
  int layer,
  double rise,
) => ws.inside!.strikes(layer, rise);

/// Loudness of [layer] from [from] to [to] in [n] steps, or null if not yet computed.
Future<List<double>?> loudnessOver(
  WorkspaceController ws,
  int layer,
  double from,
  double to,
  int n,
) => ws.inside!.loudnessOver(layer, from, to, n);

/// Loudness of every frame of [layer].
Future<List<double>> loudnessOf(WorkspaceController ws, int layer) =>
    ws.inside!.loudness(layer);

/// Current playback speed of [layer] (1.0 when unset).
double layerSpeed(WorkspaceController ws, int layer) =>
    ws.inside!.value(layer, 'speed', 0) ?? 1.0;

/// Current time-stretch hold anchor of [layer] (`start`, `now`, or `end`).
String layerSpeedHold(WorkspaceController ws, int layer) {
  final w = ws.inside!.word(layer, 'speed_hold');
  return w.isEmpty ? 'start' : w;
}

/// Persists the time-stretch hold anchor (`start`, `now`, or `end`) of [layer].
int setSpeedHold(WorkspaceController ws, int layer, String hold) =>
    ws.inside!.later('say', layer: layer, name: 'speed_hold', word: hold);

/// Stretches [layer] to [speed] about [hold] (`start`, `now`, or `end`) at [now] seconds.
int stretchLayerSpeed(
  WorkspaceController ws,
  int layer,
  double speed,
  String hold,
  double now,
) => ws.inside!.later(
  'time_stretch',
  layer: layer,
  number: speed,
  word: '$hold $now',
);

/// Writes fade-in and fade-out durations onto [layer]'s `volume` keyframes in one undo step.
int applyAudioFade(
  WorkspaceController ws,
  int layer, {
  required int inF,
  required int outF,
  required int fadeInF,
  required int fadeOutF,
  required double peak,
}) {
  final m = ws.inside!;
  final level = peak > 0.01 ? peak : 1.0;
  final keys = buildAudioFadeKeys(
    inF: inF,
    outF: outF,
    fadeInF: fadeInF,
    fadeOutF: fadeOutF,
    peak: level,
    fps: WorkspaceController.fps,
  );
  m.later('together', number: 1);
  m.later(
    'stay',
    layer: layer,
    name: 'volume',
    number: inF / WorkspaceController.fps,
  );
  m.later('set', layer: layer, name: 'volume', number: level);
  for (final (sec, val) in keys) {
    m.later('key', layer: layer, name: 'volume', word: '$sec', number: val);
  }
  return m.later('together');
}
