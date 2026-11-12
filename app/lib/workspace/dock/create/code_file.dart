// A pasted code file on the Create shelf: code that came from outside, kept as written (the group Code).
import 'dart:io';

import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';

/// One code file on the shelf: its path, what it was written for, and the hash that tells it from the others of those.
class CodeFile {
  CodeFile(this.file);
  final String file;

  String get stem =>
      file.substring(file.lastIndexOf('/') + 1, file.lastIndexOf('.'));
  String get form =>
      stem.contains('-') ? stem.substring(0, stem.lastIndexOf('-')) : stem;
  String get tail =>
      stem.contains('-') ? stem.substring(stem.lastIndexOf('-') + 1) : '';

  /// The name used when none is set: what it was written for, then its hash.
  String get plain => '$form $tail'.trim();

  /// The display name: the user's own name if set, otherwise what the file says about itself.
  ///
  /// That is the site title adapter_net.h wrote at the head of the file, or the description of a multi-tab file.
  String get name {
    try {
      if (shelfSidecar(file).existsSync()) {
        return shelfSidecar(file).readAsStringSync().trim();
      }
      final lines = File(file).readAsLinesSync();
      final kept = RegExp(r'^/\*\{.*"DESCRIPTION":"([^"]*)"')
          .firstMatch(lines.first)?[1];
      if (kept != null && kept != 'Shadertoy') return kept;
      return [
            for (final l in lines.take(8))
              RegExp(
                r'^// (.+) by [^,]+, [^,]+, openprocessing\.org/sketch/\d+',
              ).firstMatch(l)?[1],
          ].nonNulls.firstOrNull ??
          plain;
    } catch (_) {
      return plain;
    }
  }

  /// Sets the name to [to]. An empty name removes the sidecar, so [name] falls back to [plain].
  void rename(String to) {
    if (to.trim().isNotEmpty) {
      return shelfSidecar(file).writeAsStringSync(to.trim());
    }
    if (shelfSidecar(file).existsSync()) shelfSidecar(file).deleteSync();
  }

  /// The first line of the file that says something.
  String get first {
    try {
      final kept =
          RegExp(r'^/\*\{.*"DESCRIPTION":"([^"]*)"(?:,"CREDIT":"([^"]*)")?')
          // A multi-tab file describes itself in its first line.
          .firstMatch(File(file).readAsLinesSync().first);
      if (kept != null && kept[1] != 'Shadertoy') {
        return kept[2] == null ? kept[1]! : '${kept[1]} · ${kept[2]}';
      }
      return File(file)
          .readAsLinesSync()
          .map((l) => l.trim())
          .firstWhere(
            (l) =>
                l.isNotEmpty &&
                !l.startsWith('//') &&
                !l.startsWith('#') &&
                !l.startsWith('/*'),
            orElse: () => '',
          );
    } catch (_) {
      return '';
    }
  }
}

/// The user's code files, most recently written first.
///
/// A Hydra or p5 source is hidden when the shader it became sits beside it, because that shader stands for it.
List<CodeFile> codeFiles() {
  final dir = Directory('${EffectTiles.own}/programs');
  if (!dir.existsSync()) return const [];
  final all = dir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'\.(js|fs|hydra)$').hasMatch(f.path))
      .toList();
  final made = {
    for (final f in all)
      if (RegExp(r'\.(hydra|js)$').hasMatch(f.path))
        f.path.replaceFirst(RegExp(r'\.(hydra|js)$'), '.fs'),
  };
  final kept = all.where((f) => !made.contains(f.path)).toList()
    ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return [for (final f in kept) CodeFile(f.path)];
}
