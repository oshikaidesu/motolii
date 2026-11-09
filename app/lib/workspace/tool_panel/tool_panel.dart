// The Tool Panel: the drawer under the Inspector. It follows the selection and holds one tool at a time (keys picked -> Ease,
// a camera -> Depth, otherwise the Tools catalog); a tool opened by hand stays pinned until the selection moves or you unpin it.
import 'package:flutter/widgets.dart';

import '../../inspector/inspector_parts.dart' show Hov;
import '../../style/tokens.dart';
import 'tool_panel_widgets.dart';
import '../ws.dart';

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
              _ => panelTool(ws, name).build?.call() ?? _Placeholder(name: name),
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
              ToolChip(label: wide ? 'Pinned · Follow' : 'Pinned', dot: Grey.g76, onTap: () => ws.openToolPanel(null))
            else
              ToolChip(label: wide ? 'Follows selection' : 'Follows', dot: WsT.accent),
            SizedBox(width: WsT.gap),
            ToolIconButton(
              glyph: (ink) => ToolGlyph('Tools', ink),
              on: name == 'Tools',
              onTap: () => ws.openToolPanel(name == 'Tools' && pinned ? null : 'Tools'),
            ),
          ],
        );
      },
    );
  }
}

/// Every tool panel tool as a tile: sticker, name, what it acts on. The one the selection would pick wears an Auto tag.
/// Columns come from the width; the rows share the height while each keeps [_minTile], else the grid scrolls; a tall tool panel never stretches a tile past [_maxTile].
class _Catalog extends StatelessWidget {
  const _Catalog();
  static const _cell = 104.0, _minTile = 62.0, _maxTile = 92.0;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context), auto = ws.toolPanelAuto;
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
                    child: _ToolTile(t, auto: t.name == auto, onTap: () => ws.openToolPanel(t.name)),
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
  const _ToolTile(this.tool, {required this.auto, required this.onTap});
  final PanelTool tool;
  final bool auto;
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
              children: [
                ToolSticker(tool.name, size: Shape.z(26)),
                const Spacer(),
                if (auto)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topRight,
                      child: Container(
                        height: Shape.z(14),
                        padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: WsT.accent, borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius))),
                        child: Text(
                          'AUTO',
                          style: T.micro(WsT.onAccent).copyWith(fontSize: T.px(9), fontWeight: FontWeight.w700, letterSpacing: .6),
                        ),
                      ),
                    ),
                  ),
              ],
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

/// A tool the lab has not drawn yet: a poster of it (its hue, its glyph, its name) and the way back.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context), tool = panelTool(ws, name);
    return Padding(
      padding: EdgeInsets.only(top: WsT.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: WsT.card,
              padding: EdgeInsets.fromLTRB(WsT.inset * Shape.s(1.5), WsT.inset * Shape.s(1.5), WsT.inset, WsT.inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOOL', style: T.micro(tool.tone).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                  SizedBox(height: Shape.s(6)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: T.title(Grey.g95).copyWith(fontSize: T.px(34), fontWeight: FontWeight.w800, letterSpacing: -1, height: 1),
                    ),
                  ),
                  SizedBox(height: Shape.s(10)),
                  Text('Works on ${tool.acts.toLowerCase()}.', style: T.label(Grey.g76).copyWith(fontSize: T.px(11))),
                  SizedBox(height: Shape.s(5)),
                  Text('Not designed in the lab yet.', style: T.label(Grey.g56)),
                  const Spacer(),
                  Wrap(
                    spacing: WsT.gap,
                    runSpacing: WsT.gap,
                    children: [
                      ToolChip(label: 'Back to Tools', dot: Grey.g76, onTap: () => ws.openToolPanel('Tools')),
                      ToolChip(label: 'Follow selection', dot: WsT.accent, onTap: () => ws.openToolPanel(null)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: WsT.gutter),
          AspectRatio(
            aspectRatio: .5,
            child: ColoredBox(
              color: tool.tone,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: .8,
                  child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: ToolGlyph(name, WsT.onAccent))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
