// Part of effect_tiles.dart: AbsentMotion's own table of how each of its effects is shown (tools/effect_showcase.json).
part of 'effect_tiles.dart';

/// What AbsentMotion shows each of its effects with (its tools/effect_showcase.json, Apache-2.0): the knobs that make
/// the effect plain to see, and where its picture is split into before (left) and after. By the effect's name in the
/// table, the file's own `am_<name>.wgsl`; each knob as from_absent.py named it (skslc's R_ before a name WGSL keeps for
/// itself, origin_x and the like with _ after), a vector or a colour one knob each way; a moving line's list of numbers
/// for one knob the stops it goes through ([sweeps]), its layer moved the sample's drift ([moves]), the words its
/// text ones are shown on ([text], its "text" layout), its strokes drawn ([drawn], its "drawing" layout). An .am (one moved by its own motion.cpp) by its --absent: name.
/// Null: a file the table has not.
({Map<String, double> knobs, double? split, Map<String, List<double>> sweeps, bool moves, String? text, bool drawn})? showcase(
  String file,
  String head,
  Map<String, dynamic> table,
) {
  final name = RegExp(r'/am_([a-z0-9]+)\.wgsl$').firstMatch(file)?.group(1) ?? RegExp(r'^// --absent:([a-z0-9]+)', multiLine: true).firstMatch(head)?.group(1);
  final show = name == null ? null : (table['effects'] as Map<String, dynamic>?)?[name] as Map<String, dynamic>?;
  if (show == null) return null;
  final tracks = {for (final t in RegExp(r'--track@([A-Za-z0-9_]+):').allMatches(head)) t.group(1)!};
  final stem = file.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '').replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  final knobs = <String, double>{}, sweeps = <String, List<double>>{};
  String? named(String p, String way) => [
    for (final n in [p, 'R_$p', '${p}_']) '$n$way',
  ].where(tracks.contains).firstOrNull;
  for (final MapEntry(key: p, :value) in ((show['params'] as Map<String, dynamic>?) ?? const {}).entries) {
    if (show.containsKey('animate') && value is List && value.every((x) => x is num)) {
      // (effect_thumbs.py prop: its keys, evenly apart)
      if (named(p, '') case final knob?) {
        sweeps['js_${stem}_$knob'] = [for (final x in value) (x as num).toDouble()];
        continue;
      }
    }
    final parts = switch (value) {
      num v => [v.toDouble()],
      bool v => [v ? 1.0 : 0.0],
      String v when RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v) => [for (var i = 1; i < 7; i += 2) int.parse(v.substring(i, i + 2), radix: 16) / 255, 1.0],
      List v when v.length <= 4 && v.every((x) => x is num) => [
        for (final x in v) (x as num).toDouble(),
      ], // (a vector; a longer list is not one: left as the file says)
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

/// AbsentMotion's table, read once (in each isolate that draws): empty where the library has not got it.
Map<String, dynamic> table(String dir) {
  try {
    return jsonDecode(File('$dir/third_party/AbsentMotion/tools/effect_showcase.json').readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}
