// The stage's calls to the engine. Stage panels call these instead of the engine directly.
import 'dart:ui' show Offset;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// ---- reads ---------------------------------------------------------------------------------------------------------------

/// Whether the engine is connected.
bool stageConnected(WorkspaceController ws) => ws.inside != null;

/// A layer's string property. Empty if none or not connected.
String stageWord(WorkspaceController ws, int layer, String name) =>
    ws.inside?.word(layer, name) ?? '';

/// A layer's numeric value at [at], or null.
double? stageValue(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside?.value(layer, name, at);

/// The times of a property's keyframes, or empty when none or not connected.
List<double> stageKeyTimes(WorkspaceController ws, int layer, String name) =>
    ws.inside?.keyTimes(layer, name) ?? const [];

/// Layer duration in seconds. Negative = infinite.
double stageLasts(WorkspaceController ws, int layer) =>
    ws.inside?.lasts(layer) ?? -1;

/// Project length in seconds.
double stageSeconds(WorkspaceController ws) => ws.inside?.seconds ?? 0;

/// Time of the last drawn frame, in seconds.
double stageNow(WorkspaceController ws) => ws.inside?.now ?? 0;

/// Canvas points per stage unit at z = 0.
double stagePointsPerUnit(WorkspaceController ws) => ws.inside?.point ?? 1;

/// Layers in document order.
List<int> stageLayers(WorkspaceController ws) => ws.inside?.layers ?? const [];

/// Parent of [layer], or 0.
int stageParentOf(WorkspaceController ws, int layer) =>
    ws.inside?.parentOf(layer) ?? 0;

/// Outermost ancestor, or the layer itself.
int stageOutermost(WorkspaceController ws, int layer) =>
    ws.inside?.outermost(layer) ?? layer;

/// Guides: axis + distance in canvas points.
List<(String, double)> stageGuides(WorkspaceController ws) =>
    ws.inside?.guides ?? const [];

/// Layer box: [cx, cy, w, h, rotation, ax, ay, depth].
List<double>? stageBounds(WorkspaceController ws, int layer) =>
    ws.inside?.bounds(layer);

/// Path points on canvas, without handles.
List<Offset> stagePathPoints(WorkspaceController ws, int layer) =>
    ws.inside?.points(layer) ?? const [];

/// Path handles, paired with their points.
List<(Offset, Offset)> stagePathHandles(WorkspaceController ws, int layer) =>
    ws.inside?.handles(layer) ?? const [];

/// The camera the Camera tool acts on: the selected one when it is a camera, else the first camera of the project.
int? stageCameraLayer(WorkspaceController ws, int? selected) {
  final m = ws.inside;
  if (m == null) return null;
  if (selected != null && m.word(selected, 'kind') == 'camera') return selected;
  for (final l in ws.layers) {
    if (m.word(l.id, 'kind') == 'camera') return l.id;
  }
  return null;
}

/// The engine's own message for the last refused call.
String stageError(WorkspaceController ws) => ws.inside?.error ?? '';

/// Engine error message plus a user-facing fix hint where known.
String stageErrorWithHint(WorkspaceController ws) {
  final why = stageError(ws);
  if (why.isEmpty) return '';
  const hints = <(String, String)>[
    ('there is no such folder', 'Pick a folder that exists'),
    ('it is being written already', 'Wait for the current export, or Cancel'),
    ('a film is written as', 'Use .mp4, .mov, .gif, .png or .jpg'),
    (
      'the file could not be written',
      'Check that the disk has room and the folder is writable',
    ),
    (
      'the picture could not be read back',
      'Try again, or export frames instead',
    ),
    ('the document could not keep it', 'Reload the project and retry'),
    ('cancelled', ''),
  ];
  for (final (needle, hint) in hints) {
    if (why.contains(needle) && hint.isNotEmpty) return '$why · $hint';
  }
  return why;
}

/// Motion path of [layer] from [from] to [to], [n] samples (null if none).
Future<List<double>?> stageMotionPath(
  WorkspaceController ws,
  int layer, {
  required double from,
  required double to,
  required int n,
}) => ws.inside!.path(layer, from: from, to: to, n: n);

// ---- writes: each is one engine call, queued without waiting (see Motolii.later) -----------------------------------------

void stageStartDrag(WorkspaceController ws, int layer) =>
    ws.inside!.take(layer);

void stageUpdateDrag(
  WorkspaceController ws,
  String by,
  double a, [
  double b = 0,
]) => ws.inside!.dragUpdate(by, a, b);

/// [keep] false discards the drag.
int stageEndDrag(WorkspaceController ws, {required bool keep}) =>
    ws.inside!.later('drag_end', number: keep ? 1 : 0);

void stageBeginUndoStep(WorkspaceController ws) =>
    ws.inside!.later('together', number: 1);

int stageEndUndoStep(WorkspaceController ws) => ws.inside!.later('together');

/// Layer -1 = the one just added.
int stageSetValue(
  WorkspaceController ws, {
  required int layer,
  required String name,
  required double number,
}) => ws.inside!.later('set', layer: layer, name: name, number: number);

/// Writes a keyframe for [name] on [layer] at [seconds] regardless of Animate All.
int stageKeyValue(
  WorkspaceController ws, {
  required int layer,
  required String name,
  required double seconds,
  required double number,
}) => ws.inside!.later(
  'key',
  layer: layer,
  name: name,
  word: '$seconds',
  number: number,
);

int stageSetWord(
  WorkspaceController ws, {
  required int layer,
  required String name,
  required String word,
}) => ws.inside!.later('say', layer: layer, name: name, word: word);

int stageAddLayer(
  WorkspaceController ws, {
  required String name,
  required String word,
}) => ws.inside!.later('add', name: name, word: word);

int stageRaiseLayer(
  WorkspaceController ws, {
  required int layer,
  required double number,
}) => ws.inside!.later('raise', layer: layer, number: number);

/// [word] 'off' removes the guide.
int stageGuide(
  WorkspaceController ws, {
  required String axis,
  required double number,
  String word = '',
}) => ws.inside!.later('guide', name: axis, number: number, word: word);

int stageFitCurve(WorkspaceController ws, String word) =>
    ws.inside!.later('curve', word: word);

/// First point: [layer] = selected. Later: [layer] = -1.
int stagePenPoint(
  WorkspaceController ws, {
  required int layer,
  required String word,
}) => ws.inside!.later('pen', layer: layer, word: word);

int stageBrushStroke(
  WorkspaceController ws, {
  int layer = 0,
  required String word,
}) => ws.inside!.later('brush', layer: layer, word: word);

bool stageTakeStill(WorkspaceController ws, String png) =>
    ws.inside!.still(png);

// ---- the pane the engine draws ------------------------------------------------------------------------------------------

/// Link to the engine's desk rendering. [adopt] pins the engine so a project switch re-announces.
class StageDeskLink {
  Motolii? _engine;

  bool changedFor(WorkspaceController ws) => ws.inside != _engine;

  void adopt(WorkspaceController ws) => _engine = ws.inside;

  bool get attached => _engine != null;

  int draw(int w, int h, double x, double y, double scale, double point) =>
      _engine!.desk(w, h, x, y, scale, point);

  /// -1 not yet, 0 refused, 1 done.
  int answer(int ticket) => _engine!.answer(ticket);

  Future<int> texture() => _engine!.deskTexture();

  void pick(int layer, int hover) => _engine!.pick(layer, hover);

  void release() => _engine?.desk(0, 0, 0, 0, 0, 0);
}

// ---- what was last told to the engine, so each change is told once ------------------------------------------------------

/// Tracks the camera-view tab's on/off state so each change is told to the engine once.
class CameraViewLink {
  Motolii? _engine;
  bool _seen = false;

  void tell(WorkspaceController ws, bool seen) {
    final m = ws.inside;
    if (m == _engine && seen == _seen) return;
    // A new document resets the state.
    _engine = m;
    _seen = seen;
    m?.later('camera_view', word: seen ? 'on' : '');
  }

  void forget() => _engine?.later('camera_view');
}

/// Tracks the view camera so each change is told once.
class ViewCameraLink {
  Motolii? _engine;
  String _word = '';

  void tell(WorkspaceController ws, String word) {
    final m = ws.inside;
    if (m == null || (m == _engine && word == _word)) return;
    _engine = m;
    _word = word;
    m.later('view_camera', word: word);
  }
}
