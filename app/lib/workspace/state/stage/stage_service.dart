// The stage's calls to the engine: what the stage reads of the document and the picture, and what its tools and drags change.
// The panels in workspace/stage/ call these instead of the engine, so they hold plain values only.
import 'dart:ui' show Offset;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// ---- reads ---------------------------------------------------------------------------------------------------------------

/// Whether the window is connected to the engine (not the sample document).
bool stageConnected(WorkspaceController ws) => ws.inside != null;

/// A layer's string property by name (kind, file, shape, fill ...). Empty if it has none, or when not connected.
String stageWord(WorkspaceController ws, int layer, String name) =>
    ws.inside?.word(layer, name) ?? '';

/// A layer's own value of a property at time [at]. Null when there is none.
double? stageValue(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside?.value(layer, name, at);

/// How long a layer is on, in seconds. A negative value means it never ends.
double stageLasts(WorkspaceController ws, int layer) =>
    ws.inside?.lasts(layer) ?? -1;

/// The length of the whole project in seconds.
double stageSeconds(WorkspaceController ws) => ws.inside?.seconds ?? 0;

/// The time of the frame the stage last drew, in seconds.
double stageNow(WorkspaceController ws) => ws.inside?.now ?? 0;

/// Canvas points per stage unit at z = 0 (the project's own unit).
double stagePointsPerUnit(WorkspaceController ws) => ws.inside?.point ?? 1;

/// The layers of the document, in the engine's order.
List<int> stageLayers(WorkspaceController ws) => ws.inside?.layers ?? const [];

/// The layer that [layer] is parented to, or 0 when it has none.
int stageParentOf(WorkspaceController ws, int layer) =>
    ws.inside?.parentOf(layer) ?? 0;

/// The outermost ancestor of [layer], itself when it has no parent.
int stageOutermost(WorkspaceController ws, int layer) =>
    ws.inside?.outermost(layer) ?? layer;

/// The guides: 'x' or 'y', each with its distance in points from the canvas's left or top edge.
List<(String, double)> stageGuides(WorkspaceController ws) =>
    ws.inside?.guides ?? const [];

/// A layer's box on the canvas at the stage's time: centre x, y, width, height, rotation, anchor x, y and depth.
List<double>? stageBounds(WorkspaceController ws, int layer) =>
    ws.inside?.bounds(layer);

/// The points of a path shape as drawn on the canvas, without handles.
List<Offset> stagePathPoints(WorkspaceController ws, int layer) =>
    ws.inside?.points(layer) ?? const [];

/// The path's curve handles, each paired with the point it belongs to.
List<(Offset, Offset)> stagePathHandles(WorkspaceController ws, int layer) =>
    ws.inside?.handles(layer) ?? const [];

/// The camera the Camera tool acts on: the selected one when it is a camera, else the first camera of the project.
int? stageCameraLayer(WorkspaceController ws, String? selected) {
  final m = ws.inside, picked = int.tryParse(selected ?? '');
  if (m == null) return null;
  if (picked != null && m.word(picked, 'kind') == 'camera') return picked;
  for (final l in ws.layers) {
    if (int.tryParse(l.id) case final t? when m.word(t, 'kind') == 'camera') {
      return t;
    }
  }
  return null;
}

/// The engine's own message for the last refused call.
String stageError(WorkspaceController ws) => ws.inside?.error ?? '';

/// The engine's message plus, where known, a short hint on how to fix it. The engine's messages stay terse so the
/// error log reads cleanly; the hint is the app's layer on top (UAT 141).
String stageErrorWithHint(WorkspaceController ws) {
  final why = stageError(ws);
  if (why.isEmpty) return '';
  // Each entry: the substring that identifies the engine message, and the fix hint appended to it.
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

/// The motion path of [layer] between [from] and [to] seconds, in [n] samples, as the engine computes it (null if none).
Future<List<double>?> stageMotionPath(
  WorkspaceController ws,
  int layer, {
  required double from,
  required double to,
  required int n,
}) => ws.inside!.path(layer, from: from, to: to, n: n);

// ---- writes: each is one engine call, queued without waiting (see Motolii.later) -----------------------------------------

/// Starts a drag of [layer] in the engine.
void stageStartDrag(WorkspaceController ws, int layer) =>
    ws.inside!.take(layer);

/// Updates the drag in progress: [by] says what is dragged (see Motolii.dragUpdate).
void stageUpdateDrag(
  WorkspaceController ws,
  String by,
  double a, [
  double b = 0,
]) => ws.inside!.dragUpdate(by, a, b);

/// Ends the drag in progress. [keep] false discards it. Returns the ticket to pass to WorkspaceController.after.
int stageEndDrag(WorkspaceController ws, {required bool keep}) =>
    ws.inside!.later('drag_end', number: keep ? 1 : 0);

/// Starts an undo step: the changes that follow are one step, ended by [stageEndUndoStep].
void stageBeginUndoStep(WorkspaceController ws) =>
    ws.inside!.later('together', number: 1);

/// Ends the undo step started by [stageBeginUndoStep]. Returns the ticket to pass to WorkspaceController.after.
int stageEndUndoStep(WorkspaceController ws) => ws.inside!.later('together');

/// Sets a numeric property of [layer] (layer -1 is the one just added).
int stageSetValue(
  WorkspaceController ws, {
  required int layer,
  required String name,
  required double number,
}) => ws.inside!.later('set', layer: layer, name: name, number: number);

/// Sets a text property of [layer] (layer -1 is the one just added).
int stageSetWord(
  WorkspaceController ws, {
  required int layer,
  required String name,
  required String word,
}) => ws.inside!.later('say', layer: layer, name: name, word: word);

/// Adds a layer named [name] whose kind or file is [word] (layer -1 refers to it afterwards).
int stageAddLayer(
  WorkspaceController ws, {
  required String name,
  required String word,
}) => ws.inside!.later('add', name: name, word: word);

/// Moves [layer] in the stacking order by [number] places.
int stageRaiseLayer(
  WorkspaceController ws, {
  required int layer,
  required double number,
}) => ws.inside!.later('raise', layer: layer, number: number);

/// Adds a guide on [axis] ('x' or 'y') at [number], or removes one with [word] 'off'.
int stageGuide(
  WorkspaceController ws, {
  required String axis,
  required double number,
  String word = '',
}) => ws.inside!.later('guide', name: axis, number: number, word: word);

/// Makes a fitted curve from the pen scribble, given as the engine reads it.
int stageFitCurve(WorkspaceController ws, String word) =>
    ws.inside!.later('curve', word: word);

/// Adds a point to the pen's path. [layer] is the selected layer for the first point, else -1.
int stagePenPoint(
  WorkspaceController ws, {
  required int layer,
  required String word,
}) => ws.inside!.later('pen', layer: layer, word: word);

/// Makes a stroke of the brush (or erases with it from [layer]).
int stageBrushStroke(
  WorkspaceController ws, {
  int layer = 0,
  required String word,
}) => ws.inside!.later('brush', layer: layer, word: word);

/// Saves the frame at the playhead as a PNG at [png]. False if the engine refused it.
bool stageTakeStill(WorkspaceController ws, String png) =>
    ws.inside!.still(png);

// ---- the pane the engine draws ------------------------------------------------------------------------------------------

/// The engine's drawing of the whole pane (see the stage's StageDesk): which engine it was last sent to.
///
/// The engine is told where the stage sits, and which layer is selected and hovered. [adopt] keeps the engine it was
/// last sent to, so a different project starts again.
class StageDeskLink {
  Motolii? _engine;

  /// Whether the window's engine is not the one this link was last sent to.
  bool changedFor(WorkspaceController ws) => ws.inside != _engine;

  /// Remembers the window's engine, when it has one.
  void adopt(WorkspaceController ws) => _engine = ws.inside;

  /// Whether the pane has an engine to draw it.
  bool get attached => _engine != null;

  /// Asks the engine to draw the whole pane (see Motolii.desk). Returns the ticket for [answer].
  int draw(int w, int h, double x, double y, double scale, double point) =>
      _engine!.desk(w, h, x, y, scale, point);

  /// The ticket's answer: -1 not yet, 0 refused, 1 done.
  int answer(int ticket) => _engine!.answer(ticket);

  /// The texture id of the pane as the engine draws it, or -1 if unavailable.
  Future<int> texture() => _engine!.deskTexture();

  /// Tells the engine which layer is selected and which is under the pointer (0 for none).
  void pick(int layer, int hover) => _engine!.pick(layer, hover);

  /// Gives the stage back to the engine's own view.
  void release() => _engine?.desk(0, 0, 0, 0, 0, 0);
}

// ---- what was last told to the engine, so each change is told once ------------------------------------------------------

/// Whether the Camera View tab's image is wanted, as last told to the engine (see stage_camera.dart).
class CameraViewLink {
  Motolii? _engine;
  bool _seen = false;

  /// Tells the engine whether the image is wanted, when that or the engine has changed.
  void tell(WorkspaceController ws, bool seen) {
    final m = ws.inside;
    if (m == _engine && seen == _seen) return;
    // A newly opened document starts with the tab not announced.
    _engine = m;
    _seen = seen;
    m?.later('camera_view', word: seen ? 'on' : '');
  }

  /// Tells the engine the image is no longer wanted, when the tab goes.
  void forget() => _engine?.later('camera_view');
}

/// The view camera the stage was last told (see stage.dart): once per change of the engine or the view.
class ViewCameraLink {
  Motolii? _engine;
  String _word = '';

  /// Tells the engine the view camera, if it is a new one. Does nothing before there is an engine.
  void tell(WorkspaceController ws, String word) {
    final m = ws.inside;
    if (m == null || (m == _engine && word == _word)) return;
    _engine = m;
    _word = word;
    m.later('view_camera', word: word);
  }
}
