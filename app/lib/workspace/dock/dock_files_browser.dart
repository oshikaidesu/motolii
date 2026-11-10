// The Media shelf's browser: where it starts, the path to a folder, the tree, the folder rows, the breadcrumbs, and navigating and opening.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Hov;
import 'package:motolii/workspace/dock/dock_files.dart';
import 'package:motolii/workspace/dock/dock_files_contents.dart';
import 'package:motolii/workspace/dock/dock_files_used.dart';
import 'package:motolii/workspace/dock/dock_folder_row.dart';
import 'package:motolii/workspace/dock/dock_resizable.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// The tree band's height when the shelf is narrow. A double-click on its grip resets to this.
const dockTreeHeight = 132.0;

/// From this shelf width the tree stands beside the contents instead of above them.
const _wide = 440.0;

final _home = Platform.environment['HOME'] ?? '/';

class MediaShelf extends StatelessWidget {
  const MediaShelf(this.c, {super.key});
  final DockCtx c;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: dockRead, builder: (context, _, _) => _shelf(context));

  Widget _shelf(BuildContext context) {
    final at = c.mem.folder;
    if (at != 'Project' && !at.startsWith('/')) c.mem.folder = _rootsOf(c).first.id;
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
              SizedBox(width: Shape.z(160), child: _Tree(c)),
              ColoredBox(
                color: WsT.ground,
                child: SizedBox(width: WsT.gutter),
              ),
              Expanded(child: FolderContents(c)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DockResizable(
              height: c.mem.treeHeight,
              max: box.maxHeight - 160,
              reset: dockTreeHeight,
              gripKey: const ValueKey('browser:tree-grip'),
              onHeight: (h) => c.set(() => c.mem.treeHeight = h),
              child: _Tree(c),
            ),
            Expanded(child: FolderContents(c)),
          ],
        );
      },
    );
  }
}

/// The locations in the tree: the project's own files and the folders they are in, then the disk.
List<FileNode> _rootsOf(DockCtx c) {
  final kindOf = c.ws.inside!.kindOf;
  kindOfFile = (f) =>
      // CLIP STUDIO's and OpenToonz's timesheet is not a layer kind in the engine, but its columns are.
      f.toLowerCase().endsWith('.xdts') ? 'timesheet' : kindOf(f);
  thumbnailAtOf = c.ws.inside!.thumbnailAt;
  final files = filesUsed(c.ws).keys.toList()..sort();
  return [
    FileNode(
      'Project',
      'Project',
      DockG.folder,
      kids: [
        for (final d in {?c.ws.documentFolder, for (final f in files) dirname(f)})
          FileNode(d, basename(d), DockG.folder), // The project's own folder comes first: a new project is one step from what lies beside it.
        for (final f in files)
          if (glyphOf(f) case final g?) FileNode(f, basename(f), g),
      ],
    ),
    FileNode(_home, 'Home', DockG.folder),
  ];
}

/// The folders from the root down to [id], root first.
List<FileNode> folderPathOf(DockCtx c, String id) {
  final roots = _rootsOf(c);
  if (!id.startsWith('/')) return [roots.first];
  final out = <FileNode>[];
  for (var at = id; ; at = dirname(at)) {
    if (at == _home || at == '/') return out..insert(0, FileNode(at, at == _home ? 'Home' : '/', DockG.folder));
    out.insert(0, FileNode(at, basename(at), DockG.folder));
  }
}

void _go(DockCtx c, String id) => c.set(() {
  if (id.startsWith('/')) readFolder(id); // A folder on disk is read again each time it is opened.
  c.mem.folder = id;
  // Only that folder opens: the same folder is listed under more than one location,
  // and opening every location above it would move the rows under the pointer.
  c.mem.open.add(id);
});

void openNode(FileNode n, DockCtx c) {
  if (n.folder) return _go(c, n.id);
  if (DockHover.cmdAtPress && kindOfFile(n.id).isNotEmpty) {
    // Cmd adds or removes one file from the selection, as in Finder.
    if (filesPicked.isEmpty && c.sel != null && kindOfFile(c.sel!).isNotEmpty) filesPicked.add(c.sel!);
    filesPicked.contains(n.id) ? filesPicked.remove(n.id) : filesPicked.add(n.id);
  } else {
    filesPicked.clear();
  }
  c.pick(n.id);
}

class _Tree extends StatelessWidget {
  const _Tree(this.c);
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void walk(FileNode n, int depth) {
      final open = c.mem.open.contains(n.id), subs = open || n.listed ? n.kids.where((k) => k.folder).toList() : const <FileNode>[];
      final hasSubs = !n.listed || subs.isNotEmpty, files = n.listed ? n.kids.where((k) => !k.folder).length : 0;
      rows.add(
        dockFolderRow(
          key: ValueKey('browser:folder:${n.id}'),
          here: c.mem.folder == n.id,
          glyph: DockG.folder,
          glyphInk: depth == 0 ? WsT.accentInk : Grey.g63,
          rest: depth == 0 ? Grey.g95 : null,
          bold: depth == 0,
          depth: depth,
          open: hasSubs ? open : null,
          onToggle: hasSubs ? () => c.toggle(c.mem.open, n.id) : null,
          count: files > 0 ? files : null,
          onTap: () => _go(c, n.id),
          name: (s) => Text(n.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
        ),
      );
      if (open) {
        for (final s in subs) {
          walk(s, depth + 1);
        }
      }
    }

    for (final r in _rootsOf(c)) {
      walk(r, 0);
    }
    return ColoredBox(
      color: WsT.body,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
        children: rows,
      ),
    );
  }
}

/// Breadcrumbs for the open folder: each step opens that folder. While searching, they name the location searched.
class FolderCrumbs extends StatelessWidget {
  const FolderCrumbs(this.path, this.c, {super.key, required this.searching});
  final List<FileNode> path;
  final DockCtx c;
  final bool searching;
  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(24),
    color: WsT.card,
    padding: EdgeInsets.symmetric(horizontal: WsT.inset),
    child: Row(
      children: [
        if (searching)
          Expanded(
            child: Text('Search in ${path.first.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.micro(Grey.g76)),
          )
        else
          Expanded(
            child: Row(
              children: [
                for (final (i, n) in path.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
                      child: Glyph(DockG.chevron, size: Shape.z(6), color: Grey.g56),
                    ),
                  Flexible(
                    child: Hov(
                      key: ValueKey('browser:crumb:${n.id}'),
                      cursor: MouseCursor.defer,
                      onTap: () => _go(c, n.id),
                      builder: (_, _) => Text(
                        n.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.micro(n == path.last ? Grey.g95 : Grey.g63).copyWith(fontWeight: n == path.last ? FontWeight.w700 : FontWeight.w500),
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
