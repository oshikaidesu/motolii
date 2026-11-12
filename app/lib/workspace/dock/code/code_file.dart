// A code file on the Code shelf: code that came from outside, kept as written.
import 'dart:io';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';

/// One code file on the shelf: its path, what it was written for, and the hash that tells it from the others of those.
class CodeFile {
  CodeFile(this.file, {this.recipe, this.kind});
  final String file;

  /// [recipe] is the name of a closed pack from the library: a whole Cavalry script or a p5.js sketch as it came
  /// (CREATE_PROGRAM.md). It is created by that name, as Create does (doc_make).
  ///
  /// [kind] is what the code file was written for, as the engine reports it. A pack's file is never overwritten.
  final String? recipe, kind;
  String get stem =>
      file.substring(file.lastIndexOf('/') + 1, file.lastIndexOf('.'));
  String get form =>
      kind ??
      (stem.contains('-') ? stem.substring(0, stem.lastIndexOf('-')) : stem);
  String get tail =>
      stem.contains('-') ? stem.substring(stem.lastIndexOf('-') + 1) : '';

  /// The name used when none is set: what it was written for, then its hash.
  String get plain => '$form $tail'.trim();

  /// The display name: the user's own name if set, otherwise what the file says about itself.
  ///
  /// That is the site title adapter_net.h wrote at the head of the file, or the description of a multi-tab file.
  String get name {
    if (recipe case final r?) return r;
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

/// The user's code files, then the library's packs that are not among them.
///
/// A pack that was also put in from the web and kept appears only once.
List<CodeFile> codeFilesAndPacks(Motolii? m) {
  final own = codeFiles(),
      stems = {for (final p in own) p.stem},
      kinds = {
        for (final (name, kind) in m?.packKinds ?? const <(String, String)>[])
          name: kind,
      };
  return [
    ...own,
    for (final (name, file) in m?.packs ?? const <(String, String)>[])
      if (!stems.contains(name))
        CodeFile(file, recipe: name, kind: kinds[name]),
  ];
}
