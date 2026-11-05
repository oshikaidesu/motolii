// Every effect on the shelf has a tile that shows what it does, as Alight Motion's do (reports/alight_ui.md, 71 and 72).
// AbsentMotion shows each of its effects by a table written beforehand (tools/effect_showcase.json); here a tile is told
// the same things by the effect itself, so a file put in by its maker needs no line and no developer. Read from it
// (doc_recipes.h, isf_tags): a transition's progress goes from 0 to 1, what runs by the clock or keeps its frame before is
// left to run. Measured (AbsentMotion's change(), reports/sketch_import_2026-11-01.md): the sample stands still, so what
// moves is the effect; the knob that stands for it goes between two values ([_telling]); nothing seen on the whole photo,
// it goes on a card going past on AbsentMotion's grid (its "move" layout), where what it does at an edge or to what moves
// shows; with no knob to turn, the line between before and after goes across it. No tile stands but one that shows nothing.
// AbsentMotion's own effects keep their line of the table. Sixteen pictures a twelfth of a second apart, as its moving
// tiles, played there and back at 24 a second, so nothing steps or jumps where it starts again. The sample is the balloon
// fx_tiles.sh draws on (fx_sample.jpg). Drawn on a
// document of its own in another isolate (as create_preview.dart reckons the recipes), where the inside says one drawn
// for it goes (its home in ~/Library/Caches/Motolii/tiles, named by the file and when it was written: doc_recipes.h
// doc_tile), then shown at once. Put on as fx_tiles.sh and edit.sh say it: a screen effect (.fs, .wgsl) on the whole
// picture; else on the photo, as a thing's (an AviUtl2 script). Made small with sips (192 px), the moving ones JPEG by
// ffmpeg, one run a tile. Then set beside the sample's own pictures with ffmpeg's psnr (the tool the inside writes films
// with): seen to change nothing in any of them (over 40 dB: helpers of other scripts, PSD ones, scripts that stop on a
// call not made yet) it is marked (home.same), and the shelf says so instead of passing the sample off as the effect.
// The maker's own folder is watched while the window is open (dart:io's watch, FSEvents on a Mac): a file put in or taken
// out there and the shelves are read again (BRIDGE.md rule 8, the second half), and its tile drawn, ahead of the rest.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show FileImage, ResizeImage;

import '../motolii.dart';
import 'ws.dart' show wsTextFont;

abstract final class EffectTiles {
  static final _asked = <String>{}, _queue = <(String, String)>[];
  static var _drawing = false;
  static void Function()? _told;

  /// How many of the tiles in line are drawn, out of how many, while any are (the shelf's reload mark says it).
  static final progress = ValueNotifier<(int, int)?>(null);

  /// [file]'s tile drawn again, ahead of the line, or, with none, every tile on the shelf (the reload mark).
  static void again(Motolii m, {String? file}) {
    _queue.removeWhere((q) => file == null || q.$1 == file);
    for (final (_, f) in m.effects) {
      final home = m.tileHome(f);
      if (home.isEmpty || (file != null && f != file)) continue;
      _asked.remove(home);
      try {
        File('$home.tells').deleteSync();
      } catch (_) {}
      if (file != null && _asked.add(home)) _queue.insert(0, (f, home));
    }
    if (_told case final changed?) ask(m, changed);
  }

  /// How wide a tile's pictures are read (dock_effects.dart _Moving's Image.file): one drawn again under its own name is
  /// let go of at that width, or Flutter's image cache goes on showing the one drawn before (seen: AbsentMotion's split
  /// tiles came only once the window was opened again).
  static const readWide = 256;

  /// The moments its pictures are drawn at (AbsentMotion's 16 at 12 a second), and the one its still is: well on the way.
  static final moments = [for (var k = 0; k < 16; k++) 0.1 + k / 12];
  static const still = 10;

  /// What AbsentMotion shows each of its effects with (its tools/effect_showcase.json, Apache-2.0): the knobs that make
  /// the effect plain to see, and where its picture is split into before (left) and after. By the effect's name in the
  /// table, the file's own `am_<name>.wgsl`; each knob as from_absent.py named it (skslc's R_ before a name WGSL keeps for
  /// itself, origin_x and the like with _ after), a vector or a colour one knob each way; a moving line's list of numbers
  /// for one knob the stops it goes through ([sweeps]), its layer moved the sample's drift ([moves]), the words its
  /// text ones are shown on ([text], its "text" layout), its strokes drawn ([drawn], its "drawing" layout). An .am (one moved by its own motion.cpp) by its --absent: name.
  /// Null: a file the table has not.
  static ({Map<String, double> knobs, double? split, Map<String, List<double>> sweeps, bool moves, String? text, bool drawn})? showcase(String file, String head, Map<String, dynamic> table) {
    final name = RegExp(r'/am_([a-z0-9]+)\.wgsl$').firstMatch(file)?.group(1) ?? RegExp(r'^// --absent:([a-z0-9]+)', multiLine: true).firstMatch(head)?.group(1);
    final show = name == null ? null : (table['effects'] as Map<String, dynamic>?)?[name] as Map<String, dynamic>?;
    if (show == null) return null;
    final tracks = {for (final t in RegExp(r'--track@([A-Za-z0-9_]+):').allMatches(head)) t.group(1)!};
    final stem = file.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '').replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final knobs = <String, double>{}, sweeps = <String, List<double>>{};
    String? named(String p, String way) => [for (final n in [p, 'R_$p', '${p}_']) '$n$way'].where(tracks.contains).firstOrNull;
    for (final MapEntry(key: p, :value) in ((show['params'] as Map<String, dynamic>?) ?? const {}).entries) {
      if (show.containsKey('animate') && value is List && value.every((x) => x is num)) {   // (effect_thumbs.py prop: its keys, evenly apart)
        if (named(p, '') case final knob?) {
          sweeps['js_${stem}_$knob'] = [for (final x in value) (x as num).toDouble()];
          continue;
        }
      }
      final parts = switch (value) {
        num v => [v.toDouble()],
        bool v => [v ? 1.0 : 0.0],
        String v when RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v) => [for (var i = 1; i < 7; i += 2) int.parse(v.substring(i, i + 2), radix: 16) / 255, 1.0],
        List v when v.length <= 4 && v.every((x) => x is num) => [for (final x in v) (x as num).toDouble()],   // (a vector; a longer list is not one: left as the file says)
        _ => const <double>[],
      };
      for (final (i, v) in parts.indexed) {
        final way = parts.length > 1 ? '_${'xyzw'[i]}' : '';
        if (named(p, way) case final knob?) knobs['js_${stem}_$knob'] = v;
      }
    }
    return (knobs: knobs, split: (show['split'] as num?)?.toDouble(), sweeps: sweeps, moves: show['layout'] == 'move', text: show['layout'] == 'text' ? '${show['text'] ?? ''}' : null, drawn: show['layout'] == 'drawing');
  }

  /// How much moving each knob of [file] alone shows its effect, 0 to 10, as an agent that read only the effect's code
  /// weighed it (engine/knob_weights.json, by the shelf's entry: its file from the library's folder, an AviUtl2 script's
  /// #name and all; set beside AbsentMotion's effect_showcase.json, where a hand says which knob its tile moves, its
  /// heaviest was that knob in 26 of 28), by the inside's names (doc_values.h doc_screen_knob: the file's stem before
  /// the knob's), `_time` how much letting it run shows it. Empty: not weighed (the maker's own).
  static Map<String, double> weighed(String dir, String file) => {
    for (final MapEntry(key: k, value: w) in _entry(dir, file).entries)
      if (w is num) k == '_time' ? k : 'js_${_stem(file)}_$k': w.toDouble(),
  };

  /// What the tile moves to show [file] best, as one who looked at each knob moved on the sample chose it (the same
  /// file's _best): a knob by the inside's name, from and to; ('_time', 0, 0) let it run. Null: none chosen.
  static (String, double, double)? best(String dir, String file) => switch (_entry(dir, file)['_best']) {
    '_time' => ('_time', 0, 0),
    [final String k, final num from, final num to] => ('js_${_stem(file)}_$k', from.toDouble(), to.toDouble()),
    _ => null,
  };

  /// The knobs its tile holds while it moves the one chosen, as a hand set them beside it (the same file's _set: a curve's
  /// line shown while the photo goes round it, Mathy_Su's 線透明度), by the inside's names. Empty: none.
  static Map<String, double> held(String dir, String file) => switch (_entry(dir, file)['_set']) {
    final Map<String, dynamic> set => {for (final MapEntry(:key, :value) in set.entries) if (value is num) 'js_${_stem(file)}_$key': value.toDouble()},
    _ => const {},
  };

  /// What the sample lacks for [file] to show, as the one who looked said it (its _needs: text, picture, sound, motion,
  /// chain, path, shape, behind); '' nothing, or not looked at. (_stops beside it: the call an AviUtl2 script stopped on
  /// when it was looked at, aviutl_fx.h's "not yet".)
  static String needs(String dir, String file) => switch (_entry(dir, file)['_needs']) {
    final String w => w,
    _ => '',
  };

  /// What the inside said when [file] stopped as the one who looked put it on (its _said, the inside's own "stops:"
  /// words, aviutl_fx.h: a .mod2 it needs, a call not made here yet, one AviUtl2 has not), '' none: a tile that shows
  /// nothing says why under the shelf (the user, 11/5: NO CHANGE with a reason, never left unsaid).
  static String stopped(String file) => switch (_entry(motoliiDir, file)['_said']) {
    final String w => w,
    _ => '',
  };

  /// What a tile that shows nothing says, instead of passing the sample off as the effect: what the sample lacks for it,
  /// as one who looked said it; one looked at that lacks nothing (or only text, which its tile is drawn on) is one the
  /// inside does not draw yet (as an AviUtl2 script stops on a call not made: aviutl_fx.h's "not yet"); NO CHANGE, one
  /// not looked at (the maker's own).
  static String sameTag(String file) => switch (_entry(motoliiDir, file).containsKey('_stops') ? '' : needs(motoliiDir, file)) {   // (one seen to stop: what it lacks is not why)
    'picture' => 'FOR 2 LAYERS',
    'sound' => 'FOR SOUND',
    'motion' => 'FOR VIDEO',
    'chain' => 'PART OF A SET',
    'shape' => 'FOR CUT-OUTS',
    'behind' => 'NEEDS BACKDROP',
    'path' => 'FOR PATHS',
    _ when looked(motoliiDir, file) => 'UNSUPPORTED',
    _ => 'NO CHANGE',
  };

  /// Whether [file] was looked at (its line in the file), so a tile that shows nothing and lacks nothing is one the
  /// inside does not draw yet.
  static bool looked(String dir, String file) => _entry(dir, file).containsKey('_best') || _entry(dir, file).containsKey('_needs') || _entry(dir, file).containsKey('_why');

  static Map<String, dynamic> _entry(String dir, String file) {
    final all = _weights ??= () {
      try {
        return jsonDecode(File('$dir/knob_weights.json').readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        return const <String, dynamic>{};
      }
    }();
    return (all[file.startsWith('$dir/') ? file.substring(dir.length + 1) : file] as Map<String, dynamic>?) ?? const {};
  }

  static String _stem(String file) => String.fromCharCodes([   // (byte by byte, as the inside's std::isalnum: ライ is ______)
    for (final b in utf8.encode(file.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), ''))) (b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || b == 95 ? b : 95,
  ]);

  static Map<String, dynamic>? _weights;

  /// What a tile is told when it is drawn (its .tells beside it): the weights it goes by, what it moves and what it
  /// lacks, so one weighed or looked at anew is drawn anew. Null: drawn before a tile was told anything.
  static String tells(String dir, String file) => switch ({for (final MapEntry(:key, :value) in _entry(dir, file).entries) if (key != '_why') key: value}) {
    final w when w.isEmpty => '',
    final w => jsonEncode(w),
  };
  static String? _toldOf(String home) {
    try {
      return File('$home.tells').readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  /// AbsentMotion's table, read once (in each isolate that draws): empty where the library has not got it.
  static Map<String, dynamic> table(String dir) {
    try {
      return jsonDecode(File('$dir/third_party/AbsentMotion/tools/effect_showcase.json').readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Its moving pictures: home_0.jpg … home_7.jpg beside its still (none for a picture not drawn here).
  static String frame(String home, int k) => '${home.substring(0, home.length - 4)}_$k.jpg';
  static String _drawn(String home, int k) => '${home.substring(0, home.length - 4)}_$k.png';   // (as the inside draws it, before it is made small)

  /// The maker's own folder: MOTOLII_OWN, or ~/Library/Application Support/Motolii (as the inside's doc_folders).
  static String get own => Platform.environment['MOTOLII_OWN'] ?? '${Platform.environment['HOME']}/Library/Application Support/Motolii';

  /// The library's own folders beside the maker's (as the inside's doc_folders: the folder above its out/).
  static List<String> get library => [for (final f in const ['effects', 'aviutl_scripts', 'recipes', 'animators', 'relations']) '$motoliiDir/$f'];

  /// Watched until the subscription is cancelled; [changed] is told after the folders are read again and after tiles are drawn.
  static StreamSubscription<FileSystemEvent>? watch(Motolii m, void Function() changed, {void Function(String file)? program}) {
    ask(m, changed);
    final dir = Directory('$own/effects');
    try {
      dir.createSync(recursive: true); // (there to put files in, as README says)
    } catch (_) {
      return null;
    }
    Timer? soon;
    void again() {
      m.forgetFolders();
      changed();
      ask(m, changed);
    }
    final inner = <StreamSubscription<FileSystemEvent>>[];
    final merged = StreamController<FileSystemEvent>(onCancel: () => Future.wait([for (final w in inner) w.cancel()]));   // (one watch a folder, told as one)
    inner.addAll([for (final p in [own, ...library.where((p) => Directory(p).existsSync())]) Directory(p).watch(recursive: true).listen(merged.add)]);
    final told = <String, Timer>{};
    return merged.stream.listen((e) {
      if (program != null && e.path.startsWith('$own/programs/')) {   // (a program's file: what is made from it follows, no shelf is read again)
        told[e.path]?.cancel();
        told[e.path] = Timer(const Duration(milliseconds: 300), () => program(e.path));
        return;
      }
      soon?.cancel();
      soon = Timer(const Duration(milliseconds: 300), again); // (a copy is several events: read once it has settled)
    });
  }

  /// The effects on the shelf whose tile is not drawn yet: one drawn before (this run, or another) shown at once; the
  /// rest put in line, the maker's own at its head (what was just put in), drawn a few at a time, each few shown when done.
  static void ask(Motolii m, void Function() changed) {
    final mine = <(String, String)>[], theirs = <(String, String)>[];
    var shown = false;
    _told = changed;
    for (final (_, f) in [...m.effects]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))) {   // (as the shelf lists them: its top first)
      final home = m.tileHome(f);
      final stale = home.isNotEmpty && _toldOf(home) != tells(motoliiDir, f);   // (drawn before a tile showed what its effect does, or by other weights: drawn again)
      if (home.isEmpty || (!stale && m.picture(f) == home)) continue;
      if (!stale && File(home).existsSync()) {
        m.tileDrawn(home, same: File('$home.same').existsSync());
        shown = true;
      } else if (_asked.add(home)) {
        (f.startsWith(own) ? mine : theirs).add((f, home));
      }
    }
    if (shown) changed();
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;   // (flutter test's widget tests: none drawn behind them, seven hundred pictures on the GPU while they time the window; flutter drive's draw them)
    _queue
      ..insertAll(0, mine)
      ..addAll(theirs);
    if (!_drawing) unawaited(_work(m, changed));
  }

  static Future<void> _work(Motolii m, void Function() changed) async {
    _drawing = true;
    final dir = motoliiDir;
    var done = 0;
    try {
      while (_queue.isNotEmpty) {
        progress.value = (done, done + _queue.length);
        final some = _queue.take(12).toList();
        _queue.removeRange(0, some.length);
        done += some.length;
        for (final (home, same) in await Isolate.run(() => draw(dir, some))) {
          for (final p in [home, for (final (k, _) in moments.indexed) frame(home, k)]) {
            ResizeImage(FileImage(File(p)), width: readWide).evict();
          }
          m.tileDrawn(home, same: same);
        }
        changed();
      }
    } finally {
      _drawing = false;
      progress.value = null;
    }
  }

  static List<(String, bool)> draw(String dir, List<(String, String)> files) {
    final folder = Directory.systemTemp.createTempSync('motolii_tiles'), drawn = <(String, bool)>[];
    final m = Motolii.open('${folder.path}/tiles.motolii', wide: 384, high: 384, dir: dir);   // (AbsentMotion's RENDER, its THUMB below)
    if (m == null) return drawn;
    _ffmpeg(['-f', 'lavfi', '-i', 'color=c=0x2c2c34:s=384x384,drawgrid=w=48:h=48:t=1:c=0x45454f', '-frames:v', '1', '${folder.path}/grid.png']);   // (its grid, where its "move" layout stands)
    // (under the photo, the picture a transition goes to: put on a clip, one takes it away and what is under it shows
    //  (doc_fx_file), as gl-transitions' own previews go from one photo to another (scripts/rendering/render-preview.mjs:
    //  a road among its three); on the whole screen it had nothing to go to, and went to black)
    final grid = m.add('picture', '${folder.path}/grid.png'), under = m.add('picture', '$dir/fx_sample_end.jpg'), photo = m.add('picture', '$dir/fx_sample.jpg'), card = m.add('picture', '$dir/fx_sample.jpg');
    final words = m.add('text', wsTextFont);   // (for one that works on text: white words over the grid, as AbsentMotion's effect_thumbs.py lays its "text" layout)
    m
      ..say(words, 'fill', 'ffffff')
      ..set(words, 'size', 0.4)
      ..set(grid, 'size', 3.6)
      ..set(under, 'size', 3.6)
      ..set(photo, 'size', 3.6)
      ..set(card, 'size', 1.8)
      ..key(card, 'x', moments.first, -0.84)
      ..key(card, 'x', moments.last, 0.84);
    var drawing = 0;   // (AbsentMotion's sample drawing, made the first time one asks for it; -1 not made)
    int sketch() {   // (effect_thumbs.py sketch(): a spiral and a wave, pen strokes, as the window's brush makes them (doc_brush), its RENDER 384 as here)
      if (drawing != 0) return drawing;
      m.at(0);   // (a stroke is on from the stage's present moment, as a thing added is: from the first, as the tile's pictures are)
      final made = <int>[];
      for (final (wide, line) in [
        (16, [for (var j = 0; j < 100; j++) (192 + math.cos(j / 9) * (14 + j * 1.1), 172 + math.sin(j / 9) * (14 + j * 1.1))]),
        (12, [for (var j = 0; j < 41; j++) (62 + j * 6.5, 302 + math.sin(j / 3) * 18)]),
      ]) {
        final ticket = m.later('brush', word: '0 $wide ${[for (final (x, y) in line) '${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} 1'].join(' ')}');
        var made1 = -1;
        for (var n = 0; n < 2000 && (made1 = m.answer(ticket)) == -1; n++) {
          sleep(const Duration(milliseconds: 5));
        }
        made.add(made1);   // (the shape it made)
      }
      if (made.any((t) => t <= 0)) return drawing = -1;
      m
        ..say(made[0], 'drawing', '${m.word(made[0], 'drawing')} ; ${m.word(made[1], 'drawing')}')   // (one drawing of both, as AbsentMotion's is one layer)
        ..say(made[0], 'path', '${m.word(made[0], 'path')} ${m.word(made[1], 'path')}')
        ..say(made[0], 'fill', 'ffc23d')
        ..set(made[1], 'opacity', 0);
      return drawing = made[0];
    }
    var small = false;   // (the photo small over the grid: _lay "small")
    void lay(bool moving, {bool road = false, int only = 0}) {   // (only: the words or the drawing alone over the grid)
      for (final (thing, seen) in [(grid, moving || only != 0 || small), (card, moving), (photo, !moving && only == 0), (under, road), (words, only == words), if (drawing > 0) (drawing, only == drawing)]) {
        m.set(thing, 'opacity', seen ? 1 : 0);
      }
    }
    List<String> shoot(String home, {bool plays = false, void Function(double at)? turn}) {   // (its pictures, made small; plays: one that keeps its frame before (ISF's PERSISTENT) drawn every other frame from the start, the sixteen kept as it passes them, as fx_tiles.sh warms one)
      final made = <String>[];
      bool one(double at, String to) {
        turn?.call(at);
        return m.at(at) && m.still(to);
      }
      if (plays) {
        for (var n = 1, k = 0; k < moments.length && n <= (moments.last * 30).round(); n++) {
          final keep = n == (moments[k] * 30).round();
          if (one(n / 30, keep ? _drawn(home, k) : '${folder.path}/warm.png') && keep) made.add(_drawn(home, k));
          if (keep) k++;
        }
      } else {
        made.addAll([for (final (k, at) in moments.indexed) if (one(at, _drawn(home, k))) _drawn(home, k)]);
      }
      if (made.isNotEmpty) Process.runSync('sips', ['-Z', '192', ...made]);
      return made;
    }
    lay(false);
    final plain = shoot('${folder.path}/plain.png');   // (the sample as it is, to tell a tile that shows nothing done)
    if (m.at(moments[still])) m.still('${folder.path}/sample.png');   // (as large as the tries set beside it)
    lay(true);
    final moved = shoot('${folder.path}/moved.png');
    final enough = plain.length == moments.length && moved.length == moments.length;
    final shows = table(dir), own = {for (final t in [photo, card, words]) ...m.values(t)};   // (a drawing's are a shape's: none of them js_)
    for (final (f, home) in files) {
      try {
        Directory(File(home).parent.path).createSync(recursive: true);
      } catch (_) {
        continue;
      }
      final show = f.endsWith('.wgsl') || f.endsWith('.am') ? showcase(f, File(f).readAsStringSync(), shows) : null;
      final said = m.tags(f), isf = f.endsWith('.fs') ? File(f).readAsStringSync() : '', plays = RegExp(r'"PERSISTENT"\s*:\s*(true|1)').hasMatch(isf);
      final lists = [for (final l in RegExp(r'\{[^{}]*"TYPE"\s*:\s*"long"[^{}]*\}').allMatches(isf)) '_${RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1)}'];   // (ISF's "long": a choice, which the inside takes as a span)
      final weights = weighed(dir, f), time = weights['_time'] ?? 0;
      final chosen = best(dir, f);   // (what one who looked at each knob moved on the sample chose to show it by)
      final timed = chosen?.$1 == '_time' || (time > 0 && weights.entries.every((w) => w.key == '_time' || w.value <= time));   // (its weights say letting it run shows it best: no knob turned, as AbsentMotion's Noise Displace)
      final runs = said.contains('time') || said.contains('feedback') || plays || timed;
      final first = (show?.moves ?? false) || said.contains('feedback') || plays;   // (an effect of what was has something going past it to see)
      final base = home.substring(0, home.length - 4);
      var same = false, split = false, stands = true;
      var made = const <String>[];
      final worded = show?.text != null || needs(dir, f) == 'text';   // (one for text, as its table or one who looked says: on words alone)
      final alone = worded ? words : (show?.drawn ?? false) || needs(dir, f) == 'path' ? math.max(sketch(), 0) : 0;   // (one for strokes or a path: on the drawing alone)
      final aloneOk = alone != 0 && () {   // (the words or the drawing as they are, beside which it is seen to do something)
        if (worded) m.say(words, 'text', show?.text?.isNotEmpty ?? false ? show!.text! : 'Motolii');
        lay(false, only: alone);
        return shoot('${folder.path}/alone.png').length == moments.length;
      }();
      final bare = alone != 0 ? 'alone' : 'plain';
      small = alone == 0 && _entry(dir, f)['_lay'] == 'small';   // (one that takes the thing round a path (Mathy_Su's curves): the photo small over the grid, so the path it goes round is seen about it, not under it)
      if (small) m.set(photo, 'size', 0.6);
      for (final moving in alone != 0 ? [false] : [first, if (!first) true]) {   // (nothing seen on the whole photo: on a card going past, where what it does at an edge or to what moves shows, as AbsentMotion's "move")
        final passes = said.contains('transition') && alone == 0;   // (one is put on the photo, the road under it)
        lay(moving, road: passes, only: alone);
        final whole = !moving && !passes && alone == 0 && (f.endsWith('.fs') || f.endsWith('.wgsl') || f.endsWith('.json')) && m.say(0, 'script', f);   // (.json: Filament's own settings, laid on the stage's view: viewer_settings.h)   // (a screen effect; the stage takes an AviUtl2 script too, but draws none of it: motolii.h, a thing's)
        final thing = alone != 0 ? alone : moving ? card : photo, on = whole ? 0 : thing, onIt = !whole && m.say(thing, 'fx', f);   // (as a thing's: as edit.sh says it)
        final filed = <String, double>{};
        for (final MapEntry(:key, :value) in {...?show?.knobs, ...held(dir, f)}.entries) {
          if (m.value(on, key, 0) case final was? when !_part.hasMatch(key)) filed[key] = was;
          m.set(on, key, value);   // (as AbsentMotion shows it: its table's values, not the file's defaults)
        }
        final knobs = [for (final v in m.values(on)) if (v.startsWith('js_') && !own.contains(v)) v];
        final sweeps = <String, List<double>>{...?show?.sweeps};
        final heaviest = ([for (final k in knobs) if (weights[k] case final w? when w > time) (k, w)]..sort((a, b) => b.$2.compareTo(a.$2))).firstOrNull?.$1;   // (the knob its weights say shows it most, more than letting it run)
        if (knobs.where((k) => k.endsWith('_progress')).firstOrNull case final p? when said.contains('transition')) {
          sweeps[p] = const [0, 1];   // (a transition seen going from 0 to 1 across its pictures)
        } else if (chosen case (final k, final from, final to) when sweeps.isEmpty && knobs.contains(k)) {
          sweeps[k] = [from, to];   // (as the one who looked chose it, ahead of the one measured)
        } else if (sweeps.isEmpty && (!runs || heaviest != null)) {   // (one that runs by the clock its heaviest knob turned as it runs, or none)
          if (_telling(m, on, knobs, filed, lists, folder.path, first: heaviest, alone: runs) case final knob?) sweeps[knob.$1] = [knob.$2, knob.$3];
        }
        if (!moving && alone == 0 && !runs && sweeps.isEmpty && enough && _same('${folder.path}/usual.png', '${folder.path}/sample.png')) {   // (nothing on the photo: no sixteen pictures of nothing)
          if (whole) m.say(0, 'script', 'none');
          if (onIt) m.say(thing, 'fx', 'none');
          same = true;
          continue;
        }
        made = shoot(home, plays: plays, turn: (at) {
          final t = ((at - moments.first) / (moments.last - moments.first)).clamp(0.0, 1.0);
          for (final MapEntry(key: knob, value: stops) in sweeps.entries) {
            m.set(on, knob, _along(stops, t * t * (3 - 2 * t)));   // (smoothstep: there and back, it does not hit its ends)
          }
        });
        if (whole) m.say(0, 'script', 'none');
        if (onIt) m.say(thing, 'fx', 'none');
        if (made.length < moments.length) continue;
        same = enough && (alone == 0 || aloneOk) && _unseen(home, '${folder.path}/${moving ? 'moved' : bare}');
        stands = !moving && !runs && sweeps.isEmpty;
        split = stands && !said.contains('generator');
        if (!same) break;
      }
      if (small) m.set(photo, 'size', 3.6);
      small = false;
      if (made.length < moments.length || same) {   // (put on but not drawn, a script that stops, or nothing seen: the sample as it is)
        for (final (k, _) in moments.indexed) {
          if (enough) File('${folder.path}/${aloneOk ? bare : 'plain'}_$k.png').copySync(_drawn(home, k));
        }
        stands = true;
        if (!enough) continue;
      }
      final at = split ? '0.1+0.8*(3*pow(N/15,2)-2*pow(N/15,3))' : show?.split;   // (AbsentMotion's split, its 22 where one stands; no knob to turn, what it did is seen by the line going across: no model for that, the user's wish that no tile stand)
      if (at != null && !same && enough) {   // (before at its left, as AbsentMotion's effect_thumbs.py lays the photo over it up to there, a white line where they meet)
        if (_ffmpeg(['-i', '${base}_%d.png', '-i', '${folder.path}/${bare}_%d.png', '-filter_complex', "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_expr='if(lt(abs(X-W*($at)),1),255,if(lt(X,W*($at)),B,A))'", '-start_number', '0', '${base}_%d.split.png'])) {
          for (final (k, _) in moments.indexed) {
            File('${base}_$k.split.png').renameSync(_drawn(home, k));
          }
          stands = false;
        }
      }
      File(_drawn(home, EffectTiles.still)).copySync(home);
      if (stands) {
        for (final (k, _) in moments.indexed) {
          File(frame(home, k)).existsSync() ? File(frame(home, k)).deleteSync() : null;   // (nothing moves: its still alone)
        }
      } else {
        _ffmpeg(['-i', '${base}_%d.png', '-q:v', '6', '-start_number', '0', '${base}_%d.jpg']);
      }
      for (final (k, _) in moments.indexed) {
        File(_drawn(home, k)).deleteSync();
      }
      try {
        same ? File('$home.same').writeAsStringSync('') : File('$home.same').deleteSync();
      } catch (_) {}
      File('$home.tells').writeAsStringSync(tells(dir, f));
      drawn.add((home, same));
    }
    m.close();
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
    return drawn;
  }

  /// How far along [t] (0 to 1) a line of evenly spaced stops stands.
  static double _along(List<double> stops, double t) {
    final at = t * (stops.length - 1), k = at.floor().clamp(0, stops.length - 2);
    return stops[k] + (stops[k + 1] - stops[k]) * (at - k);
  }

  /// The knob that stands for an effect, and the two values it goes between. Set beside the 121 lines of AbsentMotion's
  /// table where a hand says which (reports/sketch_import_2026-11-01.md), the one that changes the picture most is right
  /// for 3 of the 27 it moves: what a hand moves is what plays as a clock would, rotY, progress, evolution, phase (After
  /// Effects' own Evolution and Transition Completion); then, of [filed], the knobs the hand gave a value, the one that
  /// makes most of it, from what the file has to that; then the file's first that shows, its author's first, single
  /// numbers before a vector's parts, leaving what only fades it out, draws it anew at each value or picks from a list. Each is tried half
  /// way to the far end of its span (all the way round, an angle's far end is where it began), at most eight, as
  /// fx_first.sh tries them and AbsentMotion's change() tells a tile that shows nothing; a turn or a progress goes that
  /// far, as the hand's, the rest as far as is plainly seen, short of wiping the picture out. Null: none shows.
  /// Before all of those, [first]: the knob its weights say shows it most ([weighed]), the user's wish (11/5) that a tile
  /// move by the knob that stands for it; [alone], that one or none (an effect that runs by the clock is let run).
  static (String, double, double)? _telling(Motolii m, int on, List<String> knobs, Map<String, double> filed, List<String> lists, String folder, {String? first, bool alone = false}) {
    if (!m.at(moments[still]) || !m.still('$folder/usual.png')) return null;
    bool says(RegExp words, String k) => words.hasMatch(k) || words.hasMatch(m.shown(k)?.label ?? '');
    double change(String k, double to, double back) {
      m.set(on, k, to);
      m.still('$folder/try_0.png');
      m.set(on, k, back);
      return _changes(folder).firstOrNull?.$2 ?? 0;
    }
    var tried = 0;
    (String, double, double)? turned(String k) {
      final span = m.shown(k), range = m.range(on, k), from = m.value(on, k, 0);
      if (_faint.hasMatch(k) || range == null || from == null || const ['onoff', 'seed'].contains(span?.look) || m.words(on, k).isNotEmpty || lists.any(k.endsWith) || tried++ == 8) return null;
      final (low, high) = span != null && span.high > span.low ? (span.low, span.high) : range;
      final half = from + (((high - from).abs() >= (from - low).abs() ? high : low) - from) / 2;
      if (change(k, half, from) <= _plain) return null;
      if (says(_whole, k)) return (k, from, half);
      final steps = [if (says(_clock, k)) ...[1 / 512, 1 / 128], 1 / 32, 1 / 8, 1 / 2, 1.0, 2.0];   // (spans go to 4000 in an AviUtl2 script: what shows is often far short of half way; a phase's to 2000, the hand's goes to 3)
      final at = [for (final s in steps) from + (half - from) * s];
      for (final (i, v) in at.indexed) {
        m.set(on, k, v);
        m.still('$folder/try_$i.png');
      }
      m.set(on, k, from);
      final fine = _changes(folder), ways = [
        for (final (i, v) in at.indexed) (v, fine.elementAtOrNull(i)?.$2 ?? 0),
      ];
      return (k, from, (ways.where((w) => w.$2 >= _clear).firstOrNull ?? ways.reduce((a, b) => b.$2 > a.$2 ? b : a)).$1);
    }
    if (first != null) {
      if (turned(first) case final knob?) return knob;
    }
    if (alone) return null;
    for (final k in knobs.where((k) => says(_clock, k))) {
      if (turned(k) case final knob?) return knob;
    }
    final given = [
      for (final MapEntry(key: k, value: was) in filed.entries)
        if (m.value(on, k, 0) case final to? when to != was && !_faint.hasMatch(k)) (k, was, to, change(k, was, to)),
    ];
    if (given.isNotEmpty) {
      final most = given.reduce((a, b) => b.$4 > a.$4 ? b : a);
      if (most.$4 > _plain) return (most.$1, most.$2, most.$3);
    }
    for (final k in [...knobs.where((k) => !_part.hasMatch(k)), ...knobs.where(_part.hasMatch)]) {
      if (turned(k) case final knob?) return knob;
    }
    return null;
  }

  static final _clock = RegExp(r'progress|completion|evolution|phase|rot_?y|進行|進捗|位相', caseSensitive: false);
  static final _whole = RegExp(r'progress|completion|rot_?y|進行|進捗', caseSensitive: false);
  static final _part = RegExp(r'_[xyzw]$'), _faint = RegExp(r'alpha|opacity|blend|mix|seed', caseSensitive: false);

  /// How far each try is from the usual picture: (its number, ffmpeg psnr's mean squared error), one run for them all.
  static List<(int, double)> _changes(String folder) {
    final ProcessResult r;
    try {
      r = Process.runSync('ffmpeg', ['-hide_banner', '-loop', '1', '-i', '$folder/usual.png', '-i', '$folder/try_%d.png', '-lavfi', '[0:v][1:v]psnr=shortest=1:stats_file=-', '-f', 'null', '-']);
    } on ProcessException {
      return const [];   // (no ffmpeg where the window was opened from: not measured)
    } finally {
      for (var i = 0; File('$folder/try_$i.png').existsSync(); i++) {
        File('$folder/try_$i.png').deleteSync();   // (the next effect's may be fewer)
      }
    }
    return [for (final l in '${r.stdout}'.split('\n')) if (RegExp(r'n:(\d+) mse_avg:([\d.]+)').firstMatch(l) case final w?) (int.parse(w.group(1)!) - 1, double.parse(w.group(2)!))];
  }

  static final _plain = 255 * 255 / 10000.0, _clear = 255 * 255 / 251.0;   // (mean squared error at 40 dB, where _unseen stops seeing a change; at 24 dB, plainly seen and the picture still there, measured on these tiles)

  /// Whether two pictures are not seen to differ (as [_unseen]).
  static bool _same(String a, String b) => _hardly(_differ(a, b));

  /// ffmpeg over a tile's pictures; false where it did not run (none where the window was opened from: its still alone).
  static bool _ffmpeg(List<String> also) {
    try {
      return Process.runSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', ...also]).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// Whether none of its pictures is seen to differ from the sample's (as [_hardly]).
  static bool _unseen(String home, String sample) => _hardly(_differ('${home.substring(0, home.length - 4)}_%d.png', '${sample}_%d.png'));

  /// Whether the picture that differs most is "hardly visible": AbsentMotion's effect_thumbs.py, its SAME of 2.0 over
  /// the frame that differs most (max(changes)). Not measured (no ffmpeg): not said to be.
  static bool _hardly(List<double> changes) => changes.isNotEmpty && changes.every((c) => c < 2.0);

  /// How far pictures differ, frame by frame, as AbsentMotion's effect_thumbs.py tells it (change(): each laid over
  /// grey, each channel's difference out of 255, the mean): ffmpeg lays the two side by side, the mean is taken here.
  /// Empty: no ffmpeg where the window was opened from, not measured.
  static List<double> _differ(String a, String b) {
    try {
      final head = File(a.replaceFirst('%d', '0')).openSync()..setPositionSync(16);   // (the PNG's IHDR: its width, its height)
      final wh = head.readSync(8);
      head.closeSync();
      final w = wh[0] << 24 | wh[1] << 16 | wh[2] << 8 | wh[3], h = wh[4] << 24 | wh[5] << 16 | wh[6] << 8 | wh[7];
      final r = Process.runSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-i', a, '-i', b, '-lavfi', '[0:v]format=rgba[a];[1:v]format=rgba[b];[a][b]hstack=shortest=1', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-'], stdoutEncoding: null);
      final d = r.stdout as List<int>, row = w * 4, frame = 2 * row * h;
      if (r.exitCode != 0 || frame == 0) return const [];
      double change(int f) {
        var sum = 0.0;
        for (var y = 0; y < h; y++) {
          for (var x = f + y * 2 * row, end = x + row; x < end; x += 4) {
            final pa = d[x + 3] / 255, pb = d[x + row + 3] / 255;
            for (var c = 0; c < 3; c++) {
              sum += (d[x + c] * pa + 128 * (1 - pa) - d[x + row + c] * pb - 128 * (1 - pb)).abs();
            }
          }
        }
        return sum / (w * h * 3);
      }
      return [for (var f = 0; f + frame <= d.length; f += frame) change(f)];
    } on FileSystemException {
      return const [];
    } on ProcessException {
      return const [];
    }
  }
}
