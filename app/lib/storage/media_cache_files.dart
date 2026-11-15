// The image files the timeline's media cache reads from disk: the frames and thumbnails the engine wrote, and a still.
// Panels import this instead of dart:io.
import 'dart:io';
import 'dart:typed_data';

/// The bytes of the image file [path], read now.
Uint8List readImageSync(String path) => File(path).readAsBytesSync();

/// The bytes of the image file [path].
Future<Uint8List> readImage(String path) => File(path).readAsBytes();
