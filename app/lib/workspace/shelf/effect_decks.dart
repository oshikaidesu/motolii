// What the hand keeps of the Effects shelf: the effects put on lately, what was typed and where as each went on, the decks.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;

import '../../engine/motolii.dart' show motoliiShelves;

/// Where the effects put on lately are kept, the newest first, forty, as Alight Motion's effect browser keeps them
/// (EffectBrowser.kt:117), in the Fonts shelf's way (font_recent.json; a test points it elsewhere: [effectRecentAt]).
File _recentFile = File('${Platform.environment['HOME']}/.motolii/effect_recent.json');
List<String>? _recent;
void effectRecentAt(File f) => (_recentFile = f, _recent = null);
List<String> effectRecent() => _recent ??= () {
  try {
    return [for (final s in jsonDecode(_recentFile.readAsStringSync()) as List) '$s'];
  } catch (_) {
    return <String>[];
  }
}();

/// An effect went on: it comes first among the recent, and a line is added to effect_used.jsonl beside them (one JSON
/// object a line, JSON Lines' way of a log that only grows): when, which, the words typed and the table it was picked
/// from, so what was looked over and what was searched for can be counted.
void effectUsed(String id, {required String words, required String chip}) {
  final r = effectRecent()
    ..remove(id)
    ..insert(0, id);
  if (r.length > 40) r.removeRange(40, r.length);
  try {
    _recentFile.parent.createSync(recursive: true);
    _recentFile.writeAsStringSync(jsonEncode(r));
    File('${_recentFile.parent.path}/effect_used.jsonl').writeAsStringSync('${jsonEncode({'at': DateTime.now().toIso8601String(), 'id': id, 'words': words, 'chip': chip})}\n', mode: FileMode.append);
  } catch (_) {}   // (not kept: known while the window is open)
}

/// One effect in a deck: what the shelf tells it by here, its name, and a fingerprint of its file (none for one of the
/// inside's own), so that a deck knows it by what it is, not by where it lay: Modrinth's .mrpack holds each file's hash,
/// a font manager's collection waits for a font that is gone (FontBase), a name alone fails (Figma's swap, Hearthstone's
/// Core cards; 54 names on this shelf are held by two effects).
class DeckThing {
  DeckThing(this.id, this.name, this.sum);
  String id;
  final String name, sum;
  Map<String, String> get json => {'id': id, 'name': name, 'sum': sum};
  static DeckThing of(Map j) => DeckThing('${j['id']}', '${j['name']}', '${j['sum'] ?? ''}');
}

/// One deck, the maker's own, any number of them, an effect in as many as it likes (Ableton's Collections, Suitcase's
/// sets). Each holds what was put in by hand and, if it has them, the words it finds by: a hand's bundle alone meets
/// nothing new, a saved search alone takes no hand (Lightroom's collection and smart collection, Ableton's Add Label,
/// each of them two kinds of thing). [without]: what its words find and the hand took out.
class EffectDeck {
  EffectDeck(this.name, {this.words = '', List<DeckThing>? things, Set<String>? without}) : things = things ?? [], without = without ?? {};
  String name, words;
  final List<DeckThing> things;
  final Set<String> without;
  bool target = false;   // (the one an effect's right click puts in: kept in the file, never in a deck code)
  Map<String, Object> get json => {'name': name, 'words': words, 'things': [for (final t in things) t.json], 'without': without.toList()};
  static EffectDeck of(Map j) => EffectDeck('${j['name']}', words: '${j['words'] ?? ''}', things: [for (final t in j['things'] as List? ?? const []) DeckThing.of(t as Map)], without: {for (final s in j['without'] as List? ?? const []) '$s'});

  /// Put in, or taken out, by hand; [found]: its words find it.
  void toggle(String id, String name, {required bool found}) {
    final there = !without.contains(id) && (found || things.any((t) => t.id == id));
    things.removeWhere((t) => t.id == id);
    without.remove(id);
    if (there && found) without.add(id);
    if (!there && !found) things.add(DeckThing(id, name, effectSum(id)));
  }
}

/// Where the decks are kept (a test points it elsewhere: [effectDecksAt]), as the Colors shelf keeps the maker's palettes.
File _decksFile = File('${Platform.environment['HOME']}/.motolii/effect_decks.json');
List<EffectDeck>? _decks;
void effectDecksAt(File f) => (_decksFile = f, _decks = null);
List<EffectDeck> effectDecks() => _decks ??= () {
  try {
    return [for (final d in (jsonDecode(_decksFile.readAsStringSync()) as Map)['decks'] as List) EffectDeck.of(d as Map)..target = d['target'] == true];
  } catch (_) {
    return <EffectDeck>[];
  }
}();
void effectDecksKeep() {
  try {
    _decksFile.parent.createSync(recursive: true);
    _decksFile.writeAsStringSync(jsonEncode({'decks': [for (final d in effectDecks()) {...d.json, if (d.target) 'target': true}]}));
  } catch (_) {}   // (not kept: known while the window is open)
}

/// Where an effect's right click puts it, one place however many decks there are: a deck set as the target, else the
/// Favorites, as Lightroom Classic's Add to Target Collection (B) goes to the one collection set as the target, the
/// Quick Collection until one is.
EffectDeck? effectTarget() => effectDecks().where((d) => d.target).firstOrNull;
void effectTargetSet(EffectDeck? to) {
  for (final d in effectDecks()) {
    d.target = identical(d, to);
  }
  effectDecksKeep();
}

/// A name no other deck has: the name, then the name 2, as Finder names a copy.
String deckName(String name) {
  final held = {for (final d in effectDecks()) d.name}, base = name.trim().isEmpty ? 'Deck' : name.trim();
  var n = base;
  for (var k = 2; held.contains(n); k++) {
    n = '$base $k';
  }
  return n;
}

/// The fingerprint of an effect's file, SHA-256's first twelve (package:crypto; '' for what is no file).
String effectSum(String id) {
  try {
    final at = id.indexOf('#');   // (one of a file's several scripts: its word stays on)
    return sha256.convert(File(at < 0 ? id : id.substring(0, at)).readAsBytesSync()).toString().substring(0, 12) + (at < 0 ? '' : id.substring(at));
  } catch (_) {
    return '';
  }
}

/// The pack an effect came in, as its maker named it: the folder under aviutl_scripts ('author__pack'), its name part;
/// null for one that came alone.
String? effectPack(String id) => RegExp(r'/aviutl_scripts/(?:[^/]*?__)?([^/]+)/').firstMatch(id)?[1];

/// An effect's place under what ships with the window: the same on any machine.
String _place(String id) => id.startsWith('$motoliiShelves/') ? id.substring(motoliiShelves.length + 1) : id;

/// A deck as words to hand on, a line that goes wherever words go, as a Hearthstone deck code is pasted from a forum or
/// a video's description: a list, names and fingerprints, the effects not in it, as every set handed on holds its
/// programs by name (.mrpack, Nexus Collections, ReShade's presets). JSON, gzipped, in Base64 for URLs.
const deckCodeHead = 'motolii-deck:';
String deckCode(EffectDeck d) => deckCodeHead + base64Url.encode(gzip.encode(utf8.encode(jsonEncode({
  ...d.json,
  'things': [for (final t in d.things) {...t.json, 'id': _place(t.id)}],
  'without': [for (final s in d.without) _place(s)],
}))));

/// The deck a line says; null when it says none.
EffectDeck? deckRead(String line) {
  if (!line.startsWith(deckCodeHead)) return null;
  try {
    return EffectDeck.of(jsonDecode(utf8.decode(gzip.decode(base64Url.decode(line.substring(deckCodeHead.length).trim())))) as Map);
  } catch (_) {
    return null;
  }
}

/// What a deck's effects are told by here, of [ids] (those on the shelf): the same place, else the same fingerprint. One
/// found neither way stays as it came, its name and fingerprint kept for the day it comes, as Hearthstone keeps a card
/// one lacks in a pasted deck, and marked (a ReShade preset forgets the effects it could not load as it is saved).
void deckSettle(EffectDeck d, Set<String> ids) {
  final at = {for (final id in ids) _place(id): id};
  Map<String, String>? sums;
  for (final t in d.things) {
    if (ids.contains(t.id)) continue;
    final here = at[_place(t.id)] ?? (t.sum.isEmpty ? null : (sums ??= {for (final id in ids) effectSum(id): id})[t.sum]);
    if (here != null) t.id = here;
  }
  final out = {for (final s in d.without) at[_place(s)] ?? s};
  d.without
    ..clear()
    ..addAll(out);
}
