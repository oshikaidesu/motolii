// The disk as the picture features reach it: the CLIP models built beside the app, a picture's bytes and the feature
// vectors kept for each picture. Panels import this instead of dart:io.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:motolii/storage/host_platform.dart' show homeFolder;

import 'package:crypto/crypto.dart' show sha1;

import 'package:motolii/storage/json_file.dart' show fileKeep;

/// Path of the CLIP image encoder [name] (clip_b32 is OpenAI's ViT-B/32, fontclip_b32 is FontCLIP's) if it has been
/// built (engine/deps/likeness_models.py), otherwise null. Without a model the maps use tiny colours
/// (ImageFeatures.tiny).
String? likenessModel(String name) {
  final f = '$homeFolder/Library/Caches/Motolii/models/$name.onnx';
  return File(f).existsSync() ? f : null;
}

int lastChangedMicros(String path) =>
    File(path).lastModifiedSync().microsecondsSinceEpoch;

Future<Uint8List> readPictureBytes(String path) => File(path).readAsBytes();

/// The cache file for an image's feature vector, in ~/Library/Caches/Motolii/looks.
/// [key] combines the model, the image and when it was drawn. [featuresKept] returns null when nothing is cached.
File _look(String key) => File(
  '$homeFolder/Library/Caches/Motolii/looks/${sha1.convert(utf8.encode(key))}.f32',
);

Float32List? featuresKept(String key) {
  try {
    final had = _look(key).readAsBytesSync();
    return had.isEmpty || had.length % 4 != 0
        ? null
        : had.buffer.asFloat32List();
  } catch (_) {
    return null;
  }
}

void keepFeatures(String key, Float32List v) {
  fileKeep(_look(key), Float32List.fromList(v).buffer.asUint8List());
}
