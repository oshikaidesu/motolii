// The Tool Panel: the drawer under the Inspector. It holds the catalog or one catalog row (a tool opened by hand stays pinned until
// the selection moves or you unpin it).
import 'package:flutter/widgets.dart';

import '../../widgets/controls.dart' show Chip, Hov, IconPress;

import '../../skin/tokens.dart';
import '../dock/dock_glyphs.dart';
import '../window/panes.dart';
import 'tool_panel_widgets.dart';
import '../state/state.dart';

class WsToolPanel extends StatelessWidget {
  const WsToolPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.fronted, WsAspect.picked}), name = ws.toolPanel;
    return WsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToolHeader(name: name),
          Expanded(
            child: switch (name) {
              'Tools' => const _Catalog(),
              _ => panelTool(ws, name)?.build() ?? const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

/// The tool's sticker and name, whether it follows the selection or is pinned, and the way back to the catalog.
class _ToolHeader extends StatelessWidget {
  const _ToolHeader({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.fronted, WsAspect.picked}), pinned = ws.toolPanelManual != null;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 340;
        return WsHeader(
          name,
          leading: ToolSticker(name),
          trailing: [
            if (pinned)
              Chip(label: wide ? 'Pinned · Follow' : 'Pinned', dot: Grey.g76, onTap: () => ws.openToolPanel(null))
            else
              Chip(label: wide ? 'Follows selection' : 'Follows', dot: WsT.accent),
            SizedBox(width: WsT.gap),
            IconPress(
              (ink) => DockGlyph(DockG.tools, size: 20, color: ink),
              rest: WsT.well,
              ink: Grey.g76,
              size: 20,
              on: name == 'Tools',
              onTap: () => ws.openToolPanel(name == 'Tools' && pinned ? null : 'Tools'),
            ),
          ],
        );
      },
    );
  }
}

/// Every tool panel tool as a tile: sticker, name, what it acts on. /// Columns come from the width; the rows share the height while each keeps [_minTile], else the grid scrolls; a tall tool panel never stretches a tile past [_maxTile].
class _Catalog extends StatelessWidget {
  const _Catalog();
  static const _cell = 104.0, _minTile = 62.0, _maxTile = 92.0;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth - WsT.gap * 2, h = box.maxHeight - WsT.gap * 2;
        final cols = wsCols(w, _cell, gap: WsT.gap, min: 2), rows = (WsScope.read(context).tools.length / cols).ceil();
        final tile = ((h - WsT.gap * (rows - 1)) / rows).clamp(_minTile, _maxTile), cw = wsCell(w, cols, gap: WsT.gap);
        return ListView(
          padding: EdgeInsets.all(WsT.gap),
          children: [
            Wrap(
              spacing: WsT.gap,
              runSpacing: WsT.gap,
              children: [
                for (final t in WsScope.read(context).tools)
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
  final WsPane tool;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Hov(
    onTap: onTap,
    builder: (_, h) => Container(
      padding: EdgeInsets.fromLTRB(Shape.s(7), Shape.s(7), Shape.s(6), Shape.s(7)),
      decoration: BoxDecoration(color: h ? WsT.raised : WsT.card, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
      child: LayoutBuilder(
        builder: (context, box) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ToolSticker(tool.name, size: Shape.z(26))],
            ),
            const Spacer(),
            Text(
              tool.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.name(h ? Grey.g100 : Grey.g95).copyWith(fontSize: T.px(12), fontWeight: FontWeight.w700),
            ),
            if (box.maxHeight >= 54) ...[SizedBox(height: Shape.s(3)), Text(tool.acts, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g56))],
          ],
        ),
      ),
    ),
  );
}
