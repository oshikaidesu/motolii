// Where the Media shelf's tree starts, the path from there to a folder, and opening a folder or a file.
import 'dart:io';

import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

final _home = Platform.environment['HOME'] ?? '/';

/// The locations in the tree: the project's own files and the folders they are in, then the disk.
List<FileNode> mediaRoots(ShelfContext c, MediaController media) {
  final files = media.filesUsed.keys.toList()..sort();
  return [
    FileNode(
      'Project',
      'Project',
      AppGlyphs.folder,
      fixedKids: [
        for (final d in {
          ?c.ws.documentFolder,
          for (final f in files) dirname(f),
        })
          FileNode(d, basename(d), AppGlyphs.folder), // The project's own folder comes first: a new project is one step from what lies beside it.
        for (final f in files)
          if (media.glyphOf(f) case final g?) FileNode(f, basename(f), g),
      ],
    ),
    FileNode(_home, 'Home', AppGlyphs.folder),
  ];
}

/// The folders from the root down to [id], root first.
List<FileNode> folderPathOf(ShelfContext c, MediaController media, String id) {
  final roots = mediaRoots(c, media);
  if (!id.startsWith('/')) return [roots.first];
  final out = <FileNode>[];
  for (var at = id; ; at = dirname(at)) {
    if (at == _home || at == '/') {
      return out
        ..insert(0, FileNode(at, at == _home ? 'Home' : '/', AppGlyphs.folder));
    }
    out.insert(0, FileNode(at, basename(at), AppGlyphs.folder));
  }
}

/// Opens the folder [id] in the shelf: its contents are shown and its row in the tree is opened.
void openFolder(ShelfContext c, MediaController media, String id) => c.set(() {
  if (id.startsWith('/')) {
    // A folder on disk is read again each time it is opened.
    media.readFolder(id);
  }
  c.mem.folder = id;
  // Only that folder opens: the same folder is listed under more than one location,
  // and opening every location above it would move the rows under the pointer.
  c.mem.open.add(id);
});

/// What a press on [n] does: a folder is opened, a file is picked. With Cmd held, a file joins or leaves the files
/// picked together.
void openNode(FileNode n, ShelfContext c, MediaController media) {
  if (n.folder) return openFolder(c, media, n.id);
  if (DockHover.cmdAtPress && media.kindOf(n.id).isNotEmpty) {
    // Cmd adds or removes one file from the selection, as in Finder.
    if (media.picked.isEmpty &&
        c.sel != null &&
        media.kindOf(c.sel!).isNotEmpty) {
      media.picked.add(c.sel!);
    }
    media.picked.contains(n.id)
        ? media.picked.remove(n.id)
        : media.picked.add(n.id);
  } else {
    media.picked.clear();
  }
  c.pick(n.id);
}
