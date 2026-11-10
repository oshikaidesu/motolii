// The Tool Panel's Align tool: aligns the selected layer to an edge or the center of the canvas.
// It aligns the layer's visible bounds, the upright box around its outline as the engine reports it.
// The move is sent as a drag on the stage (drag start, an offset in canvas points, drag end), which is one undo step.
// The engine converts the offset into the layer's own units, taking its parent's rotation into account.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, IconPress;

import 'package:motolii/skin/tokens.dart';

import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';

/// The Align tool: six buttons that align the selected layer to the canvas edges or center.
class AlignTool extends StatelessWidget {
  const AlignTool({super.key});

  /// The visible bounds of the selected layer: the upright box around its outline as the engine reports it.
  /// Null when no layer is selected or nothing is visible.
  static Rect? _seen(WorkspaceController ws) {
    final t = int.tryParse(ws.selected ?? '');
    return t == null ? null : ws.inside?.seen(t);
  }

  /// Aligns the selected layer to [side]: 0 left, 1 horizontal center, 2 right, 3 top, 4 vertical center, 5 bottom.
  ///
  /// It runs at most twice. A layer in depth or tilted towards the camera has different bounds after it moves,
  /// so the second pass corrects the remaining offset.
  static void align(WorkspaceController ws, int side, [int pass = 0]) {
    final m = ws.inside, t = int.tryParse(ws.selected ?? ''), r = t == null ? null : m?.seen(t);
    if (m == null || t == null || r == null) return;
    final pic = ArtGeometry.comp;
    final dx = switch (side) {
      0 => -r.left,
      1 => pic.width / 2 - r.center.dx,
      2 => pic.width - r.right,
      _ => 0.0,
    };
    final dy = switch (side) {
      3 => -r.top,
      4 => pic.height / 2 - r.center.dy,
      5 => pic.height - r.bottom,
      _ => 0.0,
    };
    if (dx.abs() < .25 && dy.abs() < .25) return;
    // Moves the layer like a drag on the stage, without waiting for the engine.
    m.later('drag_start', layer: t);
    m.dragUpdate('place', dx, dy);
    ws.after(m.later('drag_end', number: 1), (done, _) => done && pass == 0 ? align(ws, side, 1) : null);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked}), r = _seen(ws), pic = ArtGeometry.comp;
    bool at(int side) =>
        r != null &&
        switch (side) {
          0 => r.left.abs() < .5,
          1 => (r.center.dx - pic.width / 2).abs() < .5,
          2 => (r.right - pic.width).abs() < .5,
          3 => r.top.abs() < .5,
          4 => (r.center.dy - pic.height / 2).abs() < .5,
          _ => (r.bottom - pic.height).abs() < .5,
        };
    return ListView(
      padding: EdgeInsets.all(WindowTokens.gap),
      children: [
        if (ws.layer case final l?)
          ToolStrip(
            left: [Chip(label: l.name, look: ChipLook.flat(layerKindColor(l.kind)))],
          ),
        SizedBox(height: Shape.s(8)),
        for (final row in const [
          [0, 1, 2],
          [3, 4, 5],
        ])
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(4)),
            child: Opacity(
              // Dimmed when there is no visible selected layer to align.
              opacity: r == null ? .35 : 1,
              child: Row(
                children: [
                  for (final side in row) ...[
                    IconPress(
                      paintInk((ink) => _Side(side, ink)),
                      rest: WindowTokens.well,
                      ink: Grey.g76,
                      key: ValueKey('align.$side'),
                      size: Shape.z(36),
                      on: at(side),
                      onTap: () => r == null ? null : align(ws, side),
                    ),
                    SizedBox(width: Shape.s(4)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Draws a side button's icon: the canvas edge or center as a line, with a box placed against it.
class _Side extends CustomPainter {
  _Side(this.side, this.ink);
  final int side;
  final Color ink;
  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..color = ink
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final box = Paint()..color = ink.withValues(alpha: .55);
    final across = side < 3, k = side % 3, lo = s.width * .2, hi = s.width * .8, mid = s.width / 2;
    final edge = k == 0
        ? lo
        : k == 1
        ? mid
        : hi;
    if (across) {
      c.drawLine(Offset(edge, s.height * .15), Offset(edge, s.height * .85), line);
      final w = s.width * .32,
          left = k == 0
              ? edge
              : k == 1
              ? edge - w / 2
              : edge - w;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, s.height * .32, w, s.height * .36), Shape.r(1.5)), box);
    } else {
      c.drawLine(Offset(s.width * .15, edge), Offset(s.width * .85, edge), line);
      final h = s.height * .32,
          top = k == 0
              ? edge
              : k == 1
              ? edge - h / 2
              : edge - h;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .32, top, s.width * .36, h), Shape.r(1.5)), box);
    }
  }

  @override
  bool shouldRepaint(_Side o) => o.side != side || o.ink != ink;
}
