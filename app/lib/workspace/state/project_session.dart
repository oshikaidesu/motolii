// The engine calls a window makes to open, save, export and pack its project. The window holds a ProjectSession rather than
// the engine itself, so the panels keep no engine handle; the functions below take the window's controller, as the other
// state services do.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The engine a window has open. It is opened for a document, joined to the window's controller, and closed when another
/// document replaces it.
class ProjectSession {
  Motolii? _engine;

  /// The time of the engine's playhead in seconds, or 0 when none is open.
  double get now => _engine?.now ?? 0;

  /// Opens [doc] in the engine, creating it if it does not exist. False when the engine cannot open it.
  bool open(String doc) {
    _engine = Motolii.open(doc);
    return _engine != null;
  }

  /// Closes the engine and forgets it.
  void close() {
    _engine?.close();
    _engine = null;
  }

  /// Asks the engine to follow the elements as a project opens. It is sent before the controller is joined, so the
  /// controller does not wait for it, as before.
  void followOnOpen(WorkspaceController ws) =>
      ws.after(_engine!.later('follow_elements'));

  /// The id of the texture the stage draws the project on, or a negative number when there is none.
  Future<int> texture() => _engine!.texture();

  /// Connects [ws] to the engine that was opened, so it reads the document.
  void joinInto(WorkspaceController ws) => ws.join(_engine!);

  /// Moves the engine's playhead to [seconds].
  void seek(double seconds) => _engine?.at(seconds);

  /// Saves the frame the project picture is drawn at to [png]. False if the engine refused it.
  bool keepPoster(String png) => _engine?.poster(png) ?? false;
}

/// The folder of the open project's engine library, the `libmotolii` the project was opened with.
String engineLibPath(WorkspaceController ws) => ws.inside!.libPath;

/// Exports the project as a video file at [mp4]. False if the engine did not write it.
Future<bool> exportVideoTo(WorkspaceController ws, String mp4) =>
    ws.inside!.exportVideo(mp4);

/// How far the current export has come, from 0 at the start to 1 at the last frame. Returns 0 when no export is
/// running. Safe to call from the UI thread while [exportVideoTo] runs; the engine updates it per frame.
double exportFractionOf(WorkspaceController ws) =>
    ws.inside?.exportFraction() ?? 0.0;

/// Checks the video [film] for flashes that may cause seizures: each flash's start and end in seconds, or null if the
/// check could not run.
Future<List<(double, double)>?> flashesIn(
  WorkspaceController ws,
  String film,
) => flashesOf(ws.inside!.libPath, film);

/// Gathers the project and its media into [folder], under the name [name]. Returns how many files were gathered, or
/// a negative number when it failed.
int packProject(WorkspaceController ws, String folder, String name) =>
    ws.inside!.pack(folder, name);

/// Tells the engine the project's size is now [wide] by [high] pixels. The project is reopened when it does not fit.
int resizeProject(WorkspaceController ws, int wide, int high) =>
    ws.inside!.later('size', word: '$wide $high');

/// Sets the frame the project picture is drawn at to [seconds]. False if the engine refused it.
bool setProjectPoster(WorkspaceController ws, double seconds) =>
    ws.inside?.set(0, 'poster_at', seconds) ?? false;

/// Asks the engine to follow the elements again, after an element file was written over.
int followElements(WorkspaceController ws) =>
    ws.inside!.later('follow_elements');

/// Asks the engine to read the code file [file] again, after it was changed.
int codeChanged(WorkspaceController ws, String file) =>
    ws.inside!.later('code', word: file);
