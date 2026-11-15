// The folder the home screen writes its project thumbnails into: made in the system's temporary folder, and removed
// again when the screen closes. Panels import this instead of dart:io.
import 'dart:io';

/// Makes a new folder in the system's temporary folder, and returns its path.
String makeThumbnailFolder() =>
    Directory.systemTemp.createTempSync('motolii_home').path;

/// Removes the folder at [path] and everything in it.
void removeThumbnailFolder(String path) =>
    Directory(path).deleteSync(recursive: true);
