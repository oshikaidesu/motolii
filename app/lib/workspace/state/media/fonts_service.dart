// What the Fonts shelf asks of the engine: the font files it can set text in, the text layers in each font, setting a
// text layer's font or adding one, and each font's kind and look for the map.
import 'dart:convert';
import 'dart:typed_data';

import 'package:motolii/bridge/engine_paths.dart' show motoliiDir, motoliiOwn;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/storage/folder_entries.dart' show entriesKept;
import 'package:motolii/storage/host_platform.dart'
    show homeFolder, windowsFontFolders;
import 'package:motolii/storage/picture_files.dart'
    show featuresKept, keepFeatures, lastChangedMicros;
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/workspace/state/document/document_service.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/media/pictures_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

final _fontFile = RegExp(r'\.(ttf|otf|ttc|otc)$', caseSensitive: false);

typedef FontsRead = ({
  List<({String path, String family, String? script, String? sample})> fonts,
  int unoffered,
  Map<String, String> samples,
});

/// Reads the font files the engine can set text in: the fonts of this machine, the bundled fallback font, the user's own and
/// the document's folder. A font is named after its file. A collection (.ttc) is one row and only its first face is used,
/// because ThorVG sets no other (see thorvg_ttc.patch).
///
/// A font that can set [sampleLine] is offered with that line. A font with other letters is offered with a sample in its
/// own script, as fonts.google.com does (samples.json, from Google Fonts' gflanguages), so the user never sees
/// missing-glyph boxes. The bundled fonts and the user's own are offered as well.
Future<FontsRead> readFontFiles(
  WorkspaceController ws,
  String sampleLine,
) async {
  final files = <String>[];
  for (final dir in [
    '/System/Library/Fonts',
    '/System/Library/Fonts/Supplemental',
    '/Library/Fonts',
    '$homeFolder/Library/Fonts',
    ...windowsFontFolders,
    // The bundled fallback font the engine draws with.
    '$motoliiDir/third_party/noto_sans_jp',
    '$motoliiOwn/fonts',
    ?ws.documentFolder,
  ]) {
    files.addAll(
      await entriesKept(
        dir,
        (e, _) async => e.file && _fontFile.hasMatch(e.path) ? e.path : null,
      ),
    );
  }
  var scripts = const <(String, String)>[];
  try {
    scripts = [
      for (final s in jsonDecode(
        readTextNow('$motoliiDir/third_party/gflanguages/samples.json'),
      ) as List)
        for (final w in [s['sample'], s['letters']])
          // The sample text, or else the first letters of the alphabet for a script that has no sample.
          if (w is String && w.isNotEmpty) ('${s['script']}', w),
    ];
  } catch (_) {
    // Without samples.json only fonts with Latin letters are offered.
  }
  final first = await ws.inside!.settingFirst(files, [
    sampleLine,
    for (final (_, w) in scripts) w,
  ]);
  final fonts = [
    for (final (i, f) in files.indexed)
      if (first[i] >= 0)
        (
          path: f,
          family: f.split('/').last.substring(0, f.split('/').last.length - 4),
          script: first[i] == 0 ? null : scripts[first[i] - 1].$1,
          sample: first[i] == 0 ? null : scripts[first[i] - 1].$2,
        ),
  ]..sort((a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()));
  return (
    fonts: fonts,
    unoffered: first.where((k) => k < 0).length,
    samples: {
      for (final f in fonts)
        if (f.sample != null) f.path: f.sample!,
    },
  );
}

Set<String> fontFileTags(WorkspaceController ws, String path) =>
    ws.inside?.fontTags(path) ?? const <String>{};

Map<String, Layer> textLayersByFile(WorkspaceController ws) {
  final m = ws.inside!;
  return {
    for (final l in ws.layers)
      if (m.word(l.id, 'kind') == 'text') m.whole(m.word(l.id, 'file')): l,
  };
}

bool isTextLayer(WorkspaceController ws, int layer) =>
    layerWord(ws, layer, 'kind') == 'text';

bool selectedIsText(WorkspaceController ws) {
  final t = ws.selected;
  return t != null && isTextLayer(ws, t);
}

bool canSetRoleFont(WorkspaceController ws) =>
    documentOpen(ws) && !selectedIsText(ws);

void setFontOnSelection(
  WorkspaceController ws,
  String path, {
  required ({String text, int start, int end})? picked,
  required void Function(bool done, String why) told,
}) {
  final m = ws.inside!, t = ws.selected;
  if (t != null && m.word(t, 'kind') == 'text') {
    // Letters selected in the text take the font as a range of their own, as a word processor's font menu sets
    // the selection's font; the range names the file as its font-family (inspector/text/text_ranges.dart).
    if (pickedLetters(m.word(t, 'text'), picked) case final at?) {
      return ws.after(
        m.later(
          'say',
          layer: t,
          name: 'text_styles',
          word: styleRange(
            m.word(t, 'text_styles'),
            at.start,
            at.count,
            'font-family',
            "'$path'",
          ),
        ),
        told,
      );
    }
    return ws.after(m.later('say', layer: t, name: 'file', word: path), told);
  }
  addTextIn(ws, path, told);
}

void addTextIn(
  WorkspaceController ws,
  String font,
  void Function(bool done, String why) told,
) {
  final m = ws.inside!;
  // The new text layer and its colors form one undo step.
  m.later('together', number: 1);
  ws.after(
    m.later('add', name: 'text', word: font),
    null,
    (made) => ws.select(made),
  );
  applyChosenInks(ws, 'text', '');
  ws.after(m.later('together'), told);
}

/// Sets the font file of the text layer [layer] to [face], the font of a role.
void setLayerFace(WorkspaceController ws, int layer, String face) =>
    ws.after(ws.inside!.later('say', layer: layer, name: 'file', word: face));

String fontKindOf(WorkspaceController ws, String path) {
  final t = ws.inside!.fontTags(path);
  return t.contains('mono')
      ? 'mono'
      : const [
          'serif',
          'sans',
          'script',
          'ornaments',
          'symbols',
        ].firstWhere(t.contains, orElse: () => '');
}

/// Embeds each font with FontCLIP ([model]) from a specimen image drawn as FontMap draws it for FontCLIP.
///
/// FontMap's code is tfrere/fontmap, pipeline/render/2-generate-svgs.mjs, generateEmbeddingSVG. The specimen has
/// "Hamburge" over "fonstiv" in a 224 pixel square with a 12 pixel margin. Each line fits in its half, at most 200 wide
/// and 85 tall, is set at size 75 or smaller and is centred on its half. The text is black on white.
/// Fonts are embedded 32 at a time, and an entry is null when the font could not be drawn.
/// [wordOf] gives the sample text of a font: its lines 1 and 2 are the two lines of the specimen.
Future<List<Float32List?>> fontClipLooks(
  WorkspaceController ws,
  String model,
  List<String> files,
  String Function(String path, int line) wordOf,
) async {
  String key(String f) {
    // The cache key is the model, the font and its modification time, as for the effect thumbnails, so only a new font is embedded.
    try {
      return '$model\n$f\n${lastChangedMicros(f)}\n${wordOf(f, 1)} ${wordOf(f, 2)}';
    } catch (_) {
      return '';
    }
  }

  final out = [for (final f in files) featuresKept(key(f))],
      missing = [
        for (final (k, f) in files.indexed)
          if (out[k] == null && key(f).isNotEmpty) f,
      ];
  if (missing.isEmpty) return out;
  final lines = [
        for (final _ in const [1, 2])
          List<Uint8List?>.filled(missing.length, null),
      ],
      byWords = <(String, String), List<int>>{};
  for (final (k, f) in missing.indexed) {
    (byWords[(wordOf(f, 1), wordOf(f, 2))] ??= []).add(k);
  }
  for (final MapEntry(key: (a, b), value: ks) in byWords.entries) {
    // A font with its own sample text uses its own two lines.
    for (final (j, w) in [a, b].indexed) {
      final drawn = await typePicturesOf(
        ws,
        [for (final k in ks) missing[k]],
        w,
        202,
        87,
        most: 75,
      );
      for (final (i, k) in ks.indexed) {
        lines[j][k] = drawn[i];
      }
    }
  }
  for (var i = 0; i < missing.length; i += 32) {
    final some = [for (var k = i; k < missing.length && k < i + 32; k++) k],
        drawn = [
          for (final k in some)
            if (lines[0][k] != null && lines[1][k] != null) k,
        ];
    final told = drawn.isEmpty
        ? null
        : await likenessOf(ws, model, [
            for (final k in drawn) _specimen(lines[0][k]!, lines[1][k]!),
          ]);
    for (final (j, k) in drawn.indexed) {
      if (told?[j] case final t?) {
        keepFeatures(key(missing[k]), t);
        out[files.indexOf(missing[k])] = t;
      }
    }
  }
  return out;
}

Uint8List _specimen(Uint8List top, Uint8List bottom) {
  final px = Uint8List(224 * 224 * 4)..fillRange(0, 224 * 224 * 4, 255);
  for (final (line, g) in [top, bottom].indexed) {
    // Centres the line on the middle of its half.
    final y0 = 12 + 100 * line + 50 - 87 ~/ 2, x0 = 112 - 202 ~/ 2;
    for (var y = 0; y < 87; y++) {
      for (var x = 0; x < 202; x++) {
        final at = ((y0 + y) * 224 + x0 + x) * 4;
        px[at] = px[at + 1] = px[at + 2] = 255 - g[y * 202 + x];
      }
    }
  }
  return px;
}
