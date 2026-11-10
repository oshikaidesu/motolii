// The contents of the open folder in the Media shelf: what is listed, narrowed by the search and the chips.
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/media/file_footer.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/file_tile.dart';
import 'package:motolii/workspace/dock/media/folder_crumbs.dart';
import 'package:motolii/workspace/dock/media/folder_navigation.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';

/// The contents of the open folder: breadcrumbs, the chips of the kinds found, the tiles or rows, and the footer for
/// the picked file. While searching, it shows what the search finds under the open location.
class FolderContents extends StatelessWidget {
  const FolderContents(this.c, this.media, {super.key});
  final ShelfContext c;

  /// What the shelf keeps between builds: the folders read, the files picked.
  final MediaController media;
  @override
  Widget build(BuildContext context) {
    final path = folderPathOf(c, media, c.mem.folder), here = path.last;
    final root = here.disk
        ? here
        : path.first; // On the disk a search stays within the open folder.
    final searching = c.query.isNotEmpty;
    final List<FileNode> items;
    if (searching) {
      final found = <FileNode>[];
      void walk(FileNode n, int depth) {
        for (final k in media.kidsOf(n)) {
          if (k.folder) {
            if (depth < 4) walk(k, depth + 1);
          } else if (ShelfTags.hit(
            c.query,
            k.name,
            ShelfTags.of('Media', k.id, {
              kindLabelOf(k).toLowerCase(),
              if (k.id.contains('.')) k.id.split('.').last.toLowerCase(),
            }),
          )) {
            found.add(k);
          }
        }
      }

      walk(root, 0);
      items = {for (final n in found) n.id: n}.values
          .toList(); // A file in use appears twice, so keep one per id.
    } else {
      if (c.mem.mediaDeep) {
        // Lists the files of the folder and of every folder below it together.
        final all = <FileNode>[];
        void below(FileNode f, int depth) {
          if (f.disk && !media.listed(f) && depth > 0) media.readFolder(f.id);
          for (final k in media.kidsOf(f)) {
            if (k.folder) {
              if (depth < 4) below(k, depth + 1);
            } else {
              all.add(k);
            }
          }
        }

        below(here, 0);
        items = [...media.kidsOf(here).where((k) => k.folder), ...all];
      } else {
        items = [
          ...media.kidsOf(here).where((k) => k.folder),
          ...media.kidsOf(here).where((k) => !k.folder),
        ];
      }
    }
    final kinds = <String, int>{};
    for (final n in items) {
      kinds.update(kindLabelOf(n), (v) => v + 1, ifAbsent: () => 1);
    }
    final chip = kinds.containsKey(c.chip) ? c.chip : 'All';
    final shown = chip == 'All'
        ? items
        : items.where((n) => kindLabelOf(n) == chip).toList();
    final sel = c.foot(
      shown.where((n) => n.id == c.sel && !n.folder).firstOrNull,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FolderCrumbs(path, c, media, searching: searching),
        FilterChips(
          [
            ('All', items.length),
            for (final e in kinds.entries) (e.key, e.value),
          ],
          active: chip,
          onPick: c.pickChip,
        ),
        Expanded(
          child: shown.isEmpty
              ? EmptyShelf(c.query)
              : ShelfGrid(
                  shelfLooks['Media']!,
                  list: c.mem.mediaList,
                  count: shown.length,
                  tile: (i) => FileTile(
                    shown[i],
                    c,
                    media,
                    list: c.mem.mediaList,
                    where: searching
                        ? (shown[i].disk ? basename(dirname(shown[i].id)) : '')
                        : null,
                  ),
                ),
        ),
        if (sel != null) FileFooter(sel, c, media),
      ],
    );
  }
}
