// Reads of the document as a whole, and of the engine's own clock and diagnostics. Panels ask here; the engine is held only by the state.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Whether the window is connected to an engine. False for the sample document.
bool isConnected(WorkspaceController ws) => ws.inside != null;

// Each engine the window has been connected to gets its own number, and none gets 0. The top bar counts a project's
// problems from the start of that project, so a new engine starts again.
final _engineIds = Expando<int>();
int _lastEngineId = 0;
int engineIdOf(WorkspaceController ws) {
  final m = ws.inside;
  if (m == null) return 0;
  return _engineIds[m] ??= ++_lastEngineId;
}

/// The time of the frame the stage last drew, in seconds. Null when not connected.
double? documentNow(WorkspaceController ws) => ws.inside?.now;

/// Canvas points per stage unit at z = 0. Null when not connected.
double? documentPoint(WorkspaceController ws) => ws.inside?.point;

/// The project's frame rate in frames per second. Null when not connected.
int? documentRate(WorkspaceController ws) => ws.inside?.rate;

/// How long the project has been worked on, in whole seconds. Null when not connected.
int? documentEdited(WorkspaceController ws) => ws.inside?.edited;

/// The engine's diagnostics, one line each. Null when not connected.
String? engineBroken(WorkspaceController ws) => ws.inside?.broken;

/// How much of a frame's time the engine took for the frames drawn since the last call (see `EngineLoad.take`).
/// Null when not connected or when it drew none.
({double cpu, double cpuMost, double gpu})? engineLoadTaken(
  WorkspaceController ws,
) => ws.inside?.load.take();

/// How many diagnostics the engine has recorded. Null when not connected.
int? engineBrokenCount(WorkspaceController ws) => ws.inside?.brokenCount;
