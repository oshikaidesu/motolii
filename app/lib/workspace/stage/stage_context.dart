// The stage view as its gesture controllers see it.
import 'dart:ui' show Offset;

import 'package:motolii/workspace/stage/stage_tool.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What a gesture controller of the stage reads from the view that owns it.
///
/// The view's State implements this. A controller reads it each time it acts, so it works on the scene, the
/// selection and the tool the view has at that moment.
abstract interface class StageContext {
  /// The workspace the stage belongs to.
  WorkspaceController get workspace;

  /// The scene the stage shows.
  ArtScene get scene;

  /// The id of the selected layer, or null when none is selected.
  String? get selected;

  /// The active tool and its options.
  StageTool get tool;

  /// The selected layer's handles where the stage draws them now, by name, in the stage's own coordinates.
  Map<String, Offset> get handles;

  /// The selected image's crop while it is being cropped: the share cut from its left, top, right and bottom.
  ///
  /// Empty when no image is being cropped.
  List<double> get crop;
}
