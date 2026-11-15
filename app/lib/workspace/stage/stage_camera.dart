// The Camera View tab: the image the camera takes, shown beside the stage whichever view camera the stage uses.
// Like After Effects' 2 Views with Active Camera. It is view-only; all editing happens on the stage.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Camera View tab: shows what the camera layer sees.
class CameraView extends StatefulWidget {
  const CameraView({super.key});
  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final _told = CameraViewLink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_look);
  }

  /// Tells the engine whether this image is wanted, after every frame the app draws.
  ///
  /// It is wanted only while the tab is in front. The tab view keeps a hidden tab built but Offstage, so a tab
  /// nobody looks at costs no second image.
  void _look(Duration _) {
    if (!mounted) return;
    final seen =
        context.findAncestorWidgetOfExactType<Offstage>()?.offstage != true;
    _told.tell(WorkspaceScope.read(context), seen);
    WidgetsBinding.instance.addPostFrameCallback(_look);
  }

  @override
  void dispose() {
    _told.forget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = WorkspaceScope.of(context, {
      WorkspaceAspect.document,
      WorkspaceAspect.stage,
    }).stageTexture;
    return ColoredBox(
      color: Grey.g10,
      child: id == null
          ? null
          : Center(
              child: AspectRatio(
                aspectRatio: ArtGeometry.comp.aspectRatio,
                child: Texture(
                  textureId: id,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
    );
  }
}
