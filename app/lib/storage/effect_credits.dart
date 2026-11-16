// Collects the author, licence and source of every effect used in the open project, for the export log.
// The log lists each unique effect once, grouped by licence, so the user can include it with an exported video.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/storage/shelf_meta.dart' show shelfMetaOfFile;
import 'package:motolii/workspace/state/workspace_controller.dart'
    show WorkspaceController;

/// One effect and what its meta.yaml says about it.
class EffectCredit {
  const EffectCredit({
    required this.title,
    this.file = '',
    this.author = '',
    this.license = '',
    this.source = '',
  });
  final String title, file, author, license, source;
}

/// Every effect the project uses, each once, with its meta.yaml metadata.
List<EffectCredit> projectCredits(Motolii doc) {
  final seen = <String>{};
  final credits = <EffectCredit>[];
  for (final t in doc.layers) {
    final titles = doc.fxTitles(t);
    final files = WorkspaceController.fxFiles(doc.word(t, 'fx'));
    for (var i = 0; i < titles.length && i < files.length; i++) {
      final title = titles[i], file = files[i];
      if (seen.contains(title)) continue;
      seen.add(title);
      final meta = shelfMetaOfFile(file);
      credits.add(
        EffectCredit(
          title: title,
          file: file,
          author: meta?.author ?? '',
          license: meta?.license ?? '',
          source: meta?.source ?? '',
        ),
      );
    }
  }
  return credits;
}

/// The credits as a readable text, grouped by licence. Effects with no metadata are listed under "Unknown".
String creditsText(List<EffectCredit> credits) {
  if (credits.isEmpty) return 'No effects used.';
  final grouped = <String, List<EffectCredit>>{};
  for (final c in credits) {
    (grouped[c.license.isEmpty ? 'Unknown' : c.license] ??= []).add(c);
  }
  final buf = StringBuffer('Effects used in this project\n');
  buf.writeln('${'=' * 40}\n');
  for (final license in grouped.keys.toList()..sort()) {
    buf.writeln('[$license]');
    for (final c in grouped[license]!) {
      buf.write('  ${c.title}');
      if (c.author.isNotEmpty) buf.write('  by ${c.author}');
      if (c.source.isNotEmpty) buf.write('  (${c.source})');
      buf.writeln();
    }
    buf.writeln();
  }
  return buf.toString();
}
