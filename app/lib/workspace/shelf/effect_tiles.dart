// Every effect on the shelf has a tile that shows what it does, as Alight Motion's do (docs/design/alight_motion_ui.md).
// AbsentMotion shows each effect from a table written beforehand (tools/effect_showcase.json). Here the effect file itself tells the tile what to
// show, so a file the user puts in needs no table line and no developer. What is read from the file (engine/document/scripts/recipes.h, isf_tags):
// - A transition's progress goes from 0 to 1. An effect that runs by the clock, or keeps its previous frame, is left to run.
// - Otherwise the sample stands still, so the parameter that stands for the effect goes between two values (see [tellingKnob]).
// - If nothing shows on the whole photo, the effect goes on a card moving across AbsentMotion's grid (its "move" layout).
// - With no parameter to turn, a line between before and after sweeps across the tile.
// Only a tile that shows nothing stays still. AbsentMotion's own effects use their line of the table.
// A tile is sixteen pictures a twelfth of a second apart, played forwards and back at 24 fps so nothing jumps where it loops. The sample is the
// balloon photo that shelves/effects/sources/fx_tiles.sh draws on (fx_sample.jpg beside it). Tiles are drawn in a project of their own in another
// isolate, as create_preview.dart does for presets, and the engine says where each goes (~/Library/Caches/Motolii/tiles: doc_tile in
// engine/document/scripts/recipes.h). The effect is applied as fx_tiles.sh and engine/edit.sh do: a screen effect (.fs, .wgsl) on the whole picture,
// anything else on the photo layer. Pictures are shrunk with sips (192 px); moving ones are JPEG from ffmpeg. They are compared with the sample's
// own pictures using ffmpeg's psnr. If the effect changes nothing (over 40 dB: helpers of other scripts, PSD ones, scripts that stop on a call
// not supported yet), the tile is marked `home.same` and the shelf says so.
//
// The user's own folder is watched while the app is open (dart:io watch, FSEvents on a Mac). When a file is put in or taken out there, the
// shelves are read again (docs/app/BRIDGE.md rule 8) and its tile is drawn ahead of the rest.
import 'package:motolii/workspace/easing/ease.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/workspace/state/workspace_controller.dart'
    show defaultTextFont;
import 'package:motolii/workspace/shelf/copies_tiles.dart' show TileQueue;
import 'package:motolii/workspace/shelf/effect_tiles_knob.dart';
import 'package:motolii/workspace/shelf/effect_tiles_difference.dart';
import 'package:motolii/workspace/shelf/effect_tiles_showcase.dart';

abstract final class EffectTiles {
  static void Function()? _told;

  /// How many of the queued tiles are drawn, out of how many, while any are queued. The shelf's reload mark shows it.
  static final progress = ValueNotifier<(int, int)?>(null);
  static final _tiles = TileQueue<(String, String)>(
    draw,
    moving: true,
    batch: 12,
    progress: progress,
  );

  /// Draws [file]'s tile again ahead of the queue or, without [file], every tile on the shelf (the reload mark).
  static void again(Motolii m, {String? file}) {
    _tiles.drop((q) => file == null || q.$1 == file);
    for (final (_, f) in m.effects) {
      final home = m.tileHome(f);
      if (home.isEmpty || (file != null && f != file)) continue;
      _tiles.forget(home);
      try {
        File('$home.tells').deleteSync();
      } catch (_) {}
      if (file != null) _tiles.ask(home, (f, home), at: 0);
    }
    if (_told case final changed?) ask(m, changed);
  }

  /// How wide a tile's pictures are read. A picture drawn again under its own name is evicted at this width, or Flutter's image cache shows the old one.
  static const readWide = 256;

  /// The times its pictures are drawn at (AbsentMotion's 16 at 12 per second), and the index of the still: well into the motion.
  static final moments = [for (var k = 0; k < 16; k++) 0.1 + k / 12];
  static const still = 10;

  /// How much moving each parameter of [file] alone shows its effect, 0 to 10, as an agent that read only the effect's code judged it.
  /// Read from app/assets/effect_parameter_weights.json by the shelf entry: the file path from the library folder, including an AviUtl2 script's #name.
  /// AbsentMotion's effect_showcase.json names by hand the parameter its tile moves; its heaviest agreed with this in 26 of 28 cases.
  /// Keys are the engine's parameter names (doc_screen_knob in engine/document/scripts/scripts.h), and `_time` is how much letting the effect run shows it.
  /// Empty when the file was not weighed (the user's own).
  static Map<String, double> weighed(String dir, String file) => {
    for (final MapEntry(key: k, value: w) in _entry(dir, file).entries)
      if (w is num) k == '_time' ? k : 'js_${_stem(file)}_$k': w.toDouble(),
  };

  /// What the tile moves to show [file] best, as chosen by someone who tried each parameter on the sample (`_best` of the same entry):
  /// a parameter by the engine's name with the values it goes from and to, or ('_time', 0, 0) to let it run. Null when none was chosen.
  static (String, double, double)? best(String dir, String file) =>
      switch (_entry(dir, file)['_best']) {
        '_time' => ('_time', 0, 0),
        [final String k, final num from, final num to] => (
          'js_${_stem(file)}_$k',
          from.toDouble(),
          to.toDouble(),
        ),
        _ => null,
      };

  /// The parameters the tile holds fixed while it moves the chosen one, set by hand (`_set` of the same entry), by the engine's names.
  /// For example a curve's line stays shown while the photo goes round it (Mathy_Su's 線透明度). Empty when none.
  static Map<String, double> held(String dir, String file) =>
      switch (_entry(dir, file)['_set']) {
        final Map<String, dynamic> set => {
          for (final MapEntry(:key, :value) in set.entries)
            if (value is num) 'js_${_stem(file)}_$key': value.toDouble(),
        },
        _ => const {},
      };

  /// What the sample lacks for [file] to show, as the reviewer put it (`_needs`: text, picture, sound, motion, chain, path, shape, behind).
  /// '' when nothing is lacking or the file was not reviewed. `_stops` beside it records the call an AviUtl2 script stopped on (aviutl_fx.h's "not yet").
  static String needs(String dir, String file) =>
      switch (_entry(dir, file)['_needs']) {
        final String w => w,
        _ => '',
      };

  /// What the engine said when [file] stopped as the reviewer applied it (`_said`: the "stops:" message in engine/community/aviutl/aviutl_fx.h,
  /// such as a .mod2 it needs, a call not supported yet, or one AviUtl2 does not have). '' when none. A tile that shows nothing says why under the shelf.
  static String stopped(String file) =>
      switch (_entry(motoliiDir, file)['_said']) {
        final String w => w,
        _ => '',
      };

  /// What the sample lacks for [file] in the reviewer's words (`_lacks`, for example "a PSD with layers"). '' when nothing. Shown under the shelf
  /// beside the one word of [needs], so a tile that shows nothing says what to give it, not only that something is missing.
  static String lacks(String file) =>
      switch (_entry(motoliiDir, file)['_lacks']) {
        final String w => w,
        _ => '',
      };

  /// The label of a tile that shows nothing, so the sample is not passed off as the effect. It names what the sample lacks, as the reviewer put it.
  /// A reviewed effect that lacks nothing (or only text, which its tile is drawn on) is one the engine cannot draw yet, as an AviUtl2 script stops
  /// on a call not supported yet (aviutl_fx.h's "not yet"). An effect that was not reviewed (the user's own) gets NO CHANGE.
  static String sameTag(String file) =>
      switch (_entry(motoliiDir, file).containsKey('_stops')
      ? ''
      : needs(motoliiDir, file)) {
        // An effect seen to stop: what it lacks is not the reason.
        'picture' => 'FOR 2 LAYERS',
        'sound' => 'FOR SOUND',
        'motion' => 'FOR VIDEO',
        'chain' => 'PART OF A SET',
        'shape' => 'FOR CUT-OUTS',
        'behind' => 'NEEDS BACKDROP',
        'path' => 'FOR PATHS',
        'input' => 'NEEDS INPUT', // Something the sample lacks that none of the words above covers; [lacks] says what.
        _ when looked(motoliiDir, file) => 'UNSUPPORTED',
        _ => 'NO CHANGE',
      };

  /// Whether [file] was reviewed (it has an entry in the weights file). A reviewed tile that shows nothing and lacks nothing is one the engine cannot draw yet.
  static bool looked(String dir, String file) =>
      _entry(dir, file).containsKey('_best') ||
      _entry(dir, file).containsKey('_needs') ||
      _entry(dir, file).containsKey('_why');

  static Map<String, dynamic> _entry(String dir, String file) {
    final all = _weights ??= () {
      try {
        return jsonDecode(
          File(
            '${Directory(motoliiDir).absolute.parent.path}/app/assets/effect_parameter_weights.json',
          ).readAsStringSync(),
        ) as Map<String, dynamic>;
      } catch (_) {
        return const <String, dynamic>{};
      }
    }();
    return (all[file.startsWith('$motoliiShelves/')
                ? file.substring(motoliiShelves.length + 1)
                : file]
            as Map<String, dynamic>?) ??
        const {};
  }

  /// A file's stem as parameter names spell it (`js_<stem>_<knob>`, see doc_screen_knob).
  static String knobStem(String file) => _stem(file);

  static String _stem(String file) => String.fromCharCodes([
    // Byte by byte like the engine's std::isalnum, so ライ becomes ______.
    for (final b in utf8.encode(
      file.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), ''),
    ))
      (b >= 48 && b <= 57) ||
              (b >= 65 && b <= 90) ||
              (b >= 97 && b <= 122) ||
              b == 95
          ? b
          : 95,
  ]);

  static Map<String, dynamic>? _weights;

  /// What a tile is told when it is drawn (saved beside it as .tells): the weights it goes by, what it moves and what it
  /// lacks. A tile whose entry was weighed or reviewed again since is drawn again.
  static String tells(String dir, String file) => switch ({
    for (final MapEntry(:key, :value) in _entry(dir, file).entries)
      if (key != '_why') key: value,
  }) {
    final w when w.isEmpty => '',
    final w => jsonEncode(w),
  };

  /// The saved .tells of [home]. Null when it was drawn before tiles were told anything.
  static String? _toldOf(String home) {
    try {
      return File('$home.tells').readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  /// Its moving pictures: home_0.jpg … home_15.jpg beside its still (none for a tile not drawn here).
  static String frame(String home, int k) =>
      '${home.substring(0, home.length - 4)}_$k.jpg';
  static String _drawn(String home, int k) =>
      '${home.substring(0, home.length - 4)}_$k.png'; // Full size, before shrinking.

  static String get own => motoliiOwn;

  /// The library's folders beside the user's own (the engine's doc_folders: the folder above its out/).
  static List<String> get library => [
    for (final f in const [
      'effects',
      'aviutl_scripts',
      'create',
      'expressions',
      'relations',
    ])
      '$motoliiShelves/$f',
  ];

  /// Watches until the subscription is cancelled. [changed] is called after the folders are read again and after tiles are drawn.
  static StreamSubscription<FileSystemEvent>? watch(
    Motolii m,
    void Function() changed, {
    void Function(String file)? program,
  }) {
    ask(m, changed);
    final dir = Directory('$own/effects');
    try {
      dir.createSync(
        recursive: true,
      ); // There is somewhere to put files, as the README says.
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
    final merged = StreamController<FileSystemEvent>(
      onCancel: () => Future.wait([for (final w in inner) w.cancel()]),
    );
    inner.addAll([
      for (final p in [own, ...library.where((p) => Directory(p).existsSync())])
        Directory(p).watch(recursive: true).listen(merged.add),
    ]);
    final told = <String, Timer>{};
    return merged.stream.listen((e) {
      if (program != null && e.path.startsWith('$own/programs/')) {
        // A program's file: what is made from it follows, and no shelf is read again.
        told[e.path]?.cancel();
        told[e.path] = Timer(
          const Duration(milliseconds: 300),
          () => program(e.path),
        );
        return;
      }
      soon?.cancel();
      soon = Timer(
        const Duration(milliseconds: 300),
        again,
      ); // A copy is several events, so read once it has settled.
    });
  }

  /// Draws the tiles of effects on the shelf that are not drawn yet. One drawn before (in this run or another) is shown at once. The rest are queued,
  /// the user's own at the head (they were just put in), drawn a few at a time and shown as each batch finishes.
  static void ask(Motolii m, void Function() changed) {
    var shown = false, head = 0;
    _told = changed;
    _tiles.onDrawn = (homes) {
      for (final h in homes) {
        m.tileRendered(h, same: File('$h.same').existsSync());
      }
      changed();
    };
    for (final (_, f) in [
      ...m.effects,
    ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))) {
      final home = m.tileHome(f);
      // Stale if drawn before tiles showed what the effect does, or with other weights. It is drawn again.
      final stale = home.isNotEmpty && _toldOf(home) != tells(motoliiDir, f);
      if (home.isEmpty || (!stale && m.tileImage(f) == home)) continue;
      if (!stale && File(home).existsSync()) {
        m.tileRendered(home, same: File('$home.same').existsSync());
        shown = true;
      } else {
        // The user's own effects go at the head (just put in). None are drawn under flutter test: seven hundred pictures would slow its timing.
        final own1 = f.startsWith(own);
        if (_tiles.ask(home, (f, home), at: own1 ? head : null) && own1) head++;
      }
    }
    if (shown) changed();
    _tiles.start();
  }

  static List<String> draw(String dir, List<(String, String)> files) {
    final folder = Directory.systemTemp.createTempSync('motolii_tiles'),
        drawn = <String>[];
    final m = Motolii.open(
      '${folder.path}/tiles.motolii',
      wide: 384,
      high: 384,
      dir: dir,
    ); // AbsentMotion's RENDER size. Its THUMB size is below.
    if (m == null) return drawn;
    ffmpeg([
      '-f',
      'lavfi',
      '-i',
      'color=c=0x2c2c34:s=384x384,drawgrid=w=48:h=48:t=1:c=0x45454f',
      '-frames:v',
      '1',
      '${folder.path}/grid.png',
    ]); // AbsentMotion's grid, where its "move" layout stands.
    // The picture under the photo is what a transition goes to. On a clip, a transition takes the photo away and shows what is under it (doc_fx_file),
    // as gl-transitions' previews do. On the whole screen it had nothing to go to and went to black.
    final sample =
            '${Directory(dir).absolute.parent.path}/shelves/effects/sources',
        grid = m.add('picture', '${folder.path}/grid.png'),
        under = m.add('picture', '$sample/fx_sample_end.jpg'),
        photo = m.add('picture', '$sample/fx_sample.jpg'),
        card = m.add('picture', '$sample/fx_sample.jpg');
    // For effects that hear: a kick three times a second under a tone rising from 300 to 2000 Hz, made by the same ffmpeg lavfi as the grid.
    ffmpeg([
      '-f',
      'lavfi',
      '-i',
      "aevalsrc='0.9*sin(2*PI*(50+120*exp(-25*mod(t,1/3)))*t)*exp(-9*mod(t,1/3))+0.25*sin(2*PI*(300+850*t)*t)*(0.5+0.5*sin(6*PI*t))':s=48000:d=2",
      '${folder.path}/beat.wav',
    ]);
    final song = m.add('film', '${folder.path}/beat.wav'); // Sound only: AviUtl2 scripts hear it (audiobuffer, doc_sound_now) and ISF effects hear it through the audio input a parameter names.
    m.set(song, 'opacity', 0); // Hidden but still heard, as a sound added in the app is (Alight Motion's sound layer has no picture).
    var heard = false; // Whether the sound was read once, aside (sound_level.h sound_of). Until then it is silent.
    final words = m.add('text', defaultTextFont); // For effects that work on text: white words over the grid, as AbsentMotion's effect_thumbs.py lays its "text" layout.
    m
      ..say(words, 'fill', 'ffffff')
      ..set(words, 'size', 0.4)
      ..set(grid, 'size', 3.6)
      ..set(under, 'size', 3.6)
      ..set(photo, 'size', 3.6)
      ..set(card, 'size', 1.8)
      ..key(card, 'x', moments.first, -0.84)
      ..key(card, 'x', moments.last, 0.84);
    var drawing = 0; // AbsentMotion's sample drawing, made the first time it is needed. -1 when it could not be made.
    int sketch() {
      // effect_thumbs.py sketch(): a spiral and a wave drawn as pen strokes, as the app's brush makes them (doc_brush), at its RENDER size of 384.
      if (drawing != 0) return drawing;
      m.at(0); // A stroke starts at the current time, as an added layer does, so go to the first time as the tile's pictures do.
      final made = <int>[];
      for (final (wide, line) in [
        (
          16,
          [
            for (var j = 0; j < 100; j++)
              (
                192 + math.cos(j / 9) * (14 + j * 1.1),
                172 + math.sin(j / 9) * (14 + j * 1.1),
              ),
          ],
        ),
        (
          12,
          [
            for (var j = 0; j < 41; j++)
              (62 + j * 6.5, 302 + math.sin(j / 3) * 18),
          ],
        ),
      ]) {
        final ticket = m.later(
          'brush',
          word:
              '0 $wide ${[for (final (x, y) in line) '${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} 1'].join(' ')}',
        );
        var made1 = -1;
        for (var n = 0; n < 2000 && (made1 = m.answer(ticket)) == -1; n++) {
          sleep(const Duration(milliseconds: 5));
        }
        made.add(made1); // The layer the brush made.
      }
      if (made.any((t) => t <= 0)) return drawing = -1;
      m
        ..say(
          made[0],
          'drawing',
          '${m.word(made[0], 'drawing')} ; ${m.word(made[1], 'drawing')}',
        ) // Both strokes as one drawing, as in AbsentMotion.
        ..say(
          made[0],
          'path',
          '${m.word(made[0], 'path')} ${m.word(made[1], 'path')}',
        )
        ..say(made[0], 'fill', 'ffc23d')
        ..set(made[1], 'opacity', 0);
      return drawing = made[0];
    }

    var small =
        false; // The photo is small over the grid (the _lay "small" entry).
    void lay(bool moving, {bool road = false, int only = 0}) {
      for (final (thing, seen) in [
        (grid, moving || only != 0 || small),
        (card, moving),
        (photo, !moving && only == 0),
        (under, road),
        (words, only == words),
        if (drawing > 0) (drawing, only == drawing),
      ]) {
        m.set(thing, 'opacity', seen ? 1 : 0);
      }
    }

    List<String> shoot(
      String home, {
      bool plays = false,
      void Function(double at)? turn,
    }) {
      // Draws its pictures, shrunk. [plays] is for an effect that keeps its previous frame (ISF's PERSISTENT): it is stepped
      // through from the start at 30 fps and the sixteen pictures are kept as they pass, as fx_tiles.sh warms one up.
      final made = <String>[];
      bool one(double at, String to) {
        turn?.call(at);
        return m.at(at) && m.still(to);
      }

      if (plays) {
        for (
          var n = 1, k = 0;
          k < moments.length && n <= (moments.last * 30).round();
          n++
        ) {
          final keep = n == (moments[k] * 30).round();
          if (one(n / 30, keep ? _drawn(home, k) : '${folder.path}/warm.png') &&
              keep) {
            made.add(_drawn(home, k));
          }
          if (keep) k++;
        }
      } else {
        made.addAll([
          for (final (k, at) in moments.indexed)
            if (one(at, _drawn(home, k))) _drawn(home, k),
        ]);
      }
      if (made.isNotEmpty) Process.runSync('sips', ['-Z', '192', ...made]);
      return made;
    }

    lay(false);
    final plain = shoot(
      '${folder.path}/plain.png',
    ); // The sample as it is, to tell a tile that shows nothing.
    if (m.at(moments[still])) {
      m.still(
        '${folder.path}/sample.png',
      ); // Full size, like the tries it is compared with.
    }
    lay(true);
    final moved = shoot('${folder.path}/moved.png');
    for (final moving in [false, true]) {
      // Each again with the road photo under it, as an effect laid on the road is drawn. Beside these it is seen whether the effect did anything.
      lay(moving, road: true);
      shoot('${folder.path}/${moving ? 'moved' : 'plain'}_road.png');
    }
    for (final (empty, seen) in [('none', null), ('stage', grid)]) {
      // Nothing on the stage (black), then the grid alone. A tile hardly different from either shows nothing, by the same
      // looksSame test. The road alone is not used: rain on a pane, thin streaks over it, is hardly different from it by the mean.
      for (final t in [grid, card, photo, under, words]) {
        m.set(t, 'opacity', t == seen ? 1 : 0);
      }
      shoot('${folder.path}/$empty.png');
    }
    final enough =
        plain.length == moments.length && moved.length == moments.length;
    final shows = table(dir),
        own = {
          for (final t in [photo, card, words]) ...m.values(t),
        }; // A drawing's values belong to a shape, so none of them start with js_.
    for (final (f, home) in files) {
      try {
        Directory(File(home).parent.path).createSync(recursive: true);
      } catch (_) {
        continue;
      }
      final show = f.endsWith('.wgsl') || f.endsWith('.am')
          ? showcase(f, File(f).readAsStringSync(), shows)
          : null;
      final said = m.tags(f),
          isf = f.endsWith('.fs') ? File(f).readAsStringSync() : '',
          plays = RegExp(r'"PERSISTENT"\s*:\s*(true|1)').hasMatch(isf);
      final lists = [
        for (final l in RegExp(
          r'\{[^{}]*"TYPE"\s*:\s*"long"[^{}]*\}',
        ).allMatches(isf))
          '_${RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1)}',
      ]; // ISF's "long" inputs: a choice, which the engine takes as a range.
      final ears = [
        for (final l in RegExp(
          r'\{[^{}]*"TYPE"\s*:\s*"audio(FFT)?"[^{}]*\}',
        ).allMatches(isf))
          ?RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1),
      ]; // ISF_Spec's audio and audioFFT inputs.
      final hears =
          ears.isNotEmpty || said.contains('sound') || needs(dir, f) == 'sound';
      final weights = weighed(dir, f), time = weights['_time'] ?? 0;
      final chosen = best(
        dir,
        f,
      ); // What the reviewer chose, after moving each parameter on the sample.
      final timed =
          chosen?.$1 == '_time' ||
          (time > 0 &&
              weights.entries.every(
                (w) => w.key == '_time' || w.value <= time,
              )); // Its weights say letting it run shows it best, so no parameter is turned, as for AbsentMotion's Noise Displace.
      final runs =
          said.contains('time') || said.contains('feedback') || plays || timed;
      // Whether to try the moving card first. Effects of what came before, and cut-out effects (they need an edge with room around it), have something to see.
      // A glass over the whole photo would just turn it black. An effect that hears goes on the whole picture first, so its sound is drawn large.
      final first =
          ((show?.moves ?? false) ||
              said.contains('feedback') ||
              plays ||
              needs(dir, f) == 'shape') &&
          !hears;
      final base = home.substring(0, home.length - 4);
      var same = false, split = false, stands = true;
      var made = const <String>[];
      final worded = show?.text != null || needs(dir, f) == 'text'; // For text effects, as the table or the reviewer says: shown on words alone.
      final alone = worded
          ? words
          : (show?.drawn ?? false) || needs(dir, f) == 'path'
          ? math.max(sketch(), 0)
          : 0; // For strokes or a path: shown on the drawing alone.
      final aloneOk =
          alone != 0 &&
          () {
            if (worded) {
              m.say(
                words,
                'text',
                show?.text?.isNotEmpty ?? false ? show!.text! : 'Motolii',
              );
            }
            lay(false, only: alone);
            return shoot('${folder.path}/alone.png').length == moments.length;
          }();
      final bare = alone != 0 ? 'alone' : 'plain';
      // For effects that take the layer round a path (Mathy_Su's curves): the photo is small over the grid, so the path shows about it, not under it.
      small = alone == 0 && _entry(dir, f)['_lay'] == 'small';
      if (small) m.set(photo, 'size', 0.6);
      for (final moving in alone != 0 ? [false] : [first, if (!first) true]) {
        // Nothing shows on the whole photo, so use a card moving past, where its edge and motion effects show (AbsentMotion's "move").
        // A transition goes on the photo with the road under it. So does an effect that shows what is behind (rain on a pane over
        // nothing was black) and one for cut-outs, which gets its card over the road: a glass or a shape needs a background to refract.
        final passes =
            (said.contains('transition') ||
                const {'behind', 'shape'}.contains(needs(dir, f))) &&
            alone == 0;
        lay(moving, road: passes, only: alone);
        // A screen effect. A .json is Filament's own settings (engine/stage/effects/viewer_settings.h). An AviUtl2 script goes on a layer instead.
        final whole =
            !moving &&
            !passes &&
            alone == 0 &&
            (f.endsWith('.fs') || f.endsWith('.wgsl') || f.endsWith('.json')) &&
            m.say(0, 'script', f);
        final thing = alone != 0
                ? alone
                : moving
                ? card
                : photo,
            on = whole ? 0 : thing,
            onIt =
                !whole &&
                m.say(
                  thing,
                  'fx',
                  f,
                ); // Applied to a layer, as edit.sh says (engine/edit.sh).
        for (final e in ears) {
          m.set(on, 'js_${_stem(f)}_$e', song.toDouble()); // On the beat.
        }
        if (hears && !heard && (whole || onIt)) {
          // Asked for once and waited for, so its pictures are drawn hearing it from the first.
          if (m.at(moments.first)) m.still('${folder.path}/warm.png');
          sleep(const Duration(seconds: 1));
          heard = true;
        }
        final filed = <String, double>{};
        for (final MapEntry(:key, :value) in {
          ...?show?.knobs,
          ...held(dir, f),
        }.entries) {
          if (m.value(on, key, 0) case final was?
              when !vectorPart.hasMatch(key)) {
            filed[key] = was;
          }
          m.set(on, key, value); // As AbsentMotion shows it: the table's values, not the file's defaults.
        }
        final knobs = [
          for (final v in m.values(on))
            if (v.startsWith('js_') && !own.contains(v)) v,
        ];
        final sweeps = <String, List<double>>{...?show?.sweeps};
        final heaviest = ([
          for (final k in knobs)
            if (weights[k] case final w? when w > time) (k, w),
        ]..sort((a, b) => b.$2.compareTo(a.$2))).firstOrNull?.$1; // The parameter whose weight shows the effect most, more than letting it run.
        if (knobs.where((k) => k.endsWith('_progress')).firstOrNull
            case final p? when said.contains('transition')) {
          sweeps[p] = const [
            0,
            1,
          ]; // A transition is seen going from 0 to 1 across its pictures.
        } else if (chosen case (final k, final from, final to)
            when sweeps.isEmpty && knobs.contains(k)) {
          sweeps[k] = [
            from,
            to,
          ]; // As the reviewer chose it, ahead of the measured one.
        } else if (sweeps.isEmpty && (!runs || heaviest != null)) {
          // An effect that runs by the clock has its heaviest parameter turned as it runs, or none.
          if (tellingKnob(
                m,
                on,
                knobs,
                filed,
                lists,
                folder.path,
                first: heaviest,
                alone: runs,
              )
              case final knob?) {
            sweeps[knob.$1] = [knob.$2, knob.$3];
          }
        }
        if (!moving &&
            alone == 0 &&
            !runs &&
            sweeps.isEmpty &&
            enough &&
            looksSame(
              '${folder.path}/usual.png',
              '${folder.path}/sample.png',
            )) {
          // Nothing on the photo: no sixteen pictures of nothing.
          if (whole) m.say(0, 'script', 'none');
          if (onIt) m.say(thing, 'fx', 'none');
          same = true;
          continue;
        }
        made = shoot(
          home,
          plays: plays,
          turn: (at) {
            final t = ((at - moments.first) / (moments.last - moments.first))
                .clamp(0.0, 1.0);
            for (final MapEntry(key: knob, value: stops) in sweeps.entries) {
              m.set(
                on,
                knob,
                easeAlong(stops, t * t * (3 - 2 * t)),
              ); // Smoothstep, so it eases at its ends instead of hitting them.
            }
          },
        );
        if (whole) m.say(0, 'script', 'none');
        if (onIt) m.say(thing, 'fx', 'none');
        if (made.length < moments.length) continue;
        // Also unchanged when hardly different from nothing, black, or the grid alone. A square that a sound, a video or what it lacks would fill is marked so.
        same =
            enough &&
            (alone == 0 || aloneOk) &&
            ([
              '${moving ? 'moved' : bare}${passes ? '_road' : ''}',
              'none',
              'stage',
            ].any(
              (b) => looksSame('${base}_%d.png', '${folder.path}/${b}_%d.png'),
            ));
        stands = !moving && !runs && sweeps.isEmpty;
        split = stands && !said.contains('generator');
        if (!same) break;
      }
      if (small) m.set(photo, 'size', 3.6);
      small = false;
      if (made.length < moments.length || same) {
        // Put on but not drawn (a script that stops), or nothing seen: the sample as it is.
        for (final (k, _) in moments.indexed) {
          if (enough) {
            File('${folder.path}/${aloneOk ? bare : 'plain'}_$k.png')
                .copySync(_drawn(home, k));
          }
        }
        stands = true;
        if (!enough) continue;
      }
      // AbsentMotion's split, at its 22 where one stands. With no parameter to turn, a line going across shows what the effect did, so no tile stands still.
      final at = split ? '0.1+0.8*(3*pow(N/15,2)-2*pow(N/15,3))' : show?.split;
      if (at != null && !same && enough) {
        // Before is at its left, as AbsentMotion's effect_thumbs.py lays the photo over it up to there, with a white line where they meet.
        if (ffmpeg([
              '-i',
              '${base}_%d.png',
              '-i',
              '${folder.path}/${bare}_%d.png',
              '-filter_complex',
              "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_expr='if(lt(abs(X-W*($at)),1),255,if(lt(X,W*($at)),B,A))'",
              '-start_number',
              '0',
              '${base}_%d.split.png',
            ])?.exitCode ==
            0) {
          for (final (k, _) in moments.indexed) {
            File('${base}_$k.split.png').renameSync(_drawn(home, k));
          }
          stands = false;
        }
      }
      File(_drawn(home, EffectTiles.still)).copySync(home);
      if (stands) {
        for (final (k, _) in moments.indexed) {
          File(frame(home, k)).existsSync()
              ? File(frame(home, k)).deleteSync()
              : null; // Nothing moves, so only the still.
        }
      } else {
        ffmpeg([
          '-i',
          '${base}_%d.png',
          '-q:v',
          '6',
          '-start_number',
          '0',
          '${base}_%d.jpg',
        ]);
      }
      for (final (k, _) in moments.indexed) {
        File(_drawn(home, k)).deleteSync();
      }
      try {
        same
            ? File('$home.same').writeAsStringSync('')
            : File('$home.same').deleteSync();
      } catch (_) {}
      File('$home.tells').writeAsStringSync(tells(dir, f));
      drawn.add(home);
    }
    m.close();
    try {
      folder.deleteSync(recursive: true);
    } catch (_) {}
    return drawn;
  }
}
