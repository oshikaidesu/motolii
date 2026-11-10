// The Camera View tab: the image the camera takes, shown beside the stage whichever view camera the stage uses.
// Like After Effects' 2 Views with Active Camera. It is view-only; all editing happens on the stage.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiWrites;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Camera View tab: shows what the camera layer sees.
class WsCameraView extends StatefulWidget {
  const WsCameraView({super.key});
  @override
  State<WsCameraView> createState() => _WsCameraViewState();
}

class _WsCameraViewState extends State<WsCameraView> {
  (Motolii?, bool) _told = (null, false);

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
    final m = WsScope.read(context).inside, seen = context.findAncestorWidgetOfExactType<Offstage>()?.offstage != true;
    if (_told != (m, seen)) {
      // A newly opened document starts with the tab not announced.
      _told = (m, seen);
      m?.later('camera_view', word: seen ? 'on' : '');
    }
    WidgetsBinding.instance.addPostFrameCallback(_look);
  }

  @override
  void dispose() {
    _told.$1?.later('camera_view');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = WsScope.of(context, {WsAspect.document, WsAspect.stage}).stageTexture;
    return ColoredBox(
      color: Grey.g10,
      child: id == null
          ? null
          : Center(
              child: AspectRatio(
                aspectRatio: WsArt.comp.aspectRatio,
                child: Texture(textureId: id, filterQuality: FilterQuality.medium),
              ),
            ),
    );
  }
}
