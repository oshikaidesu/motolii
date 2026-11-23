// The Tool Panel's Depth tool: a top view of the camera and the layers.
// Each layer is a slab at its Z position, drawn in the color of its kind.
// The lens cone widens as the focal length shortens.
// The user drags the focus line, together with its depth-of-field band, or clicks a slab to focus on that layer.
import 'package:motolii/workspace/tool_panel/depth_lens.dart';
import 'package:motolii/workspace/tool_panel/depth_diagram.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Depth tool: a top view of the camera lens with the layers as slabs.
class DepthTool extends StatefulWidget {
  const DepthTool({super.key});
  @override
  State<DepthTool> createState() => _DepthToolState();
}

class _DepthToolState extends State<DepthTool> {
  @override
  Widget build(BuildContext context) {
    // Rebuild on playhead frames and snapshot changes so the radar tracks live camera motion.
    WorkspaceScope.frameOf(context);
    WorkspaceScope.pictureOf(context);
    final ws = WorkspaceScope.of(context, {
          WorkspaceAspect.document,
          WorkspaceAspect.picked,
        }),
        lens = depthLenses[ws] ??= DepthLens(),
        joined = depthLensOf(ws, lens);
    // Sets one camera value and sends it to the engine as a drag, the same way a drag on the stage does.
    void edit(void Function() f, String name, double value) {
      setState(f);
      if (joined != null) {
        if (!ws.live.isOpen) ws.live.hold(joined.camera);
        ws.live.update(name, value);
      }
    }

    final cam = activeDepthCamera(ws);
    if (joined != null) {
      final d = lens.dof,
          sharp =
              depthSlabsOf(ws, lens)
                  .where(
                    (s) =>
                        s.depthPx > 0 &&
                        s.depthPx >= d.near &&
                        s.depthPx <= d.far,
                  )
                  .toList()
                ..sort(
                  (a, b) => (a.depthPx - lens.focus).abs().compareTo(
                    (b.depthPx - lens.focus).abs(),
                  ),
                );
      lens.target = sharp.firstOrNull?.id;
    }
    final target = ws.layers.where((l) => l.id == lens.target).firstOrNull;
    final locked = ws.layers.where((l) => l.id == lens.lockTarget).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolStrip(
          left: [
            Chip(
              label: cam?.name ?? 'Camera',
              look: ChipLook.flat(WindowTokens.toneCamera),
            ),
            SizedBox(width: Shape.s(8)),
            Text('${lens.focal.round()} mm', style: TextStyles.value(Grey.g91)),
            SizedBox(width: Shape.s(8)),
            Text(
              'f/${lens.fstop.toStringAsFixed(1)}',
              style: TextStyles.value(Grey.g91),
            ),
            SizedBox(width: Shape.s(8)),
            Text(
              '${(lens.fov * 180 / math.pi).toStringAsFixed(1)}° view',
              style: TextStyles.label(Grey.g56),
            ),
          ],
          right: [
            if (locked != null) ...[
              Chip(label: 'Lock ${locked.name}', dot: WindowTokens.toneCamera),
              SizedBox(width: Shape.s(6)),
            ],
            Chip(
              label: lens.autoFocus
                  ? (target == null ? 'Auto focus' : 'Auto · ${target.name}')
                  : (target == null ? 'Manual ×' : 'On ${target.name} ×'),
              dot: target == null ? Grey.g56 : layerKindColor(target.kind),
              onTap: !lens.autoFocus && joined != null
                  ? () {
                      // Reset manual focus back to 0 (auto-focus on the Boxcam frame).
                      edit(
                        () {
                          lens.autoFocus = true;
                          lens.focus = joined.eye;
                        },
                        'focus',
                        0,
                      );
                      ws.live.letGo();
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: WindowTokens.gutter),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: WindowTokens.card,
                  child: DepthDiagram(
                    lens: lens,
                    onFocus: (z, id) => edit(
                      () {
                        lens.autoFocus = false;
                        lens.focus = z.clamp(50.0, depthZMax * 3);
                        lens.target = id;
                      },
                      'focus',
                      z.clamp(50.0, depthZMax * 3) / (joined?.point ?? 1),
                    ),
                    // A narrower view is a longer lens.
                    onFocal: (f) => edit(
                      () => lens.focal = f.clamp(8.0, 400.0),
                      'focal_length',
                      f.clamp(8.0, 400.0),
                    ),
                    onDone: () {
                      if (joined != null) ws.live.letGo();
                    },
                    onCancel: () {
                      if (joined != null) {
                        ws.live.cancel();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: WindowTokens.gutter),
              SizedBox(
                width: Shape.z(108),
                child: _LensNumbers(lens: lens),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact optical readout beside the radar: depth of field, near/far limits, focus mode, and Boxcam distance.
class _LensNumbers extends StatelessWidget {
  const _LensNumbers({required this.lens});
  final DepthLens lens;
  @override
  Widget build(BuildContext context) {
    final d = lens.dof;
    String far(double v) => v.isInfinite ? '∞' : v.round().toString();
    Widget pair(String a, String b) => Row(
      children: [
        Expanded(child: Text(a, style: TextStyles.label(Grey.g56))),
        Text(
          b,
          style: TextStyles.value(Grey.g91)
              .copyWith(fontSize: TextStyles.px(10.5)),
        ),
      ],
    );
    return ColoredBox(
      color: WindowTokens.card,
      child: Padding(
        padding: EdgeInsets.all(WindowTokens.inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolReadout(
              value: far(d.far - d.near),
              unit: 'px',
              sub: 'depth of field',
            ),
            SizedBox(height: Shape.s(8)),
            pair('Near', far(d.near)),
            SizedBox(height: Shape.s(4)),
            pair('Far', far(d.far)),
            SizedBox(height: Shape.s(8)),
            pair('Focus', lens.autoFocus ? 'Auto' : '${lens.focus.round()}'),
            SizedBox(height: Shape.s(4)),
            pair('Dist', '${lens.distance.toStringAsFixed(2)}×'),
          ],
        ),
      ),
    );
  }
}
