// Text read from a file: a file the caller needs now, and one that may be missing or unreadable.
import 'dart:io';

String readTextNow(String path) => File(path).readAsStringSync();

String? readText(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return null;
  }
}

Future<String> readTextOrEmpty(String path) =>
    File(path).readAsString().catchError((_) => '');
