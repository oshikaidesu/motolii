// The Effects shelf: all the inside does to a picture, as tiles sorted by what each is for (the inside's labels as
// chips, not who draws it): the effects a thing may be given (picked: its foot puts it on or takes it off), the
// whole-screen effects (on the picked thing as the camera sees it, or on the stage, in their order), the motions.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../tokens.dart';
import 'dock_effect_places.dart';
import 'dock_glyphs.dart';
import 'dock_parts.dart';
import 'dock_resizable.dart';
import 'dock_tags.dart';
import 'effect_decks.dart';
import 'effect_tiles.dart';
import 'ws.dart';
import 'ws_menu.dart';

// (each: what it is told by (a thing's own by its name; a file's by its file: two files may share a name, Halftone's
//  three.js .wgsl and an AviUtl2 script), its name, what it is for, its tile, whether it is on, what two presses do
//  (also what a drop on the stage does), what it says of itself)
typedef _Fx = ({String id, String name, String label, Widget Function(bool small) tile, bool on, VoidCallback apply, String said});

class EffectsShelf extends StatefulWidget {
  const EffectsShelf(this.c, {super.key});
  final DockCtx c;

  /// The files' effects by their names, as After Effects' Effects & Presets lists each kind: the inside gives them by
  /// file, so VIDVOX's capitals came before AbsentMotion's am_ files, two runs of A to Z (golf_noise.md ㊾). Once a shelf.
  static final _byName = Expando<List<(String, String)>>();

  @override
  State<EffectsShelf> createState() => _EffectsShelfState();
}

class _EffectsShelfState extends State<EffectsShelf> {
  final _menu = GlobalKey<WsMenuState>(), _places = GlobalKey<EffectPlacesState>();
  DockCtx get c => widget.c;

  @override
  Widget build(BuildContext context) {
    final ws = c.ws, m = ws.inside;
    if (m == null) return DockEmpty(c.query);
    final on = ws.fxOf(ws.selected), screen = ws.screenFx, picked = int.tryParse(ws.selected ?? '') != null;
    // (a thing's own effects and motions go on a picked thing only; the whole-screen ones on it, or on the stage)
    // (put on with words typed: latched to them, the first for them next time, golf (94))
    VoidCallback chosen(String id, VoidCallback put, {bool taken = false}) {
      final VoidCallback go = () {   // (a closure of its own, not a declaration's tear-off: what a carried tile is told by)
        DockTags.latch('Effects', c.query, id);
        if (!taken) c.set(() => effectUsed(id, words: c.query, chip: c.chip));
        put();
      };
      carriedEffect[go] = id;
      return go;
    }
    final every = <_Fx>[
      if (picked)
        for (final (n, _) in m.thingEffects)
          (id: n, name: n, label: m.label(n), on: on.contains(n), apply: chosen(n, () => ws.fxToggle(n), taken: on.contains(n)), said: _said(ws, n),
           tile: (small) => EffectTile(n, small: small, file: m.picture(n), look: _FxLook(n), on: on.contains(n) ? 'ON' : null, picked: c.sel == n, onTap: () => c.pick(n), onApply: chosen(n, () => ws.fxToggle(n), taken: on.contains(n)), star: small ? null : c)),
      for (final (n, f) in EffectsShelf._byName[m.effects] ??= ([...m.effects]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))))
        (id: f, name: n, label: m.label(n), on: screen.contains(f), apply: chosen(f, () => ws.screenToggle(f), taken: screen.contains(f)), said: m.about(f).isEmpty ? (picked ? 'On the picked thing' : 'On all under it') : m.about(f),
         tile: (small) => EffectTile(n, key: small ? null : ValueKey('ws-screen-$f'), small: small, file: m.picture(f), same: m.tileSame(f), on: screen.contains(f) ? 'ON ${screen.indexOf(f) + 1}' : null, picked: c.sel == f, onTap: () => c.pick(f), onApply: chosen(f, () => ws.screenToggle(f), taken: screen.contains(f)), star: small ? null : c, starId: f)),
      if (picked)   // (a look kept by its name, Save Look: given to the picked thing, its values, effects and keys)
        for (final (n, f) in m.looks)
          (id: f, name: n, label: 'Look', on: false, apply: chosen(f, () => ws.after(m.later('paste_style', thing: int.parse(ws.selected!), word: f))), said: 'A look for the picked thing',
           tile: (small) => EffectTile(n, key: small ? null : ValueKey('ws-look-$n'), small: small, file: m.picture(f), on: null, picked: c.sel == f, onTap: () => c.pick(f), onApply: chosen(f, () => ws.after(m.later('paste_style', thing: int.parse(ws.selected!), word: f))), star: small ? null : c, starId: f)),
      if (picked)
        for (final (n, f) in m.animators)
          (id: f, name: n, label: 'Motion', on: ws.motion == f, apply: chosen(f, () => ws.motionToggle(f), taken: ws.motion == f), said: 'A motion for the picked thing',
           tile: (small) => EffectTile(n, key: small ? null : ValueKey('ws-motion-$n'), small: small, on: ws.motion == f ? 'ON' : null, picked: c.sel == f, onTap: () => c.pick(f), onApply: chosen(f, () => ws.motionToggle(f), taken: ws.motion == f))),
    ];
    // (by its name, or by what it does in its maker's words, as Alight Motion's search reads the descriptions; when that
    //  finds nothing, a word typed wrong or in part, the nearest five by RapidFuzz (the inside's find, the user's choice),
    //  as a search engine's "Did you mean" comes when the words as typed find nothing)
    // (and by what it is, read from it, as the other shelves' tags are found: DockTags, each word on its own; golf (92))
    Set<String> tagsOf(String id) => DockTags.of('Effects', id, m.tags(id));
    bool found(String q, _Fx e) => q.isEmpty || e.name.toLowerCase().contains(q.toLowerCase()) || m.about(e.id).toLowerCase().contains(q.toLowerCase()) || DockTags.hit(q, e.name, tagsOf(e.id));
    final hits = [for (final e in every) if (c.hit(e.name) || (c.query.isNotEmpty && found(c.query, e))) e], hit = {for (final e in hits) e.id};
    final near = c.query.trim().isEmpty || hits.isNotEmpty ? const <String>[] : m.find(c.query, [for (final e in every) if (!hit.contains(e.id)) (e.id, '${e.name} ${e.label}', m.about(e.id))]);
    final first = DockTags.latched('Effects', c.query), latched = every.where((e) => e.id == first).take(1).toList();
    final all = [...latched, for (final e in hits) if (e.id != first) e, for (final id in near) if (id != first) ...every.where((e) => e.id == id).take(1)];
    final byId = {for (final e in all) e.id: e}, recent = [for (final id in effectRecent()) ?byId[id]];
    // (the decks: what the hand put in and what their words find, as one bundle (EffectDeck))
    final decks = effectDecks(), deckIds = {for (final d in decks) d: {...d.things.map((t) => t.id), for (final e in all) if (d.words.isNotEmpty && found(d.words, e)) e.id}.difference(d.without)};
    final used = ws.fxUsed, packs = <String, int>{};
    for (final e in every) {
      if (effectPack(e.id) case final p?) packs[p] = (packs[p] ?? 0) + 1;
    }
    packs.removeWhere((_, n) => n < 2);   // (in the window most folders held one: one effect is no bundle)
    final deck = decks.where((d) => '@${d.name}' == c.mem.fxPlace).firstOrNull;
    final place = deck != null || !c.mem.fxPlace.startsWith('@') ? c.mem.fxPlace : 'All', pack = place.startsWith('/') ? place.substring(1) : null;
    // (the last put on the newest first, the Fonts shelf's Recent, as Alight Motion keeps forty, EffectBrowser.kt:117)
    final here = place == 'Recent' ? recent : [for (final e in all) if (switch (place) {
      '★' => c.starred(e.id),
      'In video' => used.contains(e.id),
      _ when deck != null => deckIds[deck]!.contains(e.id),
      _ when pack != null => effectPack(e.id) == pack,
      _ => true,
    }) e];
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
    final tagChips = [for (final t in (read.entries.where((t) => t.key != 'transition').toList()..sort((a, b) => b.value.compareTo(a.value))).take(8)) MapEntry('#${t.key}', t.value)];
    final chip = kinds.containsKey(c.chip) || tagChips.any((t) => t.key == c.chip) ? c.chip : 'All';
    final shown = [for (final e in here) if (chip == 'All' || (chip.startsWith('#') ? tagsOf(e.id).contains(chip.substring(1)) : e.label == chip)) e];
    // (one a deck holds and the shelf does not: its name kept, marked; not an effect of a thing, which waits for a thing)
    final known = {...every.map((e) => e.id), ...m.thingEffects.map((e) => e.$1), ...m.looks.map((e) => e.$2), ...m.animators.map((e) => e.$2)};
    if (deck != null && deck.things.any((t) => !known.contains(t.id))) deckSettle(deck, known);
    final lost = <_Fx>[
      if (deck != null && c.query.isEmpty)
        for (final t in deck.things) if (!known.contains(t.id))
          (id: t.id, name: t.name, label: 'Not here', on: true, said: 'Not on this machine', apply: () => c.set(() {
            deck.things.remove(t);
            effectDecksKeep();
          }), tile: (bool small) => EffectTile(t.name, lost: true, on: null, picked: c.sel == t.id, onTap: () => c.pick(t.id))),
    ];
    // (ten in sight over the tiles while nothing narrows them, as Alight Motion's effect browser opens on its last ten,
    //  EffectBrowser.kt:217: a list out of sight is not gone back to, Bergman's bookmarks, 32 of 41 by the bar always in sight)
    final inSight = place == 'All' && chip == 'All' && c.query.isEmpty ? recent.take(10).toList() : const <_Fx>[];
    final listed = [...shown, ...lost];
    void put(EffectDeck d, _Fx e) => c.set(() {
      d.toggle(e.id, e.name, found: d.words.isNotEmpty && found(d.words, e));
      effectDecksKeep();
    });
    // (what is done to an effect is on the effect, by a right click or by the foot's three dots: Add to Playlist's list of
    //  playlists with New at its end, Spotify's and YouTube's Save; Ableton's right click on an item; Go to Album)
    void menuOn(_Fx e, Offset at) {
      final box = _menu.currentContext?.findRenderObject() as RenderBox?;
      _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
        WsMenuItem(e.on ? 'Remove' : 'Add', e.apply),
        WsMenuItem(c.starred(e.id) ? 'Remove from Favorites' : 'Add to Favorites', () => c.star(e.id)),
        const WsMenuItem.rule(),
        for (final d in decks) WsMenuItem(d.name, () => put(d, e), keys: deckIds[d]!.contains(e.id) ? '✓' : ''),
        WsMenuItem('New Deck…', () => _places.currentState?.newDeck(thing: DeckThing(e.id, e.name, effectSum(e.id)))),
        if (effectPack(e.id) case final p? when packs.containsKey(p)) ...[const WsMenuItem.rule(), WsMenuItem('Go to Pack: $p', () => c.set(() => c.mem.fxPlace = '/$p'))],
      ]);
    }
    Widget tile(_Fx e, bool small) => GestureDetector(onSecondaryTapDown: (d) => menuOn(e, d.globalPosition), child: e.tile(small));
    final list = EffectPlaces(c, key: _places, known: known, packs: Map.fromEntries(packs.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))), counts: {'All': all.length, 'Recent': recent.length, '★': all.where((e) => c.starred(e.id)).length, 'In video': all.where((e) => used.contains(e.id)).length}, decks: {for (final d in decks) d: deckIds[d]!.intersection(byId.keys.toSet()).length}, put: (d, id) {
      if (!deckIds[d]!.contains(id)) put(d, every.firstWhere((e) => e.id == id));
    });
    final sel = c.foot([...all, ...lost].where((e) => e.id == c.sel).firstOrNull);
    final tiles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DockChips([('All', here.length), for (final t in tagChips) (t.key, t.value), for (final k in kinds.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) (k.key, k.value)], active: chip, onPick: c.pickChip),   // (the tags read first, as Shadertoy's filters head its results: the kinds are many, a hundred and more, the most first as the tags)
        if (inSight.isNotEmpty)
          GridView.count(
            key: const ValueKey('ws-fx-recent'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: WsT.gutter, bottom: WsT.gutter),
            crossAxisCount: 5,
            crossAxisSpacing: WsT.gutter,
            mainAxisSpacing: WsT.gutter,
            children: [for (var i = 0; i < (inSight.length > 5 ? 10 : 5); i++) i < inSight.length ? tile(inSight[i], true) : const SizedBox()],   // (as Alight Motion's box of two rows; one until a sixth: in the window a row with one tile stood empty over the shelf)
          ),
        Expanded(
          child: listed.isEmpty
              ? DockEmpty(c.query, said: c.query.isNotEmpty ? null : deck != null ? 'Drag an effect onto the deck, or right-click one' : 'Nothing here yet')
              : LayoutBuilder(
                  builder: (context, box) {
                    final cols = wsCols(box.maxWidth, Shape.z(84)), w = wsCell(box.maxWidth, cols);
                    return GridView.builder(   // (only the tiles in sight are made, Flutter's own lazy grid, as the Fonts shelf's rows: a Wrap made all 1,293 at each opening)
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: WsT.gutter, mainAxisSpacing: WsT.gutter, mainAxisExtent: w + Shape.z(18)),   // (a tile: its square and its name, EffectTile)
                      itemCount: listed.length,
                      itemBuilder: (context, i) => tile(listed[i], false),
                    );
                  },
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
            child: LayoutBuilder(   // (as the Media shelf's tree: beside the tiles by the room, over them with its height the hand's)
              builder: (context, box) => box.maxWidth >= 440
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: Shape.z(160), child: list),
                        ColoredBox(color: WsT.ground, child: SizedBox(width: WsT.gutter)),
                        Expanded(child: tiles),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DockResizable(height: c.mem.fxListHeight, min: 44, max: box.maxHeight - 160, reset: dockFxListHeight, gripKey: const ValueKey('ws-fx-list-grip'), onHeight: (h) => c.set(() => c.mem.fxListHeight = h), child: list),
                        Expanded(child: tiles),
                      ],
                    ),
            ),
          ),
          if (sel != null && m.picture(sel.id).isNotEmpty)   // (its pictures large and moving, as Alight Motion's effect browser opens a large moving sample of the one pressed)
            SizedBox(key: const ValueKey('ws-fx-preview'), height: Shape.z(140), child: TileMoving(m.picture(sel.id), playing: true)),
          if (sel != null) _FxFooter(sel.name, kind: sel.label, said: sel.said, done: sel.on, ws: ws, onAction: sel.apply, needs: !picked, more: Builder(builder: (b) => DockIconButton(DockG.more, key: const ValueKey('ws-fx-more'), onTap: () => menuOn(sel, (b.findRenderObject() as RenderBox).localToGlobal(Offset.zero))))),   // (none picked: a file's goes on a board of its own, one of a thing's waits for a thing)
        ],
      ),
    );
  }
}

/// One tile, whatever draws it: what it does to a sample (the picture the inside says, drawn by effect_tiles.dart and
/// moving while the hand is on it, as Alight Motion's tiles move; or made by engine/fx_tiles.sh; without one, a thing's
/// effect its small drawing, else a plain tile), its name, ON (and its place among those on the stage) when it is on,
/// NO CHANGE when it is seen to change nothing on the sample, the star for a thing's effect.
class EffectTile extends StatelessWidget {
  const EffectTile(this.name, {super.key, this.file, this.look, required this.on, required this.onTap, this.onApply, this.picked = false, this.same = false, this.star, this.starId, this.naming, this.small = false, this.lost = false});
  final String name;
  final bool small;   // (its square alone, among the last put on: no name, no tags; the foot says which)
  final bool lost;   // (a deck holds it, this machine does not)
  final Widget? naming;   // (where its name is being written, in its place)
  final String? file, on;
  final CustomPainter? look;
  final bool picked, same;
  final VoidCallback onTap;
  final VoidCallback? onApply;   // (two presses: it is put on, or taken off)
  final DockCtx? star;
  final String? starId;   // (what it is starred by: a file's effect by its file, two files may share a name)
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    onDoubleTap: onApply,
    picks: true,
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
                TileMoving(f, playing: h)
              else if (look != null)
                FittedBox(child: CustomPaint(size: const Size(18, 16), painter: look)),
              if (on case final o? when !small) Positioned(left: 3, top: 3, child: DockTag(o, hue: WsT.accent, edge: true)),
              if (same && !small) Positioned(left: 3, bottom: 3, child: DockTag('NO CHANGE', hue: Grey.g63, edge: true)),   // (the sample as it is: its defaults show nothing on a photo, or it helps other scripts)
              if (lost) Positioned(left: 3, bottom: 3, child: DockTag('NOT HERE', hue: Grey.g63, edge: true)),
              if (star case final s? when s.starred(starId ?? name) || h) Positioned(right: 0, top: 0, child: DockStar(key: ValueKey('ws-star-${starId ?? name}'), on: s.starred(starId ?? name), onTap: () => s.star(starId ?? name))),
              if (on != null || picked || h) IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: on != null || picked ? WsT.accentInk : Grey.g76, width: on != null || picked ? 2 : 1)))),   // (drawn over all, taking no hand: the star under it is pressed)
            ],
          ),
        ),
        if (!small) Container(
          height: Shape.z(18),
          padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
          alignment: Alignment.centerLeft,
          color: dockFill(picked, h, WsT.card),
          child: naming ?? FittedBox(fit: BoxFit.scaleDown, child: Text(name, maxLines: 1, style: T.micro(dockInk(picked, Grey.g76)))), // (a name wider than its tile is drawn smaller, never cut)
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

  void _follow() {
    final go = widget.playing && File(EffectTiles.frame(widget.file, EffectTiles.moments.length - 1)).existsSync();   // (the last: one drawn with fewer stands until it is drawn again)
    if (go == (_clock != null)) return;
    _clock?.cancel();
    _clock = go ? Timer.periodic(const Duration(microseconds: 41667), (_) => mounted ? setState(() => _step = ((_step ?? EffectTiles.still) + 1) % _way.length) : null) : null;
    if (!go) _step = null;
  }

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) => Image.file(key: ValueKey(FileStat.statSync(widget.file).modified), File(_step == null ? widget.file : EffectTiles.frame(widget.file, _way[_step!])), fit: BoxFit.cover, cacheWidth: EffectTiles.readWide, gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox());
}

/// Joined: the document's value an effect is, and what the picked thing has for it now.
String _said(Ws ws, String name) {
  final m = ws.inside!, v = m.thingEffects.firstWhere((e) => e.$1 == name).$2, t = int.tryParse(ws.selected ?? ''); // (the shelf shows only what the inside does)
  final now = t == null ? '' : m.word(t, v);
  return now.isEmpty ? '$v · none on it' : '$v · $now';
}

/// The foot: the picked effect, what it is for and what it does, and Add (or Remove): one press picks, two put it on.
class _FxFooter extends StatelessWidget {
  const _FxFooter(this.name, {required this.kind, required this.said, required this.ws, required this.done, required this.onAction, required this.needs, required this.more});
  final String name, kind, said;
  final Ws ws;
  final bool done, needs;   // (needs: an effect of a thing, with no thing picked)
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
        c.drawRect(r, Paint()
          ..color = ink
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)); // (soft all round: nothing sharp left)
      case 'Drop Shadow':
        c.drawRect(r.shift(const Offset(2, 2)), Paint()
          ..color = const Color(0xFF000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
        c.drawRect(r, Paint()..color = ink);
      case 'Trim Paths':
        c.drawArc(Rect.fromCircle(center: r.center, radius: 5.5), -1.6, 3.8, false, Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
      case 'Move Along Path':
        c.drawArc(Rect.fromCircle(center: r.center, radius: 5.5), -1.6, 3.8, false, Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
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
