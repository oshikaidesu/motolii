// Tags shared by all shelves (Colors: hot, cold, pastel; Fonts: serif, gothic; Media: its kinds).
//
// - A search matches an item by its name, its tags or, for a color, its code. Each word of the search is matched on its own.
// - The word being typed is completed from the tags the shelf has seen.
// - The user's own tags are read once from ~/.motolii/tags.json, as {"Colors|coda": ["title", "warm"]}.
//   The key is the shelf name, a bar, then the item's id.
import 'dart:convert';
import 'dart:io';

import '../window/settings_file.dart' show fileJson, fileKeep;

abstract final class DockTags {
  static final _own = <String, Set<String>>{};
  static bool _read = false;

  /// The tags each shelf has used so far. A search is completed from these words.
  static final seen = <String, Set<String>>{};

  static void _load() {
    if (_read) return;
    _read = true;
    try {
      final told = fileJson(File('${Platform.environment['HOME']}/.motolii/tags.json')) as Map;
      for (final e in told.entries) {
        _own['${e.key}'] = {for (final t in e.value as List) '$t'.toLowerCase()};
      }
    } catch (_) {
      // No file, or not a map: only the built-in tags are used.
    }
  }

  /// The tags of an item: the built-in ones and the user's own.
  static Set<String> of(String shelf, String id, Set<String> builtIn) {
    _load();
    final all = {...builtIn, ...?_own['$shelf|$id']};
    (seen[shelf] ??= {}).addAll(all);
    return all;
  }

  /// An item chosen after a search becomes the first result the next time the same words are typed.
  ///
  /// This follows Alfred's Keyword Latching (alfredapp.com/help/kb/understanding-result-ordering).
  /// It is stored in ~/.motolii/latched.json as {"Effects|adjustment layer": the item's id}. A test can point it elsewhere.
  static File _latchFile = File('${Platform.environment['HOME']}/.motolii/latched.json');
  static Map<String, String>? _latches;
  static void latchedAt(File f) => (_latchFile = f, _latches = null);
  static Map<String, String> get _latched {
    if (_latches case final l?) return l;
    try {
      return _latches = {for (final e in (fileJson(_latchFile) as Map).entries) '${e.key}': '${e.value}'};
    } catch (_) {
      // No file yet, or not a map.
      return _latches = {};
    }
  }

  /// The item latched to these words on a shelf, or null if there is none.
  static String? latched(String shelf, String query) => query.trim().isEmpty ? null : _latched['$shelf|${query.trim().toLowerCase()}'];

  /// Latches [id] to [query] on [shelf].
  static void latch(String shelf, String query, String id) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || _latched['$shelf|$q'] == id) return;
    _latched['$shelf|$q'] = id;
    fileKeep(_latchFile, jsonEncode(_latched));
  }

  /// Whether an item matches a search: every word of [query] is in its name or in one of its tags.
  static bool hit(String query, String name, Set<String> tags) {
    if (query.trim().isEmpty) return true;
    final lower = name.toLowerCase();
    for (final w in query.toLowerCase().split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      if (lower.contains(w) || tags.any((t) => t.contains(w))) continue;
      return false;
    }
    return true;
  }

  /// The tags that complete the last word of [query], sorted. A tag equal to the word is not included.
  static List<String> completing(String shelf, String query) {
    final words = query.split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last.toLowerCase();
    if (last.isEmpty) return const [];
    final found = [
      for (final t in seen[shelf] ?? const <String>{})
        if (t.startsWith(last) && t != last) t,
    ]..sort();
    return found;
  }

  /// [query] with its last word replaced by [tag].
  static String complete(String query, String tag) {
    final i = query.lastIndexOf(RegExp(r'\s'));
    return '${i < 0 ? '' : query.substring(0, i + 1)}$tag ';
  }
}
