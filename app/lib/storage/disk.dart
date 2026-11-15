// The disk as the panels reach it: a file's time, whether it is there, and an image read from it. Panels import this
// instead of dart:io, so every read of the disk is in one place.
import 'dart:io';

import 'package:flutter/painting.dart';

/// When [path] was last changed, or null when there is no such file.
DateTime? modifiedOf(String path) {
  final stat = FileStat.statSync(path);
  return stat.type == FileSystemEntityType.notFound ? null : stat.modified;
}

bool existsFile(String path) => File(path).existsSync();

/// The image in [path], shrunk to [cacheWidth] wide when given.
ImageProvider imageFile(String path, {int? cacheWidth}) {
  final image = FileImage(File(path));
  return cacheWidth == null ? image : ResizeImage(image, width: cacheWidth);
}
