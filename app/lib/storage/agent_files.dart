// File helpers for the ACP Agent pane (fs/read_text_file, fs/write_text_file,
// base64 image attachments, and user-defined custom ACP agents). Panels import
// this instead of dart:io.
import 'dart:convert';
import 'dart:io';

/// Reads [path] as UTF-8 text, optionally sliced to 1-based [line] and [limit] lines
/// as required by ACP `fs/read_text_file`.
String readAgentTextFile(String path, {int? line, int? limit}) {
  final raw = File(path).readAsStringSync();
  if (line == null && limit == null) return raw;
  final lines = raw.split('\n');
  final start = ((line ?? 1) - 1).clamp(0, lines.length);
  final end = limit == null
      ? lines.length
      : (start + limit).clamp(start, lines.length);
  return lines.sublist(start, end).join('\n');
}

/// Writes UTF-8 [content] to [path], creating parent directories when needed.
void writeAgentTextFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

/// Returns the MIME type for a common image extension, or null if not an image.
String? imageMimeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return null;
}

/// Reads an image at [path] as base64 + MIME type (capped at 8 MiB to protect
/// RPC frames), or null when unreadable / not an image.
({String data, String mimeType})? readBase64Image(
  String path, {
  int maxBytes = 8 * 1024 * 1024,
}) {
  final mime = imageMimeForPath(path);
  if (mime == null) return null;
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    final len = file.lengthSync();
    if (len <= 0 || len > maxBytes) return null;
    return (data: base64Encode(file.readAsBytesSync()), mimeType: mime);
  } catch (_) {
    return null;
  }
}

/// Reads a UTF-8 file if it exists, or returns null.
String? readOptionalTextFile(String path) {
  try {
    final f = File(path);
    return f.existsSync() ? f.readAsStringSync() : null;
  } catch (_) {
    return null;
  }
}

/// Reads user-defined custom ACP agents from `<ownFolder>/agents/custom.json`.
/// Accepts either a JSON array or `{ "agents": [...] }`.
List<Map<String, Object?>> readCustomAgentsFile(String ownFolder) {
  final text = readOptionalTextFile('$ownFolder/agents/custom.json');
  if (text == null || text.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(text);
    final list = switch (decoded) {
      final List l => l,
      {'agents': final List l} => l,
      _ => const <Object?>[],
    };
    return [
      for (final item in list)
        if (item is Map) {for (final e in item.entries) '${e.key}': e.value},
    ];
  } catch (_) {
    return const [];
  }
}
