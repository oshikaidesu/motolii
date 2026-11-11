// What the Effects shelf lists. The entries are the shelf's effects as plain data (a tile to draw, whether it is on, what a press does); effectListing
// is the pure part of the shelf: from the entries, the search words, the place, the chip and the decks it works out what is shown, in what order,
// and the counts the places and chips display. It draws nothing and changes nothing.
import 'package:motolii/workspace/shelf/tile_moving.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/state/effects.dart';

/// One effect tile of the shelf. The id is a layer effect's name or a file effect's file, since two files can share a name.
/// The label says what it is for, [on] whether it is applied, `apply` what a double-click or a drop on the stage does.
typedef EffectEntry = ({
  String id,
  String name,
  String label,
  Widget Function(bool small, ValueChanged<Offset>? menu) tile,
  bool on,
  VoidCallback apply,
  String said,
});

/// What the shelf shows for its search words, place and chip: every field is read straight from [effectListing].
class EffectListing {
  const EffectListing({
    required this.found,
    required this.all,
    required this.byId,
    required this.recent,
    required this.decks,
    required this.deckIds,
    required this.used,
    required this.packs,
    required this.deck,
    required this.place,
    required this.building,
    required this.here,
    required this.kinds,
    required this.tagChips,
    required this.chip,
    required this.shown,
    required this.known,
  });

  /// Whether an effect matches the words: its name, its description or its tags.
  final bool Function(String words, EffectEntry e) found;

  /// Every effect that matches the search, the latched one first, then the nearest ones when nothing matches.
  final List<EffectEntry> all;
  final Map<String, EffectEntry> byId;

  /// The recently applied ones that match, newest first.
  final List<EffectEntry> recent;

  /// The decks, and the ids each one holds (what was put in, then what its words find).
  final List<EffectDeck> decks;
  final Map<EffectDeck, Set<String>> deckIds;

  /// The ids of the effects in the video, and the number of effects in each pack.
  final Set<String> used;
  final Map<String, int> packs;

  /// The deck the place names, if it names one, and the place itself ('All', 'Recent', '★', 'In video', '@deck' or '/pack').
  final EffectDeck? deck;
  final String place;

  /// Whether a deck is being built on the map, where every effect is listed whatever the place.
  final bool building;

  /// The effects of the place, the counts of their kinds and tags for the chips, the chip in force, and the effects it leaves.
  final List<EffectEntry> here, shown;
  final Map<String, int> kinds;
  final List<MapEntry<String, int>> tagChips;
  final String chip;

  /// Every id the shelf knows now: effects, layer effects, presets and animators.
  final Set<String> known;
}

/// Works out what the Effects shelf shows. [every] is all of its effects, [seen] what the engine said about each by id.
EffectListing effectListing({
  required ShelfContext c,
  required ShelfTags tags,
  required List<EffectEntry> every,
  required Map<String, ShelfItem> seen,
}) {
  final ws = c.ws, m = ws.inside!;
  // Search matches the name, or what the effect does in its author's words, as Alight Motion's search reads descriptions.
  // It also matches the tags read from the effect (ShelfTags), each word on its own.
  // When nothing matches, as for a misspelt or partial word, the nearest five by RapidFuzz are shown, like "Did you mean".
  Set<String> tagsOf(String id) =>
      tags.of('Effects', id, seen[id]?.tags ?? const {});
  bool found(String q, EffectEntry e) =>
      q.isEmpty ||
      e.name.toLowerCase().contains(q.toLowerCase()) ||
      (seen[e.id]?.about ?? '').toLowerCase().contains(q.toLowerCase()) ||
      ShelfTags.hit(q, e.name, tagsOf(e.id));
  final hits = [
        for (final e in every)
          if (c.hit(e.name) || (c.query.isNotEmpty && found(c.query, e))) e,
      ],
      hit = {for (final e in hits) e.id};
  final near = c.query.trim().isEmpty || hits.isNotEmpty
      ? const <String>[]
      : m.find(c.query, [
          for (final e in every)
            if (!hit.contains(e.id))
              (e.id, '${e.name} ${e.label}', (seen[e.id]?.about ?? '')),
        ]);
  final first = tags.latched('Effects', c.query),
      latched = every.where((e) => e.id == first).take(1).toList();
  final all = [
    ...latched,
    for (final e in hits)
      if (e.id != first) e,
    for (final id in near)
      if (id != first) ...every.where((e) => e.id == id).take(1),
  ];
  final byId = {for (final e in all) e.id: e},
      recent = [for (final id in effectRecent()) ?byId[id]];
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
  final place = deck != null || !c.mem.fxPlace.startsWith('@')
          ? c.mem.fxPlace
          : 'All',
      pack = place.startsWith('/') ? place.substring(1) : null;
  // On the map, the map shows all effects and the selected deck sits beside it to add and remove effects, like Hearthstone's
  // Collection Manager. Elsewhere a deck shows what it holds as tiles.
  final building =
      c.mem.mapped.contains('Effects') && (deck != null || place == '★');
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
  // Tags read from the effects, most common first, as the Fonts shelf's tag chips do (fonts/fonts_shelf.dart).
  // Each shows the # that is typed to search for it (ShelfTags). A kind with the same word is a different thing:
  // VIDVOX's Feedback kind is not the feedback passes read from the shader.
  // "transition" is left out because the Transition kind is read the same way (isf.cpp). Shadertoy's filters are read from the shaders.
  final tagChips = [
    for (final t
        in (read.entries.where((t) => t.key != 'transition').toList()
          ..sort((a, b) => b.value.compareTo(a.value))))
      MapEntry('#${t.key}', t.value),
  ]; // Most common first; the row scrolls, since all the kinds follow it.
  final chip = kinds.containsKey(c.chip) || tagChips.any((t) => t.key == c.chip)
      ? c.chip
      : 'All';
  final shown = [
    for (final e in here)
      if (chip == 'All' ||
          (chip.startsWith('#')
              ? tagsOf(e.id).contains(chip.substring(1))
              : e.label == chip))
        e,
  ];
  // An effect the deck holds but the shelf does not: its name is kept and marked. Layer effects are excluded, since they wait for a layer.
  final known = {
    ...every.map((e) => e.id),
    ...m.layerEffects.map((e) => e.$1),
    ...m.presets.map((e) => e.$2),
    ...m.animators.map((e) => e.$2),
  };
  return EffectListing(
    found: found,
    all: all,
    byId: byId,
    recent: recent,
    decks: decks,
    deckIds: deckIds,
    used: used,
    packs: packs,
    deck: deck,
    place: place,
    building: building,
    here: here,
    kinds: kinds,
    tagChips: tagChips,
    chip: chip,
    shown: shown,
    known: known,
  );
}
