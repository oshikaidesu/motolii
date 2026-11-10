// A tool's sticker and the lookup of a tool by name.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/app_glyphs.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The tool named [name], or null if there is none.
WsPane? panelTool(Ws ws, String name) => ws.tools.where((t) => t.name == name).firstOrNull;

/// A tool's sticker: a flat tile in its colour with the glyph knocked out in dark ink.
class ToolSticker extends StatelessWidget {
  const ToolSticker(this.name, {super.key, this.size = 16});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final tool = panelTool(WsScope.read(context), name);
    final tone = name == 'Tools' ? Grey.g76 : tool?.tone ?? Grey.g63;
    final g = name == 'Tools' ? DockG.tools : tool?.glyph;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(size * .3)),
      child: g == null
          // A tool the user made shows its first letter.
          ? Center(child: Text(name.characters.first, style: T.micro(WsT.onAccent)))
          : Glyph(g, size: size, color: WsT.onAccent),
    );
  }
}
