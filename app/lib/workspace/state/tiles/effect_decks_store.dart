// Storage for the Effects shelf: recent effects, usage log, decks and stars.
import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;

import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/storage/unique_name.dart' show firstFree;

/// Tests point this elsewhere with [effectRecentAt].
String _recentFile = '$homeFolder/.motolii/effect_recent.json';
List<String>? _recent;
void effectRecentAt(String path) => (_recentFile = path, _recent = null);
List<String> effectRecent() =>
    _recent ??= [for (final s in readJsonList(_recentFile)) '$s'];

/// Records that an effect was applied. Also appends to effect_used.jsonl for usage analytics.
void effectUsed(String id, {required String words, required String chip}) {
  final r = effectRecent()
    ..remove(id)
    ..insert(0, id);
  if (r.length > 40) r.removeRange(40, r.length);
  keepText(_recentFile, jsonEncode(r));
  try {
    appendText(
      '${parentFolderOf(_recentFile)}/effect_used.jsonl',
      '${jsonEncode({'at': DateTime.now().toIso8601String(), 'id': id, 'words': words, 'chip': chip})}\n',
    );
  } catch (_) {
    // The log is optional. The recent list stays in memory while the app is open.
  }
}

/// One effect in a deck: shelf [id], [name], and file fingerprint [sum].
/// Identified by content hash, not path, so it survives moves. Empty sum = built-in.
class DeckThing {
  DeckThing(this.id, this.name, this.sum);
  String id;
  final String name, sum;
  Map<String, String> get json => {'id': id, 'name': name, 'sum': sum};
  static DeckThing of(Map j) =>
      DeckThing('${j['id']}', '${j['name']}', '${j['sum'] ?? ''}');
}

/// A user-made set of effects: hand-picked [things] plus optional search [words].
/// [without] excludes effects found by [words] that the user removed by hand.
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

  /// The deck that "Add to Deck" targets. Saved in the decks file but not in a deck code.
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

  /// Toggles an effect. [found]: whether the deck's search words already match it.
  void toggle(String id, String name, {required bool found}) {
    final there =
        !without.contains(id) && (found || things.any((t) => t.id == id));
    things.removeWhere((t) => t.id == id);
    without.remove(id);
    if (there && found) without.add(id);
    if (!there && !found) things.add(DeckThing(id, name, effectSum(id)));
  }
}

/// Tests point this elsewhere with [effectDecksAt].
String _decksFile = '$homeFolder/.motolii/effect_decks.json';
List<EffectDeck>? _decks;
void effectDecksAt(String path) => (_decksFile = path, _decks = null);
List<EffectDeck> effectDecks() => _decks ??= () {
  try {
    return [
      for (final d in (readJsonFile(_decksFile) as Map)['decks'] as List)
        EffectDeck.of(d as Map)..target = d['target'] == true,
    ];
  } catch (_) {
    return <EffectDeck>[];
  }
}();
void effectDecksKeep() {
  keepText(
    _decksFile,
    jsonEncode({
      'decks': [
        for (final d in effectDecks())
          {...d.json, if (d.target) 'target': true},
      ],
    }),
  );
}

/// The deck that "Add to Deck" targets, or null (then Favorites is used).
EffectDeck? effectTarget() => effectDecks().where((d) => d.target).firstOrNull;
void effectTargetSet(EffectDeck? to) {
  for (final d in effectDecks()) {
    d.target = identical(d, to);
  }
  effectDecksKeep();
}

/// A unique deck name: [name], then "name 2" and so on.
String deckName(String name) {
  final held = {for (final d in effectDecks()) d.name},
      base = name.trim().isEmpty ? 'Deck' : name.trim();
  return firstFree(base, held.contains, (k) => '$base $k');
}

/// SHA-256 prefix (12 chars) of the effect's file, or '' if not a file.
String effectSum(String id) {
  try {
    // An id with '#' names one script of a file. The part after '#' is kept.
    final at = id.indexOf('#');
    return sha256
            .convert(readBytes(at < 0 ? id : id.substring(0, at)))
            .toString()
            .substring(0, 12) +
        (at < 0 ? '' : id.substring(at));
  } catch (_) {
    return '';
  }
}

/// Pack name from the aviutl_scripts folder path, or null for standalone effects.
String? effectPack(String id) =>
    RegExp(r'/aviutl_scripts/(?:[^/]*?__)?([^/]+)/').firstMatch(id)?[1];

/// Machine-independent effect id (relative to the bundled shelves folder).
String _place(String id) => id.startsWith('$motoliiShelves/')
    ? id.substring(motoliiShelves.length + 1)
    : id;

/// Encodes a deck as a pasteable string: JSON → gzip → Base64.
const deckCodeHead = 'motolii-deck:';
String deckCode(EffectDeck d) =>
    deckCodeHead +
    base64Url.encode(
      gzipBytes(
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

/// Decodes a deck from a [deckCode] string, or null if invalid.
EffectDeck? deckRead(String line) {
  if (!line.startsWith(deckCodeHead)) return null;
  try {
    return EffectDeck.of(
      jsonDecode(
        utf8.decode(
          gunzipBytes(
            base64Url.decode(line.substring(deckCodeHead.length).trim()),
          ),
        ),
      ) as Map,
    );
  } catch (_) {
    return null;
  }
}

/// Resolves the deck's effect ids against available [ids] by path then by fingerprint.
/// Unresolved effects keep their name and fingerprint for later.
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

/// A test can point this elsewhere with [dockStarsAt].
String _starsFile = '$homeFolder/.motolii/effect_stars.json';
void dockStarsAt(String path) => _starsFile = path;

Set<String> starsRead() => {for (final s in readJsonList(_starsFile)) '$s'};

void starsKeep(Set<String> all) =>
    keepText(_starsFile, jsonEncode(all.toList()));
