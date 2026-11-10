// The Copies' tiles on Create (the Repeater, the expressions the maker added: dock_make_3.dart) drawn as the Effects
// shelf's are (effect_tiles.dart): on a document of its own in another isolate, by the inside, sixteen moments of
// EffectTiles.moments, made small with sips and the moving ones JPEG by ffmpeg, where the effect tiles go
// (~/Library/Caches/Motolii/tiles, named by the file and when it was written), played under the hand by TileMoving. What
// is drawn is what the Repeater recipe's head makes to show itself (create/repeats/repeater.js: a circle, five copies), its
// shape, size and copies as the file's own head says them (// make shape, // set size, // set copies: After Effects' expressions are in a
// comp's pixels, on a 1080 square), the expression put on it (fx_file). One the inside does not take (code: a SyntaxError) is marked and keeps its glyph.
// A closed pack on the Program shelf (dock_program.dart) the same way, but made by its name as the shelf makes it (make).
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FileImage, ResizeImage;

import '../../bridge/motolii.dart';
import 'effect_tiles.dart' show EffectTiles;

/// Where a tile goes: [kind] and [key] hashed, in the tiles' cache.
String tileHome(String kind, String key) {
  var hash = 1469598103934665603;
  for (final c in key.codeUnits) {
    hash = (hash ^ c) * 1099511628211;
  }
  return '${Platform.environment['HOME']}/Library/Caches/Motolii/tiles/${kind}_${(hash & 0x7fffffffffffffff).toRadixString(16)}.png';
}

/// The tiles of one kind, each asked for once and drawn in another isolate by [draw] (the homes drawn); [seen] says
/// which pictures of a home to forget when it is drawn.
class TileQueue<T> {
  TileQueue(this.draw, this.seen);
  final List<String> Function(String dir, List<T> jobs) draw;
  final Iterable<String> Function(String home) seen;
  final _asked = <String>{}, _queue = <T>[];
  var _drawing = false;

  /// Told once some are drawn: the tiles look again.
  final drawn = ValueNotifier<int>(0);

  /// [home]'s tile ('' none: not drawn yet, or the inside did not draw it), [job] queued once.
  String of(String home, T job) {
    if (File(home).existsSync()) return home;
    if (File('$home.none').existsSync() || Platform.environment['FLUTTER_TEST'] == 'true' || !_asked.add(home)) return '';
    _queue.add(job);
    if (!_drawing) unawaited(_work());
    return '';
  }

  Future<void> _work() async {
    _drawing = true;
    final dir = motoliiDir, draw = this.draw;
    try {
      while (_queue.isNotEmpty) {
        final some = [..._queue];
        _queue.clear();
        for (final h in await Isolate.run(() => draw(dir, some))) {
          for (final p in seen(h)) {
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
}

abstract final class CopiesTiles {
  static final _tiles = TileQueue<(String, String, String?)>(draw, (h) => [h, for (final (k, _) in EffectTiles.moments.indexed) EffectTiles.frame(h, k)]);

  /// Told once some are drawn: the tiles look again.
  static final drawn = _tiles.drawn;

  /// Where [file]'s tile goes: by its file and when it was written, as the inside's doc_tile names an effect's.
  static String home(String file, {String? make}) {
    final at = File(file).existsSync() ? File(file).lastModifiedSync().microsecondsSinceEpoch : 0;
    return tileHome('copies', '$file|$at|${make == null ? 'copies 5' : 'make $make'}');
  }

  /// [file]'s tile ('' none: not drawn yet, or the inside does not take it), asked for once; [make]: the recipe of that
  /// name, [file] its file, made as it is (a pack).
  static String of(String file, {String? make}) {
    final h = home(file, make: make);
    return _tiles.of(h, (file, h, make));
  }

  /// Each file's tile drawn where its home says; the homes drawn.
  static List<String> draw(String dir, List<(String, String, String?)> files) {
    final folder = Directory.systemTemp.createTempSync('motolii_copies'), made = <String>[];
    for (final (i, (f, home, make)) in files.indexed) {
      // (a document each: what one put on leaves (its knobs' values, js_<knob>) is not the next one's)
      final m = Motolii.open('${folder.path}/copies_$i.motolii', wide: 1080, high: 1080, dir: dir);
      if (m == null) continue;
      try {
        Directory(File(home).parent.path).createSync(recursive: true);
        final on = make != null ? _answer(m, m.later('create', word: make)) >= 1 : _put(m, f); // (a pack: made by its name, as the Program shelf makes it)
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

  /// An expression's: a shape as its head says, the expression put on it, taken by the inside as code is, or not.
  static bool _put(Motolii m, String f) {
    final shape = _said(f, 'make shape') ?? 'circle', t = m.add('shape', shape); // (its head's shape: a maze's lines)
    m
      ..say(t, 'fill', 'ff3366')
      ..set(t, 'size', (_head(f, 'size') ?? 0.1) * 2.5) // (larger than its own, its place as it says: seen at 192 px)
      ..set(t, 'copies', _head(f, 'copies') ?? 5);
    // (the rest its head says of its thing, as the recipe makes it: a maze's white, a row's height)
    for (final l in File(f).readAsLinesSync().takeWhile((l) => l.startsWith('//') && !l.startsWith('// then '))) {
      if (RegExp(r'^// (say|set) ([a-z_]+) (.+)$').firstMatch(l) case final w? when !{'size', 'copies', 'script'}.contains(w[2])) {
        w[1] == 'say' ? m.say(t, w[2]!, w[3]!) : m.set(t, w[2]!, double.tryParse(w[3]!) ?? 0);
      }
    }
    if (shape == 'line') m.set(t, 'tall', (_head(f, 'tall') ?? 1) * 4); // (a line as thick as it is seen at 192 px)
    // (put on, then taken by the inside as code is, or not: its SyntaxError, FxCode's "does not compile")
    return _answered(m, m.later('fx_file', layer: t, word: f)) && _answered(m, m.later('code', word: f));
  }

  /// A value its head sets its own thing to ("// set size 0.03"; null none).
  static double? _head(String file, String name) {
    for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// set $name ([0-9.]+)').firstMatch(l)?[1] case final v?) return double.tryParse(v);
    }
    return null;
  }

  /// A word its head says ("// make shape line"; null none).
  static String? _said(String file, String what) {
    for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//'))) {
      if (RegExp('^// $what ([a-z_]+)').firstMatch(l)?[1] case final v?) return v;
    }
    return null;
  }

  static bool _answered(Motolii m, int ticket) => _answer(m, ticket) == 1;

  /// What the inside said to a step (-1: nothing in ten seconds; a recipe made: its new thing).
  static int _answer(Motolii m, int ticket) {
    var a = -1;
    for (var n = 0; n < 2000 && (a = m.answer(ticket)) == -1; n++) {
      sleep(const Duration(milliseconds: 5));
    }
    return a;
  }
}
