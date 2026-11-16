// Where the paste-from-clipboard and drop-from-browser code writes image and
// video bytes before the engine opens them. Each call makes a fresh temp
// folder so the files do not step on each other, and the folder is cleaned
// up when the OS wipes /tmp.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Writes [bytes] under a fresh temp folder as [filename] (if given) or a
/// unique name with [ext]. Returns the full path. Rethrows on I/O failure.
Future<String> writePastedBytes(
  Uint8List bytes, {
  String? filename,
  required String ext,
}) async {
  final dir = await Directory.systemTemp.createTemp('motolii_pasted_');
  final name = (filename ?? '').isEmpty
      ? 'pasted_${DateTime.now().millisecondsSinceEpoch}$ext'
      : filename!;
  final path = '${dir.path}/$name';
  await File(path).writeAsBytes(bytes);
  return path;
}
