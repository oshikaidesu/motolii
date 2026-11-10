// Small files the app keeps: write text or bytes to a file, read JSON or a list back. Errors are ignored, so nothing is saved.
import 'dart:convert';
import 'dart:io';

/// Writes text or bytes to [f], creating its folder first. Any error is ignored, so nothing is saved.
void fileKeep(File f, Object data) {
  try {
    f.parent.createSync(recursive: true);
    data is String
        ? f.writeAsStringSync(data)
        : f.writeAsBytesSync(data as List<int>);
  } catch (_) {}
}

/// The JSON decoded from [f], or null if the file is missing or is not JSON.
Object? fileJson(File f) {
  try {
    return jsonDecode(f.readAsStringSync());
  } catch (_) {
    return null;
  }
}

/// The list stored in [f] as JSON, or an empty list if the file is missing or does not hold a list.
List fileList(File f) => switch (fileJson(f)) {
  final List l => l,
  _ => const [],
};
