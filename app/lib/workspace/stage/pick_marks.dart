// The lasso being drawn and a ring on each layer picked together, over the stage.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/view_painter.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

class PickMarks extends StatelessWidget {
  const PickMarks({
    super.key,
    required this.scene,
    required this.v,
    required this.lasso,
  });
  final ArtScene scene;
  final StageViewport v;
  final List<Offset>? lasso;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WorkspaceScope.read(context).on[WorkspaceAspect.document],
      WorkspaceScope.read(context).on[WorkspaceAspect.picked],
      WorkspaceScope.read(context).seen,
    ]), // Where the layers are in the preview shown.
    builder: (context, _) {
      final ws = WorkspaceScope.read(context);
      final picked = [
        for (final id in ws.many)
          if (scene.box(id) case final b?) v.toScreen(b.c),
      ];
      return IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _MarksPainter(lasso, picked),
        ),
      );
    },
  );
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.lasso, this.at);
  final List<Offset>? lasso;
  final List<Offset> at;
  @override
  void paint(Canvas c, Size s) {
    final ink = linePaint(WindowTokens.accent, 1.5);
    if (lasso case final l? when l.length > 1) {
      c.drawPath(Path()..addPolygon(l, false), ink);
    }
    for (final p in at) {
      c.drawCircle(p, 14, ink);
    }
  }

  @override
  bool shouldRepaint(_MarksPainter o) => true;
}
