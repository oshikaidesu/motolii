// The Effects shelf: every effect the engine can apply, as tiles sorted by what each is for.
// - Layer effects go on the selected layer; the footer button adds or removes one.
// - Whole-screen effects apply to the selected layer as the camera sees it, or to the stage, in order.
// - Presets saved from a layer's values can be applied to another layer.
import 'package:motolii/workspace/dock/effects/effect_catalog.dart';
import 'package:motolii/workspace/shelf/tile_moving.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:flutter/services.dart';
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, IconPress;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/resizable_band.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/common/star_button.dart';
import 'package:motolii/workspace/dock/effects/effect_drawings.dart';
import 'package:motolii/workspace/dock/effects/effect_places.dart';
import 'package:motolii/workspace/dock/effects/effects_controller.dart';
import 'package:motolii/workspace/dock/map/image_features.dart';
import 'package:motolii/workspace/dock/map/shelf_map_view.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The Effects shelf: the list of places to look in, the tiles or the map of what is there, and the footer for the
/// picked effect.
class EffectsShelf extends StatefulWidget {
  const EffectsShelf(this.c, this.effects, {super.key});
  final ShelfContext c;

  /// What the shelf keeps between builds: its map, and which effect a dragged tile carries.
  final EffectsController effects;

  @override
  State<EffectsShelf> createState() => _EffectsShelfState();
}

class _EffectsShelfState extends State<EffectsShelf> {
  final _menu = GlobalKey<ContextMenuState>(),
      _places = GlobalKey<EffectPlacesState>();
  final _tileKeys = FocusNode(debugLabel: 'ws-fx-tiles'); // Once a tile is pressed, B goes to the tiles instead of the stage's brush.
  ShelfContext get c => widget.c;
  String? _renaming; // The file the user added whose name is being edited in its tile (shelf_add.dart).
  String? _tagging; // The effect whose own tags are being edited in its tile, as words with spaces between.

  void _tagged(String id, String? to) {
    setState(() => _tagging = null);
    if (to != null) {
      widget.effects.tags.setOwn('Effects', id, to.split(RegExp(r'\s+')));
    }
  }

  // Renames by the displayed name written beside the tile, never by the file name.
  void _renamed(String file, String was, String? to) {
    setState(() => _renaming = null);
    if (to == null || to.trim() == was) return;
    final why = shelfRename(
      c.ws,
      file,
      to,
      shelfTaken(c.ws, expression: false).difference({was}),
    );
    if (why.isNotEmpty) c.ws.notice = 'Not renamed: $why';
  }

  @override
  void dispose() {
    _tileKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = c.ws, m = ws.inside;
    if (m == null) return EmptyShelf(c.query);
    final on = ws.fxOf(ws.selected),
        screen = ws.screenFx,
        picked = int.tryParse(ws.selected ?? '') != null;
    // A layer's own effects, presets and motions go on the selected layer, or on a new layer when none is selected.
    // Whole-screen effects go on the selected layer, or on the stage.
    // Applying while words are typed in the search box latches the effect to those words, so it comes first next time.
    VoidCallback chosen(String id, VoidCallback put, {bool taken = false}) {
      void go() {
        // A closure of its own rather than a tear-off, because a dragged tile is identified by it.
        widget.effects.tags.latch('Effects', c.query, id);
        if (!taken) c.set(() => effectUsed(id, words: c.query, chip: c.chip));
        ws.tryOn(null); // Stop previewing the hovered effect first: applying reads the document as it is.
        put();
      }

      widget.effects.carried[go] = id;
      return go;
    }

    // Effects are listed whatever is selected, as After Effects' Effects & Presets panel does.
    // With no layer selected, a layer effect goes on a new layer (WorkspaceController.fxToggle).
    // A screen effect on the stage is taken off by Remove, and a press adds another (WorkspaceController.screenPut).
    VoidCallback? off(EffectEntry e) =>
        screen.contains(e.id) ? () => ws.screenToggle(e.id) : null;
    final look = shelfLooks['Effects']!;
    // Overlays on a tile's image, none on a small tile.
    // ON, with its place among the stage's effects, when applied; the reason the sample looks unchanged (FOR SOUND, UNSUPPORTED ...);
    // and the star when starred or hovered.
    List<Widget> Function(bool) marks(
      String id,
      bool small, {
      String? on,
      String? same,
    }) =>
        (h) => [
          if (on != null && !small)
            Positioned(
              left: 3,
              top: 3,
              child: Chip(
                label: on,
                look: ChipLook.tag(WindowTokens.accent, edge: true),
              ),
            ),
          if (same != null && !small)
            Positioned(
              left: 3,
              bottom: 3,
              child: Chip(
                label: same,
                look: ChipLook.tag(Grey.g63, edge: true),
              ),
            ), // Shows why the sample is unchanged: what it lacks, or that the engine does not draw it yet.
          if (!small && (c.starred(id) || h))
            Positioned(
              right: 0,
              top: 0,
              child: StarButton(
                key: ValueKey('ws-star-$id'),
                on: c.starred(id),
                onTap: () => c.star(id),
              ),
            ),
        ];
    // What the engine said about each effect, by id: a layer effect by its name, a file effect by its file.
    final seen = <String, ShelfItem>{};
    String pic(String id) => seen[id]?.picture ?? '';
    // Builds one item for any of the three listings; only what really differs by listing is switched on its [from].
    EffectEntry fx(String name, ShelfItem i) {
      final thing = i.from == 'thing',
          screened = i.from == 'screen',
          id = thing ? i.name : i.id;
      final lit = thing ? on.contains(id) : screened && screen.contains(id);
      final apply = chosen(
        id,
        thing
            ? () => ws.fxToggle(id)
            : (screened ? () => ws.screenPut(id) : () => ws.lookPut(id)),
        taken: thing && lit,
      );
      seen[id] = i;
      return (
        id: id,
        name: name,
        label: thing || screened ? i.label : 'Look',
        on: lit,
        apply: apply,
        said: thing
            ? _said(ws, id)
            : !screened
            ? (picked
                  ? 'A look for the picked thing'
                  : 'A look, on a new board')
            : i.same && TileReview.stopped(id).isNotEmpty
            ? 'Stops here: ${TileReview.stopped(id)}'
            : i.same && TileReview.lacks(id).isNotEmpty
            ? 'Needs: ${TileReview.lacks(id)}'
            : i.about.isEmpty
            ? (picked ? 'On the picked thing' : 'On all under it')
            : i.about,
        tile: (small, menu) => ShelfTile(
          ShelfItem(id, name, picture: i.picture),
          look,
          key: small || thing
              ? null
              : ValueKey(screened ? 'ws-screen-$id' : 'ws-look-$name'),
          small: small,
          art: thing && i.picture.isEmpty
              ? paintedArt(Draw((c, _) => drawEffectLook(c, name), name))
              : null, // Without an image, its small drawing.
          picked: c.sel == id,
          lit: lit,
          onTap: () => c.pick(id),
          onApply: apply,
          onMenu: menu,
          onHover: screened ? (h) => ws.tryOn(h ? id : null) : null, // Shows what it does on the selected layer meanwhile (WorkspaceController.tryOn).
          naming: _tagging == id
              ? ShelfNameField(
                  widget.effects.tags.ownOf('Effects', id).join(' '),
                  (to) => _tagged(id, to),
                )
              : screened && _renaming == id
              ? ShelfNameField(name, (to) => _renamed(id, name, to))
              : null,
          over: marks(
            id,
            small,
            on: !lit
                ? null
                : (screened ? 'ON ${screen.indexOf(id) + 1}' : 'ON'),
            same: screened && i.same ? TileReview.sameTag(id) : null,
          ),
        ),
      );
    }

    // File effects sorted by name. One the user added and renamed shows the name written beside it (shelf_add.dart).
    final screens = m.items('screen');
    final lined = <(String, ShelfItem)>[
      for (final i in m.items('thing')) (i.name, i),
      ...(widget.effects.byName[screens] ??= ([
        for (final i in screens) (shelfNamed(i.id) ?? i.name, i),
      ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase())))),
      // A saved preset by its name (Save Look). Applying it gives the selected layer its values, effects and keyframes.
      for (final (_, f) in m.presets)
        if (m.item(f) case final i?) (i.name, i),
    ];
    final every = <EffectEntry>[
      // First comes an empty effect. Its code opens on its card, ready for an ISF effect to be pasted in (empty_effect.dart).
      (
        id: 'empty:effect',
        name: 'Empty',
        label: '',
        on: false,
        apply: chosen(
          'empty:effect',
          () => emptyPut(
            ws,
            expression: false,
            told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why',
          ),
        ),
        said: picked
            ? 'An empty effect on the picked thing: paste ISF code into its card'
            : 'An empty effect, on a new board: paste ISF code into its card',
        tile: (small, menu) => ShelfTile(
          ShelfItem('empty:effect', 'Empty'),
          look,
          small: small,
          art: paintedArt(const EmptyLook()),
          picked: c.sel == 'empty:effect',
          onTap: () => c.pick('empty:effect'),
          onApply: chosen(
            'empty:effect',
            () => emptyPut(
              ws,
              expression: false,
              told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why',
            ),
          ),
          onMenu: menu,
        ),
      ),
      for (final (n, i) in lined) fx(n, i),
      // There are no motions here: they are expressions, in Create's Expression group.
    ];
    final listing = effectListing(
      c: c,
      tags: widget.effects.tags,
      every: every,
      seen: seen,
    );
    final found = listing.found,
        all = listing.all,
        byId = listing.byId,
        recent = listing.recent,
        decks = listing.decks,
        deckIds = listing.deckIds,
        used = listing.used,
        packs = listing.packs,
        deck = listing.deck,
        place = listing.place,
        building = listing.building,
        here = listing.here,
        kinds = listing.kinds,
        tagChips = listing.tagChips,
        chip = listing.chip,
        shown = listing.shown,
        known = listing.known;
    if (deck != null && deck.things.any((t) => !known.contains(t.id))) {
      deckSettle(deck, known);
    }
    final lost = <EffectEntry>[
      if (deck != null && c.query.isEmpty)
        for (final t in deck.things)
          if (!known.contains(t.id))
            (
              id: t.id,
              name: t.name,
              label: 'Not here',
              on: true,
              said: 'Not on this machine',
              apply: () => c.set(() {
                deck.things.remove(t);
                effectDecksKeep();
              }),
              tile: (small, menu) => ShelfTile(
                ShelfItem(t.id, t.name),
                look,
                picked: c.sel == t.id,
                onTap: () => c.pick(t.id),
                onMenu: menu,
                over: (_) => [
                  Positioned(
                    left: 3,
                    bottom: 3,
                    child: Chip(
                      label: 'NOT HERE',
                      look: ChipLook.tag(Grey.g63, edge: true),
                    ),
                  ),
                ],
              ),
            ),
    ];
    // Up to ten recent effects show above the tiles while nothing narrows the list, as Alight Motion's effect browser opens on its last ten
    // at EffectBrowser.kt:217. A list out of sight is not revisited, so the recent ones stay in view.
    final inSight =
        place == 'All' &&
            chip == 'All' &&
            c.query.isEmpty &&
            !c.mem.mapped.contains('Effects')
        ? recent.take(10).toList()
        : const <EffectEntry>[]; // On the map only the map shows, as in XO's Space: the recent box took half the shelf.
    final listed = building ? shown : [...shown, ...lost];
    // What the deck holds in the order added, then what its words find. Effects not on this machine come last.
    final holds = place == '★'
        ? {for (final id in c.mem.starred) id}
        : deck == null
        ? const <String>{}
        : deckIds[deck]!;
    final held = !building
        ? const <EffectEntry>[]
        : [
            for (final id in holds) ...every.where((e) => e.id == id).take(1),
            ...lost,
          ];
    void put(EffectDeck d, EffectEntry e) => c.set(() {
      d.toggle(e.id, e.name, found: d.words.isNotEmpty && found(d.words, e));
      effectDecksKeep();
    });
    // Where one press sends an effect, however many decks exist: the target deck, else Favorites. A notice says where it went.
    // Lightroom Classic does the same with Add to Target Collection (B), using the Quick Collection until a target is set.
    final to = effectTarget(),
        aim = to != null && deckIds.containsKey(to) ? to : null;
    bool aimed(EffectEntry e) =>
        aim != null ? deckIds[aim]!.contains(e.id) : c.starred(e.id);
    void target(EffectEntry e) {
      final was = aimed(e);
      aim != null ? put(aim, e) : c.star(e.id);
      ws.notice =
          '${was ? 'Removed from' : 'Added to'} ${aim?.name ?? 'Favorites'}';
    }

    // Actions on an effect are in its right-click menu and the footer's three-dot button, as in Ableton's item menu.
    void menuOn(EffectEntry e, Offset at) {
      final box = _menu.currentContext?.findRenderObject() as RenderBox?;
      _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
        if (off(e) case final o?) ...[
          ContextMenuItem('Add Again', e.apply),
          ContextMenuItem('Remove', o),
        ] else
          ContextMenuItem(e.on ? 'Remove' : 'Add', e.apply),
        const ContextMenuItem.rule(),
        ContextMenuItem(
          '${aimed(e) ? 'Remove from' : 'Add to'} ${aim == null ? 'Favorites' : 'Target Deck'}',
          () => target(e),
          keys: 'B',
        ),
        ContextMenuItem(
          'New Deck…',
          () => _places.currentState?.newDeck(
            thing: DeckThing(e.id, e.name, effectSum(e.id)),
          ),
        ),
        ContextMenuItem('Tags…', () => setState(() => _tagging = e.id)),
        if (shelfAdded(e.id)) ...[
          const ContextMenuItem.rule(),
          ContextMenuItem('Rename…', () => setState(() => _renaming = e.id)),
        ],
        if (effectPack(e.id) case final p? when packs.containsKey(p)) ...[
          const ContextMenuItem.rule(),
          ContextMenuItem(
            'Go to Pack: $p',
            () => c.set(() => c.mem.fxPlace = '/$p'),
          ),
        ],
      ]);
    }

    Widget tile(EffectEntry e, bool small) =>
        e.tile(small, (at) => menuOn(e, at));
    // A strip for an effect the deck holds, under the deck's row, like a card in a Hearthstone deck list: its image and name.
    // A click selects it, a double-click applies it, a drop applies it where released, and a right-click opens its menu, as on its tile.
    Widget strip(EffectEntry e) => ShelfTile(
      ShelfItem(e.id, e.name, picture: pic(e.id)),
      look,
      key: ValueKey('ws-fx-held-${e.id}'),
      list: true,
      indent: Shape.z(14),
      ink: e.label == 'Not here' ? Grey.g56 : null,
      picked: c.sel == e.id,
      onTap: () => c.pick(e.id),
      onApply: e.apply,
      onMenu: e.label == 'Not here' ? null : (at) => menuOn(e, at),
    );
    // A deck's cover, as Spotify makes a playlist's cover: the images of its first four effects in a 2x2 grid,
    // or the first one alone while it holds fewer than four.
    Widget? cover(Iterable<String> ids) {
      final f = [
        for (final id in ids)
          if (pic(id) case final p when p.isNotEmpty) p,
      ].take(4).toList();
      Widget one(String p) => TileMoving(p, playing: false);
      return f.isEmpty
          ? null
          : f.length < 4
          ? one(f.first)
          : Column(
              children: [
                for (final r in const [0, 2])
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: one(f[r])),
                        Expanded(child: one(f[r + 1])),
                      ],
                    ),
                  ),
              ],
            );
    }

    Widget list(bool narrow) => EffectPlaces(
      c,
      key: _places,
      carried: widget.effects.carried,
      narrow: narrow,
      known: known,
      packs: Map.fromEntries(
        packs.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
      ),
      counts: {
        'All': all.length,
        'Recent': recent.length,
        '★': all.where((e) => c.starred(e.id)).length,
        'In video': all.where((e) => used.contains(e.id)).length,
      },
      decks: {
        for (final d in decks)
          d: deckIds[d]!.intersection(byId.keys.toSet()).length,
      },
      mapped: c.mem.mapped.contains('Effects'),
      held: [for (final e in held) strip(e)],
      covers: {for (final d in decks) '@${d.name}': ?cover(deckIds[d]!)},
      put: (d, id) {
        if (every.where((e) => e.id == id).firstOrNull case final e?
            when !(deckIds[d]?.contains(id) ?? false)) {
          put(d, e); // A deck made a moment ago is not in the table yet (Save Favorites...).
        }
      },
    );
    final sel = c.foot(
      [...all, ...lost].where((e) => e.id == c.sel).firstOrNull,
    );
    final tiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChips(
          [
            ('All', here.length),
            for (final t in tagChips) (t.key, t.value),
            for (final k
                in kinds.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
              (k.key, k.value),
          ],
          active: chip,
          onPick: c.pickChip,
        ), // Tags first, as Shadertoy's filters head its results; the kinds follow, since there are over a hundred.
        if (inSight.isNotEmpty)
          ShelfGrid(
            look,
            key: const ValueKey('ws-fx-recent'),
            cols: 5,
            small: true,
            shrinkWrap: true,
            pad: EdgeInsets.only(
              top: WindowTokens.gutter,
              bottom: WindowTokens.gutter,
            ),
            count: inSight.length,
            tile: (i) => tile(inSight[i], true),
          ), // Two rows as in Alight Motion's box, one row until a sixth effect: a single tile in a row looked empty over the shelf.
        Expanded(
          child: CallbackShortcuts(
            // B runs the target action on the selected effect, like the menu's single row, as in Lightroom's Library grid.
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyB): () =>
                  sel == null ? null : target(sel),
            },
            child: Focus(
              focusNode: _tileKeys,
              child: TapRegion(
                behavior: HitTestBehavior.translucent,
                onTapInside: (_) => c.mem.mapped.contains('Effects')
                    ? null
                    : _tileKeys
                          .requestFocus(), // The map handles the keys itself.
                child: listed.isEmpty
                    ? EmptyShelf(
                        c.query,
                        said: c.query.isNotEmpty
                            ? null
                            : deck != null
                            ? (identical(deck, aim)
                                  ? 'Drag an effect onto the deck, or right-click one'
                                  : 'Drag an effect onto the deck')
                            : 'Nothing here yet',
                      )
                    : c.mem.mapped.contains('Effects')
                    ? ListenableBuilder(
                        // Laid out by the tiles there are, and again once all are drawn; tiles drawn in between join then.
                        listenable: EffectTiles.progress,
                        builder: (context, _) {
                          final map = widget.effects.map,
                              drawing = EffectTiles.progress.value != null;
                          final clip = likenessModel('clip_b32'); // Placed by how CLIP sees each tile's frames once the model is made, else by tiny colours.
                          final drawn = [
                            for (final e in every)
                              if (pic(e.id).isNotEmpty) e,
                          ];
                          if (!drawing || map.places.value.isEmpty) {
                            map.need(
                              m,
                              [for (final e in drawn) (e.id, pic(e.id))],
                              (from) => widget.effects.numbersOf(m, clip, [
                                for (final e in drawn) e.label,
                              ], from),
                              also: '${clip ?? ''} kinds',
                            );
                          }
                          return ShelfMapView(
                            map,
                            [for (final e in listed) (e.id, tile(e, true))],
                            picked: c.sel,
                            press: c.pick,
                            peek: (id) => TileMoving(pic(id), playing: true),
                            names: {for (final e in every) e.id: e.name},
                          );
                        },
                      )
                    : ShelfGrid(
                        look,
                        count: listed.length,
                        tile: (i) => tile(listed[i], false),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
    return ContextMenu(
      key: _menu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              // As the Media shelf's tree: beside the tiles when wide, above them with a height the user sets when narrow.
              builder: (context, box) => box.maxWidth >= 440
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: Shape.z(160), child: list(false)),
                        ColoredBox(
                          color: WindowTokens.ground,
                          child: SizedBox(width: WindowTokens.gutter),
                        ),
                        Expanded(child: tiles),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.mem.fxListOpen || building) // A deck on the map, with what it holds under it, at the list's height.
                          ResizableBand(
                            height: c.mem.fxListHeight,
                            max: box.maxHeight - 160,
                            reset: defaultEffectListHeight,
                            gripKey: const ValueKey('ws-fx-list-grip'),
                            onHeight: (h) =>
                                c.set(() => c.mem.fxListHeight = h),
                            child: list(true),
                          )
                        else
                          SizedBox(height: Shape.z(22), child: list(true)), // One row for the list leaves room for tiles: the whole list left 3.3 rows of tiles, or 1.7 with the footer open.
                        Expanded(child: tiles),
                      ],
                    ),
            ),
          ),
          if (sel != null && pic(sel.id).isNotEmpty) // A large moving sample of the selected effect, as Alight Motion's effect browser opens.
            SizedBox(
              key: const ValueKey('ws-fx-preview'),
              height: Shape.z(140),
              child: TileMoving(pic(sel.id), playing: true),
            ),
          if (sel != null)
            ShelfFooter(
              title: sel.name,
              meta: sel.label.isEmpty
                  ? sel.said
                  : '${sel.label} · ${sel.said} · double-click to add', // A click selects, a double-click applies.
              action: sel.on ? 'Remove' : 'Add',
              fresh: !picked,
              onAction: off(sel) ?? sel.apply,
              more: Builder(
                builder: (b) => IconPress(
                  dockMark(AppGlyphs.more),
                  key: const ValueKey('ws-fx-more'),
                  onTap: () => menuOn(
                    sel,
                    (b.findRenderObject() as RenderBox).localToGlobal(
                      Offset.zero,
                    ),
                  ),
                ),
              ),
            ), // With nothing selected, the effect goes on a layer of its own.
        ],
      ),
    );
  }
}

/// The description of a layer effect: the document's value for it, and what the selected layer has for it now.
String _said(WorkspaceController ws, String name) {
  final m = ws.inside!,
      v = m.layerEffects.firstWhere((e) => e.$1 == name).$2,
      t = int.tryParse(
        ws.selected ?? '',
      ); // The selected layer's id, or null when none is selected.
  final now = t == null ? '' : m.word(t, v);
  return now.isEmpty ? '$v · none on it' : '$v · $now';
}
