// The Media shelf's browser: where it starts, the path to a folder, the tree, the folder rows, the breadcrumbs, and navigating and opening.
part of 'dock_files.dart';

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
              Expanded(child: _Contents(c)),
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
            Expanded(child: _Contents(c)),
          ],
        );
      },
    );
  }
}

/// The locations in the tree: the project's own files and the folders they are in, then the disk.
List<FileNode> _rootsOf(DockCtx c) {
  final kindOf = c.ws.inside!.kindOf;
  _kindOfFile = (f) =>
      // CLIP STUDIO's and OpenToonz's timesheet is not a layer kind in the engine, but its columns are.
      f.toLowerCase().endsWith('.xdts') ? 'timesheet' : kindOf(f);
  _thumbnailAtOf = c.ws.inside!.thumbnailAt;
  final files = _used(c.ws).keys.toList()..sort();
  return [
    FileNode(
      'Project',
      'Project',
      DockG.folder,
      kids: [
        for (final d in {?c.ws.documentFolder, for (final f in files) _dir(f)})
          FileNode(d, _base(d), DockG.folder), // The project's own folder comes first: a new project is one step from what lies beside it.
        for (final f in files)
          if (_glyphOf(f) case final g?) FileNode(f, _base(f), g),
      ],
    ),
    FileNode(_home, 'Home', DockG.folder),
  ];
}

/// The folders from the root down to [id], root first.
List<FileNode> _pathOf(DockCtx c, String id) {
  final roots = _rootsOf(c);
  if (!id.startsWith('/')) return [roots.first];
  final out = <FileNode>[];
  for (var at = id; ; at = _dir(at)) {
    if (at == _home || at == '/') return out..insert(0, FileNode(at, at == _home ? 'Home' : '/', DockG.folder));
    out.insert(0, FileNode(at, _base(at), DockG.folder));
  }
}

void _go(DockCtx c, String id) => c.set(() {
  if (id.startsWith('/')) _read(id); // A folder on disk is read again each time it is opened.
  c.mem.folder = id;
  // Only that folder opens: the same folder is listed under more than one location,
  // and opening every location above it would move the rows under the pointer.
  c.mem.open.add(id);
});

void _open(FileNode n, DockCtx c) {
  if (n.folder) return _go(c, n.id);
  if (DockHover.cmdAtPress && _kindOfFile(n.id).isNotEmpty) {
    // Cmd adds or removes one file from the selection, as in Finder.
    if (_filesPicked.isEmpty && c.sel != null && _kindOfFile(c.sel!).isNotEmpty) _filesPicked.add(c.sel!);
    _filesPicked.contains(n.id) ? _filesPicked.remove(n.id) : _filesPicked.add(n.id);
  } else {
    _filesPicked.clear();
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
class _Crumbs extends StatelessWidget {
  const _Crumbs(this.path, this.c, {required this.searching});
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
