// Part of dock_make.dart (cut there by size, as it was).
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

// ---- the expressions the maker added to the shelf (Add to shelf on a card's code: shelf_add.dart), in the Copies
//  after the library's: put on the picked thing, or a new board, as Empty is; renamed by their menu, as the Program
//  shelf's (dock_program.dart).
List<_Make> _ownExpressions() => [
  for (final (name, file) in shelfExpressions()) _Make(name, DockG.copies, Pop.tonePlace, '', 'Your expression, on the picked thing (nothing picked: on a new board); its knobs are on its card', file: file),
];

void _ownPut(DockCtx c, String name, String file) {
  c.set(() => c.mem.trouble.remove(name));
  fxPut(c.ws, file, expression: true, told: (why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why));
}

/// The names on Create, the library's and the maker's (an expression is not added under one: shelf_add.dart).
Set<String> createNames(Ws ws) => {
  for (final (_, items) in [if (ws.inside != null) ...[_recipesOf(ws), _elementsOf(ws)], ..._makes, _solids, _materials, _lights]) ...items.map((m) => m.name),
  for (final (name, _) in shelfExpressions()) name,
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

/// The expression a Copies tile is drawn by (copies_tiles.dart): the Repeater's recipe, one the maker added; null, a
/// glyph (Empty keeps its "+").
String? _copiesTile(_Make m) => m.file ?? (m.name == 'Repeater' && !m.recipe ? '$motoliiDir/recipes/repeater.js' : null);
