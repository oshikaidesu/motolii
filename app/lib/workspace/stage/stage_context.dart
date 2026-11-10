// The stage view as its gesture controllers see it.
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What a gesture controller of the stage reads from the view that owns it.
///
/// The view's State implements this. A controller reads it each time it acts, so it works on the scene and the
/// selection the view has at that moment.
abstract interface class StageContext {
  /// The workspace the stage belongs to.
  WorkspaceController get workspace;

  /// The scene the stage shows.
  ArtScene get scene;

  /// The id of the selected layer, or null when none is selected.
  String? get selected;
}
