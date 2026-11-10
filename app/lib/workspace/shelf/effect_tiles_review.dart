// What the reviewer recorded about each effect, read from app/assets/effect_parameter_weights.json: how much each parameter shows the effect,
// what the tile moves, what it holds still, and what the sample lacks for the effect to show. EffectTiles draws the tiles by it.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/bridge/engine_paths.dart';

abstract final class TileReview {
  /// How much moving each parameter of [file] alone shows its effect, 0 to 10, as an agent that read only the effect's code judged it.
  /// Read from app/assets/effect_parameter_weights.json by the shelf entry: the file path from the library folder, including an AviUtl2 script's #name.
  /// AbsentMotion's effect_showcase.json names by hand the parameter its tile moves; its heaviest agreed with this in 26 of 28 cases.
  /// Keys are the engine's parameter names (doc_screen_knob in engine/document/scripts/scripts.h), and `_time` is how much letting the effect run shows it.
  /// Empty when the file was not weighed (the user's own).
  static Map<String, double> weighed(String dir, String file) => {
    for (final MapEntry(key: k, value: w) in entry(dir, file).entries)
      if (w is num) k == '_time' ? k : 'js_${_stem(file)}_$k': w.toDouble(),
  };

  /// What the tile moves to show [file] best, as chosen by someone who tried each parameter on the sample (`_best` of the same entry):
  /// a parameter by the engine's name with the values it goes from and to, or ('_time', 0, 0) to let it run. Null when none was chosen.
  static (String, double, double)? best(String dir, String file) =>
      switch (entry(dir, file)['_best']) {
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
      switch (entry(dir, file)['_set']) {
        final Map<String, dynamic> set => {
          for (final MapEntry(:key, :value) in set.entries)
            if (value is num) 'js_${_stem(file)}_$key': value.toDouble(),
        },
        _ => const {},
      };

  /// What the sample lacks for [file] to show, as the reviewer put it (`_needs`: text, picture, sound, motion, chain, path, shape, behind).
  /// '' when nothing is lacking or the file was not reviewed. `_stops` beside it records the call an AviUtl2 script stopped on (aviutl_fx.h's "not yet").
  static String needs(String dir, String file) =>
      switch (entry(dir, file)['_needs']) {
        final String w => w,
        _ => '',
      };

  /// What the engine said when [file] stopped as the reviewer applied it (`_said`: the "stops:" message in engine/community/aviutl/aviutl_fx.h,
  /// such as a .mod2 it needs, a call not supported yet, or one AviUtl2 does not have). '' when none. A tile that shows nothing says why under the shelf.
  static String stopped(String file) =>
      switch (entry(motoliiDir, file)['_said']) {
        final String w => w,
        _ => '',
      };

  /// What the sample lacks for [file] in the reviewer's words (`_lacks`, for example "a PSD with layers"). '' when nothing. Shown under the shelf
  /// beside the one word of [needs], so a tile that shows nothing says what to give it, not only that something is missing.
  static String lacks(String file) =>
      switch (entry(motoliiDir, file)['_lacks']) {
        final String w => w,
        _ => '',
      };

  /// The label of a tile that shows nothing, so the sample is not passed off as the effect. It names what the sample lacks, as the reviewer put it.
  /// A reviewed effect that lacks nothing (or only text, which its tile is drawn on) is one the engine cannot draw yet, as an AviUtl2 script stops
  /// on a call not supported yet (aviutl_fx.h's "not yet"). An effect that was not reviewed (the user's own) gets NO CHANGE.
  static String sameTag(String file) =>
      switch (entry(motoliiDir, file).containsKey('_stops')
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
      entry(dir, file).containsKey('_best') ||
      entry(dir, file).containsKey('_needs') ||
      entry(dir, file).containsKey('_why');

  static Map<String, dynamic> entry(String dir, String file) {
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
    for (final MapEntry(:key, :value) in entry(dir, file).entries)
      if (key != '_why') key: value,
  }) {
    final w when w.isEmpty => '',
    final w => jsonEncode(w),
  };
}
