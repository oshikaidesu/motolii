// Tags for the shelves, one thing for all of them (Colors: hot, cold, pastel…; Fonts: serif, gothic…; Media: its kinds): a
// search finds a thing by its name, its tags, or (a colour) its code, each word of the search on its own; the words
// being typed are completed from the tags the shelf knows. The maker's own tags are a file, ~/.motolii/tags.json
// ({"Colors|coda": ["title", "warm"]}, a shelf, a bar, the thing's id), read once.
import 'dart:convert';
import 'dart:io';

abstract final class DockTags {
  static final _own = <String, Set<String>>{};
  static bool _read = false;

  /// The tags each shelf has been seen to use (the words a search is completed from).
  static final seen = <String, Set<String>>{};

  static void _load() {
    if (_read) return;
    _read = true;
    try {
      final told = jsonDecode(File('${Platform.environment['HOME']}/.motolii/tags.json').readAsStringSync()) as Map;
      for (final e in told.entries) {
        _own['${e.key}'] = {for (final t in e.value as List) '$t'.toLowerCase()};
      }
    } catch (_) {} // (no file, or not a map: the built-in tags alone)
  }

  /// A thing's tags: the built-in, and the maker's own.
  static Set<String> of(String shelf, String id, Set<String> builtIn) {
    _load();
    final all = {...builtIn, ...?_own['$shelf|$id']};
    (seen[shelf] ??= {}).addAll(all);
    return all;
  }

  /// A thing chosen after a search is that search's first the next time, for the words exactly as typed: Alfred's
  /// Keyword Latching (alfredapp.com/help/kb/understanding-result-ordering); the user's "選んだ物から覚える", golf
  /// (94). Kept in ~/.motolii/latched.json ({"Effects|adjustment layer": the thing's id}); a test points it elsewhere.
  static File _latchFile = File('${Platform.environment['HOME']}/.motolii/latched.json');
  static Map<String, String>? _latches;
  static void latchedAt(File f) => (_latchFile = f, _latches = null);
  static Map<String, String> get _latched {
    if (_latches case final l?) return l;
    try {
      return _latches = {for (final e in (jsonDecode(_latchFile.readAsStringSync()) as Map).entries) '${e.key}': '${e.value}'};
    } catch (_) {
      return _latches = {}; // (none yet, or not a map)
    }
  }

  /// The thing latched to the words as typed on a shelf (null: none).
  static String? latched(String shelf, String query) => query.trim().isEmpty ? null : _latched['$shelf|${query.trim().toLowerCase()}'];

  /// A thing chosen with these words typed: latched to them.
  static void latch(String shelf, String query, String id) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || _latched['$shelf|$q'] == id) return;
    _latched['$shelf|$q'] = id;
    try {
      _latchFile.parent.createSync(recursive: true);
      _latchFile.writeAsStringSync(jsonEncode(_latched));
    } catch (_) {} // (not kept: the latch holds while the window is open)
  }

  /// Whether a thing answers a search: every word of it is in its name or among its tags.
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

  /// The tags that complete the word being typed (its end begun, not yet whole), all of them.
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

  /// The query with its last word made whole as [tag].
  static String complete(String query, String tag) {
    final i = query.lastIndexOf(RegExp(r'\s'));
    return '${i < 0 ? '' : query.substring(0, i + 1)}$tag ';
  }
}
