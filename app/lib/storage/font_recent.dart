// The fonts used lately, kept in a file of the user's own: read when the Fonts shelf starts, written each time a font is used.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/json_file.dart' show fileKeep, fileList;

/// The file that stores the eight most recently used fonts, newest first. A test points it elsewhere with [fontRecentAt]. The
/// Ease tool panel stores its recent easings the same way (ease_stars.json).
File _recentFile = File(
  '${Platform.environment['HOME']}/.motolii/font_recent.json',
);

/// Sets where the fonts used lately are stored. A test points it at a file of its own.
void fontRecentAt(File f) => _recentFile = f;

List<String> recentFontsKept() => [for (final s in fileList(_recentFile)) '$s'];

void recentFontsKeep(List<String> families) =>
    fileKeep(_recentFile, jsonEncode(families));
