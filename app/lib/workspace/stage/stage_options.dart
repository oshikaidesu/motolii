// The strip under the stage: the selected tool's options (fill, stroke, radius, font, brush kind), read from the
// selected layer or from the fill and stroke the next drawn layer gets, and the selected layer's position.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Chip, ChipLook;
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/workspace/inspector_feed/values.dart'
    show layerPlacement;
import 'package:motolii/workspace/stage/camera_gestures.dart'
    show
        cameraAlignToView,
        cameraReleaseTarget,
        cameraResetTilt,
        cameraTargetOf;
import 'package:motolii/workspace/stage/stage_tool.dart';
import 'package:motolii/workspace/stage/stroke_smooth.dart'
    show strokeSmoothLabels;
import 'package:motolii/workspace/stage/toggle.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// A document colour (six hex digits) as a Flutter [Color], or null when there is none.
/// A gradient is read as its first stop, with the stop's position left out.
Color? _colorOf(String word) =>
    colorOfHex(word.split(' ').first.split('@').first)?.withAlpha(255);

// The paint values last read, with the key they were read for.
// The strip is rebuilt on every image during playback. These values do not change with time, so they are read
// once per document revision and selection instead of waiting for the engine to report the current time.
(
  Object,
  ({
    Color? fill,
    Color? stroke,
    String width,
    String round,
    String font,
    String size,
    int align,
  }),
)?
_paintRead;

/// What the selected layer is painted with and how it is set.
/// With nothing selected, it is the fill and stroke the next drawn layer gets.
({
  Color? fill,
  Color? stroke,
  String width,
  String round,
  String font,
  String size,
  int align,
})
paintOf(WorkspaceController ws) {
  final key = (ws.rev, ws.selected, ws.ink, ws.edge);
  if (_paintRead case (final k, final p) when k == key) return p;
  final p = _paintNow(ws);
  _paintRead = (key, p);
  return p;
}

({
  Color? fill,
  Color? stroke,
  String width,
  String round,
  String font,
  String size,
  int align,
})
_paintNow(WorkspaceController ws) {
  final t = ws.selected;
  if (t == null) {
    return (
      fill: _colorOf(ws.ink),
      stroke: _colorOf(ws.edge),
      width: ws.edge.isEmpty ? 'None' : '6 px',
      round: '0%',
      font: '—',
      size: '—',
      align: 0,
    );
  }
  final w = stageValue(ws, t, 'stroke_width', 0),
      r = stageValue(ws, t, 'round', 0),
      text = stageWord(ws, t, 'kind') == 'text';
  return (
    fill: _colorOf(stageWord(ws, t, 'fill')),
    stroke: _colorOf(stageWord(ws, t, 'stroke')),
    width: stageWord(ws, t, 'stroke').isEmpty
        ? 'None'
        : '${(w ?? 0).round()} px',
    // A share of half the shorter side.
    round: '${((r ?? 0) * 200).round()}%',
    font: text
        ? stageWord(
            ws,
            t,
            'file',
          ).split('/').last.replaceFirst(RegExp(r'\.ttf$'), '')
        : '—',
    size: text
        ? '${((stageValue(ws, t, 'size', stageNow(ws)) ?? 1) * stagePointsPerUnit(ws)).round()} px'
        : '—',
    align: ((stageValue(ws, t, 'align', 0) ?? 0) * 2).round().clamp(0, 2),
  );
}

// ---- tool options strip ------------------------------------------------------------------------------------------------

/// The strip of the selected tool's options, with the selected layer's readout at its right.
class OptionsStrip extends StatelessWidget {
  const OptionsStrip({
    super.key,
    required this.tool,
    required this.opts,
    required this.onOpt,
    required this.scene,
    required this.layer,
    required this.ws,
  });
  final WorkspaceController ws;
  final int tool;
  final Map<String, int> opts;
  final void Function(String, int) onOpt;
  final ArtScene scene;
  final Layer? layer;

  Widget _seg(
    BuildContext c,
    String key,
    List<String> items, {
    int initial = 0,
  }) => Forms.worn.segment(
    c,
    ChoiceSpec(
      labels: items,
      selected: opts[key] ?? initial,
      onSelect: (i) => onOpt(key, i),
    ),
  );
  Widget _flag(String key, String label, {bool initial = false}) {
    final on = (opts[key] ?? (initial ? 1 : 0)) == 1;
    return Toggle(
      label: label,
      on: on,
      icon: StageIcon.safe,
      onTap: () => onOpt(key, on ? 0 : 1),
    );
  }

  List<Widget> _cameraStrip(WorkspaceController ws) {
    final cam = stageCameraLayer(ws, ws.selected);
    if (cam == null) {
      return const [_Field('Camera', value: 'None — add from Create › Layers')];
    }
    final targetId = cameraTargetOf(ws, cam);
    final targetLayer = targetId == null
        ? null
        : ws.layers.where((l) => l.id == targetId).firstOrNull;
    return [
      if (targetLayer != null)
        Chip(
          label: 'Target: ${targetLayer.name} ×',
          look: ChipLook.flat(WindowTokens.toneCamera),
          onTap: () => cameraReleaseTarget(ws, cam),
        )
      else
        const _Field('Target', value: 'Click layer'),
      if (ws.freeEye)
        Chip(
          key: const ValueKey('ws-camera-align-chip'),
          label: 'Match View',
          look: ChipLook.flat(WindowTokens.accent),
          onTap: () => cameraAlignToView(ws, cam),
        ),
      Chip(label: 'Flat 0°', onTap: () => cameraResetTilt(ws, cam)),
      _Field(
        'Drag',
        value: ws.freeEye
            ? 'View Orbit · Frame Pan/Scale/Roll'
            : 'Orbit / Shift Pan',
      ),
      const _Field('Wheel', value: 'Distance'),
    ];
  }

  List<Widget> _items(BuildContext c) => _joined(c, ws, paintOf(ws));

  /// The tool's own settings (how it draws or moves) and the selected layer's values as the document has them.
  List<Widget> _joined(
    BuildContext c,
    WorkspaceController ws,
    ({
      Color? fill,
      Color? stroke,
      String width,
      String round,
      String font,
      String size,
      int align,
    })
    p,
  ) => switch (tool) {
    0 => [
      _seg(c, 'sel.level', const ['Layer', 'Group']),
      _flag('sel.snap', 'Snap', initial: true),
      _flag('sel.pivot', 'Pivots'),
    ],
    1 => [
      _seg(c, 'move.axis', const ['Free', 'X', 'Y']),
      _flag('move.snap', 'Snap', initial: true),
    ],
    2 => [
      _Field('Fill', swatch: p.fill ?? WindowTokens.body),
      _Field('Stroke', value: p.width),
      _Field('Radius', value: p.round),
      _seg(c, 'rect.mode', const ['Shape', 'Mask']),
    ],
    3 => [
      _Field('Fill', swatch: p.fill ?? WindowTokens.body),
      _Field('Stroke', value: p.width),
      _seg(c, 'ell.from', const ['Corner', 'Centre']),
    ],
    4 => [
      _seg(c, 'pen.mode', const ['Path', 'Mask']),
      const _Field('Smooth', value: ''),
      _seg(c, 'draw.smooth', strokeSmoothLabels, initial: 2),
    ],
    // Camera tool strip: active Z-target status/release, tilt reset to flat Boxcam, and gesture hint.
    7 => _cameraStrip(ws),
    6 => [
      _Field('Fill', swatch: p.fill ?? WindowTokens.body),
      _seg(c, 'brush.kind', const ['Brush', 'Pen', 'Fill', 'Eraser']),
      _seg(c, 'brush.size', const ['Thin', 'Medium', 'Thick'], initial: 1),
      const _Field('Smooth', value: ''),
      _seg(c, 'draw.smooth', strokeSmoothLabels, initial: 2),
    ], // Alight Motion's drawing tools: pen (width follows pressure), brush (constant width), fill, and eraser.
    _ => [
      _Field('Font', value: p.font),
      _Field('Size', value: p.size),
      Forms.worn.segment(
        c,
        ChoiceSpec(
          labels: const ['L', 'C', 'R'],
          selected: p.align,
          onSelect: (i) {
            // Aligns the selected text's lines this way, using the document's align property.
            final t = ws.selected;
            if (t == null || !stageConnected(ws)) return;
            stageBeginUndoStep(ws);
            stageSetValue(ws, layer: t, name: 'align', number: i / 2);
            // Anchors the text where it stands
            stageSetValue(ws, layer: t, name: 'anchor_x', number: i - 1.0);
            // Does not wait for the result.
            ws.after(stageEndUndoStep(ws));
          },
        ),
      ),
      // The colour sits in the same row text bar: align, font, size, colour.
      _Field('Fill', swatch: p.fill ?? WindowTokens.body),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return LayoutBuilder(
      builder: (_, box) => ToolStrip(
        height: WindowTokens.header,
        color: WindowTokens.body,
        line: true,
        gap: WindowTokens.inset,
        left: [
          SizedBox(
            width: Shape.z(62),
            child: Text(
              stageTools[tool].$2.toUpperCase(),
              style: TextStyles.micro(Grey.g56).bold.copyWith(letterSpacing: 1),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: Shape.s(6)),
            items[i],
          ],
        ],
        right: [
          ConstrainedBox(
            // As wide as it needs, with the tool options before it getting the rest. If it is wider than the whole
            // strip it is scaled down and never cut off, as the trailing part in dock_widgets.dart is.
            constraints: BoxConstraints(
              maxWidth: (box.maxWidth - 2 * WindowTokens.inset).clamp(
                0,
                double.infinity,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<int>(
                valueListenable: ws.seen,
                builder: (_, _, _) => _Readout(scene: scene, layer: layer),
              ),
            ), // Also rebuilt while a value is being dragged.
          ),
        ],
      ),
    );
  }
}

/// A labelled value in a well: a read-only field of the options strip.
class _Field extends StatelessWidget {
  const _Field(this.label, {this.value, this.swatch});
  final String label;
  final String? value;
  final Color? swatch;
  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(20),
    padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
    decoration: BoxDecoration(
      color: WindowTokens.well,
      borderRadius: Shape.round(WindowTokens.radius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyles.micro(Grey.g56)),
        SizedBox(width: Shape.s(6)),
        if (swatch case final s?)
          Container(
            width: Shape.z(22),
            height: Shape.z(12),
            decoration: BoxDecoration(color: s, borderRadius: Shape.round(3)),
          )
        else
          Text(value ?? '', style: TextStyles.value(Grey.g91)),
      ],
    ),
  );
}

/// The selected layer at this frame: its hue and name, then position, scale and rotation as the stage sees them.
class _Readout extends StatelessWidget {
  const _Readout({required this.scene, required this.layer});
  final ArtScene scene;
  final Layer? layer;
  @override
  Widget build(BuildContext context) {
    final l = layer,
        box = ArtGeometry.boxOf(scene, l?.id),
        ws = WorkspaceScope.of(context, {
          WorkspaceAspect.document,
          WorkspaceAspect.picked,
        });
    if (l == null || ws.many.length > 1) {
      return Text(
        ws.many.isEmpty ? 'Nothing selected' : '${ws.many.length} picked',
        style: TextStyles.label(Grey.g56),
      ); // Several layers selected together: say so, as the bar above the stage does.
    }
    Widget pair(String k, String v) => Padding(
      padding: EdgeInsets.only(left: Shape.s(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: TextStyles.micro(Grey.g56)),
          SizedBox(width: Shape.s(4)),
          Text(v, style: TextStyles.value(Grey.g91)),
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(l.tone, size: Shape.z(8), radius: Shape.r(2)),
        SizedBox(width: Shape.s(6)),
        Text(
          l.name,
          style: TextStyles.name(Grey.g95)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        // A behaviour layer has no image of its own, so there is nothing to say. A camera layer, while its bar covers
        // the current frame, also has no size: only its name is shown
        if (box == null &&
            stageWord(ws, l.id, 'kind') != 'behaviour' &&
            !(l.kind == LayerKind.camera &&
                (scene.layer(l.id)?.live(scene.frame) ?? false)))
          Padding(
            padding: EdgeInsets.only(left: Shape.s(10)),
            child: Text(
              l.kind == LayerKind.audio
                  ? 'No picture'
                  : ws.freeEye &&
                        (scene.layer(l.id)?.live(scene.frame) ?? false)
                  ? 'In Camera View'
                  : 'Not on this frame',
              style: TextStyles.label(Grey.g56),
            ), // A 2D layer shows only through the camera, as in After Effects' working views.
          )
        else if (l.kind != LayerKind.camera) ...[
          // The same numbers as the inspector shows, which come from the document.
          if (layerPlacement(ws, l.id) case final at) ...[
            pair('P', '${at['x']?.round()}, ${at['y']?.round()}'),
            pair('S', '${at['scale_y']?.round()}%'),
            pair('R', '${at['rotate']?.round()}°'),
          ],
        ],
      ],
    );
  }
}
