// The Shelves' own tags and latched items on disk (~/.motolii/tags.json and latched.json). Panels import this
// instead of dart:io.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/storage/json_file.dart' show fileJson, fileKeep;

File _tags = File('$homeFolder/.motolii/tags.json');
File _latched = File('$homeFolder/.motolii/latched.json');

/// Sets where the user's own tags are kept. A test points it at a file of its own before it opens a window.
void ownTagsAt(String path) => _tags = File(path);

/// The user's own tags as JSON, or null when there is no file or it is not JSON.
Object? ownTagsJson() => fileJson(_tags);

/// Writes [text] as the user's own tags.
void keepOwnTags(String text) => fileKeep(_tags, text);

/// Sets where the latched items are stored. A test points it at a file of its own before it opens a window.
void latchFileAt(String path) => _latched = File(path);

/// The latched items as JSON, or null when there is no file or it is not JSON.
Object? latchedJson() => fileJson(_latched);

/// Writes [text] as the latched items.
void keepLatched(String text) => fileKeep(_latched, text);
