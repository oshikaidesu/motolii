// A pasted code file on the Create shelf: code that came from outside, kept as written (the group Code).
import 'package:motolii/storage/script_files.dart'
    show filesUnder, linesOf, writtenAt;
import 'package:motolii/workspace/state/media/shelf_items.dart'
    show shelfSidecarDelete, shelfSidecarText, shelfSidecarWrite;
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
      final named = shelfSidecarText(file);
      if (named != null) return named.trim();
      final lines = linesOf(file);
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
  /// [taken] holds the names already used by the other pasted files; when [to] matches one,
  /// a number is appended to make it one of its own, so the user cannot accidentally give two
  /// tiles the same name (B150). Case-insensitive, to match shelfRename.
  void rename(String to, {Iterable<String> taken = const []}) {
    to = to.trim();
    if (to.isEmpty) return shelfSidecarDelete(file);
    final lower = {for (final t in taken) t.toLowerCase()};
    if (lower.contains(to.toLowerCase())) {
      for (var i = 2; i < 1000; i++) {
        final tried = '$to $i';
        if (!lower.contains(tried.toLowerCase())) {
          to = tried;
          break;
        }
      }
    }
    shelfSidecarWrite(file, to);
  }

  /// The first line of the file that says something.
  String get first {
    try {
      final kept =
          RegExp(r'^/\*\{.*"DESCRIPTION":"([^"]*)"(?:,"CREDIT":"([^"]*)")?')
          // A multi-tab file describes itself in its first line.
          .firstMatch(linesOf(file).first);
      if (kept != null && kept[1] != 'Shadertoy') {
        return kept[2] == null ? kept[1]! : '${kept[1]} · ${kept[2]}';
      }
      return linesOf(file)
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
  final all = [
    for (final p in filesUnder('${EffectTiles.own}/programs'))
      if (RegExp(r'\.(js|fs|hydra)$').hasMatch(p)) p,
  ];
  final made = {
    for (final p in all)
      if (RegExp(r'\.(hydra|js)$').hasMatch(p))
        p.replaceFirst(RegExp(r'\.(hydra|js)$'), '.fs'),
  };
  final kept = all.where((p) => !made.contains(p)).toList()
    ..sort((a, b) => writtenAt(b).compareTo(writtenAt(a)));
  return [for (final p in kept) CodeFile(p)];
}
