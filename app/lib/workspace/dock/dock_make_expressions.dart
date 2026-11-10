// Part of dock_make.dart: a script's motion preview and the Expression group.
part of 'dock_make.dart';

// ---- A script's motion preview: the engine is asked for it once (create_preview.dart), on a project of its own.

/// True if [name] is one of the engine's create scripts. It also starts asking for the motions of all the scripts.
bool _isRecipe(DockCtx c, String name) {
  final m = c.ws.inside;
  if (m == null || !m.createScripts.any((r) => r.$1 == name)) return false;
  RecipeMotions.ask(File(m.libPath).parent.parent.path, [for (final r in m.createScripts) r.$1]);
  return true;
}

/// A field for typing a color's hex value, as in the color pickers of After Effects and Figma: #d4a72c, d4a72c or #da2.
/// It reports the color on Return or when the field loses focus.
class _HexField extends StatelessWidget {
  const _HexField(this.hex, this.onTold);
  final String hex;
  final ValueChanged<Color> onTold;

  void _tell(String? said) {
    final bare = (said ?? '').trim().replaceFirst('#', ''), whole = bare.length == 3 ? [for (final k in bare.split('')) '$k$k'].join() : bare;
    if (said == null || whole.length != 6 || colorOfHex(whole) == null || '#${whole.toLowerCase()}' == hex.toLowerCase()) return;
    onTold(colorOfHex(whole)!);
  }

  @override
  Widget build(BuildContext context) => TypedField(
    text: hex,
    standing: true,
    pickOnFocus: true,
    style: T.value(Grey.g91).copyWith(fontWeight: FontWeight.w600),
    cursor: WsT.accent,
    backgroundCursor: Grey.g44,
    selection: Grey.g38,
    cursorWidth: 1.5,
    onDone: _tell,
  );
}

// ---- The Expression group: every JS file that goes on a layer and moves its values (docs/internal/notes/CREATE_PROGRAM.md).
// It gathers three kinds in one place:
// - scripts with each(): the Repeater, After Effects expressions, Maze, Sunflower and others
// - motions: Cavalry's Animators, in expressions/
// - the user's own, added with Add to shelf (shelf_add.dart)
// Each is added to the picked layer as a card of its own, as many times as wanted (fx_file, empty_fx.dart fxPut).
// With nothing picked, a script creates its own layer as its head says, and the others go on a new layer.

/// The create scripts that are expressions, as (name from the file's head, file path).
/// A user's file replaces a library file of the same name, as the engine's doc_folders does.
List<(String, String)> _expressionRecipes() {
  final by = <String, String>{};
  for (final dir in ['$motoliiShelves/create', '${EffectTiles.own}/recipes', '${EffectTiles.own}/create']) {
    // recipes/ is the user's folder under its former name, which doc_folders still reads.
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {
      // Subfolders: shapes/, cavalry/, repeats/, over_footage/.
      final n = f.path.split('/').last;
      if (n.endsWith('.js') && f.readAsStringSync().contains(RegExp(r'function\s+each\b'))) by[n] = f.path;
    }
  }
  return [
    for (final f in by.values)
      if (File(f).readAsLinesSync().firstOrNull case final first? when first.startsWith('// ') && first.contains(':'))
        (first.substring(3, first.indexOf(':')), f),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

/// The tiles of the Expression group: scripts that are expressions, then the engine's motions, then the user's own.
List<_Make> _expressionsOf(Ws ws) => [
  for (final (name, file) in _expressionRecipes())
    _Make(name, DockG.copies, Pop.tonePlace, '', 'On the picked thing, a card of its own (nothing picked: makes its own thing)', file: file, made: true),
  for (final (name, file) in ws.inside?.animators ?? const <(String, String)>[])
    // A motion the user added is also in expressions/, the engine's motions folder. Its tile is the one below, with its own name.
    if (!shelfAdded(file))
      _Make(name, DockG.copies, Pop.tonePlace, '', 'A motion, on the picked thing, a card of its own (nothing picked: on a new board)', file: file),
  for (final (name, file) in shelfExpressions())
    _Make(
      name,
      DockG.copies,
      Pop.tonePlace,
      '',
      'Your expression, on the picked thing (nothing picked: on a new board); its knobs are on its card',
      file: file,
    ),
];

/// Puts an expression on the picked layer, or on a new layer when none is picked.
void _expressionPut(DockCtx c, _Make tile) {
  final m = c.ws.inside!, name = tile.name, file = tile.file!, t = int.tryParse(c.ws.selected ?? '');
  void told(String why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why);
  c.set(() => c.mem.trouble.remove(name));
  if (t == null && tile.made) {
    // Created the same way as a script tile.
    return c.ws.after(m.later('create', word: name), (done, why) => told(done ? '' : why), (made) => c.ws.select('$made'));
  }
  final first = t != null && !Ws.fxFiles(m.word(t, 'fx')).contains(file);
  fxPut(c.ws, file, expression: true, told: told);
  if (t == null) return;
  // If the script's head has a "// set copies N" line and the layer has no copies to lay out yet, set copies to N.
  // The first time the Repeater is added, its starting parameters are also set from _laid.
  final head = File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'));
  if (head.map((l) => RegExp(r'^// set copies (\d+)').firstMatch(l)?[1]).nonNulls.firstOrNull case final n? when (m.value(t, 'copies', 0) ?? 1) <= 1) {
    m.later('set', layer: t, name: 'copies', number: double.parse(n));
  }
  if (first) {
    for (final e in (_laid[name] ?? const <String, double>{}).entries) {
      m.later('set', layer: t, name: e.key, number: e.value);
    }
  }
}

/// All names on Create, the library's and the user's. An expression cannot be added under one of them (shelf_add.dart).
Set<String> createNames(Ws ws) => {
  for (final (_, items) in [
    if (ws.inside != null) ...[_recipesOf(ws), _elementsOf(ws)],
    ..._makes,
    _solids,
    _materials,
    _lights,
  ])
    ...items.map((m) => m.name),
  for (final m in _expressionsOf(ws)) m.name,
};

/// A tile for an item the user added, with Rename… on its menu (library tiles have none).
/// The new name is stored beside the file and never changes the file (shelf_add.dart shelfRename).
class _OwnTile extends StatefulWidget {
  const _OwnTile(this.m, this.c, {super.key});
  final _Make m;
  final DockCtx c;
  @override
  State<_OwnTile> createState() => _OwnTileState();
}

class _OwnTileState extends State<_OwnTile> {
  final _menu = GlobalKey<WsMenuState>();
  bool _naming = false;

  void _renamed(String? to) {
    setState(() => _naming = false);
    final m = widget.m, ws = widget.c.ws;
    if (to == null || to.trim() == m.name) return;
    final why = shelfRename(ws, m.file!, to, createNames(ws).difference({m.name}));
    if (why.isNotEmpty) ws.notice = 'Not renamed: $why';
  }

  @override
  Widget build(BuildContext context) => WsMenu(
    key: _menu,
    child: _makeTile(
      widget.m,
      widget.c,
      naming: _naming ? ShelfNameField(widget.m.name, _renamed) : null,
      onMenu: (at) {
        final box = _menu.currentContext?.findRenderObject() as RenderBox?;
        _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [WsMenuItem('Rename…', () => setState(() => _naming = true))]);
      },
    ),
  );
}
