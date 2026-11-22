// Phase 4 tests: shelves SHA-256 manifest delta sync and Velopack feed/semver version comparison.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/storage/shelves_sync.dart';
import 'package:motolii/workspace/state/update_check.dart';

void main() {
  test('computeShelvesManifest + diffShelvesManifest + applyShelvesDelta only fetches changed files', () async {
    final tmp = Directory.systemTemp.createTempSync('motolii_shelves_sync_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final localDir = Directory('${tmp.path}/local')..createSync();
    final remoteDir = Directory('${tmp.path}/remote')..createSync();

    // Unchanged file
    File('${localDir.path}/effects/a.fs')
      ..createSync(recursive: true)
      ..writeAsStringSync('same-content');
    File('${remoteDir.path}/effects/a.fs')
      ..createSync(recursive: true)
      ..writeAsStringSync('same-content');

    // Updated file
    File('${localDir.path}/effects/b.fs')
      ..createSync(recursive: true)
      ..writeAsStringSync('old-v1');
    File('${remoteDir.path}/effects/b.fs')
      ..createSync(recursive: true)
      ..writeAsStringSync('new-v2');

    // Added file
    File('${remoteDir.path}/panels/new_tool.js')
      ..createSync(recursive: true)
      ..writeAsStringSync('function render() { return {}; }');

    final local = computeShelvesManifest(localDir.path);
    final remote = computeShelvesManifest(remoteDir.path);
    final delta = diffShelvesManifest(local: local, remote: remote);

    expect(delta.added, ['panels/new_tool.js']);
    expect(delta.updated, ['effects/b.fs']);
    expect(delta.removed, isEmpty);

    final fetched = <String>[];
    final applied = await applyShelvesDelta(
      targetDir: localDir.path,
      local: local,
      remote: remote,
      fetchFile: (rel) async {
        fetched.add(rel);
        return File('${remoteDir.path}/$rel').readAsBytesSync();
      },
    );

    expect(applied, 2);
    expect(fetched, unorderedEquals(['effects/b.fs', 'panels/new_tool.js']));
    expect(File('${localDir.path}/effects/b.fs').readAsStringSync(), 'new-v2');
    expect(File('${localDir.path}/panels/new_tool.js').existsSync(), isTrue);
  });

  test(
    'applyShelvesDelta rejects corrupted download with SHA-256 mismatch',
    () async {
      final tmp = Directory.systemTemp.createTempSync('motolii_shelves_hash_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final goodBytes = utf8.encode('expected-bytes');
      final remote = <String, ShelfManifestEntry>{
        'effects/x.fs': (
          sha256: sha256.convert(goodBytes).toString(),
          size: goodBytes.length,
        ),
      };

      await expectLater(
        () => applyShelvesDelta(
          targetDir: tmp.path,
          local: const {},
          remote: remote,
          fetchFile: (_) async => utf8.encode('tampered-bytes'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(File('${tmp.path}/effects/x.fs').existsSync(), isFalse);
    },
  );

  test('parseShelvesManifestJson rejects path traversal', () {
    final badJson = jsonEncode({
      'version': 1,
      'files': {
        '../escape.fs': {'sha256': 'a' * 64, 'size': 4},
      },
    });
    expect(
      () => parseShelvesManifestJson(badJson),
      throwsA(isA<FormatException>()),
    );
  });

  test('Velopack feed parsing and semver comparison work across beta and stable versions', () {
    expect(isNewerVersion('0.2.0', '0.1.0'), isTrue);
    expect(isNewerVersion('0.1.0', '0.1.0-beta.1'), isTrue);
    expect(isNewerVersion('0.1.0-beta.2', '0.1.0-beta.1'), isTrue);
    expect(isNewerVersion('0.1.0-beta.1', '0.1.0'), isFalse);
    expect(isNewerVersion('0.1.0', '0.1.0'), isFalse);

    final feed = jsonEncode({
      'Assets': [
        {
          'Type': 'Full',
          'Version': '0.1.0-beta.1',
          'FileName': 'Motolii-0.1.0-beta.1-full.nupkg',
        },
        {
          'Type': 'Delta',
          'Version': '0.2.0',
          'FileName': 'Motolii-0.2.0-delta.nupkg',
        },
        {
          'Type': 'Full',
          'Version': '0.2.0',
          'FileName': 'Motolii-0.2.0-full.nupkg',
        },
      ],
    });
    final latest = parseVelopackFeed(feed);
    expect(latest?.version, '0.2.0');
    expect(latest?.fileName, 'Motolii-0.2.0-full.nupkg');
  });
}
