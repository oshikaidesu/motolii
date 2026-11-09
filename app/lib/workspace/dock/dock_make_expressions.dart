// Part of dock_make.dart: a recipe's motion and the Expression group.
part of 'dock_make.dart';

// ---- a recipe's motion: asked of the inside once (create_preview.dart), on a document of its own.
bool _isRecipe(DockCtx c, String name) {
  final m = c.ws.inside;
  if (m == null || !m.recipes.any((r) => r.$1 == name)) return false;
  RecipeMotions.ask(File(m.libPath).parent.parent.path, [for (final r in m.recipes) r.$1]);
  return true;
}

/// The colour's number, typed: After Effects' Color Picker and Figma's both take one, #d4a72c, d4a72c or #da2. Told on Return or on leaving it.
class _HexField extends StatefulWidget {
  const _HexField(this.hex, this.onTold);
  final String hex;
  final ValueChanged<Color> onTold;
  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  final _c = TextEditingController();
  final _f = FocusNode(debugLabel: 'colour-hex');

  void _tell() {
    final said = _c.text.trim().replaceFirst('#', ''), whole = said.length == 3 ? [for (final k in said.split('')) '$k$k'].join() : said;
    if (whole.length != 6 || _colourOf(whole) == null || '#${whole.toLowerCase()}' == widget.hex.toLowerCase()) return;
    widget.onTold(_colourOf(whole)!);
  }

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) return _tell();
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length) : null);
    });
  }

  @override
  void dispose() {
    _f.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_f.hasFocus) _c.text = widget.hex;
    return TextHand(field: (k) => EditableText(key: k, rendererIgnoresPointer: true,
      controller: _c,
      focusNode: _f,
      style: T.value(Grey.g91).copyWith(fontWeight: FontWeight.w600),
      cursorColor: WsT.accent,
      backgroundCursorColor: Grey.g44,
      selectionColor: Grey.g38,
      cursorWidth: 1.5,
      maxLines: 1,
      onSubmitted: (_) => _f.unfocus(),
    ));
  }
}

// ---- the Expression group: every JS that goes on a thing and moves its values (docs/notes/CREATE_PROGRAM.md), one
//  place for them all: the recipes with each() (the Repeater, After Effects' expressions, Maze, Sunflower…), the
//  motions (Cavalry's Animators, animators/), the maker's own (Add to shelf: shelf_add.dart). Each is put on the picked
//  thing as a card of its own, as many as are wanted (fx_file, empty_fx.dart fxPut); nothing picked, a recipe makes
//  its thing as its head says, the others go on a new board.

/// The recipes that are expressions, by their head's name, and their files (the maker's of a file's name stands over
/// the library's, as the inside's doc_folders).
List<(String, String)> _expressionRecipes() {
  final by = <String, String>{};
  for (final dir in ['$motoliiShelves/recipes', '${EffectTiles.own}/recipes']) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {   // (its folders: shapes/, cavalry/, copies/, on_film/)
      final n = f.path.split('/').last;
      if (n.endsWith('.js') && f.readAsStringSync().contains(RegExp(r'function\s+each\b'))) by[n] = f.path;
    }
  }
  return [
    for (final f in by.values)
      if (File(f).readAsLinesSync().firstOrNull case final first? when first.startsWith('// ') && first.contains(':')) (first.substring(3, first.indexOf(':')), f),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

List<_Make> _expressionsOf(Ws ws) => [
  for (final (name, file) in _expressionRecipes()) _Make(name, DockG.copies, Pop.tonePlace, '', 'On the picked thing, a card of its own (nothing picked: makes its own thing)', file: file, made: true),
  for (final (name, file) in ws.inside?.animators ?? const <(String, String)>[]) _Make(name, DockG.copies, Pop.tonePlace, '', 'A motion, on the picked thing, a card of its own (nothing picked: on a new board)', file: file),
  for (final (name, file) in shelfExpressions()) _Make(name, DockG.copies, Pop.tonePlace, '', 'Your expression, on the picked thing (nothing picked: on a new board); its knobs are on its card', file: file),
];

void _expressionPut(DockCtx c, _Make tile) {
  final m = c.ws.inside!, name = tile.name, file = tile.file!, t = int.tryParse(c.ws.selected ?? '');
  void told(String why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why);
  c.set(() => c.mem.trouble.remove(name));
  if (t == null && tile.made) return c.ws.after(m.later('make', word: name), (done, why) => told(done ? '' : why), (made) => c.ws.select('$made'));   // (as a recipe's tile makes it)
  final first = t != null && !Ws.fxFiles(m.word(t, 'fx')).contains(file);
  fxPut(c.ws, file, expression: true, told: told);
  if (t == null) return;
  // (the copies its head makes its own thing with (// set copies), on a thing that has none to lay out; the Repeater's
  //  first knobs as its tile laid a thing out: _laid)
  final head = File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'));
  if (head.map((l) => RegExp(r'^// set copies (\d+)').firstMatch(l)?[1]).nonNulls.firstOrNull case final n? when (m.value(t, 'copies', 0) ?? 1) <= 1) m.later('set', thing: t, name: 'copies', number: double.parse(n));
  if (first) {
    for (final e in (_laid[name] ?? const <String, double>{}).entries) {
      m.later('set', thing: t, name: e.key, number: e.value);
    }
  }
}

/// The names on Create, the library's and the maker's (an expression is not added under one: shelf_add.dart).
Set<String> createNames(Ws ws) => {
  for (final (_, items) in [if (ws.inside != null) ...[_recipesOf(ws), _elementsOf(ws)], ..._makes, _solids, _materials, _lights]) ...items.map((m) => m.name),
  for (final m in _expressionsOf(ws)) m.name,
};

/// One the maker added: its tile, with Rename… on its menu (a library tile has none). The name is written beside its
/// file, never the file (shelf_add.dart shelfRename).
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
    child: GestureDetector(
      onSecondaryTapDown: (d) {
        final box = _menu.currentContext?.findRenderObject() as RenderBox?;
        _menu.currentState?.show(box?.globalToLocal(d.globalPosition) ?? Offset.zero, [WsMenuItem('Rename…', () => setState(() => _naming = true))]);
      },
      child: _MakeTile(widget.m, widget.c, naming: _naming ? ShelfNameField(widget.m.name, _renamed) : null),
    ),
  );
}

