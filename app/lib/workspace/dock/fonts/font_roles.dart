// The title and body fonts at the top of the Fonts shelf.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip;
import 'package:motolii/workspace/dock/fonts/font_commands.dart';
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/font_tile.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// The title and body fonts, shown first on the shelf like PowerPoint's Headings and Body theme fonts
/// and Canva's brand fonts.
///
/// With no text layer selected, clicking a role chooses which role the next clicked font is for.
/// With a text layer selected, clicking a role applies that role's font to it. The + button adds a new text in that font.
class FontRoles extends StatelessWidget {
  /// The two roles of the shelf [c], their fonts named from [fonts].
  const FontRoles(this.c, this.controller, this.fonts, {super.key});

  /// The shelf as it is built now.
  final ShelfContext c;

  /// What the shelf keeps between builds; the fonts used lately are noted in it.
  final FontsController controller;

  /// The fonts the shelf offers; a role's font is named from them.
  final List<FontFile> fonts;
  @override
  Widget build(BuildContext context) {
    final commands = FontCommands(c, controller);
    final m = c.ws.inside!,
        t = int.tryParse(c.ws.selected ?? ''),
        onText = t != null && m.word(t, 'kind') == 'text';
    Widget role(String r, String label, String face) {
      final f =
          fonts.where((f) => f.path == face).firstOrNull ??
          FontFile(
            face.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), ''),
            path: face,
          );
      final on = !onText && c.ws.fontRole == r;
      return Expanded(
        child: DockHover(
          key: ValueKey('font-role-$r'),
          onTap: () => onText
              ? commands.setFace(t, face)
              : c.set(() => c.ws.fontRole = r),
          builder: (context, h) => Container(
            height: Shape.z(46),
            padding: EdgeInsets.only(left: Shape.s(8), right: Shape.s(4)),
            color: dockFill(on, h, WindowTokens.card),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyles.label(dockInk(on, Grey.g63)),
                      ),
                      SizedBox(height: Shape.s(2)),
                      Text(
                        f.family,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fontFaceStyle(f, 14, dockInk(on, Grey.g95)),
                      ),
                    ],
                  ),
                ),
                Chip(
                  key: ValueKey('font-add-$r'),
                  label: '+',
                  onTap: () => commands.addIn(face),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: WindowTokens.gutter),
      child: Row(
        children: [
          role('title', 'Title', c.ws.titleFace),
          SizedBox(width: WindowTokens.gutter),
          role('body', 'Body', c.ws.bodyFace),
        ],
      ),
    );
  }
}
