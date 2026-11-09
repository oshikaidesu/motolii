// The Copies' tiles on Create (the Repeater, the expressions the maker added: dock_make_3.dart) drawn as the Effects
// shelf's are (effect_tiles.dart): on a document of its own in another isolate, by the inside, sixteen moments of
// EffectTiles.moments, made small with sips and the moving ones JPEG by ffmpeg, where the effect tiles go
// (~/Library/Caches/Motolii/tiles, named by the file and when it was written), played under the hand by TileMoving. What
// is drawn is what the Repeater recipe's head makes to show itself (recipes/repeater.js: a circle, five copies), the
// expression put on it (fx_file). One the inside does not take (code: a SyntaxError) is marked and keeps its glyph.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FileImage, ResizeImage;

import '../motolii.dart';
import 'effect_tiles.dart' show EffectTiles;

abstract final class CopiesTiles {
  static final _asked = <String>{}, _queue = <(String, String)>[];
  static var _drawing = false;

  /// Told once some are drawn: the tiles look again.
  static final drawn = ValueNotifier<int>(0);

  /// Where [file]'s tile goes: by its file and when it was written, as the inside's doc_tile names an effect's.
  static String home(String file) {
    var hash = 1469598103934665603;
    final at = File(file).existsSync() ? File(file).lastModifiedSync().microsecondsSinceEpoch : 0;
    for (final c in '$file|$at|copies 1'.codeUnits) {
      hash = (hash ^ c) * 1099511628211;
    }
    return '${Platform.environment['HOME']}/Library/Caches/Motolii/tiles/copies_${(hash & 0x7fffffffffffffff).toRadixString(16)}.png';
  }

  /// [file]'s tile ('' none: not drawn yet, or the inside does not take it), asked for once.
  static String of(String file) {
    final h = home(file);
    if (File(h).existsSync()) return h;
    if (File('$h.none').existsSync() || Platform.environment['FLUTTER_TEST'] == 'true' || !_asked.add(h)) return '';
    _queue.add((file, h));
    if (!_drawing) unawaited(_work());
    return '';
  }

  static Future<void> _work() async {
    _drawing = true;
    final dir = motoliiDir;
    try {
      while (_queue.isNotEmpty) {
        final some = [..._queue];
        _queue.clear();
        for (final h in await Isolate.run(() => draw(dir, some))) {
          for (final p in [h, for (final (k, _) in EffectTiles.moments.indexed) EffectTiles.frame(h, k)]) {
            ResizeImage(FileImage(File(p)), width: EffectTiles.readWide).evict();
          }
        }
        drawn.value++;
      }
    } catch (_) {
    } finally {
      _drawing = false;
    }
  }

  /// Each file's tile drawn where its home says; the homes drawn.
  static List<String> draw(String dir, List<(String, String)> files) {
    final folder = Directory.systemTemp.createTempSync('motolii_copies'), made = <String>[];
    for (final (i, (f, home)) in files.indexed) {
      // (a document each: what one put on leaves (its knobs' values, js_<knob>) is not the next one's)
      final m = Motolii.open('${folder.path}/copies_$i.motolii', wide: 384, high: 384, dir: dir);
      if (m == null) continue;
      try {
        Directory(File(home).parent.path).createSync(recursive: true);
        final t = m.add('shape', 'circle');
        m
          ..say(t, 'fill', 'ff3366')
          ..set(t, 'size', 0.2)
          ..set(t, 'copies', 5);
        // (put on, then taken by the inside as code is, or not: its SyntaxError, FxCode's "does not compile")
        final on = _answered(m, m.later('fx_file', thing: t, word: f)) && _answered(m, m.later('code', word: f));
        final pictures = [
          if (on)
            for (final (k, at) in EffectTiles.moments.indexed)
              if (m.at(at) && m.still('${home.substring(0, home.length - 4)}_$k.png')) '${home.substring(0, home.length - 4)}_$k.png',
        ];
        if (pictures.length < EffectTiles.moments.length) {
          File('$home.none').writeAsStringSync('');
          for (final p in pictures) {
            File(p).deleteSync();
          }
          continue;
        }
        Process.runSync('sips', ['-Z', '192', ...pictures]);
        File(pictures[EffectTiles.still]).copySync(home);
        final base = home.substring(0, home.length - 4);
        try {
          Process.runSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', '${base}_%d.png', '-q:v', '6', '-start_number', '0', '${base}_%d.jpg']);
        } on ProcessException {
          // (no ffmpeg: its still alone)
        }
        for (final p in pictures) {
          File(p).deleteSync();
        }
        made.add(home);
      } catch (_) {
        try {
          File('$home.none').writeAsStringSync('');
        } catch (_) {}
      } finally {
        m.close();
      }
    }
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
    return made;
  }

  static bool _answered(Motolii m, int ticket) {
    var a = -1;
    for (var n = 0; n < 2000 && (a = m.answer(ticket)) == -1; n++) {
      sleep(const Duration(milliseconds: 5));
    }
    return a == 1;
  }
}
