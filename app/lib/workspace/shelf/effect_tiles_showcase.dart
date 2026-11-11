// AbsentMotion's table of how each of its effects is shown (tools/effect_showcase.json).
import 'dart:convert';
import 'dart:io';

/// How AbsentMotion shows an effect, from its tools/effect_showcase.json (Apache-2.0).
///
/// The effect is looked up by name: the `am_<name>.wgsl` file name, or for an .am file (moved by its own motion.cpp)
/// the name on its `--absent:` line. Returns null for a file the table does not list. The fields are:
/// - knobs: parameter values that make the effect plain to see. Names are as from_absent.py made them: skslc's `R_`
///   prefix for a name WGSL reserves, and a trailing `_` for names like origin_x. A vector or colour gives one
///   parameter per component.
/// - split: where the picture is split into before (left) and after.
/// - sweeps: for a parameter given as a list of numbers, the stops it goes through.
/// - moves: the layer is moved by the sample's drift.
/// - text: the words a text effect is shown on (the "text" layout).
/// - drawn: strokes are drawn for it (the "drawing" layout).
typedef TileShow = ({
  Map<String, double> knobs,
  double? split,
  Map<String, List<double>> sweeps,
  bool moves,
  String? text,
  bool drawn,
});

TileShow? showcase(String file, String head, Map<String, dynamic> table) {
  final name =
      RegExp(r'/am_([a-z0-9]+)\.wgsl$').firstMatch(file)?.group(1) ??
      RegExp(
        r'^// --absent:([a-z0-9]+)',
        multiLine: true,
      ).firstMatch(head)?.group(1);
  final show = name == null
      ? null
      : (table['effects'] as Map<String, dynamic>?)?[name]
            as Map<String, dynamic>?;
  if (show == null) return null;
  final tracks = {
    for (final t in RegExp(r'--track@([A-Za-z0-9_]+):').allMatches(head))
      t.group(1)!,
  };
  final stem = file
      .split('/')
      .last
      .replaceFirst(RegExp(r'\.[^.]*$'), '')
      .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  final knobs = <String, double>{}, sweeps = <String, List<double>>{};
  String? named(String p, String way) => [
    for (final n in [p, 'R_$p', '${p}_']) '$n$way',
  ].where(tracks.contains).firstOrNull;
  for (final MapEntry(key: p, :value)
      in ((show['params'] as Map<String, dynamic>?) ?? const {}).entries) {
    if (show.containsKey('animate') &&
        value is List &&
        value.every((x) => x is num)) {
      // A list of numbers is the keys of an animated property, evenly spaced, as effect_thumbs.py prop does.
      if (named(p, '') case final knob?) {
        sweeps['js_${stem}_$knob'] = [
          for (final x in value) (x as num).toDouble(),
        ];
        continue;
      }
    }
    final parts = switch (value) {
      num v => [v.toDouble()],
      bool v => [v ? 1.0 : 0.0],
      String v when RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v) => [
        for (var i = 1; i < 7; i += 2)
          int.parse(v.substring(i, i + 2), radix: 16) / 255,
        1.0,
      ],
      List v when v.length <= 4 && v.every((x) => x is num) => [
        for (final x in v) (x as num).toDouble(),
      ], // A vector. A longer list is not one and is left as the file has it.
      _ => const <double>[],
    };
    for (final (i, v) in parts.indexed) {
      final way = parts.length > 1 ? '_${'xyzw'[i]}' : '';
      if (named(p, way) case final knob?) knobs['js_${stem}_$knob'] = v;
    }
  }
  return (
    knobs: knobs,
    split: (show['split'] as num?)?.toDouble(),
    sweeps: sweeps,
    moves: show['layout'] == 'move',
    text: show['layout'] == 'text' ? '${show['text'] ?? ''}' : null,
    drawn: show['layout'] == 'drawing',
  );
}

/// AbsentMotion's table, read once in each isolate that draws. Empty where the library does not have it.
Map<String, dynamic> table(String dir) {
  try {
    return jsonDecode(
      File('$dir/third_party/AbsentMotion/tools/effect_showcase.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}
