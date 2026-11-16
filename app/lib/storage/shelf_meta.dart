// Shelf metadata: author, licence and source of each effect, read from meta.yaml in shelf folders.
// The engine reads tags from each file's header (isf_tags); this reads what the file header does not carry.
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:motolii/storage/text_file.dart' show readText;

/// What a shelf's meta.yaml says about one item: who made it, under what licence, and where it came from.
class ShelfMeta {
  const ShelfMeta({this.author = '', this.license = '', this.source = ''});
  final String author, license, source;
  bool get isEmpty => author.isEmpty && license.isEmpty && source.isEmpty;
}

final _cache = <String, Map<String, ShelfMeta>>{};

/// The metadata of the item [name] in the shelf folder [folder], or null when there is none.
/// The folder's meta.yaml is read once and cached for the life of the app.
ShelfMeta? shelfMetaOf(String folder, String name) {
  final map = _cache.putIfAbsent(folder, () => _read(folder));
  return map[name];
}

/// The metadata of the item whose file is [path] (an effect's .fs, .js or .wgsl), looked up by filename stem.
ShelfMeta? shelfMetaOfFile(String path) {
  final sep = path.lastIndexOf('/');
  if (sep < 0) return null;
  final folder = path.substring(0, sep);
  final file = path.substring(sep + 1);
  final dot = file.lastIndexOf('.');
  final stem = dot > 0 ? file.substring(0, dot) : file;
  return shelfMetaOf(folder, stem);
}

Map<String, ShelfMeta> _read(String folder) {
  try {
    final text = readText('$folder/meta.yaml');
    if (text == null) return const {};
    final doc = loadYaml(text);
    if (doc is! YamlMap) return const {};
    return {
      for (final e in doc.entries)
        if (e.key is String && e.value is YamlMap)
          e.key as String: ShelfMeta(
            author: '${(e.value as YamlMap)['author'] ?? ''}',
            license: '${(e.value as YamlMap)['license'] ?? ''}',
            source: '${(e.value as YamlMap)['source'] ?? ''}',
          ),
    };
  } catch (_) {
    return const {};
  }
}

/// The metadata of an item looked up by its display name, searching all meta.yaml files under [shelvesDir].
/// The first call scans the shelves folder once; after that it is a map lookup.
/// Call [loadAllShelfMeta] with the shelves path before the first lookup by name.
ShelfMeta? shelfMetaByName(String name) => _byName[name];

final _byName = <String, ShelfMeta>{};
bool _allLoaded = false;

/// Scans [shelvesDir] for every meta.yaml and caches the entries by name. Called once early (engine_access.dart).
void loadAllShelfMeta(String shelvesDir) {
  if (_allLoaded) return;
  _allLoaded = true;
  try {
    for (final d in Directory(shelvesDir).listSync(recursive: true)) {
      if (d is! File || !d.path.endsWith('/meta.yaml')) continue;
      final folder = d.parent.path;
      final map = _cache.putIfAbsent(folder, () => _read(folder));
      _byName.addAll(map);
    }
  } catch (_) {}
}

/// Drops the cache so the next lookup re-reads from disk. Called when a meta.yaml is known to have changed.
void clearShelfMetaCache() {
  _cache.clear();
  _byName.clear();
  _allLoaded = false;
}
