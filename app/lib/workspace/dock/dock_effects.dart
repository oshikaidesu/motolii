// The Effects shelf: all the inside does to a picture, as tiles sorted by what each is for (the inside's labels as
// chips, not who draws it): the effects a thing may be given (picked: its foot puts it on or takes it off), the
// whole-screen effects (on the picked thing as the camera sees it, or on the stage, in their order), the motions.
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../bridge/motolii.dart' show Motolii;
import '../../skin/tokens.dart';
import 'dock_effect_places.dart';
import 'dock_glyphs.dart';
import 'dock_map.dart';
import 'dock_widgets.dart';
import 'dock_resizable.dart';
import 'dock_tags.dart';
import '../shelf/effect_decks.dart';
import '../shelf/effect_tiles.dart';
import '../shelf/empty_fx.dart';
import '../shelf/shelf_add.dart';
import '../shelf/shelf_tile.dart';
import '../state/state.dart';
import '../commands/context_menu.dart';

// (each: what it is told by (a thing's own by its name; a file's by its file: two files may share a name, Halftone's
//  three.js .wgsl and an AviUtl2 script), its name, what it is for, its tile, whether it is on, what two presses do
//  (also what a drop on the stage does), what it says of itself)
typedef _Fx = ({
  String id,
  String name,
  String label,
  Widget Function(bool small, ValueChanged<Offset>? menu) tile, // (menu: what a right click on it does)
  bool on,
  VoidCallback apply,
  String said,
});

class EffectsShelf extends StatefulWidget {
  const EffectsShelf(this.c, {super.key});
  final DockCtx c;

  /// The files' effects by their names, as After Effects' Effects & Presets lists each kind: the inside gives them by
  /// file, so VIDVOX's capitals came before AbsentMotion's am_ files, two runs of A to Z (golf_noise.md ㊾). Once a shelf.
  static final _byName = Expando<List<(String, ShelfItem)>>(); // (as shown, the inside's item)

  @override
  State<EffectsShelf> createState() => _EffectsShelfState();
}

class _EffectsShelfState extends State<EffectsShelf> {
  final _menu = GlobalKey<WsMenuState>(), _places = GlobalKey<EffectPlacesState>();
  final _tileKeys = FocusNode(debugLabel: 'ws-fx-tiles'); // (B goes to the tiles once one is pressed, not to the stage's brush)
  DockCtx get c => widget.c;
  String? _renaming; // (the file, added by the maker, whose name is being written in its tile: shelf_add.dart)

  // (its name written beside it, never its file: one of the library's has no Rename)
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
    // (a thing's own effects, looks and motions go on the picked thing, or on a new board; the whole-screen ones on it, or on the stage)
    // (put on with words typed: latched to them, the first for them next time, golf (94))
    VoidCallback chosen(String id, VoidCallback put, {bool taken = false}) {
      final VoidCallback go = () {
        // (a closure of its own, not a declaration's tear-off: what a carried tile is told by)
        DockTags.latch('Effects', c.query, id);
        if (!taken) c.set(() => effectUsed(id, words: c.query, chip: c.chip));
        ws.tryOn(null); // (the one shown under the hand let go first: the put reads the document as it is)
        put();
      };
      carriedEffect[go] = id;
      return go;
    }

    // (all of them whatever is picked, as After Effects' Effects & Presets panel lists them: nothing picked, those of a
    //  thing go on a new board, Ws.fxToggle)
    // (an effect file on the picked thing taken off by Remove, a press putting on another: Ws.screenPut)
    VoidCallback? off(_Fx e) => screen.contains(e.id) ? () => ws.screenToggle(e.id) : null;
    final look = shelfLooks['Effects']!;
    // (laid over a tile's picture, none on a small one: ON (and its place among those on the stage) when it is on, why
    //  it is seen to change nothing on the sample when it is (FOR SOUND, UNSUPPORTED…), the star once starred or under
    //  the pointer)
    List<Widget> Function(bool) marks(String id, bool small, {String? on, String? same}) =>
        (h) => [
          if (on != null && !small) Positioned(left: 3, top: 3, child: DockTag(on, hue: WsT.accent, edge: true)),
          if (same != null && !small)
            Positioned(
              left: 3,
              bottom: 3,
              child: DockTag(same, hue: Grey.g63, edge: true),
            ), // (the sample as it is: what it lacks there, or that the inside does not draw it yet)
          if (!small && (c.starred(id) || h))
            Positioned(
              right: 0,
              top: 0,
              child: DockStar(key: ValueKey('ws-star-$id'), on: c.starred(id), onTap: () => c.star(id)),
            ),
        ];
    // (what the inside said of each, by the id it is told by: a thing's own by its name, a file's by its file)
    final seen = <String, ShelfItem>{};
    String pic(String id) => seen[id]?.picture ?? '';
    // (one item of the three listings: only what truly differs by listing is switched on its [from])
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
          art: thing && i.picture.isEmpty ? _painted(_FxLook(name)) : null, // (without a picture, its small drawing)
          picked: c.sel == id,
          lit: lit,
          onTap: () => c.pick(id),
          onApply: apply,
          onMenu: menu,
          onHover: screened ? (h) => ws.tryOn(h ? id : null) : null, // (what it does shown on the picked thing meanwhile, Ws.tryOn)
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

    // (the files' effects by their names, one the maker added and renamed by the name written beside it, shelf_add.dart)
    final screens = m.items('screen');
    final lined = <(String, ShelfItem)>[
      for (final i in m.items('thing')) (i.name, i),
      ...(EffectsShelf._byName[screens] ??= ([for (final i in screens) (shelfNamed(i.id) ?? i.name, i)]
        ..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase())))),
      // (a look kept by its name, Save Look: given to the picked thing, its values, effects and keys)
      for (final (_, f) in m.presets)
        if (m.item(f) case final i?) (i.name, i),
    ];
    final every = <_Fx>[
      // (first: an empty one, its code open on its card to paste an ISF effect into: empty_fx.dart)
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
      // (no motions: they are expressions, on Create's Expression group: dock_make_3.dart)
    ];
    // (by its name, or by what it does in its maker's words, as Alight Motion's search reads the descriptions; when that
    //  finds nothing, a word typed wrong or in part, the nearest five by RapidFuzz (the inside's find, the user's choice),
    //  as a search engine's "Did you mean" comes when the words as typed find nothing)
    // (and by what it is, read from it, as the other shelves' tags are found: DockTags, each word on its own; golf (92))
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
    // (the decks: what the hand put in and what their words find, as one bundle (EffectDeck))
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
    // (every folder, one effect in it too, as sashimono-edit's add menu gives each folder its own submenu, add_menu.py:280)
    final deck = decks.where((d) => '@${d.name}' == c.mem.fxPlace).firstOrNull;
    final place = deck != null || !c.mem.fxPlace.startsWith('@') ? c.mem.fxPlace : 'All', pack = place.startsWith('/') ? place.substring(1) : null;
    // (on the map the map is all of them, the deck picked beside it to put in and take out: Hearthstone's Collection
    //  Manager, the collection and the deck being made side by side; elsewhere a deck shows what it holds as the tiles)
    final building = c.mem.mapped.contains('Effects') && (deck != null || place == '★');
    // (the last put on the newest first, the Fonts shelf's Recent, as Alight Motion keeps forty, EffectBrowser.kt:117)
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
    // (and the tags read from them, the most first, as the Fonts shelf's tag chips (dock_fonts.dart), each with the #
    //  a tag is typed with (DockTags), a kind of the same word being another thing (VIDVOX's Feedback kind is not the
    //  kept passes read); transition not twice, the kind Transition being read the same way (isf.cpp): Shadertoy's
    //  filters, read from the shaders, golf (92))
    final tagChips = [
      for (final t in (read.entries.where((t) => t.key != 'transition').toList()..sort((a, b) => b.value.compareTo(a.value)))) MapEntry('#${t.key}', t.value),
    ]; // (all, the most first: the row slides, as the kinds after them are all there)
    final chip = kinds.containsKey(c.chip) || tagChips.any((t) => t.key == c.chip) ? c.chip : 'All';
    final shown = [
      for (final e in here)
        if (chip == 'All' || (chip.startsWith('#') ? tagsOf(e.id).contains(chip.substring(1)) : e.label == chip)) e,
    ];
    // (one a deck holds and the shelf does not: its name kept, marked; not an effect of a thing, which waits for a thing)
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
                over: (_) => [Positioned(left: 3, bottom: 3, child: DockTag('NOT HERE', hue: Grey.g63, edge: true))],
              ),
            ),
    ];
    // (ten in sight over the tiles while nothing narrows them, as Alight Motion's effect browser opens on its last ten,
    //  EffectBrowser.kt:217: a list out of sight is not gone back to, Bergman's bookmarks, 32 of 41 by the bar always in sight)
    final inSight = place == 'All' && chip == 'All' && c.query.isEmpty && !c.mem.mapped.contains('Effects')
        ? recent.take(10).toList()
        : const <_Fx>[]; // (on the map the map alone, as XO's Space: the recent box took half the shelf)
    final listed = building ? shown : [...shown, ...lost];
    // (what the deck holds, in the order put in, then what its words find; one not here last)
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
    // (where an effect goes by one press, however many decks there are: the target deck, else the Favorites, and a word
    //  says where it went, as Lightroom Classic's Add to Target Collection (B), the Quick Collection until one is set)
    final to = effectTarget(), aim = to != null && deckIds.containsKey(to) ? to : null;
    bool aimed(_Fx e) => aim != null ? deckIds[aim]!.contains(e.id) : c.starred(e.id);
    void target(_Fx e) {
      final was = aimed(e);
      aim != null ? put(aim, e) : c.star(e.id);
      ws.notice = '${was ? 'Removed from' : 'Added to'} ${aim?.name ?? 'Favorites'}';
    }

    // (what is done to an effect is on the effect, by a right click or by the foot's three dots: Ableton's right click on
    //  an item, the target's one row, New at its end; Go to Album)
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
    // (one the deck holds, under its row: Hearthstone's deck list, each card a strip of its picture and its name; a
    //  press picks it, two put it on, carried it goes where it is let go, a right click its menu, as its tile)
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
    // (a deck's picture: the pictures of its first four, two by two, or of its first alone while it holds fewer, as
    //  Spotify makes a playlist's cover)
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
          put(d, e); // (a deck made a moment ago is not in the table yet: Save Favorites…)
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
        ), // (the tags read first, as Shadertoy's filters head its results: the kinds are many, a hundred and more, the most first as the tags)
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
          ), // (as Alight Motion's box of two rows; one until a sixth: in the window a row with one tile stood empty over the shelf)
        Expanded(
          child: CallbackShortcuts(
            // (B puts the one picked where its menu's one row would, as in Lightroom's Library grid)
            bindings: {const SingleActivator(LogicalKeyboardKey.keyB): () => sel == null ? null : target(sel)},
            child: Focus(
              focusNode: _tileKeys,
              child: TapRegion(
                behavior: HitTestBehavior.translucent,
                onTapInside: (_) => c.mem.mapped.contains('Effects') ? null : _tileKeys.requestFocus(), // (the map takes the keys itself)
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
                        // (laid out by the tiles there are, and again once all are drawn: those drawn meanwhile join it then)
                        listenable: EffectTiles.progress,
                        builder: (context, _) {
                          final map = dockMap('Effects'), drawing = EffectTiles.progress.value != null;
                          final clip = dockModel('clip_b32'); // (by how CLIP sees each moment, once it is made; else by tiny colours)
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
              // (as the Media shelf's tree: beside the tiles by the room, over them with its height the hand's)
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
                        if (c.mem.fxListOpen || building) // (a deck on the map, what it holds under it, at the list's height)
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
                          ), // (the whole list over the tiles left 3.3 rows of them, 1.7 with the foot open, of the 5.4 and 3.8 before it)
                        Expanded(child: tiles),
                      ],
                    ),
            ),
          ),
          if (sel != null && pic(sel.id).isNotEmpty) // (large and moving, as Alight Motion's effect browser opens a large moving sample of the one pressed)
            SizedBox(key: const ValueKey('ws-fx-preview'), height: Shape.z(140), child: TileMoving(pic(sel.id), playing: true)),
          if (sel != null)
            _FxFooter(
              sel.name,
              kind: sel.label,
              said: sel.said,
              done: sel.on,
              ws: ws,
              onAction: off(sel) ?? sel.apply,
              needs: !picked,
              more: Builder(
                builder: (b) => IconPress(
                  dockMark(DockG.more),
                  key: const ValueKey('ws-fx-more'),
                  onTap: () => menuOn(sel, (b.findRenderObject() as RenderBox).localToGlobal(Offset.zero)),
                ),
              ),
            ), // (none picked: it goes on a board of its own)
        ],
      ),
    );
  }
}

/// A tile's picture drawn by the window, where the inside has none for it: a thing's effect its small drawing, Empty its plus.
Widget Function(bool) _painted(CustomPainter p) =>
    (_) => FittedBox(
      child: CustomPaint(size: const Size(18, 16), painter: p),
    );

/// The Effects map's numbers for [ids], their tiles' moments read from [homes]: how each looks (CLIP's at three moments
/// of its sixteen: how it moves too; or their tiny colours) beside what it is for, the shelf's own word ([kinds]: the
/// inside's label, as an ISF's CATEGORIES or its startImage, endImage and progress say it, isf.cpp), that weighted
/// twice: each kind an island, the alike near within it, as XO's Space keeps each drum type's colour together.
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

/// Joined: the document's value an effect is, and what the picked thing has for it now.
String _said(Ws ws, String name) {
  final m = ws.inside!,
      v = m.layerEffects.firstWhere((e) => e.$1 == name).$2,
      t = int.tryParse(ws.selected ?? ''); // (the shelf shows only what the inside does)
  final now = t == null ? '' : m.word(t, v);
  return now.isEmpty ? '$v · none on it' : '$v · $now';
}

/// The foot: the picked effect, what it is for and what it does, and Add (or Remove): one press picks, two put it on.
class _FxFooter extends StatelessWidget {
  const _FxFooter(
    this.name, {
    required this.kind,
    required this.said,
    required this.ws,
    required this.done,
    required this.onAction,
    required this.needs,
    required this.more,
  });
  final String name, kind, said;
  final Ws ws;
  final bool done, needs; // (needs: nothing picked, it makes a board)
  final VoidCallback onAction;
  final Widget more;
  @override
  Widget build(BuildContext context) => DockFooter(
    title: name,
    meta: kind.isEmpty ? said : '$kind · $said · double-click to add',
    action: done ? 'Remove' : 'Add',
    fresh: needs,
    onAction: onAction,
    more: more,
  );
}

/// What the inside's path effects do to a square, drawn small, where the shelf has no picture for them: a path half
/// drawn, a dot moving along one. (An effect the window does not know has no picture.)
class _FxLook extends CustomPainter {
  const _FxLook(this.name);
  final String name;
  @override
  void paint(Canvas c, Size s) {
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

  @override
  bool shouldRepaint(_FxLook o) => o.name != name;
}
