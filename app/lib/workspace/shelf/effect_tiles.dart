// Every effect on the shelf has a tile that shows what it does, as Alight Motion's do (docs/internal/reports/alight_motion/alight_ui.md, 71 and 72).
// AbsentMotion shows each of its effects by a table written beforehand (tools/effect_showcase.json); here a tile is told
// the same things by the effect itself, so a file put in by its maker needs no line and no developer. Read from it
// (doc_recipes.h, isf_tags): a transition's progress goes from 0 to 1, what runs by the clock or keeps its frame before is
// left to run. Measured (AbsentMotion's change(), docs/internal/reports/engine/sketch_import_2026-11-01.md): the sample stands still, so what
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

import '../../engine/motolii.dart';
import '../ws.dart' show wsTextFont;

part 'effect_tiles_knob.dart';
part 'effect_tiles_seen.dart';
part 'effect_tiles_showcase.dart';

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

  /// How much moving each knob of [file] alone shows its effect, 0 to 10, as an agent that read only the effect's code
  /// weighed it (knob_weights.json beside this file, by the shelf's entry: its file from the library's folder, an AviUtl2 script's
  /// #name and all; set beside AbsentMotion's effect_showcase.json, where a hand says which knob its tile moves, its
  /// heaviest was that knob in 26 of 28), by the inside's names (doc_scripts.h doc_screen_knob: the file's stem before
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

  /// What the sample lacks for [file] to show, in the words of the one who looked (its _lacks: "a PSD with layers",
  /// "the 本体 part of this particle set before it"), '' none: under the shelf beside [needs]'s one word, so a tile that
  /// shows nothing says what to give it, not only that it lacks something.
  static String lacks(String file) => switch (_entry(motoliiDir, file)['_lacks']) {
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
    'input' => 'NEEDS INPUT',   // (something the sample has not that none of the words above says: [lacks] tells what)
    _ when looked(motoliiDir, file) => 'UNSUPPORTED',
    _ => 'NO CHANGE',
  };

  /// Whether [file] was looked at (its line in the file), so a tile that shows nothing and lacks nothing is one the
  /// inside does not draw yet.
  static bool looked(String dir, String file) => _entry(dir, file).containsKey('_best') || _entry(dir, file).containsKey('_needs') || _entry(dir, file).containsKey('_why');

  static Map<String, dynamic> _entry(String dir, String file) {
    final all = _weights ??= () {
      try {
        return jsonDecode(File('${Directory(motoliiDir).absolute.parent.path}/app/lib/workspace/shelf/knob_weights.json').readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        return const <String, dynamic>{};
      }
    }();
    return (all[file.startsWith('$motoliiShelves/') ? file.substring(motoliiShelves.length + 1) : file] as Map<String, dynamic>?) ?? const {};
  }

  /// A file's stem as its values' names say it (`js_<stem>_<knob>`: doc_screen_knob).
  static String knobStem(String file) => _stem(file);

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

  /// Its moving pictures: home_0.jpg … home_7.jpg beside its still (none for a picture not drawn here).
  static String frame(String home, int k) => '${home.substring(0, home.length - 4)}_$k.jpg';
  static String _drawn(String home, int k) => '${home.substring(0, home.length - 4)}_$k.png';   // (as the inside draws it, before it is made small)

  /// The maker's own folder: MOTOLII_OWN, or ~/Library/Application Support/Motolii (as the inside's doc_folders).
  static String get own => Platform.environment['MOTOLII_OWN'] ?? '${Platform.environment['HOME']}/Library/Application Support/Motolii';

  /// The library's own folders beside the maker's (as the inside's doc_folders: the folder above its out/).
  static List<String> get library => [for (final f in const ['effects', 'aviutl_scripts', 'recipes', 'animators', 'relations']) '$motoliiShelves/$f'];

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
    _ffmpeg(['-f', 'lavfi', '-i', "aevalsrc='0.9*sin(2*PI*(50+120*exp(-25*mod(t,1/3)))*t)*exp(-9*mod(t,1/3))+0.25*sin(2*PI*(300+850*t)*t)*(0.5+0.5*sin(6*PI*t))':s=48000:d=2", '${folder.path}/beat.wav']);   // (for one that hears: a kick three times a second under a tone rising 300 to 2000 Hz, by the same ffmpeg's lavfi as the grid)
    final song = m.add('film', '${folder.path}/beat.wav');   // (a sound alone: heard by every AviUtl2 script (its audiobuffer: doc_sound_now), by an ISF's audio input its knob names)
    m.set(song, 'opacity', 0);   // (its wavescope not seen: heard, as the window puts a sound in hidden (Alight Motion's sound layer has no picture))
    var heard = false;   // (its sound read once, aside (sound.h sound_of): silence until then)
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
    for (final moving in [false, true]) {   // (and each with the road under it, as one laid on the road is drawn: beside these it is seen whether it did anything)
      lay(moving, road: true);
      shoot('${folder.path}/${moving ? 'moved' : 'plain'}_road.png');
    }
    for (final (empty, seen) in [('none', null), ('stage', grid)]) {   // (nothing on the stage, black; the grid alone: a tile hardly apart from either shows nothing, by the same SAME; not the road alone, which rain on a pane, thin streaks over it, is hardly apart from by the mean)
      for (final t in [grid, card, photo, under, words]) {
        m.set(t, 'opacity', t == seen ? 1 : 0);
      }
      shoot('${folder.path}/$empty.png');
    }
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
      final ears = [for (final l in RegExp(r'\{[^{}]*"TYPE"\s*:\s*"audio(FFT)?"[^{}]*\}').allMatches(isf)) ?RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1)];   // (ISF_Spec's audio and audioFFT inputs)
      final hears = ears.isNotEmpty || said.contains('sound') || needs(dir, f) == 'sound';
      final weights = weighed(dir, f), time = weights['_time'] ?? 0;
      final chosen = best(dir, f);   // (what one who looked at each knob moved on the sample chose to show it by)
      final timed = chosen?.$1 == '_time' || (time > 0 && weights.entries.every((w) => w.key == '_time' || w.value <= time));   // (its weights say letting it run shows it best: no knob turned, as AbsentMotion's Noise Displace)
      final runs = said.contains('time') || said.contains('feedback') || plays || timed;
      final first = ((show?.moves ?? false) || said.contains('feedback') || plays || needs(dir, f) == 'shape') && !hears;   // (an effect of what was has something going past it to see; one for cut-outs, as one who looked said, an edge with room round it: the whole photo turned black by a glass with nothing to see through is not it shown; one that hears, on the whole picture first: its sound drawn as large as it goes, not in a card's corner)
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
        final passes = (said.contains('transition') || const {'behind', 'shape'}.contains(needs(dir, f))) && alone == 0;   // (one is put on the photo, the road under it; so is one that shows what is behind, as one who looked said: rain on a pane over nothing was black; and one for cut-outs, its card over it: a glass, a shape over a background to refract)
        lay(moving, road: passes, only: alone);
        final whole = !moving && !passes && alone == 0 && (f.endsWith('.fs') || f.endsWith('.wgsl') || f.endsWith('.json')) && m.say(0, 'script', f);   // (.json: Filament's own settings, laid on the stage's view: viewer_settings.h)   // (a screen effect; the stage takes an AviUtl2 script too, but draws none of it: motolii.h, a thing's)
        final thing = alone != 0 ? alone : moving ? card : photo, on = whole ? 0 : thing, onIt = !whole && m.say(thing, 'fx', f);   // (as a thing's: as edit.sh says it)
        for (final e in ears) {
          m.set(on, 'js_${_stem(f)}_$e', song.toDouble());   // (on the beat)
        }
        if (hears && !heard && (whole || onIt)) {   // (asked for once, and waited for: its pictures drawn hearing it from the first)
          if (m.at(moments.first)) m.still('${folder.path}/warm.png');
          sleep(const Duration(seconds: 1));
          heard = true;
        }
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
        same = enough && (alone == 0 || aloneOk) && (['${moving ? 'moved' : bare}${passes ? '_road' : ''}', 'none', 'stage'].any((b) => _unseen(home, '${folder.path}/$b')));   // (or hardly apart from nothing, black, or the grid alone: a square a sound, a video, what it lacks would fill, said so, not left black)
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
}
