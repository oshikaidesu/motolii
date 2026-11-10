// Storage for the Effects shelf: recently used effects, a log of what was applied, and the decks.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;

import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/storage/unique_name.dart' show firstFree;
import 'package:motolii/storage/json_file.dart'
    show fileJson, fileKeep, fileList;

/// The file of recently used effects, newest first, at most forty, as Alight Motion's effect browser keeps them
/// (EffectBrowser.kt:117). It is stored like the Fonts shelf's font_recent.json. Tests point it elsewhere with
/// [effectRecentAt].
File _recentFile = File(
  '${Platform.environment['HOME']}/.motolii/effect_recent.json',
);
List<String>? _recent;
void effectRecentAt(File f) => (_recentFile = f, _recent = null);
List<String> effectRecent() =>
    _recent ??= [for (final s in fileList(_recentFile)) '$s'];

/// Records that an effect was applied.
///
/// The effect moves to the front of the recent list. A line is also appended to effect_used.jsonl beside it, one JSON
/// object per line, as JSON Lines logs do. It holds the time, the effect [id], the search [words] typed and the [chip]
/// (table) it was picked from, so browsing and searching can be counted.
void effectUsed(String id, {required String words, required String chip}) {
  final r = effectRecent()
    ..remove(id)
    ..insert(0, id);
  if (r.length > 40) r.removeRange(40, r.length);
  fileKeep(_recentFile, jsonEncode(r));
  try {
    File('${_recentFile.parent.path}/effect_used.jsonl').writeAsStringSync(
      '${jsonEncode({'at': DateTime.now().toIso8601String(), 'id': id, 'words': words, 'chip': chip})}\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // The log is optional. The recent list stays in memory while the app is open.
  }
}

/// One effect in a deck: its shelf [id], its [name], and a fingerprint [sum] of its file.
///
/// The fingerprint is empty for effects built into the engine. A deck identifies an effect by what it is, not by where
/// the file lies. Modrinth's .mrpack holds each file's hash, and a font manager's collection waits for a font that is
/// gone (FontBase). A name alone is not enough, as Figma's swap and Hearthstone's Core cards show: 54 names on this
/// shelf belong to two effects.
class DeckThing {
  DeckThing(this.id, this.name, this.sum);
  String id;
  final String name, sum;
  Map<String, String> get json => {'id': id, 'name': name, 'sum': sum};
  static DeckThing of(Map j) =>
      DeckThing('${j['id']}', '${j['name']}', '${j['sum'] ?? ''}');
}

/// A deck of effects made by the user, like Ableton's Collections or Suitcase's sets.
///
/// There can be any number of decks, and an effect can be in several. A deck holds the effects the user added by hand
/// and, optionally, search [words] that find more. A hand-picked list alone never picks up new effects, and a saved
/// search alone cannot be adjusted by hand, so a deck has both, as Lightroom's collections and smart collections do.
/// [without] holds the effects that the words find but the user removed.
class EffectDeck {
  EffectDeck(
    this.name, {
    this.words = '',
    List<DeckThing>? things,
    Set<String>? without,
  }) : things = things ?? [],
       without = without ?? {};
  String name, words;
  final List<DeckThing> things;
  final Set<String> without;

  /// Whether this is the deck that an effect's context menu adds to. It is saved in the decks file but not in a deck code.
  bool target = false;
  Map<String, Object> get json => {
    'name': name,
    'words': words,
    'things': [for (final t in things) t.json],
    'without': without.toList(),
  };
  static EffectDeck of(Map j) => EffectDeck(
    '${j['name']}',
    words: '${j['words'] ?? ''}',
    things: [
      for (final t in j['things'] as List? ?? const []) DeckThing.of(t as Map),
    ],
    without: {for (final s in j['without'] as List? ?? const []) '$s'},
  );

  /// Adds the effect to the deck or removes it by hand. [found] tells whether the deck's words find it.
  void toggle(String id, String name, {required bool found}) {
    final there =
        !without.contains(id) && (found || things.any((t) => t.id == id));
    things.removeWhere((t) => t.id == id);
    without.remove(id);
    if (there && found) without.add(id);
    if (!there && !found) things.add(DeckThing(id, name, effectSum(id)));
  }
}

/// The file that stores the decks, like the Colors shelf's palettes. Tests point it elsewhere with [effectDecksAt].
File _decksFile = File(
  '${Platform.environment['HOME']}/.motolii/effect_decks.json',
);
List<EffectDeck>? _decks;
void effectDecksAt(File f) => (_decksFile = f, _decks = null);
List<EffectDeck> effectDecks() => _decks ??= () {
  try {
    return [
      for (final d in (fileJson(_decksFile) as Map)['decks'] as List)
        EffectDeck.of(d as Map)..target = d['target'] == true,
    ];
  } catch (_) {
    return <EffectDeck>[];
  }
}();
void effectDecksKeep() {
  fileKeep(
    _decksFile,
    jsonEncode({
      'decks': [
        for (final d in effectDecks())
          {...d.json, if (d.target) 'target': true},
      ],
    }),
  );
}

/// The deck that an effect's context menu adds to, or null when none is set (then the Favorites are used).
///
/// Lightroom Classic's Add to Target Collection (B) works the same way: it uses the collection set as the target, or the
/// Quick Collection until one is.
EffectDeck? effectTarget() => effectDecks().where((d) => d.target).firstOrNull;
void effectTargetSet(EffectDeck? to) {
  for (final d in effectDecks()) {
    d.target = identical(d, to);
  }
  effectDecksKeep();
}

/// A deck name no other deck has: [name], then "name 2" and so on, as Finder names a copy.
String deckName(String name) {
  final held = {for (final d in effectDecks()) d.name},
      base = name.trim().isEmpty ? 'Deck' : name.trim();
  return firstFree(base, held.contains, (k) => '$base $k');
}

/// The fingerprint of an effect's file: the first twelve characters of its SHA-256 (package:crypto), or '' if the id is not a file.
String effectSum(String id) {
  try {
    // An id with '#' names one script of a file. The part after '#' is kept.
    final at = id.indexOf('#');
    return sha256
            .convert(File(at < 0 ? id : id.substring(0, at)).readAsBytesSync())
            .toString()
            .substring(0, 12) +
        (at < 0 ? '' : id.substring(at));
  } catch (_) {
    return '';
  }
}

/// The name of the pack an effect came in: the folder under aviutl_scripts ('author__pack'), without the author part.
/// Null for an effect that came alone.
String? effectPack(String id) =>
    RegExp(r'/aviutl_scripts/(?:[^/]*?__)?([^/]+)/').firstMatch(id)?[1];

/// An effect id relative to the shelves folder that ships with the app, so it is the same on any machine.
String _place(String id) => id.startsWith('$motoliiShelves/')
    ? id.substring(motoliiShelves.length + 1)
    : id;

/// Encodes a deck as one line of text that can be pasted anywhere, as a Hearthstone deck code is pasted into a forum
/// or a video description.
///
/// It holds the effects' names and fingerprints and the excluded effects, because every shared set refers to its
/// programs by name (.mrpack, Nexus Collections, ReShade's presets). The format is JSON, gzipped, then Base64 for URLs.
const deckCodeHead = 'motolii-deck:';
String deckCode(EffectDeck d) =>
    deckCodeHead +
    base64Url.encode(
      gzip.encode(
        utf8.encode(
          jsonEncode({
            ...d.json,
            'things': [
              for (final t in d.things) {...t.json, 'id': _place(t.id)},
            ],
            'without': [for (final s in d.without) _place(s)],
          }),
        ),
      ),
    );

/// Decodes a deck from a line made by [deckCode], or returns null when the line is not a deck code.
EffectDeck? deckRead(String line) {
  if (!line.startsWith(deckCodeHead)) return null;
  try {
    return EffectDeck.of(
      jsonDecode(
        utf8.decode(
          gzip.decode(
            base64Url.decode(line.substring(deckCodeHead.length).trim()),
          ),
        ),
      ) as Map,
    );
  } catch (_) {
    return null;
  }
}

/// Points the deck's effects at the effects on this shelf, given their [ids].
///
/// An effect matches by the same place, otherwise by the same fingerprint. One that matches neither way stays as it came,
/// with its name and fingerprint kept for the day it appears, as Hearthstone keeps a card the player lacks in a pasted
/// deck. A ReShade preset, by contrast, forgets effects it could not load when it is saved.
void deckSettle(EffectDeck d, Set<String> ids) {
  final at = {for (final id in ids) _place(id): id};
  Map<String, String>? sums;
  for (final t in d.things) {
    if (ids.contains(t.id)) continue;
    final here =
        at[_place(t.id)] ??
        (t.sum.isEmpty
            ? null
            : (sums ??= {for (final id in ids) effectSum(id): id})[t.sum]);
    if (here != null) t.id = here;
  }
  final out = {for (final s in d.without) at[_place(s)] ?? s};
  d.without
    ..clear()
    ..addAll(out);
}
