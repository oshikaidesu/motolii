// The Create shelf. It holds the tiles (shapes, solids, lights, materials, copies), what each
// one makes, and how many are ready.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/dock/dock_folder_row.dart';
import 'package:motolii/workspace/dock/dock_make_expressions.dart';
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart';
import 'package:motolii/workspace/shelf/create_preview.dart';
import 'package:motolii/workspace/shelf/empty_fx.dart';
import 'package:motolii/workspace/shelf/material_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

/// The "N ready" count: how many of the Create shelf's tiles can make or lay out something in the project.
String createFact(WorkspaceController ws) {
  // Scripts that are expressions have tiles in the Expression group, so they are counted with the expressions.
  final recipes = _recipesOf(ws).$2.length, expressions = expressionsOf(ws).length;
  // The shelf shows only these tiles.
  return '${_asked.length + _worn.length + recipes + expressions} ready';
}

/// The engine's create scripts, each shown as a tile. A script builds a whole image in one call, as Cavalry's tutorials do.
(String, List<CreateTile>) _recipesOf(WorkspaceController ws) {
  // Scripts that are expressions are left out: their tiles are in the Expression group.
  final expressions = {for (final (name, _) in expressionRecipes()) name};
  // Closed packs are left out too: they belong to the Program shelf (dock_program.dart).
  final packs = {for (final (name, _) in ws.inside!.packs) name};
  return (
    'Recipes',
    [
      for (final (name, what) in ws.inside!.createScripts)
        if (!expressions.contains(name) && !packs.contains(name)) CreateTile(name, DockG.copies, Pop.tonePlace, '', what, recipe: true),
    ],
  );
}

/// Saved elements (Edit > Save to My Elements). Each is added at the playhead and stays linked to its file, as in
/// Alight Motion (+ > Object / Element > Element) and AbsentMotion's ElementPicker
/// (engine/third_party/AbsentMotion/app/src/main/kotlin/app/absentmotion/ui/editor/ElementUi.kt).
(String, List<CreateTile>) _elementsOf(WorkspaceController ws) =>
    ('Elements', [for (final (name, _) in ws.inside!.elements) CreateTile(name, DockG.nullObj, Grey.g76, '', 'Element, linked to its file')]);

// ---------------------------------------------------------------- create

/// One tile of the Create shelf. [key] is the keyboard shortcut shown on the tile and [what] the line shown in the footer.
class CreateTile {
  const CreateTile(this.name, this.g, this.hue, this.key, this.what, {this.recipe = false, this.file, this.made = false});
  final String name, key, what;
  final DockG g;
  final Color hue;

  /// True for a create script, which builds a whole image in one call. It may share a name with a built-in tile:
  /// AbsentMotion's Rectangle, Star, Cube and Sun sit beside Motolii's shape, solid and light of the same names.
  final bool recipe;

  /// For an expression tile, its file. It is added to the picked layer as a card of its own.
  final String? file;

  /// True for an expression whose head makes its own layer (a script's "// make" line). With nothing picked, that layer is created.
  final bool made;
  String get id => file ?? (recipe ? 'recipe:$name' : name);

  /// True if the tile goes on the picked layer, or on a new layer when none is picked.
  bool get onPicked => file != null || _onPicked.contains(name);
}

final _makes = <(String, List<CreateTile>)>[
  (
    'Layers',
    [
      CreateTile('Text', DockG.text, WindowTokens.toneText, 'T', 'Type layer'),
      // The default lens is the preview's 30 degrees on Filament's 24 mm film, as the Camera tool panel shows (tool_panel_depth.dart _filmMm).
      CreateTile('Camera', DockG.camera, WindowTokens.toneCamera, '⇧C', '3D camera, 45 mm'),
      CreateTile('Null', DockG.nullObj, Grey.g76, '⇧N', 'Invisible parent'),
      CreateTile('Adjustment', DockG.nullObj, Grey.g76, '', 'What is put on it works on all under it'),
    ],
  ),
  (
    'Shapes',
    [
      CreateTile('Rectangle', DockG.rect, WindowTokens.toneShape, 'R', 'Rounded corners'),
      CreateTile('Ellipse', DockG.ellipse, WindowTokens.toneShape, 'E', 'Circle with ⇧'),
      CreateTile('Polygon', DockG.polygon, WindowTokens.toneShape, '', 'Sides · Roundness'),
      CreateTile('Star', DockG.star, WindowTokens.toneShape, '', 'Points · Inner radius'),
      CreateTile('Line', DockG.line, WindowTokens.toneShape, 'L', 'Open path'),
    ],
  ),
  (
    // Every JS file that goes on a layer and moves its values comes after Empty (dock_make_expressions.dart expressionsOf).
    'Expression',
    [
      CreateTile(
        'Empty',
        DockG.plus,
        Pop.tonePlace,
        '',
        'An empty expression on the picked thing (nothing picked: on a new board): write or paste each() into its card\'s code',
      ),
    ],
  ),
];

/// The engine's own 3D shapes. A tile is created by its kind, then its file or shape (see [_asked]).
final _solids = (
  '3D',
  [
    CreateTile('Ring', DockG.radial, WindowTokens.toneShape, '', 'A solid ring'),
    CreateTile('Gem', DockG.polygon, WindowTokens.toneShape, '', 'A cut solid'),
    CreateTile('Cube', DockG.rect, WindowTokens.toneShape, '', 'A round-edged cube'),
    CreateTile('Floor', DockG.rect, WindowTokens.toneShape, '', 'A wide flat floor that takes shadows'),
    CreateTile('Ball', DockG.ellipse, WindowTokens.toneShape, '', 'A ball'),
  ],
);

/// Filament's own lights. They are layers of the project: placed and rotated like any other layer, and they light the solid layers.
final _lights = (
  'Light',
  [
    CreateTile('Sun', DockG.light, WindowTokens.toneCamera, '', 'Light from one way, everywhere'),
    CreateTile('Point', DockG.light, WindowTokens.toneCamera, '', 'Light from a point, all round'),
    CreateTile('Spot', DockG.light, WindowTokens.toneCamera, '', 'A cone of light'),
  ],
);

/// Materials: Filament's own and the engine's, under the names a user knows (the engine's word is the shading value, see doc.h doc_material).
///
/// A material goes on the picked layer in place of the one it has, one at a time. Any visible layer can wear one: a flat layer
/// wears it on its own plane, and an image layer takes its color. With nothing picked, a ball wearing the material is created.
/// Materials are in Create, not among the colors. Each tile shows a ball wearing the material (material_tiles.dart).
final _materials = (
  'Material',
  [
    CreateTile('Lit', DockG.ellipse, WindowTokens.toneShape, '', 'Filament\'s lit surface: its colour, metal, rough, a clear coat'),
    CreateTile('Cloth', DockG.ellipse, WindowTokens.toneShape, '', 'Soft, no sharp highlight, a sheen at its rim'),
    CreateTile('Subsurface', DockG.ellipse, WindowTokens.toneShape, '', 'Light goes into it and comes out, as in wax or skin'),
    CreateTile('Glass', DockG.radial, WindowTokens.toneShape, '', 'Thick glass: bends and tints what lies behind it'),
    CreateTile('Filament glass', DockG.radial, WindowTokens.toneShape, '', 'Filament\'s own glass: bends what is behind, a thin film\'s rainbow'),
    CreateTile('Lacquer', DockG.ellipse, WindowTokens.toneShape, '', 'Its colour under a hard clear coat'),
    CreateTile('Bubble', DockG.radial, WindowTokens.toneShape, '', 'Nearly clear, a bright rim'),
  ],
);
// Tile name to the shading value it sets.
const _worn = {
  'Lit': 'lit',
  'Cloth': 'cloth',
  'Subsurface': 'subsurface',
  'Glass': 'glass',
  'Filament glass': 'filament_glass',
  'Lacquer': 'lacquer',
  'Bubble': 'bubble',
};
// The layer kinds that are visible, and so can wear a material.
const _wears = {'film', 'picture', 'text', 'shape', 'solid'};
// Tiles that go on the picked layer, or on a new layer when none is picked (empty_fx.dart).
const _onPicked = {'Empty'};

// Tile name to the (kind, shape) of the layer it creates.
final _asked = {
  'Text': ('text', wsTextFont),
  // A flat color as large as the preview; the engine builds it that size.
  'Solid': ('shape', 'solid'),
  'Rectangle': ('shape', 'rect'),
  'Ellipse': ('shape', 'circle'),
  'Polygon': ('shape', 'polygon'),
  'Star': ('shape', 'star'),
  'Line': ('shape', 'line'),
  // Invisible: other layers can be parented to it.
  'Null': ('shape', 'null'),
  // The nearest camera that is on is the one the preview looks through.
  'Camera': ('camera', 'camera'),
  'Ring': ('solid', 'ring'),
  'Gem': ('solid', 'gem'),
  'Cube': ('solid', 'cube'),
  'Floor': ('solid', 'cube'),
  'Ball': ('solid', 'ball'),
  'Sun': ('light', 'sun'),
  'Point': ('light', 'point'),
  'Spot': ('light', 'spot'),
};

/// Transform values set on a layer right after its tile creates it, in the same undo step.
///
/// Floor follows Cinema 4D's Floor object: a Cube laid flat under the preview, because a flat Rectangle is unlit and takes no shadow.
/// Sun shines from above and in front, as After Effects' new light looks at the middle of the composition from there.
/// With no rotation a Sun would shine along the floor and light nothing on it.
const _starts = <String, Map<String, double>>{
  'Floor': {'scale_x': 12, 'scale_y': .01, 'scale_z': 12, 'y': -.48},
  'Sun': {'rotate_x': -60, 'rotate_y': 35},
};

/// Values set on the picked layer when the Repeater is first added to it (its parameters js_StepX and js_Size).
/// They lay the copies out in a row, side by side and a little smaller each time, as the tile did before it was an expression.
const _laid = <String, Map<String, double>>{
  'Repeater': {'js_StepX': 1.3, 'js_Size': .92},
};

/// Runs a tile: it creates a new layer and selects it. A tile of copies lays out the picked layer instead, and a material changes it.
/// On failure the reason is stored under the tile's name, and the footer shows it.
void _make(DockCtx c, CreateTile tile) {
  final m = c.ws.inside!, name = tile.name;
  if (tile.recipe) {
    // A create script: one undo step, and the new layer is selected. It does not wait for the result.
    c.ws.after(
      m.later('create', word: name),
      (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why),
      (made) => c.ws.select('$made'),
    );
    return;
  }
  if (tile.file != null) return _expressionPut(c, tile);
  // After Effects: New > Adjustment Layer.
  if (name == 'Adjustment') return c.ws.adjustment();
  if (name == 'Empty') {
    // An empty expression for the user to write (empty_fx.dart). Any earlier error for this tile is cleared.
    c.set(() => c.mem.trouble.remove(name));
    return emptyPut(c.ws, expression: true, told: (why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why));
  }
  if (_worn[name] case final wears?) {
    // Replaces the picked layer's material. With nothing picked, creates a ball wearing it and selects the ball.
    final t = int.tryParse(c.ws.selected ?? '');
    void told(bool done, String why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why);
    if (t != null) {
      if (!_wears.contains(m.word(t, 'kind'))) return c.set(() => c.mem.trouble[name] = 'A camera, a light or a null wears nothing: pick a thing that is seen');
      c.ws.after(m.later('say', layer: t, name: 'shading', word: wears), told);
      return;
    }
    // One undo step covers the ball and its material.
    m.later('together', number: 1);
    c.ws.after(m.later('add', name: 'solid', word: 'ball'), null, (made) => c.ws.select('$made'));
    wsInked(c.ws, 'solid', 'ball');
    m.later('say', layer: -1, name: 'shading', word: wears);
    c.ws.after(m.later('together'), told);
    return;
  }
  if (!_asked.containsKey(name)) {
    if (m.elements.where((e) => e.$1 == name).firstOrNull case final e?) {
      // Added at the playhead, in the middle, and selected, as in AbsentMotion's addElement.
      c.ws.after(
        m.later('element', word: e.$2, number: c.ws.frame / WorkspaceController.fps),
        (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why),
        (made) => c.ws.select('$made'),
      );
    }
    return;
  }
  final asked = _asked[name]!;
  // One undo step covers the layer and its colors.
  m.later('together', number: 1);
  // Does not wait: the new layer is selected once it exists. A text layer uses the body font.
  c.ws.after(m.later('add', name: asked.$1, word: asked.$1 == 'text' ? c.ws.bodyFace : asked.$2), null, (made) => c.ws.select('$made'));
  wsInked(c.ws, asked.$1, asked.$2);
  for (final e in (_starts[name] ?? const <String, double>{}).entries) {
    m.later('set', layer: -1, name: e.key, number: e.value);
  }
  if (name == 'Floor') m.later('say', layer: -1, name: 'name', word: name);
  if (asked.$1 == 'light' && (m.value(0, 'environment', 0) ?? 1) == 1) {
    // As in After Effects, a light added to the project takes over from the default light. The room dims, and its old value is one field in Stage settings.
    m.later('set', layer: 0, name: 'environment', number: .3);
  }
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why));
}

/// The Create shelf: filter chips above grouped tiles, and a footer for the selected tile.
class CreateShelf extends StatelessWidget {
  const CreateShelf(this.c, {super.key});
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final makes = [
      _recipesOf(c.ws),
      _makes.first,
      _elementsOf(c.ws),
      for (final (g, items) in _makes.skip(1)) g == 'Expression' ? (g, [...items, ...expressionsOf(c.ws)]) : (g, items),
      _solids,
      _materials,
      _lights,
    ].where((e) => e.$2.isNotEmpty).toList();
    var groups = [
      for (final (g, items) in makes)
        if (c.chip == 'All' || c.chip == g) (g, items.where((m) => c.hit(m.name)).toList()),
    ].where((e) => e.$2.isNotEmpty).toList();
    if (groups.isEmpty && c.query.trim().isNotEmpty) {
      // Nothing matches the query as typed, so show the nearest five, each in its own group.
      // Matching uses the tile's name alone. With the group name included, "Material" pulled in every material for any query.
      // RapidFuzz's WRatio of a misspelled word to its tile is 77 or more (bubbel/Bubble 83, lacker/Lacquer 77, clth/Cloth 89).
      // For a word and a tile it does not mean it is 72 or less (butterfly/Bubble 49, empty/Gem 72).
      // A Japanese query is matched by meaning (WordNet scores), so all those matches are kept.
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
                        padding: EdgeInsets.only(bottom: WindowTokens.gutter),
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
                              const SizedBox(height: WindowTokens.gutter),
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
            // A tile creates a new layer. Copies are laid out on the picked layer, a material is put on it, and so is an empty
            // expression (or a new layer when none is picked).
            fresh: !sel.onPicked && !(_worn.containsKey(sel.name) && c.ws.selected != null),
            onAction: () => _make(c, sel),
          ),
      ],
    );
  }
}

/// One Create tile in the shelf's look. [naming] replaces the name while it is being renamed; [onMenu] is called with the position of a right click.
Widget _makeTile(CreateTile m, DockCtx c, {Key? key, Widget? naming, ValueChanged<Offset>? onMenu}) {
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
    // A double-click creates it, in one undo step.
    onApply: makes ? () => _make(c, m) : null,
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

/// A tile's art: a script's motion, an expression's copies, a material's ball, or otherwise its mark.
Widget _makeArt(CreateTile m, DockCtx c, bool sel) {
  Widget mark() => Align(
    alignment: Alignment.topLeft,
    child: Glyph(m.g, size: Shape.z(26), color: sel ? WindowTokens.onAccent : m.hue),
  );
  if (m.recipe && _isRecipe(c, m.name)) {
    // A script: its motion as the engine computes it, drawn by the app, with the whole list moving at once.
    return Positioned.fill(child: RecipeMotionView(m.name));
  }
  if (m.file case final f?) {
    // An expression: the copies it lays out, drawn by the engine like an effect's tile and played while visible (copies_tiles.dart).
    return Positioned.fill(
      child: ValueListenableBuilder(
        valueListenable: CopiesTiles.drawn,
        builder: (_, _, _) => switch (CopiesTiles.of(f)) {
          '' => mark(),
          final p => TileMoving(p, playing: true),
        },
      ),
    );
  }
  if (_worn[m.name] case final w?) {
    // A material: a ball wearing it, drawn by the engine (material_tiles.dart).
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

// ---- A script's motion preview: the engine is asked for it once (create_preview.dart), on a project of its own.

/// True if [name] is one of the engine's create scripts. It also starts asking for the motions of all the scripts.
bool _isRecipe(DockCtx c, String name) {
  final m = c.ws.inside;
  if (m == null || !m.createScripts.any((r) => r.$1 == name)) return false;
  RecipeMotions.ask(File(m.libPath).parent.parent.path, [for (final r in m.createScripts) r.$1]);
  return true;
}

/// Puts an expression on the picked layer, or on a new layer when none is picked.
void _expressionPut(DockCtx c, CreateTile tile) {
  final m = c.ws.inside!, name = tile.name, file = tile.file!, t = int.tryParse(c.ws.selected ?? '');
  void told(String why) => c.set(() => why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why);
  c.set(() => c.mem.trouble.remove(name));
  if (t == null && tile.made) {
    // Created the same way as a script tile.
    return c.ws.after(m.later('create', word: name), (done, why) => told(done ? '' : why), (made) => c.ws.select('$made'));
  }
  final first = t != null && !WorkspaceController.fxFiles(m.word(t, 'fx')).contains(file);
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
Set<String> createNames(WorkspaceController ws) => {
  for (final (_, items) in [
    if (ws.inside != null) ...[_recipesOf(ws), _elementsOf(ws)],
    ..._makes,
    _solids,
    _materials,
    _lights,
  ])
    ...items.map((m) => m.name),
  for (final m in expressionsOf(ws)) m.name,
};

/// A tile for an item the user added, with Rename… on its menu (library tiles have none).
/// The new name is stored beside the file and never changes the file (shelf_add.dart shelfRename).
class _OwnTile extends StatefulWidget {
  const _OwnTile(this.m, this.c, {super.key});
  final CreateTile m;
  final DockCtx c;
  @override
  State<_OwnTile> createState() => _OwnTileState();
}

class _OwnTileState extends State<_OwnTile> {
  final _menu = GlobalKey<ContextMenuState>();
  bool _naming = false;

  void _renamed(String? to) {
    setState(() => _naming = false);
    final m = widget.m, ws = widget.c.ws;
    if (to == null || to.trim() == m.name) return;
    final why = shelfRename(ws, m.file!, to, createNames(ws).difference({m.name}));
    if (why.isNotEmpty) ws.notice = 'Not renamed: $why';
  }

  @override
  Widget build(BuildContext context) => ContextMenu(
    key: _menu,
    child: _makeTile(
      widget.m,
      widget.c,
      naming: _naming ? ShelfNameField(widget.m.name, _renamed) : null,
      onMenu: (at) {
        final box = _menu.currentContext?.findRenderObject() as RenderBox?;
        _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [ContextMenuItem('Rename…', () => setState(() => _naming = true))]);
      },
    ),
  );
}
