// A tool's sticker and the lookup of a tool by name.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/app_glyphs.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The tool named [name], or null if there is none.
Pane? panelTool(WorkspaceController ws, String name) => ws.tools.where((t) => t.name == name).firstOrNull;

/// A tool's sticker: a flat tile in its colour with the glyph knocked out in dark ink.
class ToolSticker extends StatelessWidget {
  const ToolSticker(this.name, {super.key, this.size = 16});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final tool = panelTool(WorkspaceScope.read(context), name);
    final tone = name == 'Tools' ? Grey.g76 : tool?.tone ?? Grey.g63;
    final g = name == 'Tools' ? AppGlyphs.tools : tool?.glyph;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(size * .3)),
      child: g == null
          // A tool the user made shows its first letter.
          ? Center(child: Text(name.characters.first, style: TextStyles.micro(WindowTokens.onAccent)))
          : Glyph(g, size: size, color: WindowTokens.onAccent),
    );
  }
}
