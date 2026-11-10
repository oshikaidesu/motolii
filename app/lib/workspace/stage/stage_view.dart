// The stage's viewport: the composition centred on a dark surround, rulers and guides, overlays, the selection,
// the zoom HUD and the navigator.
// It repaints only when the scene, the selection, the hover or the view changes. The pointer readout repaints the rulers alone.
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/stage/stage_tool.dart';
import 'package:motolii/workspace/stage/stage_view_state.dart';
import 'package:motolii/workspace/state/art_scene.dart';

/// The stage viewport.
///
/// It draws the scene, handles pointer input for selecting, moving and drawing layers, and reports the pointer position.
class StageView extends StatefulWidget {
  const StageView({
    super.key,
    required this.scene,
    required this.selected,
    required this.zoom,
    required this.grid,
    required this.safe,
    required this.cursor,
    this.onPoke,
    this.texture,
    this.tool = const StageTool(),
    this.snapshot,
  });

  /// The active tool and its options.
  final StageTool tool;

  /// The engine's image of the stage as a Flutter texture id. When null, the stand-in art is painted.
  final int? texture;

  /// A still image taken earlier (After Effects' Take Snapshot), laid over the stage while it is shown.
  final String? snapshot;
  final ArtScene scene;
  final String? selected;
  final int zoom;
  final bool grid, safe;

  /// The pointer in composition px while it is over the viewport; the HUD and the rulers read it.
  final ValueNotifier<Offset?> cursor;
  final VoidCallback? onPoke;
  @override
  State<StageView> createState() => StageViewState();
}
