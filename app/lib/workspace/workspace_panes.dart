// The panes of the workspace and how they are docked at the start: the table of every pane, its glyph, its place and its size.
import 'package:docking/docking.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/code/code_pane.dart';
import 'package:motolii/workspace/dock/shelf_pane.dart';
import 'package:motolii/workspace/inspector_feed/panel.dart';
import 'package:motolii/workspace/stage/stage.dart';
import 'package:motolii/workspace/stage/stage_camera.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/tool_panel/tool_panel.dart';
import 'package:motolii/workspace/tool_panel/align.dart';
import 'package:motolii/workspace/tool_panel/blend.dart';
import 'package:motolii/workspace/tool_panel/depth.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';

final workspacePanes = [
  Pane(
    'Media',
    AppGlyphs.media,
    () => const ShelfPane('Media', 'Search files and media'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Effects',
    AppGlyphs.effects,
    () => const ShelfPane('Effects', 'Search effects and features'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Fonts',
    AppGlyphs.fonts,
    () => const ShelfPane('Fonts', 'Search fonts'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Colors',
    AppGlyphs.colors,
    () => const ShelfPane('Colors', 'Search palettes'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Create',
    AppGlyphs.create,
    () => const ShelfPane('Create', 'Search layers and shapes'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Presets',
    AppGlyphs.files,
    () => const ShelfPane('Presets', 'Search presets'),
    at: PaneStrip.shelves,
    minSize: 240,
    iconOnly: true,
  ),
  Pane(
    'Stage',
    AppGlyphs.stage,
    () => const StagePane(),
    at: PaneStrip.stage,
    minSize: 320,
  ),
  Pane(
    'Camera View',
    AppGlyphs.camera,
    () => const CameraView(),
    at: PaneStrip.stage,
    minSize: 240,
  ),
  Pane(
    'Inspector',
    AppGlyphs.inspector,
    () => const InspectorPane(),
    minSize: 200,
  ),
  Pane(
    'Timeline',
    AppGlyphs.timeline,
    () => const TimelinePane(),
    at: PaneStrip.timeline,
    minSize: 160,
  ),
  // Beside the Timeline: the preview stays in sight above the code, and a line has the width of the window.
  Pane(
    'Code',
    AppGlyphs.code,
    () => const CodePane(),
    at: PaneStrip.timeline,
    minSize: 160,
  ),
  Pane(
    'Ease',
    AppGlyphs.time,
    () => const EaseTool(),
    at: PaneStrip.ease,
    minSize: 260,
  ),
  Pane(
    'Camera',
    AppGlyphs.camera,
    () => const DepthTool(),
    at: PaneStrip.tools,
    minSize: WindowTokens.lower,
  ),
  Pane(
    'Tool Panel',
    AppGlyphs.toolPanel,
    () => const ToolPanel(),
    at: PaneStrip.tools,
    minSize: WindowTokens.lower,
  ),
  Pane(
    'Blend',
    AppGlyphs.blend,
    BlendTool.new,
    at: PaneStrip.catalog,
    tone: InspectorSkin.toneBlend,
    acts: 'Layer stack',
  ),
  Pane(
    'Align',
    AppGlyphs.align,
    AlignTool.new,
    at: PaneStrip.catalog,
    tone: InspectorSkin.toneLayout,
    acts: 'Selection',
  ),
];

/// Height of a pane's tab strip, added to the reference heights so the panels keep theirs.
const _strip = 22.0;

/// The default arrangement: the media shelves (one strip of tabs) and Stage over Timeline (with Code behind it) and Ease on the left,
/// Inspector over Camera on the right.
///
/// Side and lower panes start at their reference sizes in px. The panes without a size share what is left.
/// The filling panes must be given no weight: `multi_split_view` turns sizes into weights and would scale them against any weight given.
DockingArea workspacePreset(
  DockingArea Function(PaneStrip at, {double? size}) strip,
) => DockingRow([
  DockingColumn([
    DockingRow([
      strip(PaneStrip.shelves, size: WindowTokens.dock),
      strip(PaneStrip.stage),
    ]),
    // Ease edits the easing between two keyframes, so it sits beside Timeline. It is never made shorter than 220,
    // the height at which its seven shapes and curve stay readable. This is docking's own minimum, as in VS Code's views.
    DockingRow(
      [
        strip(PaneStrip.timeline),
        strip(PaneStrip.ease, size: WindowTokens.inspector),
      ],
      size: WindowTokens.lower + _strip,
      minimalSize: 220,
    ),
  ]),
  // The lower strip holds the Camera tool, whatever is selected.
  DockingColumn(
    [
      strip(PaneStrip.inspector),
      strip(PaneStrip.tools, size: WindowTokens.lower + _strip),
    ],
    size: WindowTokens.inspector,
    minimalSize: 340,
  ),
]);
