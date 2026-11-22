// SHA-256 manifest delta synchronization for `shelves/` so shelf updates ship in a few KB without rebuilding the app.
// 詳細: docs/design/release_and_delta_updates.md
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:motolii/storage/host_platform.dart' show slashed;

/// One file entry in a shelves manifest.
typedef ShelfManifestEntry = ({String sha256, int size});

/// Diff between a local and remote shelves manifest.
typedef ShelvesDelta = ({
  List<String> added,
  List<String> updated,
  List<String> removed,
  int downloadBytes,
});

/// Validates that a manifest relative path stays cleanly inside the shelves root.
bool isSafeShelfRelPath(String rel) {
  final norm = slashed(rel);
  if (norm.isEmpty || norm.startsWith('/') || norm.contains(':')) return false;
  for (final seg in norm.split('/')) {
    if (seg.isEmpty || seg == '.' || seg == '..') return false;
  }
  return true;
}

/// Computes a SHA-256 manifest map (`relativePath -> {sha256, size}`) for all files in [rootDir].
Map<String, ShelfManifestEntry> computeShelvesManifest(String rootDir) {
  final root = Directory(rootDir);
  if (!root.existsSync()) return const {};
  final prefix = '${slashed(root.absolute.path)}/';
  final result = <String, ShelfManifestEntry>{};
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final abs = slashed(entity.absolute.path);
    if (!abs.startsWith(prefix)) continue;
    final rel = abs.substring(prefix.length);
    if (rel.startsWith('.') || rel.contains('/.')) continue;
    final bytes = entity.readAsBytesSync();
    result[rel] = (
      sha256: sha256.convert(bytes).toString(),
      size: bytes.length,
    );
  }
  return result;
}

/// Parses a `shelves-manifest.json` document into a map of relative path to SHA-256 and byte size.
Map<String, ShelfManifestEntry> parseShelvesManifestJson(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Manifest root must be a JSON object');
  }
  final files = decoded['files'];
  if (files is! Map<String, dynamic>) {
    throw const FormatException('Manifest missing "files" map');
  }
  final out = <String, ShelfManifestEntry>{};
  for (final entry in files.entries) {
    if (!isSafeShelfRelPath(entry.key)) {
      throw FormatException('Unsafe shelf path in manifest: ${entry.key}');
    }
    final v = entry.value;
    if (v is! Map<String, dynamic>) continue;
    final hash = '${v['sha256'] ?? ''}';
    final size = v['size'];
    if (hash.length != 64 || size is! int || size < 0) continue;
    out[entry.key] = (sha256: hash, size: size);
  }
  return out;
}

/// Computes the exact delta needed to transform [local] into [remote].
ShelvesDelta diffShelvesManifest({
  required Map<String, ShelfManifestEntry> local,
  required Map<String, ShelfManifestEntry> remote,
}) {
  final added = <String>[];
  final updated = <String>[];
  final removed = <String>[];
  var downloadBytes = 0;

  for (final e in remote.entries) {
    final cur = local[e.key];
    if (cur == null) {
      added.add(e.key);
      downloadBytes += e.value.size;
    } else if (cur.sha256 != e.value.sha256) {
      updated.add(e.key);
      downloadBytes += e.value.size;
    }
  }
  for (final k in local.keys) {
    if (!remote.containsKey(k)) removed.add(k);
  }
  added.sort();
  updated.sort();
  removed.sort();
  return (
    added: added,
    updated: updated,
    removed: removed,
    downloadBytes: downloadBytes,
  );
}

/// Applies only changed/added files from [remote] into [targetDir] using [fetchFile], verifying SHA-256 on every file.
Future<int> applyShelvesDelta({
  required String targetDir,
  required Map<String, ShelfManifestEntry> local,
  required Map<String, ShelfManifestEntry> remote,
  required Future<List<int>> Function(String relPath) fetchFile,
}) async {
  final delta = diffShelvesManifest(local: local, remote: remote);
  final toFetch = [...delta.added, ...delta.updated];
  var applied = 0;
  for (final rel in toFetch) {
    if (!isSafeShelfRelPath(rel)) {
      throw FormatException('Unsafe shelf path: $rel');
    }
    final expected = remote[rel]!;
    final bytes = await fetchFile(rel);
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != expected.sha256) {
      throw FormatException(
        'SHA-256 mismatch for $rel: expected ${expected.sha256}, got $actualHash',
      );
    }
    final dest = File('$targetDir/$rel');
    dest.parent.createSync(recursive: true);
    final tmp = File('${dest.path}.part');
    tmp.writeAsBytesSync(bytes, flush: true);
    tmp.renameSync(dest.path);
    applied++;
  }
  return applied;
}

/// Fetches a remote `shelves-manifest.json` from [baseUrl] and syncs only changed shelf files into [targetDir].
Future<({ShelvesDelta delta, int applied})> syncShelvesFromUrl({
  required String baseUrl,
  required String localBaselineDir,
  required String targetDir,
}) async {
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    Future<List<int>> getBytes(String url) async {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode} for $url');
      }
      final chunks = <int>[];
      await for (final c in res) {
        chunks.addAll(c);
      }
      return chunks;
    }

    final manifestBytes = await getBytes('$base/shelves-manifest.json');
    final remote = parseShelvesManifestJson(utf8.decode(manifestBytes));
    final local = {
      ...computeShelvesManifest(localBaselineDir),
      ...computeShelvesManifest(targetDir),
    };
    final delta = diffShelvesManifest(local: local, remote: remote);
    final applied = await applyShelvesDelta(
      targetDir: targetDir,
      local: local,
      remote: remote,
      fetchFile: (rel) => getBytes('$base/shelves/$rel'),
    );
    return (delta: delta, applied: applied);
  } finally {
    client.close(force: true);
  }
}

/// Configured update feed base URL from `MOTOLII_UPDATE_URL`, or empty string when unset.
String updateFeedBaseUrl() =>
    (Platform.environment['MOTOLII_UPDATE_URL'] ?? '').trim();

/// Fetches UTF-8 text from [url], or returns null on non-200 HTTP status.
Future<String?> fetchTextUrl(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    if (res.statusCode != 200) return null;
    return await utf8.decodeStream(res);
  } finally {
    client.close(force: true);
  }
}
