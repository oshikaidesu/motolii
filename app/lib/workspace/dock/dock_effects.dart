// The Effects shelf: every effect the engine can apply, as tiles sorted by what each is for.
// - Layer effects go on the selected layer; the footer button adds or removes one.
// - Whole-screen effects apply to the selected layer as the camera sees it, or to the stage, in order.
// - Presets saved from a layer's values can be applied to another layer.
import 'package:motolii/skin/window_tokens.dart';

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiShelves;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/workspace/dock/dock_effect_places.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/dock_map.dart';
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/dock/dock_resizable.dart';
import 'package:motolii/workspace/dock/dock_tags.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/empty_fx.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/widgets/menu.dart';

/// One effect tile of the shelf. The id is a layer effect's name or a file effect's file, since two files can share a name.
/// The label says what it is for, [on] whether it is applied, `apply` what a double-click or a drop on the stage does.
typedef _Fx = ({String id, String name, String label, Widget Function(bool small, ValueChanged<Offset>? menu) tile, bool on, VoidCallback apply, String said});

class EffectsShelf extends StatefulWidget {
  const EffectsShelf(this.c, {super.key});
  final DockCtx c;

  /// Effect files sorted by name, as After Effects' Effects & Presets panel lists each kind.
  /// The engine lists them by file, so VIDVOX's capitals came before AbsentMotion's am_ files: two runs of A to Z.
  /// Computed once per list of files.
  static final _byName = Expando<List<(String, ShelfItem)>>(); // Each entry is the name as shown and the engine's item.

  @override
  State<EffectsShelf> createState() => _EffectsShelfState();
}

class _EffectsShelfState extends State<EffectsShelf> {
  final _menu = GlobalKey<WsMenuState>(), _places = GlobalKey<EffectPlacesState>();
  final _tileKeys = FocusNode(debugLabel: 'ws-fx-tiles'); // Once a tile is pressed, B goes to the tiles instead of the stage's brush.
  DockCtx get c => widget.c;
  String? _renaming; // The file the user added whose name is being edited in its tile (shelf_add.dart).

  // Renames by the displayed name written beside the tile, never by the file name.
  void _renamed(String file, String was, String? to) {
    setState(() => _renaming = null);
    if (to == null || to.trim() == was) return;
    final why = shelfRename(c.ws, file, to, shelfTaken(c.ws, expression: false).difference({was}));
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
    if (m == null) return DockEmpty(c.query);
    final on = ws.fxOf(ws.selected), screen = ws.screenFx, picked = int.tryParse(ws.selected ?? '') != null;
    // A layer's own effects, presets and motions go on the selected layer, or on a new layer when none is selected.
    // Whole-screen effects go on the selected layer, or on the stage.
    // Applying while words are typed in the search box latches the effect to those words, so it comes first next time.
    VoidCallback chosen(String id, VoidCallback put, {bool taken = false}) {
      final VoidCallback go = () {
        // A closure of its own rather than a tear-off, because a dragged tile is identified by it.
        DockTags.latch('Effects', c.query, id);
        if (!taken) c.set(() => effectUsed(id, words: c.query, chip: c.chip));
        ws.tryOn(null); // Stop previewing the hovered effect first: applying reads the document as it is.
        put();
      };
      carriedEffect[go] = id;
      return go;
    }

    // Effects are listed whatever is selected, as After Effects' Effects & Presets panel does.
    // With no layer selected, a layer effect goes on a new layer (Ws.fxToggle).
    // A screen effect on the stage is taken off by Remove, and a press adds another (Ws.screenPut).
    VoidCallback? off(_Fx e) => screen.contains(e.id) ? () => ws.screenToggle(e.id) : null;
    final look = shelfLooks['Effects']!;
    // Overlays on a tile's image, none on a small tile.
    // ON, with its place among the stage's effects, when applied; the reason the sample looks unchanged (FOR SOUND, UNSUPPORTED ...);
    // and the star when starred or hovered.
    List<Widget> Function(bool) marks(String id, bool small, {String? on, String? same}) =>
        (h) => [
          if (on != null && !small)
            Positioned(
              left: 3,
              top: 3,
              child: Chip(label: on, look: ChipLook.tag(WsT.accent, edge: true)),
            ),
          if (same != null && !small)
            Positioned(
              left: 3,
              bottom: 3,
              child: Chip(label: same, look: ChipLook.tag(Grey.g63, edge: true)),
            ), // Shows why the sample is unchanged: what it lacks, or that the engine does not draw it yet.
          if (!small && (c.starred(id) || h))
            Positioned(
              right: 0,
              top: 0,
              child: DockStar(key: ValueKey('ws-star-$id'), on: c.starred(id), onTap: () => c.star(id)),
            ),
        ];
    // What the engine said about each effect, by id: a layer effect by its name, a file effect by its file.
    final seen = <String, ShelfItem>{};
    String pic(String id) => seen[id]?.picture ?? '';
    // Builds one item for any of the three listings; only what really differs by listing is switched on its [from].
    _Fx fx(String name, ShelfItem i) {
      final thing = i.from == 'thing', screened = i.from == 'screen', id = thing ? i.name : i.id;
      final lit = thing ? on.contains(id) : screened && screen.contains(id);
      final apply = chosen(id, thing ? () => ws.fxToggle(id) : (screened ? () => ws.screenPut(id) : () => ws.lookPut(id)), taken: thing && lit);
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
            ? (picked ? 'A look for the picked thing' : 'A look, on a new board')
            : i.same && EffectTiles.stopped(id).isNotEmpty
            ? 'Stops here: ${EffectTiles.stopped(id)}'
            : i.same && EffectTiles.lacks(id).isNotEmpty
            ? 'Needs: ${EffectTiles.lacks(id)}'
            : i.about.isEmpty
            ? (picked ? 'On the picked thing' : 'On all under it')
            : i.about,
        tile: (small, menu) => ShelfTile(
          ShelfItem(id, name, picture: i.picture),
          look,
          key: small || thing ? null : ValueKey(screened ? 'ws-screen-$id' : 'ws-look-$name'),
          small: small,
          art: thing && i.picture.isEmpty ? _painted(Draw((c, _) => _fxLook(c, name), name)) : null, // Without an image, its small drawing.
          picked: c.sel == id,
          lit: lit,
          onTap: () => c.pick(id),
          onApply: apply,
          onMenu: menu,
          onHover: screened ? (h) => ws.tryOn(h ? id : null) : null, // Shows what it does on the selected layer meanwhile (Ws.tryOn).
          naming: screened && _renaming == id ? ShelfNameField(name, (to) => _renamed(id, name, to)) : null,
          over: marks(
            id,
            small,
            on: !lit ? null : (screened ? 'ON ${screen.indexOf(id) + 1}' : 'ON'),
            same: screened && i.same ? EffectTiles.sameTag(id) : null,
          ),
        ),
      );
    }

    // File effects sorted by name. One the user added and renamed shows the name written beside it (shelf_add.dart).
    final screens = m.items('screen');
    final lined = <(String, ShelfItem)>[
      for (final i in m.items('thing')) (i.name, i),
      ...(EffectsShelf._byName[screens] ??= ([for (final i in screens) (shelfNamed(i.id) ?? i.name, i)]
        ..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase())))),
      // A saved preset by its name (Save Look). Applying it gives the selected layer its values, effects and keyframes.
      for (final (_, f) in m.presets)
        if (m.item(f) case final i?) (i.name, i),
    ];
    final every = <_Fx>[
      // First comes an empty effect. Its code opens on its card, ready for an ISF effect to be pasted in (empty_fx.dart).
      (
        id: 'empty:effect',
        name: 'Empty',
        label: '',
        on: false,
        apply: chosen('empty:effect', () => emptyPut(ws, expression: false, told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why')),
        said: picked ? 'An empty effect on the picked thing: paste ISF code into its card' : 'An empty effect, on a new board: paste ISF code into its card',
        tile: (small, menu) => ShelfTile(
          ShelfItem('empty:effect', 'Empty'),
          look,
          small: small,
          art: _painted(const EmptyLook()),
          picked: c.sel == 'empty:effect',
          onTap: () => c.pick('empty:effect'),
          onApply: chosen('empty:effect', () => emptyPut(ws, expression: false, told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why')),
          onMenu: menu,
        ),
      ),
      for (final (n, i) in lined) fx(n, i),
      // There are no motions here: they are expressions, in Create's Expression group.
    ];
    // Search matches the name, or what the effect does in its author's words, as Alight Motion's search reads descriptions.
    // It also matches the tags read from the effect (DockTags), each word on its own.
    // When nothing matches, as for a misspelt or partial word, the nearest five by RapidFuzz are shown, like "Did you mean".
    Set<String> tagsOf(String id) => DockTags.of('Effects', id, seen[id]?.tags ?? const {});
    bool found(String q, _Fx e) =>
        q.isEmpty ||
        e.name.toLowerCase().contains(q.toLowerCase()) ||
        (seen[e.id]?.about ?? '').toLowerCase().contains(q.toLowerCase()) ||
        DockTags.hit(q, e.name, tagsOf(e.id));
    final hits = [
          for (final e in every)
            if (c.hit(e.name) || (c.query.isNotEmpty && found(c.query, e))) e,
        ],
        hit = {for (final e in hits) e.id};
    final near = c.query.trim().isEmpty || hits.isNotEmpty
        ? const <String>[]
        : m.find(c.query, [
            for (final e in every)
              if (!hit.contains(e.id)) (e.id, '${e.name} ${e.label}', (seen[e.id]?.about ?? '')),
          ]);
    final first = DockTags.latched('Effects', c.query), latched = every.where((e) => e.id == first).take(1).toList();
    final all = [
      ...latched,
      for (final e in hits)
        if (e.id != first) e,
      for (final id in near)
        if (id != first) ...every.where((e) => e.id == id).take(1),
    ];
    final byId = {for (final e in all) e.id: e}, recent = [for (final id in effectRecent()) ?byId[id]];
    // The decks: what the user put in and what their words find, as one EffectDeck.
    final decks = effectDecks(),
        deckIds = {
          for (final d in decks)
            d: {
              ...d.things.map((t) => t.id),
              for (final e in all)
                if (d.words.isNotEmpty && found(d.words, e)) e.id,
            }.difference(d.without),
        };
    final used = ws.fxUsed, packs = <String, int>{};
    for (final e in every) {
      if (effectPack(e.id) case final p?) packs[p] = (packs[p] ?? 0) + 1;
    }
    // Every pack folder is listed, even with one effect, as sashimono-edit's add menu gives each folder its own submenu (add_menu.py:280).
    final deck = decks.where((d) => '@${d.name}' == c.mem.fxPlace).firstOrNull;
    final place = deck != null || !c.mem.fxPlace.startsWith('@') ? c.mem.fxPlace : 'All', pack = place.startsWith('/') ? place.substring(1) : null;
    // On the map, the map shows all effects and the selected deck sits beside it to add and remove effects, like Hearthstone's
    // Collection Manager. Elsewhere a deck shows what it holds as tiles.
    final building = c.mem.mapped.contains('Effects') && (deck != null || place == '★');
    // Recent lists the last effects applied, newest first, like the Fonts shelf's Recent. Alight Motion keeps forty (EffectBrowser.kt:117).
    final here = place == 'Recent'
        ? recent
        : [
            for (final e in all)
              if (building ||
                  switch (place) {
                    '★' => c.starred(e.id),
                    'In video' => used.contains(e.id),
                    _ when deck != null => deckIds[deck]!.contains(e.id),
                    _ when pack != null => effectPack(e.id) == pack,
                    _ => true,
                  })
                e,
          ];
    final kinds = <String, int>{}, read = <String, int>{};
    for (final e in here) {
      if (e.label.isNotEmpty) kinds[e.label] = (kinds[e.label] ?? 0) + 1;
      for (final t in tagsOf(e.id)) {
        read[t] = (read[t] ?? 0) + 1;
      }
    }
    // Tags read from the effects, most common first, as the Fonts shelf's tag chips do (dock_fonts.dart).
    // Each shows the # that is typed to search for it (DockTags). A kind with the same word is a different thing:
    // VIDVOX's Feedback kind is not the feedback passes read from the shader.
    // "transition" is left out because the Transition kind is read the same way (isf.cpp). Shadertoy's filters are read from the shaders.
    final tagChips = [
      for (final t in (read.entries.where((t) => t.key != 'transition').toList()..sort((a, b) => b.value.compareTo(a.value)))) MapEntry('#${t.key}', t.value),
    ]; // Most common first; the row scrolls, since all the kinds follow it.
    final chip = kinds.containsKey(c.chip) || tagChips.any((t) => t.key == c.chip) ? c.chip : 'All';
    final shown = [
      for (final e in here)
        if (chip == 'All' || (chip.startsWith('#') ? tagsOf(e.id).contains(chip.substring(1)) : e.label == chip)) e,
    ];
    // An effect the deck holds but the shelf does not: its name is kept and marked. Layer effects are excluded, since they wait for a layer.
    final known = {...every.map((e) => e.id), ...m.layerEffects.map((e) => e.$1), ...m.presets.map((e) => e.$2), ...m.animators.map((e) => e.$2)};
    if (deck != null && deck.things.any((t) => !known.contains(t.id))) deckSettle(deck, known);
    final lost = <_Fx>[
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
                    child: Chip(label: 'NOT HERE', look: ChipLook.tag(Grey.g63, edge: true)),
                  ),
                ],
              ),
            ),
    ];
    // Up to ten recent effects show above the tiles while nothing narrows the list, as Alight Motion's effect browser opens on its last ten
    // at EffectBrowser.kt:217. A list out of sight is not revisited, so the recent ones stay in view.
    final inSight = place == 'All' && chip == 'All' && c.query.isEmpty && !c.mem.mapped.contains('Effects')
        ? recent.take(10).toList()
        : const <_Fx>[]; // On the map only the map shows, as in XO's Space: the recent box took half the shelf.
    final listed = building ? shown : [...shown, ...lost];
    // What the deck holds in the order added, then what its words find. Effects not on this machine come last.
    final holds = place == '★'
        ? {for (final id in c.mem.starred) id}
        : deck == null
        ? const <String>{}
        : deckIds[deck]!;
    final held = !building ? const <_Fx>[] : [for (final id in holds) ...every.where((e) => e.id == id).take(1), ...lost];
    void put(EffectDeck d, _Fx e) => c.set(() {
      d.toggle(e.id, e.name, found: d.words.isNotEmpty && found(d.words, e));
      effectDecksKeep();
    });
    // Where one press sends an effect, however many decks exist: the target deck, else Favorites. A notice says where it went.
    // Lightroom Classic does the same with Add to Target Collection (B), using the Quick Collection until a target is set.
    final to = effectTarget(), aim = to != null && deckIds.containsKey(to) ? to : null;
    bool aimed(_Fx e) => aim != null ? deckIds[aim]!.contains(e.id) : c.starred(e.id);
    void target(_Fx e) {
      final was = aimed(e);
      aim != null ? put(aim, e) : c.star(e.id);
      ws.notice = '${was ? 'Removed from' : 'Added to'} ${aim?.name ?? 'Favorites'}';
    }

    // Actions on an effect are in its right-click menu and the footer's three-dot button, as in Ableton's item menu.
    void menuOn(_Fx e, Offset at) {
      final box = _menu.currentContext?.findRenderObject() as RenderBox?;
      _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
        if (off(e) case final o?) ...[WsMenuItem('Add Again', e.apply), WsMenuItem('Remove', o)] else WsMenuItem(e.on ? 'Remove' : 'Add', e.apply),
        const WsMenuItem.rule(),
        WsMenuItem('${aimed(e) ? 'Remove from' : 'Add to'} ${aim == null ? 'Favorites' : 'Target Deck'}', () => target(e), keys: 'B'),
        WsMenuItem('New Deck…', () => _places.currentState?.newDeck(thing: DeckThing(e.id, e.name, effectSum(e.id)))),
        if (shelfAdded(e.id)) ...[const WsMenuItem.rule(), WsMenuItem('Rename…', () => setState(() => _renaming = e.id))],
        if (effectPack(e.id) case final p? when packs.containsKey(p)) ...[
          const WsMenuItem.rule(),
          WsMenuItem('Go to Pack: $p', () => c.set(() => c.mem.fxPlace = '/$p')),
        ],
      ]);
    }

    Widget tile(_Fx e, bool small) => e.tile(small, (at) => menuOn(e, at));
    // A strip for an effect the deck holds, under the deck's row, like a card in a Hearthstone deck list: its image and name.
    // A click selects it, a double-click applies it, a drop applies it where released, and a right-click opens its menu, as on its tile.
    Widget strip(_Fx e) => ShelfTile(
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
      narrow: narrow,
      known: known,
      packs: Map.fromEntries(packs.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))),
      counts: {
        'All': all.length,
        'Recent': recent.length,
        '★': all.where((e) => c.starred(e.id)).length,
        'In video': all.where((e) => used.contains(e.id)).length,
      },
      decks: {for (final d in decks) d: deckIds[d]!.intersection(byId.keys.toSet()).length},
      mapped: c.mem.mapped.contains('Effects'),
      held: [for (final e in held) strip(e)],
      covers: {for (final d in decks) '@${d.name}': ?cover(deckIds[d]!)},
      put: (d, id) {
        if (every.where((e) => e.id == id).firstOrNull case final e? when !(deckIds[d]?.contains(id) ?? false)) {
          put(d, e); // A deck made a moment ago is not in the table yet (Save Favorites...).
        }
      },
    );
    final sel = c.foot([...all, ...lost].where((e) => e.id == c.sel).firstOrNull);
    final tiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DockChips(
          [
            ('All', here.length),
            for (final t in tagChips) (t.key, t.value),
            for (final k in kinds.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) (k.key, k.value),
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
            pad: EdgeInsets.only(top: WsT.gutter, bottom: WsT.gutter),
            count: inSight.length,
            tile: (i) => tile(inSight[i], true),
          ), // Two rows as in Alight Motion's box, one row until a sixth effect: a single tile in a row looked empty over the shelf.
        Expanded(
          child: CallbackShortcuts(
            // B runs the target action on the selected effect, like the menu's single row, as in Lightroom's Library grid.
            bindings: {const SingleActivator(LogicalKeyboardKey.keyB): () => sel == null ? null : target(sel)},
            child: Focus(
              focusNode: _tileKeys,
              child: TapRegion(
                behavior: HitTestBehavior.translucent,
                onTapInside: (_) => c.mem.mapped.contains('Effects') ? null : _tileKeys.requestFocus(), // The map handles the keys itself.
                child: listed.isEmpty
                    ? DockEmpty(
                        c.query,
                        said: c.query.isNotEmpty
                            ? null
                            : deck != null
                            ? (identical(deck, aim) ? 'Drag an effect onto the deck, or right-click one' : 'Drag an effect onto the deck')
                            : 'Nothing here yet',
                      )
                    : c.mem.mapped.contains('Effects')
                    ? ListenableBuilder(
                        // Laid out by the tiles there are, and again once all are drawn; tiles drawn in between join then.
                        listenable: EffectTiles.progress,
                        builder: (context, _) {
                          final map = dockMap('Effects'), drawing = EffectTiles.progress.value != null;
                          final clip = dockModel('clip_b32'); // Placed by how CLIP sees each tile's frames once the model is made, else by tiny colours.
                          final drawn = [
                            for (final e in every)
                              if (pic(e.id).isNotEmpty) e,
                          ];
                          if (!drawing || map.places.value.isEmpty) {
                            map.need(
                              m,
                              [for (final e in drawn) (e.id, pic(e.id))],
                              (from) => _fxNumbers(m, clip, [for (final e in drawn) e.label], from),
                              also: '${clip ?? ''} kinds',
                            );
                          }
                          return DockMap(
                            map,
                            [for (final e in listed) (e.id, tile(e, true))],
                            picked: c.sel,
                            press: c.pick,
                            peek: (id) => TileMoving(pic(id), playing: true),
                            names: {for (final e in every) e.id: e.name},
                          );
                        },
                      )
                    : ShelfGrid(look, count: listed.length, tile: (i) => tile(listed[i], false)),
              ),
            ),
          ),
        ),
      ],
    );
    return WsMenu(
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
                          color: WsT.ground,
                          child: SizedBox(width: WsT.gutter),
                        ),
                        Expanded(child: tiles),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.mem.fxListOpen || building) // A deck on the map, with what it holds under it, at the list's height.
                          DockResizable(
                            height: c.mem.fxListHeight,
                            max: box.maxHeight - 160,
                            reset: dockFxListHeight,
                            gripKey: const ValueKey('ws-fx-list-grip'),
                            onHeight: (h) => c.set(() => c.mem.fxListHeight = h),
                            child: list(true),
                          )
                        else
                          SizedBox(
                            height: Shape.z(22),
                            child: list(true),
                          ), // One row for the list leaves room for tiles: the whole list left 3.3 rows of tiles, or 1.7 with the footer open.
                        Expanded(child: tiles),
                      ],
                    ),
            ),
          ),
          if (sel != null && pic(sel.id).isNotEmpty) // A large moving sample of the selected effect, as Alight Motion's effect browser opens.
            SizedBox(key: const ValueKey('ws-fx-preview'), height: Shape.z(140), child: TileMoving(pic(sel.id), playing: true)),
          if (sel != null)
            DockFooter(
              title: sel.name,
              meta: sel.label.isEmpty ? sel.said : '${sel.label} · ${sel.said} · double-click to add', // A click selects, a double-click applies.
              action: sel.on ? 'Remove' : 'Add',
              fresh: !picked,
              onAction: off(sel) ?? sel.apply,
              more: Builder(
                builder: (b) => IconPress(
                  dockMark(DockG.more),
                  key: const ValueKey('ws-fx-more'),
                  onTap: () => menuOn(sel, (b.findRenderObject() as RenderBox).localToGlobal(Offset.zero)),
                ),
              ),
            ), // With nothing selected, the effect goes on a layer of its own.
        ],
      ),
    );
  }
}

/// A tile's image drawn by the app where the engine has none: a layer effect gets its small drawing, Empty gets its plus.
Widget Function(bool) _painted(CustomPainter p) =>
    (_) => FittedBox(
      child: CustomPaint(size: const Size(18, 16), painter: p),
    );

/// The Effects map's coordinates for the effects whose tile frames are read from [homes].
/// An effect is placed by how it looks, from CLIP at three of its sixteen frames so motion counts (or tiny colours), and what it is for ([kinds], the engine's label, such as an ISF's CATEGORIES or its startImage, endImage and progress, see isf.cpp).
/// The kind is weighted twice as much as the look: each kind becomes an island with similar effects near each other,
/// as XO's Space keeps each drum type's colour together.
Future<List<Float32List?>> _fxNumbers(Motolii m, String? clip, List<String> kinds, List<String> homes) async {
  final look = [
    for (final f in homes)
      await (clip == null ? dockTiny : (List<String> at) => dockSeen(m, clip, at))([
        for (final k in const [0, 7, 15]) EffectTiles.frame(f, k),
      ]),
  ];
  final all = kinds.toSet().toList();
  return dockTogether(
    [
      look,
      [for (final k in kinds) Float32List(all.length)..[all.indexOf(k)] = 1],
    ],
    const [1, 2],
    even: const {0},
  );
}

/// The description of a layer effect: the document's value for it, and what the selected layer has for it now.
String _said(Ws ws, String name) {
  final m = ws.inside!,
      v = m.layerEffects.firstWhere((e) => e.$1 == name).$2,
      t = int.tryParse(ws.selected ?? ''); // The selected layer's id, or null when none is selected.
  final now = t == null ? '' : m.word(t, v);
  return now.isEmpty ? '$v · none on it' : '$v · $now';
}

/// Small drawings of what the engine's path effects do to a square, for effects the shelf has no image for:
/// a half-drawn path, and a dot moving along one. An effect the app does not know has no drawing.
void _fxLook(Canvas c, String name) {
  const ink = Color(0xFFE0A35A), r = Rect.fromLTWH(4, 3, 10, 10);
  switch (name) {
    case 'Trim Paths':
      c.drawArc(
        Rect.fromCircle(center: r.center, radius: 5.5),
        -1.6,
        3.8,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    case 'Move Along Path':
      c.drawArc(
        Rect.fromCircle(center: r.center, radius: 5.5),
        -1.6,
        3.8,
        false,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      c.drawCircle(r.center + const Offset(0, -5.5), 2, Paint()..color = ink);
  }
}
