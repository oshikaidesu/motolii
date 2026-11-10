// Part of dock_make.dart: the Create shelf: its tiles (shapes, solids, lights, materials, copies), what each makes, and
// how many are ready.
part of 'dock_make.dart';

/// How many of the Create shelf's tiles make or lay out something of the document, of all it shows.
String createFact(Ws ws) {
  final recipes = _recipesOf(ws).$2.length, expressions = _expressionsOf(ws).length; // (the recipes that are expressions are tiles of the Expression group's)
  return '${_asked.length + _worn.length + recipes + expressions} ready'; // (the shelf shows only these)
}

/// Joined: the inside's recipes, pictures in one call (as Cavalry's tutorials build them), each a tile.
(String, List<_Make>) _recipesOf(Ws ws) {
  final expressions = {for (final (name, _) in _expressionRecipes()) name}; // (not those that are expressions: their tiles are the Expression group's)
  final packs = {for (final (name, _) in ws.inside!.packs) name}; // (nor the closed packs: the Program shelf's, dock_program.dart)
  return (
    'Recipes',
    [
      for (final (name, what) in ws.inside!.createScripts)
        if (!expressions.contains(name) && !packs.contains(name)) _Make(name, DockG.copies, Pop.tonePlace, '', what, recipe: true),
    ],
  );
}

/// The elements kept (Edit › Save to My Elements), put in at the playhead linked to their file: Alight Motion's + ›
/// Object / Element › Element, AbsentMotion's ElementPicker (ElementUi.kt).
(String, List<_Make>) _elementsOf(Ws ws) =>
    ('Elements', [for (final (name, _) in ws.inside!.elements) _Make(name, DockG.nullObj, Grey.g76, '', 'Element, linked to its file')]);

// ---------------------------------------------------------------- create

class _Make {
  const _Make(this.name, this.g, this.hue, this.key, this.what, {this.recipe = false, this.file, this.made = false});
  final String name, key, what;
  final DockG g;
  final Color hue;

  /// One of the recipes (a picture made in one call), which may share a name with a tile of the shelf's own: AbsentMotion's
  /// Rectangle, Star, Cube, Sun beside Motolii's shape, solid and light of those names (the shelf's own were made as
  /// the recipe while it was asked first).
  final bool recipe;
  final String? file; // (an expression: its file, put on the picked thing as a card of its own)
  final bool made; // (an expression whose head makes its thing (a recipe's "// make"): nothing picked, that is made)
  String get id => file ?? (recipe ? 'recipe:$name' : name);
  bool get onPicked => file != null || _onPicked.contains(name); // (put on the picked thing, or a new board)
}

final _makes = <(String, List<_Make>)>[
  (
    'Layers',
    [
      _Make('Text', DockG.text, WsT.toneText, 'T', 'Type layer'),
      _Make(
        'Camera',
        DockG.camera,
        WsT.toneCamera,
        '⇧C',
        '3D camera, 45 mm',
      ), // (the lens it comes with: the stage's 30 degrees on Filament's 24 mm film, tool_panel_depth.dart _filmMm, as the Camera tool panel says)
      _Make('Null', DockG.nullObj, Grey.g76, '⇧N', 'Invisible parent'),
      _Make('Adjustment', DockG.nullObj, Grey.g76, '', 'What is put on it works on all under it'),
    ],
  ),
  (
    'Shapes',
    [
      _Make('Rectangle', DockG.rect, WsT.toneShape, 'R', 'Rounded corners'),
      _Make('Ellipse', DockG.ellipse, WsT.toneShape, 'E', 'Circle with ⇧'),
      _Make('Polygon', DockG.polygon, WsT.toneShape, '', 'Sides · Roundness'),
      _Make('Star', DockG.star, WsT.toneShape, '', 'Points · Inner radius'),
      _Make('Line', DockG.line, WsT.toneShape, 'L', 'Open path'),
    ],
  ),
  (
    'Expression', // (every JS that goes on a thing and moves its values, after Empty: dock_make_expressions.dart _expressionsOf)
    [
      _Make(
        'Empty',
        DockG.plus,
        Pop.tonePlace,
        '',
        'An empty expression on the picked thing (nothing picked: on a new board): write or paste each() into its card\'s code',
      ),
    ],
  ),
];

/// The inside's own 3D shapes, and how a tile is asked of it (kind, then its file or shape).
final _solids = (
  '3D',
  [
    _Make('Ring', DockG.radial, WsT.toneShape, '', 'A solid ring'),
    _Make('Gem', DockG.polygon, WsT.toneShape, '', 'A cut solid'),
    _Make('Cube', DockG.rect, WsT.toneShape, '', 'A round-edged cube'),
    _Make('Floor', DockG.rect, WsT.toneShape, '', 'A wide flat floor that takes shadows'),
    _Make('Ball', DockG.ellipse, WsT.toneShape, '', 'A ball'),
  ],
);

/// Filament's own lights, things of the document: placed and turned as any thing, they light the solid things.
final _lights = (
  'Light',
  [
    _Make('Sun', DockG.light, WsT.toneCamera, '', 'Light from one way, everywhere'),
    _Make('Point', DockG.light, WsT.toneCamera, '', 'Light from a point, all round'),
    _Make('Spot', DockG.light, WsT.toneCamera, '', 'A cone of light'),
  ],
);

/// What a thing is made of, a material: put on the picked thing, any that is seen (a flat one wears it on its own plane,
/// its picture its colour), one at a time; nothing picked, a ball wearing it (a material is made in Create, not chosen
/// among colours: the user, 10/29, "マテリアルなら普通クリエイトに入れるべき"). Filament's own and the kit's, by their names to a
/// user; the inside's word for each (shading: doc.h doc_material). Each tile a ball wearing it: material_tiles.dart.
final _materials = (
  'Material',
  [
    _Make('Lit', DockG.ellipse, WsT.toneShape, '', 'Filament\'s lit surface: its colour, metal, rough, a clear coat'),
    _Make('Cloth', DockG.ellipse, WsT.toneShape, '', 'Soft, no sharp highlight, a sheen at its rim'),
    _Make('Subsurface', DockG.ellipse, WsT.toneShape, '', 'Light goes into it and comes out, as in wax or skin'),
    _Make('Glass', DockG.radial, WsT.toneShape, '', 'Thick glass: bends and tints what lies behind it'),
    _Make('Filament glass', DockG.radial, WsT.toneShape, '', 'Filament\'s own glass: bends what is behind, a thin film\'s rainbow'),
    _Make('Lacquer', DockG.ellipse, WsT.toneShape, '', 'Its colour under a hard clear coat'),
    _Make('Bubble', DockG.radial, WsT.toneShape, '', 'Nearly clear, a bright rim'),
  ],
);
const _worn = {
  'Lit': 'lit',
  'Cloth': 'cloth',
  'Subsurface': 'subsurface',
  'Glass': 'glass',
  'Filament glass': 'filament_glass',
  'Lacquer': 'lacquer',
  'Bubble': 'bubble',
}; // (the tile, and the shading it gives)
const _wears = {'film', 'picture', 'text', 'shape', 'solid'}; // (the kinds of thing that are seen, and so wear one)
const _onPicked = {'Empty'}; // (put on the picked thing, or a new board: empty_fx.dart)

final _asked = {
  'Text': ('text', wsTextFont),
  'Solid': ('shape', 'solid'), // (a flat colour as large as the stage: the inside makes it so)
  'Rectangle': ('shape', 'rect'),
  'Ellipse': ('shape', 'circle'),
  'Polygon': ('shape', 'polygon'),
  'Star': ('shape', 'star'),
  'Line': ('shape', 'line'),
  'Null': ('shape', 'null'), // (nothing to see: a thing to go with)
  'Camera': ('camera', 'camera'), // (the nearest one that is on is the stage's eye)
  'Ring': ('solid', 'ring'),
  'Gem': ('solid', 'gem'),
  'Cube': ('solid', 'cube'),
  'Floor': ('solid', 'cube'),
  'Ball': ('solid', 'ball'),
  'Sun': ('light', 'sun'),
  'Point': ('light', 'point'),
  'Spot': ('light', 'spot'),
};

/// What a tile lays on what it makes, in its one step: Cinema 4D's Floor object, a Cube laid flat under the stage (a flat
/// Rect is unlit and takes no shadow); a light from above in front, as After Effects' new light looks at the middle of the
/// composition from there (at no turn a Sun looks along the floor and lights nothing of it).
const _starts = <String, Map<String, double>>{
  'Floor': {'scale_x': 12, 'scale_y': .01, 'scale_z': 12, 'y': -.48},
  'Sun': {'rotate_x': -60, 'rotate_y': 35},
};

/// What the Repeater tells the picked thing as it is first put on it (its knobs: js_StepX, js_Size), as its tile laid
/// the thing out before it was an expression: in a row, side by side and a little smaller each time.
const _laid = <String, Map<String, double>>{
  'Repeater': {'js_StepX': 1.3, 'js_Size': .92},
};

/// A tile made on the stage as a new thing, picked; a tile of copies lays the picked thing out. Not done: the foot of
/// the shelf says why.
void _make(DockCtx c, _Make tile) {
  final m = c.ws.inside!, name = tile.name;
  if (tile.recipe) {
    // (a picture in one call: one step, and it is picked)
    c.ws.after(
      m.later('create', word: name),
      (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why),
      (made) => c.ws.select('$made'),
    ); // (without waiting: picked once made)
    return;
  }
  if (tile.file != null) return _expressionPut(c, tile);
  if (name == 'Adjustment') return c.ws.adjustment();
  if (name == 'Empty') {
    // (an expression to write: empty_fx.dart; what went wrong before forgotten once it is taken)
    c.set(() => c.mem.trouble.remove(name));
    return emptyPut(c.ws, expression: true, told: (why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why));
  } // (After Effects' New > Adjustment Layer)
  if (_worn[name] case final wears?) {
    // (on the picked thing, in place of the one it wore; nothing picked, a ball wearing it, picked)
    final t = int.tryParse(c.ws.selected ?? '');
    void told(bool done, String why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why);
    if (t != null) {
      if (!_wears.contains(m.word(t, 'kind'))) return c.set(() => c.mem.trouble[name] = 'A camera, a light or a null wears nothing: pick a thing that is seen');
      c.ws.after(m.later('say', layer: t, name: 'shading', word: wears), told);
      return;
    }
    m.later('together', number: 1); // (one step: the ball and what it wears)
    c.ws.after(m.later('add', name: 'solid', word: 'ball'), null, (made) => c.ws.select('$made'));
    wsInked(c.ws, 'solid', 'ball');
    m.later('say', layer: -1, name: 'shading', word: wears);
    c.ws.after(m.later('together'), told);
    return;
  }
  if (!_asked.containsKey(name)) {
    if (m.elements.where((e) => e.$1 == name).firstOrNull case final e?) {
      // (at the playhead, in the middle, picked: AbsentMotion's addElement)
      c.ws.after(
        m.later('element', word: e.$2, number: c.ws.frame / Ws.fps),
        (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why),
        (made) => c.ws.select('$made'),
      );
    }
    return;
  }
  final asked = _asked[name]!;
  m.later('together', number: 1); // (one step: the thing and its inks)
  c.ws.after(
    m.later('add', name: asked.$1, word: asked.$1 == 'text' ? c.ws.bodyFace : asked.$2),
    null,
    (made) => c.ws.select('$made'),
  ); // (without waiting: picked once made; a text in the body's font)
  wsInked(c.ws, asked.$1, asked.$2);
  for (final e in (_starts[name] ?? const <String, double>{}).entries) {
    m.later('set', layer: -1, name: e.key, number: e.value);
  }
  if (name == 'Floor') m.later('say', layer: -1, name: 'name', word: name);
  if (asked.$1 == 'light' && (m.value(0, 'environment', 0) ?? 1) == 1) {
    m.later(
      'set',
      layer: 0,
      name: 'environment',
      number: .3,
    ); // (After Effects: a light put in takes over from the default light; the Room dims, what it was is one field in Stage settings)
  }
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why));
}

class CreateShelf extends StatelessWidget {
  const CreateShelf(this.c, {super.key});
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final makes = [
      _recipesOf(c.ws),
      _makes.first,
      _elementsOf(c.ws),
      for (final (g, items) in _makes.skip(1)) g == 'Expression' ? (g, [...items, ..._expressionsOf(c.ws)]) : (g, items),
      _solids,
      _materials,
      _lights,
    ].where((e) => e.$2.isNotEmpty).toList();
    var groups = [
      for (final (g, items) in makes)
        if (c.chip == 'All' || c.chip == g) (g, items.where((m) => c.hit(m.name)).toList()),
    ].where((e) => e.$2.isNotEmpty).toList();
    if (groups.isEmpty && c.query.trim().isNotEmpty) {
      // (nothing has the words as typed: the nearest five, each in its own group, golf (97))
      // (by the tile's name alone, and only those near it: with its group's name, "Material" drew every material up
      //  for any word, Butterfly's or Empty's. RapidFuzz's WRatio of a word typed wrong to its tile is 77 or more
      //  (bubbel Bubble 83, lacker Lacquer 77, clth Cloth 89), of a word to a tile it is not 72 or less (butterfly
      //  Bubble 49, empty Gem 72). A Japanese word is found by what it means (WordNet, its own scores): all kept)
      final near = c.near([
        for (final (_, items) in makes)
          for (final m in items) (m.id, m.name, ''),
      ], least: c.query.runes.every((r) => r < 128) ? 75 : 0);
      groups = [
        for (final (g, items) in makes)
          if (c.chip == 'All' || c.chip == g) (g, [for (final id in near) ...items.where((m) => m.id == id)]),
      ].where((e) => e.$2.isNotEmpty).toList();
    }
    final sel = c.foot(makes.expand((e) => e.$2).where((m) => m.id == c.sel).firstOrNull);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DockChips(
          [('All', makes.fold<int>(0, (s, e) => s + e.$2.length)), for (final (g, items) in makes) (g, items.length)],
          active: c.chip,
          onPick: c.pickChip,
        ),
        Expanded(
          child: groups.isEmpty
              ? DockEmpty(c.query)
              : DockMasonry(
                  weights: [for (final (_, items) in groups) 1 + items.length / 3],
                  children: [
                    for (final (g, items) in groups)
                      Padding(
                        padding: EdgeInsets.only(bottom: WsT.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DockSection(
                              g,
                              count: items.length,
                              hue: items.first.hue,
                              folded: c.query.isEmpty && c.mem.createFolded.contains(g),
                              onTap: () => c.set(() => c.mem.createFolded.contains(g) ? c.mem.createFolded.remove(g) : c.mem.createFolded.add(g)),
                            ),
                            if (!(c.query.isEmpty && c.mem.createFolded.contains(g))) ...[
                              const SizedBox(height: WsT.gutter),
                              ShelfGrid(
                                shelfLooks['Create']!,
                                shrinkWrap: true,
                                count: items.length,
                                tile: (i) {
                                  final m = items[i];
                                  return m.file != null && shelfAdded(m.file!) ? _OwnTile(m, c, key: ValueKey('ws-own-${m.file}')) : _makeTile(m, c);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (sel != null)
          DockFooter(
            preview: dockBadge(sel.g, sel.hue, size: Shape.z(34)),
            title: '${sel.name} layer',
            meta: c.mem.trouble[sel.name] ?? 'At ${c.ws.timecode()} · ${sel.what}',
            action: sel.onPicked || (_worn.containsKey(sel.name) && c.ws.selected != null) ? 'Put on' : 'Create',
            fresh: !sel.onPicked && !(_worn.containsKey(sel.name) && c.ws.selected != null), // (a tile makes a new thing; a tile of copies lays out the picked one, a material is put on it, an empty expression too: to the picked one, a new board with nothing picked)
            onAction: () => _make(c, sel),
          ),
      ],
    );
  }
}

/// One Create tile: the shelf's one tile, in its look. [naming]: where its name is being written, in its place; [onMenu]: a right click.
Widget _makeTile(_Make m, DockCtx c, {Key? key, Widget? naming, ValueChanged<Offset>? onMenu}) {
  final sel = c.sel == m.id, inside = c.ws.inside;
  final makes =
      inside != null &&
      (m.recipe
          ? inside.createScripts.any((r) => r.$1 == m.name)
          : _asked.containsKey(m.name) || _worn.containsKey(m.name) || m.onPicked || inside.elements.any((e) => e.$1 == m.name));
  return ShelfTile(
    ShelfItem(m.id, m.name, about: m.what),
    shelfLooks['Create']!,
    key: key,
    picked: sel,
    naming: naming,
    onMenu: onMenu,
    onTap: () => c.pick(m.id),
    onApply: makes ? () => _make(c, m) : null, // (two presses make it, one step)
    art: (_) => _makeArt(m, c, sel),
    over: (_) => [
      if (m.key.isNotEmpty)
        Align(
          alignment: Alignment.topRight,
          child: Text(m.key, style: T.micro(dockInk(sel, Grey.g56))),
        ),
    ],
  );
}

/// A tile's picture, one of four: a recipe's motion, an expression's copies, a material's ball, or its mark.
Widget _makeArt(_Make m, DockCtx c, bool sel) {
  Widget mark() => Align(
    alignment: Alignment.topLeft,
    child: Glyph(m.g, size: Shape.z(26), color: sel ? WsT.onAccent : m.hue),
  );
  if (m.recipe && _isRecipe(c, m.name)) {
    // (a recipe: its motion as the inside reckons it, drawn by the window, the whole list moving at once)
    return Positioned.fill(child: RecipeMotionView(m.name));
  }
  if (m.file case final f?) {
    // (an expression: copies it lays out, drawn by the inside as an effect's tile, played while in sight: copies_tiles.dart)
    return Positioned.fill(
      child: ValueListenableBuilder(
        valueListenable: CopiesTiles.drawn,
        builder: (_, _, _) => switch (CopiesTiles.of(f)) {
          '' => mark(),
          final p => TileMoving(p, playing: true), // (played while in sight: TileMoving's own)
        },
      ),
    );
  }
  if (_worn[m.name] case final w?) {
    // (a material: a ball wearing it, drawn by the inside: material_tiles.dart)
    return Positioned.fill(
      child: ValueListenableBuilder(
        valueListenable: MaterialTiles.drawn,
        builder: (_, _, _) => switch (MaterialTiles.of(w)) {
          '' => mark(),
          final p => TileMoving(p, playing: false),
        },
      ),
    );
  }
  return mark();
}
