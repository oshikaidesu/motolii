// The Create shelf: its tiles in groups (layers, shapes, expressions, solids, materials, lights), and the footer for
// the picked tile.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/common/shelf_masonry.dart';
import 'package:motolii/workspace/dock/common/shelf_section.dart';
import 'package:motolii/workspace/dock/create/built_in_tiles.dart';
import 'package:motolii/workspace/dock/create/create_catalog.dart';
import 'package:motolii/workspace/dock/create/create_commands.dart';
import 'package:motolii/workspace/dock/create/create_tile.dart';
import 'package:motolii/workspace/dock/create/expressions.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart';
import 'package:motolii/workspace/shelf/create_preview.dart';
import 'package:motolii/workspace/shelf/material_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// The Create shelf: filter chips above grouped tiles, and a footer for the selected tile.
class CreateShelf extends StatelessWidget {
  const CreateShelf(this.c, {super.key});
  final ShelfContext c;
  @override
  Widget build(BuildContext context) {
    final makes = [
      recipeGroup(c.ws),
      builtInGroups.first,
      elementGroup(c.ws),
      for (final (g, items) in builtInGroups.skip(1))
        g == 'Expression'
            ? (g, [...items, ...expressionsOf(c.ws)])
            : (g, items),
      solidGroup,
      materialGroup,
      lightGroup,
    ].where((e) => e.$2.isNotEmpty).toList();
    var groups = [
      for (final (g, items) in makes)
        if (c.chip == 'All' || c.chip == g)
          (g, items.where((m) => c.hit(m.name)).toList()),
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
          if (c.chip == 'All' || c.chip == g)
            (g, [for (final id in near) ...items.where((m) => m.id == id)]),
      ].where((e) => e.$2.isNotEmpty).toList();
    }
    final sel = c.foot(
      makes.expand((e) => e.$2).where((m) => m.id == c.sel).firstOrNull,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChips(
          [
            ('All', makes.fold<int>(0, (s, e) => s + e.$2.length)),
            for (final (g, items) in makes) (g, items.length),
          ],
          active: c.chip,
          onPick: c.pickChip,
        ),
        Expanded(
          child: groups.isEmpty
              ? EmptyShelf(c.query)
              : ShelfMasonry(
                  weights: [
                    for (final (_, items) in groups) 1 + items.length / 3,
                  ],
                  children: [
                    for (final (g, items) in groups)
                      Padding(
                        padding: EdgeInsets.only(bottom: WindowTokens.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ShelfSection(
                              g,
                              count: items.length,
                              hue: items.first.hue,
                              folded:
                                  c.query.isEmpty &&
                                  c.mem.createFolded.contains(g),
                              onTap: () => c.set(
                                () => c.mem.createFolded.contains(g)
                                    ? c.mem.createFolded.remove(g)
                                    : c.mem.createFolded.add(g),
                              ),
                            ),
                            if (!(c.query.isEmpty &&
                                c.mem.createFolded.contains(g))) ...[
                              const SizedBox(height: WindowTokens.gutter),
                              ShelfGrid(
                                shelfLooks['Create']!,
                                shrinkWrap: true,
                                count: items.length,
                                tile: (i) {
                                  final m = items[i];
                                  return m.file != null && shelfAdded(m.file!)
                                      ? _OwnTile(
                                          m,
                                          c,
                                          key: ValueKey('ws-own-${m.file}'),
                                        )
                                      : _makeTile(m, c);
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
          ShelfFooter(
            preview: dockBadge(sel.g, sel.hue, size: Shape.z(34)),
            title: '${sel.name} layer',
            meta:
                c.mem.trouble[sel.name] ??
                'At ${c.ws.timecode()} · ${sel.what}',
            action:
                sel.onPicked ||
                    (shadingOfTile.containsKey(sel.name) &&
                        c.ws.selected != null)
                ? 'Put on'
                : 'Create',
            // A tile creates a new layer. Copies are laid out on the picked layer, a material is put on it, and so is an empty
            // expression (or a new layer when none is picked).
            fresh:
                !sel.onPicked &&
                !(shadingOfTile.containsKey(sel.name) && c.ws.selected != null),
            onAction: () => CreateCommands(c).make(sel),
          ),
      ],
    );
  }
}

/// One Create tile in the shelf's look. [naming] replaces the name while it is being renamed; [onMenu] is called with the position of a right click.
Widget _makeTile(
  CreateTile m,
  ShelfContext c, {
  Key? key,
  Widget? naming,
  ValueChanged<Offset>? onMenu,
}) {
  final sel = c.sel == m.id, inside = c.ws.inside;
  final makes =
      inside != null &&
      (m.recipe
          ? inside.createScripts.any((r) => r.$1 == m.name)
          : layerOfTile.containsKey(m.name) ||
                shadingOfTile.containsKey(m.name) ||
                m.onPicked ||
                inside.elements.any((e) => e.$1 == m.name));
  return ShelfTile(
    ShelfItem(m.id, m.name, about: m.what),
    shelfLooks['Create']!,
    key: key,
    picked: sel,
    naming: naming,
    onMenu: onMenu,
    onTap: () => c.pick(m.id),
    // A double-click creates it, in one undo step.
    onApply: makes ? () => CreateCommands(c).make(m) : null,
    art: (_) => _makeArt(m, c, sel),
    over: (_) => [
      if (m.key.isNotEmpty)
        Align(
          alignment: Alignment.topRight,
          child: Text(m.key, style: TextStyles.micro(dockInk(sel, Grey.g56))),
        ),
    ],
  );
}

/// A tile's art: a script's motion, an expression's copies, a material's ball, or otherwise its mark.
Widget _makeArt(CreateTile m, ShelfContext c, bool sel) {
  Widget mark() => Align(
    alignment: Alignment.topLeft,
    child: Glyph(
      m.g,
      size: Shape.z(26),
      color: sel ? WindowTokens.onAccent : m.hue,
    ),
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
  if (shadingOfTile[m.name] case final w?) {
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
bool _isRecipe(ShelfContext c, String name) {
  final m = c.ws.inside;
  if (m == null || !m.createScripts.any((r) => r.$1 == name)) return false;
  RecipeMotions.ask(File(m.libPath).parent.parent.path, [
    for (final r in m.createScripts) r.$1,
  ]);
  return true;
}

/// A tile for an item the user added, with Rename… on its menu (library tiles have none).
/// The new name is stored beside the file and never changes the file (shelf_add.dart shelfRename).
class _OwnTile extends StatefulWidget {
  const _OwnTile(this.m, this.c, {super.key});
  final CreateTile m;
  final ShelfContext c;
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
    final why = shelfRename(
      ws,
      m.file!,
      to,
      createNames(ws).difference({m.name}),
    );
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
        _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
          ContextMenuItem('Rename…', () => setState(() => _naming = true)),
        ]);
      },
    ),
  );
}
