// Reads file paths from the system clipboard (⌘V) and from drops onto the
// Flutter window. The native side (macos/Runner/PasteboardFiles.swift) does
// the pasteboard and NSView drag work; here we just call the channels.
import 'package:flutter/services.dart' show MethodChannel;

const _read = MethodChannel('motolii/pasteboard');
const _drops = MethodChannel('motolii/drops');

/// File paths currently on the clipboard. An image on the clipboard is
/// written to a temp file first and that path is returned. Empty if the
/// clipboard holds neither files nor an image.
Future<List<String>> clipboardFilePaths() async {
  final raw = await _read.invokeMethod<List<Object?>>('read');
  return [
    for (final e in raw ?? const [])
      if (e is String) e,
  ];
}

/// Calls [onPaths] with each drop's file paths (one call per drop event).
/// The handler is set once at app startup; the native side keeps pushing
/// drops until the app exits.
void onDroppedFiles(void Function(List<String> paths) onPaths) {
  _drops.setMethodCallHandler((call) async {
    if (call.method != 'paths') return;
    final args = call.arguments;
    if (args is! Map) return;
    final list = args['paths'];
    if (list is! List) return;
    onPaths([
      for (final e in list)
        if (e is String) e,
    ]);
  });
}
