// The Media shelf, in the style of AEViewer 2: one browser for the project's files and media.
// A folder tree (locations, then folders only) sits beside or above the open folder's contents, shown as thumbnails or a list.
// Wide: tree | contents. Narrow: the tree band (its height set by dragging) over the contents.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/common/folder_row.dart';
import 'package:motolii/workspace/dock/common/resizable_band.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/folder_contents.dart';
import 'package:motolii/workspace/dock/media/folder_navigation.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';

/// The tree band's height when the shelf is narrow. A double-click on its grip resets to this.
const defaultTreeHeight = 132.0;

/// From this shelf width the tree stands beside the contents instead of above them.
const _wide = 440.0;

/// The Media shelf: the folder tree and the contents of the open folder.
class MediaShelf extends StatelessWidget {
  const MediaShelf(this.c, this.media, {super.key});
  final ShelfContext c;

  /// What the shelf keeps between builds: the folders read, the files picked.
  final MediaController media;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: media.reads,
    builder: (context, _, _) => _shelf(context),
  );

  Widget _shelf(BuildContext context) {
    final at = c.mem.folder;
    if (at != 'Project' && !at.startsWith('/')) {
      c.mem.folder = mediaRoots(c, media).first.id;
    }
    return LayoutBuilder(
      builder: (context, box) {
        if (switch (c.mem.treeSide) {
          1 => true,
          2 => false,
          _ => box.maxWidth >= _wide,
        }) {
          // The tree side is chosen by the available room, or by where the user put it.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: Shape.z(160), child: _Tree(c, media)),
              ColoredBox(
                color: WindowTokens.ground,
                child: SizedBox(width: WindowTokens.gutter),
              ),
              Expanded(child: FolderContents(c, media)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResizableBand(
              height: c.mem.treeHeight,
              max: box.maxHeight - 160,
              reset: defaultTreeHeight,
              gripKey: const ValueKey('browser:tree-grip'),
              onHeight: (h) => c.set(() => c.mem.treeHeight = h),
              child: _Tree(c, media),
            ),
            Expanded(child: FolderContents(c, media)),
          ],
        );
      },
    );
  }
}

class _Tree extends StatelessWidget {
  const _Tree(this.c, this.media);
  final ShelfContext c;
  final MediaController media;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void walk(FileNode n, int depth) {
      final open = c.mem.open.contains(n.id),
          subs = open || media.listed(n)
              ? media.kidsOf(n).where((k) => k.folder).toList()
              : const <FileNode>[];
      final hasSubs = !media.listed(n) || subs.isNotEmpty,
          files = media.listed(n)
              ? media.kidsOf(n).where((k) => !k.folder).length
              : 0;
      rows.add(
        folderRow(
          key: ValueKey('browser:folder:${n.id}'),
          here: c.mem.folder == n.id,
          glyph: AppGlyphs.folder,
          glyphInk: depth == 0 ? WindowTokens.accentInk : Grey.g63,
          rest: depth == 0 ? Grey.g95 : null,
          bold: depth == 0,
          depth: depth,
          open: hasSubs ? open : null,
          onToggle: hasSubs ? () => c.toggle(c.mem.open, n.id) : null,
          count: files > 0 ? files : null,
          onTap: () => openFolder(c, media, n.id),
          name: (s) => Text(
            n.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s,
          ),
        ),
      );
      if (open) {
        for (final s in subs) {
          walk(s, depth + 1);
        }
      }
    }

    for (final r in mediaRoots(c, media)) {
      walk(r, 0);
    }
    return ColoredBox(
      color: WindowTokens.body,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
        children: rows,
      ),
    );
  }
}
