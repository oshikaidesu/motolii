// The stage's navigator: the whole frame in miniature, with the part in view outlined.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/view_painter.dart';
import 'package:motolii/workspace/state/art_scene.dart';

/// The navigator: the whole frame in miniature, the part the viewport shows outlined. Shown only when zoomed past fit.
class StageNavigator extends StatelessWidget {
  const StageNavigator({
    super.key,
    required this.scene,
    required this.view,
    this.texture,
  });
  final ArtScene scene;
  final StageViewport view;

  /// The engine's preview of the whole frame, drawn under the outline. It is the same texture the stage shows.
  final int? texture;
  @override
  Widget build(BuildContext context) {
    final h =
        StageTokens.mapW * ArtGeometry.comp.height / ArtGeometry.comp.width;
    return Container(
      width: StageTokens.mapW + 8,
      height: h + 8,
      padding: EdgeInsets.all(Shape.s(4)),
      color: WindowTokens.card,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (texture != null)
            Texture(textureId: texture!, filterQuality: FilterQuality.medium),
          CustomPaint(
            painter: _MapPainter(
              scene,
              Rect.fromPoints(
                view.toComposition(view.area.topLeft),
                view.toComposition(view.area.bottomRight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.scene, this.shown);
  final ArtScene scene;
  final Rect shown;
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / ArtGeometry.comp.width;
    c.save();
    c.clipRect(Offset.zero & s);
    c.scale(k);
    c.restore();
    final r = Rect.fromLTRB(
      shown.left * k,
      shown.top * k,
      shown.right * k,
      shown.bottom * k,
    ).intersect(Offset.zero & s);
    c.drawRect(r.deflate(.75), linePaint(WindowTokens.accent, 1.5));
  }

  @override
  bool shouldRepaint(_MapPainter o) => o.scene != scene || o.shown != shown;
}
