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
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/inspector_feed/panel.dart' show LayerCards;

/// The Depth tool: a top view of the camera lens with the layers as slabs.
class DepthTool extends StatefulWidget {
  const DepthTool({super.key});
  @override
  State<DepthTool> createState() => _DepthToolState();
}

class _DepthToolState extends State<DepthTool> {
  @override
  Widget build(BuildContext context) {
    // Rebuild when the displayed snapshot changes, so the lens matches it.
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
        ws.inside!
          ..take(joined.camera)
          ..dragUpdate(name, value);
      }
    }

    final cam = ws.layers.where((l) => l.kind == LayerKind.camera).firstOrNull;
    if (joined != null) {
      // With a document camera, the focused layer is the sharp layer nearest to the focus.
      final d = lens.dof,
          sharp =
              depthSlabsOf(ws)
                  .where((s) => s.z >= d.near && s.z <= d.far)
                  .toList()
                ..sort(
                  (a, b) => (a.z - lens.focus).abs().compareTo(
                    (b.z - lens.focus).abs(),
                  ),
                );
      lens.target = sharp.firstOrNull?.id;
    }
    final target = ws.layers.where((l) => l.id == lens.target).firstOrNull;
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
            Chip(
              label: target == null ? 'Focus free' : 'On ${target.name}',
              dot: target == null ? Grey.g56 : layerKindColor(target.kind),
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
                        lens.focus = z.clamp(100.0, depthZMax);
                        lens.target = id;
                      },
                      'focus',
                      z.clamp(100.0, depthZMax) / (ws.inside?.point ?? 1),
                    ),
                    // A narrower view is a longer lens.
                    onFocal: (f) => edit(
                      () => lens.focal = f.clamp(8.0, 600.0),
                      'zoom',
                      f.clamp(8.0, 600.0) / depthFilmMm,
                    ),
                    onDone: () {
                      // Ending the drag makes the change one undo step.
                      if (joined != null) {
                        ws.after(ws.inside!.later('drag_end', number: 1));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: WindowTokens.gutter),
              SizedBox(
                width: Shape.z(128),
                child: _LensNumbers(
                  lens: lens,
                  camera: joined == null ? null : cam?.id,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The side column with the depth of field and its near and far limits. With a camera it also shows the Camera Options card.
class _LensNumbers extends StatelessWidget {
  const _LensNumbers({required this.lens, required this.camera});
  final DepthLens lens;
  final String? camera;
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
      child: ListView(
        padding: EdgeInsets.only(top: Shape.s(7), bottom: WindowTokens.inset),
        children: [
          if (camera case final id?)
            LayerCards(layer: id, only: const ['Camera Options']),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: Shape.s(6)),
                ToolReadout(
                  value: far(d.far - d.near),
                  unit: 'px',
                  sub: 'depth of field',
                ),
                SizedBox(height: Shape.s(7)),
                pair('Near', far(d.near)),
                SizedBox(height: Shape.s(4)),
                pair('Far', far(d.far)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
