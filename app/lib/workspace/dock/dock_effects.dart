// The Effects shelf: all the inside does to a picture, as tiles sorted by what each is for (the inside's labels as
// chips, not who draws it): the effects a thing may be given (picked: its foot puts it on or takes it off), the
// whole-screen effects (on the picked thing as the camera sees it, or on the stage, in their order), the motions.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../engine/motolii.dart' show Motolii;
import '../../style/tokens.dart';
import 'dock_effect_places.dart';
import 'dock_glyphs.dart';
import 'dock_map.dart';
import 'dock_parts.dart';
import 'dock_resizable.dart';
import 'dock_tags.dart';
import '../shelf/effect_decks.dart';
import '../shelf/effect_tiles.dart';
import '../shelf/empty_fx.dart';
import '../shelf/shelf_add.dart';
import '../ws.dart';
import '../ws_menu.dart';

// (each: what it is told by (a thing's own by its name; a file's by its file: two files may share a name, Halftone's
//  three.js .wgsl and an AviUtl2 script), its name, what it is for, its tile, whether it is on, what two presses do
//  (also what a drop on the stage does), what it says of itself)
typedef _Fx = ({String id, String name, String label, Widget Function(bool small) tile, bool on, VoidCallback apply, String said});

class EffectsShelf extends StatefulWidget {
  const EffectsShelf(this.c, {super.key});
  final DockCtx c;

  /// The files' effects by their names, as After Effects' Effects & Presets lists each kind: the inside gives them by
  /// file, so VIDVOX's capitals came before AbsentMotion's am_ files, two runs of A to Z (golf_noise.md ㊾). Once a shelf.
  static final _byName = Expando<List<(String, String, String)>>(); // (as shown, file, as the inside names it)

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
    final every = <_Fx>[
      // (first: an empty one, its code open on its card to paste an ISF effect into: empty_fx.dart)
      (
        id: 'empty:effect',
        name: 'Empty',
        label: '',
        on: false,
        apply: chosen('empty:effect', () => emptyPut(ws, expression: false, told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why')),
        said: picked ? 'An empty effect on the picked thing: paste ISF code into its card' : 'An empty effect, on a new board: paste ISF code into its card',
        tile: (small) => EffectTile(
          'Empty',
          small: small,
          look: const EmptyLook(),
          on: null,
          picked: c.sel == 'empty:effect',
          onTap: () => c.pick('empty:effect'),
          onApply: chosen('empty:effect', () => emptyPut(ws, expression: false, told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why')),
        ),
      ),
      for (final (n, _) in m.thingEffects)
        (
          id: n,
          name: n,
          label: m.label(n),
          on: on.contains(n),
          apply: chosen(n, () => ws.fxToggle(n), taken: on.contains(n)),
          said: _said(ws, n),
          tile: (small) => EffectTile(
            n,
            small: small,
            file: m.picture(n),
            look: _FxLook(n),
            on: on.contains(n) ? 'ON' : null,
            picked: c.sel == n,
            onTap: () => c.pick(n),
            onApply: chosen(n, () => ws.fxToggle(n), taken: on.contains(n)),
            star: small ? null : c,
          ),
        ),
      // (one the maker added and renamed by the name written beside it, shelf_add.dart)
      for (final (n, f, said) in EffectsShelf._byName[m.effects] ??= ([
        for (final (n, f) in m.effects) (shelfNamed(f) ?? n, f, n),
      ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))))
        (
          id: f,
          name: n,
          label: m.label(said),
          on: screen.contains(f),
          apply: chosen(f, () => ws.screenPut(f)),
          said: m.tileSame(f) && EffectTiles.stopped(f).isNotEmpty
              ? 'Stops here: ${EffectTiles.stopped(f)}'
              : m.tileSame(f) && EffectTiles.lacks(f).isNotEmpty
              ? 'Needs: ${EffectTiles.lacks(f)}'
              : m.about(f).isEmpty
              ? (picked ? 'On the picked thing' : 'On all under it')
              : m.about(f),
          tile: (small) => EffectTile(
            n,
            key: small ? null : ValueKey('ws-screen-$f'),
            small: small,
            file: m.picture(f),
            same: m.tileSame(f) ? EffectTiles.sameTag(f) : null,
            on: screen.contains(f) ? 'ON ${screen.indexOf(f) + 1}' : null,
            picked: c.sel == f,
            onTap: () => c.pick(f),
            onApply: chosen(f, () => ws.screenPut(f)),
            star: small ? null : c,
            starId: f,
            onHover: (h) => ws.tryOn(h ? f : null),
            naming: _renaming == f ? ShelfNameField(n, (to) => _renamed(f, n, to)) : null,
          ),
        ),
      // (a look kept by its name, Save Look: given to the picked thing, its values, effects and keys)
      for (final (n, f) in m.looks)
        (
          id: f,
          name: n,
          label: 'Look',
          on: false,
          apply: chosen(f, () => ws.lookPut(f)),
          said: picked ? 'A look for the picked thing' : 'A look, on a new board',
          tile: (small) => EffectTile(
            n,
            key: small ? null : ValueKey('ws-look-$n'),
            small: small,
            file: m.picture(f),
            on: null,
            picked: c.sel == f,
            onTap: () => c.pick(f),
            onApply: chosen(f, () => ws.lookPut(f)),
            star: small ? null : c,
            starId: f,
          ),
        ),
      // (no motions: they are expressions, on Create's Expression group: dock_make_3.dart)
    ];
    // (by its name, or by what it does in its maker's words, as Alight Motion's search reads the descriptions; when that
    //  finds nothing, a word typed wrong or in part, the nearest five by RapidFuzz (the inside's find, the user's choice),
    //  as a search engine's "Did you mean" comes when the words as typed find nothing)
    // (and by what it is, read from it, as the other shelves' tags are found: DockTags, each word on its own; golf (92))
    Set<String> tagsOf(String id) => DockTags.of('Effects', id, m.tags(id));
    bool found(String q, _Fx e) =>
        q.isEmpty ||
        e.name.toLowerCase().contains(q.toLowerCase()) ||
        m.about(e.id).toLowerCase().contains(q.toLowerCase()) ||
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
              if (!hit.contains(e.id)) (e.id, '${e.name} ${e.label}', m.about(e.id)),
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
    final known = {...every.map((e) => e.id), ...m.thingEffects.map((e) => e.$1), ...m.looks.map((e) => e.$2), ...m.animators.map((e) => e.$2)};
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
              tile: (bool small) => EffectTile(t.name, lost: true, on: null, picked: c.sel == t.id, onTap: () => c.pick(t.id)),
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

    Widget tile(_Fx e, bool small) => GestureDetector(onSecondaryTapDown: (d) => menuOn(e, d.globalPosition), child: e.tile(small));
    // (one the deck holds, under its row: Hearthstone's deck list, each card a strip of its picture and its name; a
    //  press picks it, two put it on, carried it goes where it is let go, a right click its menu, as its tile)
    Widget strip(_Fx e) => GestureDetector(
      onSecondaryTapDown: e.label == 'Not here' ? null : (d) => menuOn(e, d.globalPosition),
      child: DockHover(
        key: ValueKey('ws-fx-held-${e.id}'),
        onTap: () => c.pick(e.id),
        onDoubleTap: e.apply,
        picks: true,
        builder: (context, h) => Container(
          height: Shape.z(22),
          padding: EdgeInsets.only(left: Shape.s(4) + Shape.z(14), right: WsT.inset),
          color: dockFill(c.sel == e.id, h),
          child: Row(
            children: [
              SizedBox.square(
                dimension: Shape.z(18),
                child: m.picture(e.id).isEmpty ? ColoredBox(color: WsT.card) : TileMoving(m.picture(e.id), playing: true),
              ), // (played while in sight: TileMoving's own)
              SizedBox(width: Shape.s(6)),
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.name(dockInk(c.sel == e.id, e.label == 'Not here' ? Grey.g56 : null)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // (a deck's picture: the pictures of its first four, two by two, or of its first alone while it holds fewer, as
    //  Spotify makes a playlist's cover)
    Widget? cover(Iterable<String> ids) {
      final f = [
        for (final id in ids)
          if (m.picture(id) case final p when p.isNotEmpty) p,
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
          GridView.count(
            key: const ValueKey('ws-fx-recent'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: WsT.gutter, bottom: WsT.gutter),
            crossAxisCount: 5,
            crossAxisSpacing: WsT.gutter,
            mainAxisSpacing: WsT.gutter,
            children: [
              for (var i = 0; i < (inSight.length > 5 ? 10 : 5); i++) i < inSight.length ? tile(inSight[i], true) : const SizedBox(),
            ], // (as Alight Motion's box of two rows; one until a sixth: in the window a row with one tile stood empty over the shelf)
          ),
        Expanded(
          child: CallbackShortcuts(
            // (B puts the one picked where its menu's one row would, as in Lightroom's Library grid)
            bindings: {const SingleActivator(LogicalKeyboardKey.keyB): () => sel == null ? null : target(sel)},
            child: Focus(
              focusNode: _tileKeys,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => c.mem.mapped.contains('Effects') ? null : _tileKeys.requestFocus(), // (the map takes the keys itself)
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
                              if (m.picture(e.id).isNotEmpty) e,
                          ];
                          if (!drawing || map.places.value.isEmpty) {
                            map.need(
                              m,
                              [for (final e in drawn) (e.id, m.picture(e.id))],
                              (from) => _fxNumbers(m, clip, [for (final e in drawn) e.label], from),
                              also: '${clip ?? ''} kinds',
                            );
                          }
                          return DockMap(
                            map,
                            [for (final e in listed) (e.id, tile(e, true))],
                            picked: c.sel,
                            press: c.pick,
                            peek: (id) => TileMoving(m.picture(id), playing: true),
                            names: {for (final e in every) e.id: e.name},
                          );
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, box) {
                          final cols = wsCols(box.maxWidth, Shape.z(84)), w = wsCell(box.maxWidth, cols);
                          return GridView.builder(
                            // (only the tiles in sight are made, Flutter's own lazy grid, as the Fonts shelf's rows: a Wrap made all 1,293 at each opening)
                            padding: EdgeInsets.zero,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: WsT.gutter,
                              mainAxisSpacing: WsT.gutter,
                              mainAxisExtent: w + Shape.z(18),
                            ), // (a tile: its square and its name, EffectTile)
                            itemCount: listed.length,
                            itemBuilder: (context, i) => tile(listed[i], false),
                          );
                        },
                      ),
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
                            min: 44,
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
          if (sel != null &&
              m.picture(sel.id).isNotEmpty) // (its pictures large and moving, as Alight Motion's effect browser opens a large moving sample of the one pressed)
            SizedBox(key: const ValueKey('ws-fx-preview'), height: Shape.z(140), child: TileMoving(m.picture(sel.id), playing: true)),
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
                builder: (b) => DockIconButton(
                  DockG.more,
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

/// One tile, whatever draws it: what it does to a sample (the picture the inside says, drawn by effect_tiles.dart and
/// moving, in the grid always (11/4, the user: "keep the effect window moving"), on the map while the hand is on it, as
/// Alight Motion's tiles move; or made by engine/fx_tiles.sh; without one, a thing's
/// effect its small drawing, else a plain tile), its name, ON (and its place among those on the stage) when it is on,
/// why it is seen to change nothing on the sample when it is (FOR SOUND, UNSUPPORTED…), the star for a thing's effect.
class EffectTile extends StatelessWidget {
  const EffectTile(
    this.name, {
    super.key,
    this.file,
    this.look,
    required this.on,
    required this.onTap,
    this.onApply,
    this.picked = false,
    this.same,
    this.star,
    this.starId,
    this.naming,
    this.small = false,
    this.lost = false,
    this.onHover,
  });
  final String name;
  final bool small; // (its square alone, among the last put on: no name, no tags; the foot says which)
  final bool lost; // (a deck holds it, this machine does not)
  final Widget? naming; // (where its name is being written, in its place)
  final String? file, on;
  final CustomPainter? look;
  final bool picked;
  final String? same; // (seen to change nothing on the sample: why, EffectTiles.sameTag)
  final VoidCallback onTap;
  final VoidCallback? onApply; // (two presses: it is put on, or taken off)
  final ValueChanged<bool>? onHover; // (the hand on it, or off: what it does shown on the picked thing meanwhile, Ws.tryOn)
  final DockCtx? star;
  final String? starId; // (what it is starred by: a file's effect by its file, two files may share a name)
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    onDoubleTap: onApply,
    picks: true,
    onHover: onHover,
    builder: (context, h) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: WsT.card),
              if (file case final f? when f.isNotEmpty)
                TileMoving(
                  f,
                  playing: h || !small,
                ) // (in the grid always: played while in sight, TileMoving's own; on the map the hand's alone, 1,255 of 16 pictures about 3 GB)
              else if (look != null)
                FittedBox(
                  child: CustomPaint(size: const Size(18, 16), painter: look),
                ),
              if (on case final o? when !small) Positioned(left: 3, top: 3, child: DockTag(o, hue: WsT.accent, edge: true)),
              if (same case final why? when !small)
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: DockTag(why, hue: Grey.g63, edge: true),
                ), // (the sample as it is: what it lacks there, or that the inside does not draw it yet)
              if (lost) Positioned(left: 3, bottom: 3, child: DockTag('NOT HERE', hue: Grey.g63, edge: true)),
              if (star case final s? when s.starred(starId ?? name) || h)
                Positioned(
                  right: 0,
                  top: 0,
                  child: DockStar(key: ValueKey('ws-star-${starId ?? name}'), on: s.starred(starId ?? name), onTap: () => s.star(starId ?? name)),
                ),
              if (on != null || picked || h)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: on != null || picked ? WsT.accentInk : Grey.g76, width: on != null || picked ? 2 : 1),
                    ),
                  ),
                ), // (drawn over all, taking no hand: the star under it is pressed)
            ],
          ),
        ),
        if (!small)
          Container(
            height: Shape.z(18),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
            alignment: Alignment.centerLeft,
            color: dockFill(picked, h, WsT.card),
            child:
                naming ??
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(name, maxLines: 1, style: T.micro(dockInk(picked, Grey.g76))),
                ), // (a name wider than its tile is drawn smaller, never cut)
          ),
      ],
    ),
  );
}

/// A tile's picture, its moving ones played there and back at 24 a second while [playing], so it neither steps nor jumps
/// where it starts again (effect_tiles.dart); its still otherwise, and for a picture with none beside it. Keyed by when
/// the file was written: a widget told the same file keeps the picture it had (an equal provider is not resolved again).
class TileMoving extends StatefulWidget {
  const TileMoving(this.file, {super.key, required this.playing});
  final String file;
  final bool playing;
  @override
  State<TileMoving> createState() => TileMovingState();
}

class TileMovingState extends State<TileMoving> {
  static final _way = [for (var k = 0; k < EffectTiles.moments.length; k++) k, for (var k = EffectTiles.moments.length - 2; k > 0; k--) k];
  int? _step;
  Timer? _clock;
  bool _awake = true; // (its tab, its page shown: TickerMode, as an AnimationController's)

  void _follow() {
    final go =
        widget.playing &&
        _awake &&
        File(EffectTiles.frame(widget.file, EffectTiles.moments.length - 1)).existsSync(); // (the last: one drawn with fewer stands until it is drawn again)
    if (go == (_clock != null)) return;
    _clock?.cancel();
    _clock = go
        ? Timer.periodic(
            const Duration(microseconds: 41667),
            (_) => mounted && _inSight() ? setState(() => _step = ((_step ?? EffectTiles.still) + 1) % _way.length) : null,
          )
        : null;
    if (!go) _step = null;
  }

  /// Whether some of it is in sight: within the shelf it scrolls in, and the window (a long shelf's tiles out of it stand still).
  bool _inSight() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    var r = box.localToGlobal(Offset.zero) & box.size;
    if (Scrollable.maybeOf(context)?.context.findRenderObject() case final RenderBox view when view.attached && view.hasSize) {
      r = r.intersect(view.localToGlobal(Offset.zero) & view.size);
    }
    r = r.intersect(Offset.zero & MediaQuery.sizeOf(context));
    return r.width > 0 && r.height > 0;
  }

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _awake = TickerMode.valuesOf(context).enabled;
    _follow();
  }

  @override
  void didUpdateWidget(TileMoving old) {
    super.didUpdateWidget(old);
    _follow();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image.file(
    key: ValueKey(FileStat.statSync(widget.file).modified),
    File(_step == null ? widget.file : EffectTiles.frame(widget.file, _way[_step!])),
    fit: BoxFit.cover,
    cacheWidth: EffectTiles.readWide,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox(),
  );
}

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
      v = m.thingEffects.firstWhere((e) => e.$1 == name).$2,
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

/// What each of the inside's own effects does to a square, drawn small: a blur's soft edge, a shadow under it, a glow
/// round it, a path half drawn, two tones, a ramp of colours. (An effect the window does not know has no picture.)
class _FxLook extends CustomPainter {
  const _FxLook(this.name);
  final String name;
  @override
  void paint(Canvas c, Size s) {
    const ink = Color(0xFFE0A35A), r = Rect.fromLTWH(4, 3, 10, 10);
    switch (name) {
      case 'Gaussian Blur':
        c.drawRect(
          r,
          Paint()
            ..color = ink
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        ); // (soft all round: nothing sharp left)
      case 'Drop Shadow':
        c.drawRect(
          r.shift(const Offset(2, 2)),
          Paint()
            ..color = const Color(0xFF000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
        );
        c.drawRect(r, Paint()..color = ink);
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
      case 'Duotone':
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width / 2, r.height), Paint()..color = const Color(0xFF2B3A67));
        c.drawRect(Rect.fromLTWH(r.center.dx, r.top, r.width / 2, r.height), Paint()..color = const Color(0xFFF4C27A));
      case 'Gradient Map':
        c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF2B3A67), Color(0xFFE0607E), Color(0xFFF4C27A)]).createShader(r));
    }
  }

  @override
  bool shouldRepaint(_FxLook o) => o.name != name;
}
