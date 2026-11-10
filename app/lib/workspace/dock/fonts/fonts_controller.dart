// What the Fonts shelf keeps while the window is open: the font files it offers, the fonts used lately, and the
// fonts' dots on the map.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/engine_paths.dart' show motoliiDir;
import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/storage/json_file.dart' show fileKeep, fileList;
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/state/workspace_controller.dart';

final _fontFile = RegExp(r'\.(ttf|otf|ttc|otc)$', caseSensitive: false);

/// The size in pixels of a font's dot on the map.
///
/// The engine draws each family's sample word into [FontsController.dotsDrawn], because not every font is loaded in
/// Flutter. The embedding input is that image at half size, where each pixel averages four.
const fontDotSize = (96, 32);

/// What the Fonts shelf keeps while the window is open: the font files it offers, the fonts used lately, and each
/// font's dot on the map.
class FontsController {
  /// [reads] is the counter the shelves listen to; it goes up when the fonts or their dots have been read. [tags] is
  /// the window's tags, which a search of the shelf matches.
  FontsController(this.reads, this.tags);

  /// Goes up each time the fonts or their dots have been read: the shelf then looks again.
  final ValueNotifier<int> reads;

  /// The tags of the fonts, which a search matches beside their names.
  final ShelfTags tags;

  /// The shelf's map: where each font lies when the shelf is shown as a map.
  final map = ShelfMap('Fonts');

  /// The font files of this machine and of the project folder that the engine can set text in.
  /// They are read once, in the background. A font is named after its file; a collection (.ttc) is one row
  /// and only its first face is used, because ThorVG sets no other (see thorvg_ttc.patch).
  List<FontFile>? _disk;
  Future<void>? _reading;

  /// The fonts the shelf offers, empty until the files are read. The first call starts reading them.
  List<FontFile> fontsOf(WorkspaceController ws) {
    read(ws);
    return _disk ?? const [];
  }

  /// How many fonts the shelf offers, once the files are read.
  int? get offered => _disk?.length;

  /// How many font files the shelf does not offer: they have no letters of any language the engine can set
  /// (symbols, maths, emoji), or ThorVG cannot read them.
  int unoffered = 0;

  /// Sample text for fonts that cannot show Latin letters, keyed by file. Filled by [read].
  var samples = const <String, String>{};

  /// Reads the font files once, on the root zone so a test can wait for it.
  /// A font that can set the shelf's sample line is offered with that line. A font with other letters is offered
  /// with a sample in its own script, as fonts.google.com does (samples.json, from Google Fonts' gflanguages),
  /// so the user never sees missing-glyph boxes. The bundled fonts and the user's own are offered as well.
  Future<void> read(
    WorkspaceController ws,
  ) => _reading ??= Zone.root.run<Future<void>>(() async {
    final files = <String>[];
    for (final dir in [
      '/System/Library/Fonts',
      '/System/Library/Fonts/Supplemental',
      '/Library/Fonts',
      '${Platform.environment['HOME']}/Library/Fonts',
      // The bundled fallback font the engine draws with.
      '$motoliiDir/third_party/noto_sans_jp',
      '${EffectTiles.own}/fonts',
      ?ws.documentFolder,
    ]) {
      try {
        for (final e in await Directory(dir).list().toList()) {
          if (e is File && _fontFile.hasMatch(e.path)) files.add(e.path);
        }
      } on FileSystemException catch (_) {
        // A folder that is missing or unreadable has no fonts to offer.
      }
    }
    var scripts = const <(String, String)>[];
    try {
      scripts = [
        for (final s in jsonDecode(
          File('$motoliiDir/third_party/gflanguages/samples.json')
              .readAsStringSync(),
        ) as List)
          for (final w in [s['sample'], s['letters']])
            // The sample text, or else the first letters of the alphabet for a script that has no sample.
            if (w is String && w.isNotEmpty) ('${s['script']}', w),
      ];
    } catch (_) {
      // Without samples.json only fonts with Latin letters are offered.
    }
    final first = await ws.inside!.settingFirst(files, [
      fontSampleLine,
      for (final (_, w) in scripts) w,
    ]);
    _disk = [
      for (final (i, f) in files.indexed)
        if (first[i] >= 0)
          FontFile(
            f.split('/').last.substring(0, f.split('/').last.length - 4),
            path: f,
            script: first[i] == 0 ? null : scripts[first[i] - 1].$1,
            sample: first[i] == 0 ? null : scripts[first[i] - 1].$2,
          ),
    ]..sort((a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()));
    unoffered = first.where((k) => k < 0).length;
    samples = {
      for (final f in _disk!)
        if ((f.path, f.sample) case (final p?, final w?)) p: w,
    };
    reads.value++;
  });

  /// The file that stores the eight most recently used fonts, newest first. A test points it elsewhere with
  /// [fontRecentAt]. The Ease tool panel stores its recent easings the same way (ease_stars.json).
  static File _recentFile = File(
    '${Platform.environment['HOME']}/.motolii/font_recent.json',
  );
  List<String>? _recent;

  /// The families of the fonts used lately, newest first.
  List<String> get recent =>
      _recent ??= [for (final s in fileList(_recentFile)) '$s'];

  /// Puts [family] at the head of the fonts used lately and stores the list.
  void used(String family) {
    final r = recent
      ..remove(family)
      ..insert(0, family);
    if (r.length > 8) r.removeRange(8, r.length);
    // If the write fails, the list is still correct while the app is open.
    fileKeep(_recentFile, jsonEncode(r));
  }

  /// Each font's sample word as the engine drew it for the map, by file: one byte of ink per pixel, [fontDotSize] large.
  final dotsDrawn = <String, Uint8List?>{};
  Future<void>? _drawing;

  /// Has the engine draw the dots of [files], once.
  Future<void> drawDots(Motolii m, List<String> files) =>
      _drawing ??= Zone.root.run<Future<void>>(() async {
        // Runs once, like read.
        final byWord = <String, List<String>>{};
        for (final f in files) {
          (byWord[wordOf(f, 0)] ??= []).add(f);
        }
        for (final MapEntry(key: w, value: some) in byWord.entries) {
          final drawn = await m.typePictures(
            some,
            w,
            fontDotSize.$1,
            fontDotSize.$2,
          );
          for (final (i, f) in some.indexed) {
            dotsDrawn[f] = drawn[i];
          }
        }
        reads.value++;
      });

  /// The sample text for a font: line 0 is for its dot on the map, and lines 1 and 2 are the two lines FontMap uses for FontCLIP.
  ///
  /// A font that cannot show Latin letters uses its own sample text. Line 0 is its first word, and lines 1 and 2 are the
  /// two halves of its words. For a script with no spaces between words the halves are of its letters.
  String wordOf(String path, int line) {
    final own = samples[path];
    if (own == null) return const ['Motion', 'Hamburge', 'fonstiv'][line];
    final words = own.split(' '), letters = own.runes.toList();
    final some = words.length > 1
            ? words
            : [for (final r in letters) String.fromCharCode(r)],
        half = (some.length / 2).ceil(),
        by = words.length > 1 ? ' ' : '';
    return switch (line) {
      0 => words.length > 1 ? words.first : some.take(6).join(),
      1 => some.take(half).join(by),
      _ => some.skip(half).join(by),
    };
  }

  /// The dots as images Flutter can draw, by file, and the files whose image is being made.
  final dotImages = <String, ui.Image>{}, dotsMaking = <String>{};
}

/// Sets where the fonts used lately are stored. A test points it at a file of its own.
void fontRecentAt(File f) => FontsController._recentFile = f;
