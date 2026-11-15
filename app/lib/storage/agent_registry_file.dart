// The agent registry as it is had: downloaded, and kept on disk so that the list opens offline.
import 'dart:convert';
import 'dart:io';

/// The registry's text: downloaded from [url] (kept at [keptPath] when it arrives), else the kept copy, else null.
Future<String?> registryText(String url, String keptPath) async {
  final kept = File(keptPath);
  String? text;
  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      text = await response.transform(utf8.decoder).join();
      kept
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  } catch (_) {}
  text ??= kept.existsSync() ? kept.readAsStringSync() : null;
  return text;
}
