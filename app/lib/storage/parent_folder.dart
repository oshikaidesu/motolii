// The folder that holds a path, as a path string. Panels import this instead of dart:io.
import 'dart:io';

/// The folder that holds [path].
String parentFolderOf(String path) => File(path).parent.path;
