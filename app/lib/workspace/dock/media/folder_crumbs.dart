// The breadcrumbs above the Media shelf's contents.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/folder_navigation.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';

/// Breadcrumbs for the open folder: each step opens that folder. While searching, they name the location searched.
class FolderCrumbs extends StatelessWidget {
  const FolderCrumbs(
    this.path,
    this.c,
    this.media, {
    super.key,
    required this.searching,
  });
  final List<FileNode> path;
  final ShelfContext c;

  /// What the shelf keeps between builds; a step opens its folder through it.
  final MediaController media;
  final bool searching;
  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(24),
    color: WindowTokens.card,
    padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
    child: Row(
      children: [
        if (searching)
          Expanded(
            child: Text(
              'Search in ${path.first.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.micro(Grey.g76),
            ),
          )
        else
          Expanded(
            child: Row(
              children: [
                for (final (i, n) in path.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
                      child: Glyph(
                        AppGlyphs.chevron,
                        size: Shape.z(6),
                        color: Grey.g56,
                      ),
                    ),
                  Flexible(
                    child: Pressable(
                      key: ValueKey('browser:crumb:${n.id}'),
                      cursor: MouseCursor.defer,
                      onTap: () => openFolder(c, media, n.id),
                      builder: (_, _) => Text(
                        n.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyles.micro(
                              n == path.last ? Grey.g95 : Grey.g63,
                            ).copyWith(
                              fontWeight: n == path.last
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  );
}
