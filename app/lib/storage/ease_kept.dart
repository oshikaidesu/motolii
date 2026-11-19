// The easings the user saved on the Ease tool's shelf: one name string each, in ~/.motolii/ease_kept.json.
import 'package:motolii/storage/host_platform.dart' show homeFolder;

import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/json_file.dart' show fileKeep, fileList;

/// The easings the user saved: a curve, a card or all the cards, each stored as its name string.
/// Saving works like saving a device preset in Ableton Live (manual, 23.2.5 Saving Presets).
/// The list lives in ~/.motolii/ease_kept.json, next to colors.json.
File _keptFile = File('$homeFolder/.motolii/ease_kept.json');
List<String>? _kept;

/// Points the list at another file and forgets what was read. Tests use this, as they do with coloursAt.
void easeKeptAt(String path) => (_keptFile = File(path), _kept = null);

List<String> easeKept() =>
    _kept ??= [for (final w in fileList(_keptFile)) '$w'];

/// Saves [word], or removes it when [off] is set.
void easeKeep(String word, {bool off = false}) {
  final kept = easeKept()..remove(word);
  if (!off) kept.add(word);
  // The list is also held in memory, so it is known while the app is open even if writing the file fails.
  fileKeep(_keptFile, jsonEncode(kept));
}
