// Checks Velopack release feeds (`releases.<channel>.json`) and optional `shelves-manifest.json` delta updates.
// 詳細: docs/design/release_and_delta_updates.md
import 'dart:convert';

import 'package:motolii/storage/host_platform.dart'
    show hostIsMacOS, hostIsWindows;
import 'package:motolii/storage/open_in_host.dart' show openInHost;
import 'package:motolii/storage/shelves_sync.dart'
    show fetchTextUrl, syncShelvesFromUrl, updateFeedBaseUrl;
import 'package:motolii/storage/shelf_meta.dart' show clearShelfMetaCache;
import 'package:motolii/workspace/state/engine_access.dart'
    show ownFolder, shelvesFolder;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Current bundled app version (matches app/pubspec.yaml).
const currentAppVersion = '0.1.0';

/// Default GitHub Releases feed URL (can be overridden via MOTOLII_UPDATE_URL).
const defaultReleasesUrl = 'https://github.com/motolii/motolii/releases/latest';

/// Velopack channel name for this OS.
String updateChannel() => hostIsMacOS
    ? 'osx-arm64'
    : hostIsWindows
    ? 'win-x64'
    : 'linux-x64';

/// Parsed latest entry from a Velopack `releases.<channel>.json` feed.
typedef UpdateReleaseInfo = ({String version, String? fileName});

/// Parses a Velopack `releases.<channel>.json` payload and returns the newest Full release entry.
UpdateReleaseInfo? parseVelopackFeed(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) return null;
  final assets = decoded['Assets'];
  if (assets is! List) return null;
  UpdateReleaseInfo? best;
  for (final item in assets) {
    if (item is! Map<String, dynamic>) continue;
    final ver = '${item['Version'] ?? ''}'.trim();
    if (ver.isEmpty) continue;
    final type = '${item['Type'] ?? ''}';
    if (type.isNotEmpty && type != 'Full') continue;
    if (best == null || isNewerVersion(ver, best.version)) {
      best = (version: ver, fileName: item['FileName'] as String?);
    }
  }
  return best;
}

/// True when [candidate] is strictly newer than [current] (SemVer major.minor.patch, pre-release aware).
bool isNewerVersion(String candidate, String current) {
  List<int> core(String v) => v
      .split('-')
      .first
      .replaceFirst(RegExp(r'^v'), '')
      .split('.')
      .map((s) => int.tryParse(s) ?? 0)
      .toList();
  final a = core(candidate), b = core(current);
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av > bv;
  }
  final aPre = candidate.contains('-'), bPre = current.contains('-');
  if (aPre != bPre) return !aPre && bPre;
  if (aPre && bPre) {
    return candidate
            .split('-')
            .skip(1)
            .join('-')
            .compareTo(current.split('-').skip(1).join('-')) >
        0;
  }
  return false;
}

/// Checks for binary and `shelves/` delta updates from `MOTOLII_UPDATE_URL` (or opens GitHub Releases).
Future<void> checkForUpdates(WorkspaceController ws) async {
  final baseUrl = updateFeedBaseUrl();
  if (baseUrl.isEmpty) {
    ws.notice = 'Opening Releases page (v$currentAppVersion)…';
    await openInHost(defaultReleasesUrl);
    return;
  }
  final cleanBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  ws.notice = 'Checking for updates…';
  try {
    final body = await fetchTextUrl(
      '$cleanBase/releases.${updateChannel()}.json',
    );
    if (body != null) {
      final latest = parseVelopackFeed(body);
      if (latest != null && isNewerVersion(latest.version, currentAppVersion)) {
        ws.notice =
            'Update available: v${latest.version} (current v$currentAppVersion)';
        await openInHost(defaultReleasesUrl);
        return;
      }
    }
    try {
      final sync = await syncShelvesFromUrl(
        baseUrl: cleanBase,
        localBaselineDir: shelvesFolder(),
        targetDir: ownFolder(),
      );
      if (sync.applied > 0) {
        clearShelfMetaCache();
        ws.inside?.forgetFolders();
        ws.reread();
        ws.notice = 'Updated ${sync.applied} shelf files (delta sync)';
        return;
      }
    } catch (_) {
      // Optional shelves-manifest.json may not be hosted on every update server.
    }
    ws.notice = 'Motolii v$currentAppVersion is up to date';
  } catch (e) {
    ws.notice = 'Update check unavailable: $e';
  }
}
