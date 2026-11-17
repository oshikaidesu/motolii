// Collects the author, licence and source of every effect used in the open project, for the export log.
// The log lists each unique effect once, grouped by licence, so the user can include it with an exported video.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/storage/shelf_disk.dart' show keepText;
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
    this.origin = 'community',
  });
  final String title, file, author, license, source, origin;
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
          origin: meta?.resolvedOrigin ?? 'community',
        ),
      );
    }
  }
  return credits;
}

/// Writes a credits file beside the exported video. Called from the state layer after a successful export.
void writeCreditsFile(WorkspaceController ws, String videoPath) {
  final m = ws.inside;
  if (m == null) return;
  final credits = projectCredits(m);
  if (credits.isEmpty) return;
  final txt =
      '${videoPath.substring(0, videoPath.lastIndexOf('.'))}_credits.txt';
  keepText(txt, creditsText(credits));
}

/// The credits as a readable text, grouped by origin then by licence.
String creditsText(List<EffectCredit> credits) {
  if (credits.isEmpty) return 'No effects used.';
  final byOrigin = <String, List<EffectCredit>>{};
  for (final c in credits) {
    (byOrigin[c.origin] ??= []).add(c);
  }
  final buf = StringBuffer('Effects used in this project\n');
  buf.writeln('${'=' * 40}\n');

  void writeSection(
    String heading,
    List<EffectCredit> items, {
    bool detail = true,
  }) {
    buf.writeln(heading);
    if (!detail) {
      for (final c in items) {
        buf.writeln('  ${c.title}');
      }
    } else {
      final byLicense = <String, List<EffectCredit>>{};
      for (final c in items) {
        (byLicense[c.license.isEmpty ? 'Unknown' : c.license] ??= []).add(c);
      }
      for (final license in byLicense.keys.toList()..sort()) {
        buf.writeln('  [$license]');
        for (final c in byLicense[license]!) {
          buf.write('    ${c.title}');
          if (c.author.isNotEmpty) buf.write('  by ${c.author}');
          if (c.source.isNotEmpty) buf.write('  (${c.source})');
          buf.writeln();
        }
      }
    }
    buf.writeln();
  }

  final self = byOrigin.remove('self');
  final builtin = byOrigin.remove('builtin');
  final community = byOrigin.remove('community');
  if (self != null && self.isNotEmpty) {
    writeSection('[Your Effects]', self, detail: false);
  }
  if (builtin != null && builtin.isNotEmpty) {
    writeSection('[motolii]', builtin, detail: false);
  }
  if (community != null && community.isNotEmpty) {
    writeSection('[Community]', community);
  }
  for (final e in byOrigin.entries) {
    writeSection('[${e.key}]', e.value);
  }
  return buf.toString();
}
