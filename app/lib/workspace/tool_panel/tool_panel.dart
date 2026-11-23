// The Tool Panel, shown under the Inspector. It shows either the catalog of tools or a single tool.
// A tool the user opens from the catalog stays pinned until the selection changes or the user unpins it.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/controls.dart' show Chip, Pressable, IconPress;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/reveal_in_finder.dart' show revealFile;
import 'package:motolii/storage/shelf_disk.dart' show makeFolder;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/state/engine_access.dart' show ownFolder;
import 'package:motolii/workspace/state/pack_service.dart'
    show exportPackFromWorkspace, importPackFromDialog;
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/tool_panel/tool_sticker.dart';
import 'package:motolii/widgets/grid_columns.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

class ToolPanel extends StatelessWidget {
  const ToolPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
          WorkspaceAspect.fronted,
          WorkspaceAspect.picked,
        }),
        name = ws.toolPanel;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToolHeader(name: name),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.dur,
              child: KeyedSubtree(
                key: ValueKey(name),
                child: switch (name) {
                  'Tools' => const _Catalog(),
                  _ => panelTool(ws, name)?.build() ?? const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header showing the tool's icon and name, whether it follows the selection or is pinned, and a button back to the catalog.
class _ToolHeader extends StatelessWidget {
  const _ToolHeader({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
          WorkspaceAspect.fronted,
          WorkspaceAspect.picked,
        }),
        pinned = ws.toolPanelManual != null;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 340;
        return PanelHeader(
          name,
          leading: ToolSticker(name),
          trailing: [
            if (name == 'Tools') ...[
              Chip(
                key: const ValueKey('tool:import'),
                label: 'Import',
                dot: WindowTokens.accent,
                onTap: () => importPackFromDialog(ws),
              ),
              SizedBox(width: WindowTokens.gap),
              Chip(
                key: const ValueKey('tool:folder'),
                label: 'Folder',
                dot: Grey.g76,
                onTap: () {
                  final dir = '${ownFolder()}/panels';
                  makeFolder(dir);
                  revealFile(dir);
                },
              ),
              SizedBox(width: WindowTokens.gap),
            ],
            if (name != 'Tools')
              if (panelTool(ws, name) case final tool?) ...[
                if (jsPanelDescriptor(ws, name) case final jsPanel?) ...[
                  Chip(
                    key: ValueKey('tool:export:$name'),
                    label: 'Pack',
                    dot: Grey.g76,
                    onTap: () => exportPackFromWorkspace(
                      ws,
                      sourceFile: jsPanel.path,
                      kind: 'panel',
                      name: jsPanel.name,
                    ),
                  ),
                  SizedBox(width: WindowTokens.gap),
                ],
                Chip(
                  key: ValueKey('tool:dock:$name'),
                  label: 'Tab',
                  dot: tool.tone ?? WindowTokens.accent,
                  onTap: () => ws.openDockTab(tool),
                ),
                SizedBox(width: WindowTokens.gap),
              ],
            if (pinned)
              Chip(
                label: wide ? 'Pinned · Follow' : 'Pinned',
                dot: Grey.g76,
                onTap: () => ws.openToolPanel(null),
              )
            else
              Chip(
                label: wide ? 'Follows selection' : 'Follows',
                dot: WindowTokens.accent,
              ),
            SizedBox(width: WindowTokens.gap),
            IconPress(
              (ink) => Glyph(AppGlyphs.tools, size: 20, color: ink),
              rest: WindowTokens.well,
              ink: Grey.g76,
              size: 20,
              tip: 'Tools',
              on: name == 'Tools',
              onTap: () =>
                  ws.openToolPanel(name == 'Tools' && pinned ? null : 'Tools'),
            ),
          ],
        );
      },
    );
  }
}

/// Every tool as a tile with its icon, name and what it acts on.
/// The column count follows the width. Rows share the height but keep at least [_minTile], otherwise the grid scrolls.
/// A tile never grows beyond [_maxTile].
class _Catalog extends StatelessWidget {
  const _Catalog();
  static const _cell = 104.0, _minTile = 62.0, _maxTile = 92.0;
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth - WindowTokens.gap * 2,
            h = box.maxHeight - WindowTokens.gap * 2;
        final tools = allPanelTools(ws);
        final cols = gridColumns(w, _cell, gap: WindowTokens.gap, min: 2),
            rows = (tools.length / cols).ceil().clamp(1, 999);
        final tile = ((h - WindowTokens.gap * (rows - 1)) / rows).clamp(
              _minTile,
              _maxTile,
            ),
            cw = gridCellWidth(w, cols, gap: WindowTokens.gap);
        return ListView(
          padding: EdgeInsets.all(WindowTokens.gap),
          children: [
            Wrap(
              spacing: WindowTokens.gap,
              runSpacing: WindowTokens.gap,
              children: [
                for (final t in tools)
                  SizedBox(
                    width: cw,
                    height: tile,
                    child: _ToolTile(t, onTap: () => ws.openToolPanel(t.name)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile(this.tool, {required this.onTap});
  final Pane tool;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context);
    final isCustom = jsPanelDescriptor(ws, tool.name) != null;
    final tile = Pressable(
      onTap: onTap,
      builder: (_, h) => Container(
        padding: EdgeInsets.fromLTRB(
          Shape.s(7),
          Shape.s(7),
          Shape.s(6),
          Shape.s(7),
        ),
        decoration: BoxDecoration(
          color: h ? WindowTokens.raised : WindowTokens.card,
          borderRadius: Shape.round(WindowTokens.radius),
        ),
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ToolSticker(tool.name, size: Shape.z(26)),
                  const Spacer(),
                  if (isCustom)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(4),
                        vertical: Shape.s(1),
                      ),
                      decoration: BoxDecoration(
                        color: WindowTokens.accent.withValues(alpha: 0.18),
                        borderRadius: Shape.round(3),
                        border: Border.all(
                          color: WindowTokens.accent.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        'VST',
                        style: TextStyles.micro(WindowTokens.accent).copyWith(
                          fontSize: TextStyles.px(8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (h) ...[
                    SizedBox(width: Shape.s(3)),
                    Pressable(
                      key: ValueKey('tool:popout:${tool.name}'),
                      onTap: () => ws.openDockTab(tool),
                      builder: (_, popHot) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Shape.s(4),
                          vertical: Shape.s(1),
                        ),
                        decoration: BoxDecoration(
                          color: popHot
                              ? WindowTokens.accent
                              : WindowTokens.well,
                          borderRadius: Shape.round(3),
                        ),
                        child: Text(
                          'Tab ↗',
                          style: TextStyles.micro(
                            popHot ? WindowTokens.onAccent : Grey.g91,
                          ).copyWith(fontSize: TextStyles.px(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                tool.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.name(h ? Grey.g100 : Grey.g95).copyWith(
                  fontSize: TextStyles.px(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (box.maxHeight >= 54) ...[
                SizedBox(height: Shape.s(3)),
                Text(
                  tool.acts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.label(Grey.g56),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Draggable<Pane>(
      data: tool,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(9),
          vertical: Shape.s(5),
        ),
        decoration: BoxDecoration(
          color: WindowTokens.raised,
          borderRadius: Shape.round(6),
          border: Border.all(color: WindowTokens.accent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToolSticker(tool.name, size: Shape.z(16)),
            SizedBox(width: Shape.s(6)),
            Text(
              '${tool.name} · Drop to dock as tab',
              style: TextStyles.micro(Grey.g95)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}
