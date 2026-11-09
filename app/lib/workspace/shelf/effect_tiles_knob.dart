// Part of effect_tiles.dart: the knob that stands for an effect on its tile, and how far it is turned.
part of 'effect_tiles.dart';

/// How far along [t] (0 to 1) a line of evenly spaced stops stands.
double _along(List<double> stops, double t) {
  final at = t * (stops.length - 1), k = at.floor().clamp(0, stops.length - 2);
  return stops[k] + (stops[k + 1] - stops[k]) * (at - k);
}

/// The knob that stands for an effect, and the two values it goes between. Set beside the 121 lines of AbsentMotion's
/// table where a hand says which (docs/internal/reports/engine/sketch_import_2026-11-01.md), the one that changes the picture most is right
/// for 3 of the 27 it moves: what a hand moves is what plays as a clock would, rotY, progress, evolution, phase (After
/// Effects' own Evolution and Transition Completion); then, of [filed], the knobs the hand gave a value, the one that
/// makes most of it, from what the file has to that; then the file's first that shows, its author's first, single
/// numbers before a vector's parts, leaving what only fades it out, draws it anew at each value or picks from a list. Each is tried half
/// way to the far end of its span (all the way round, an angle's far end is where it began), at most eight, as
/// fx_first.sh tries them and AbsentMotion's change() tells a tile that shows nothing; a turn or a progress goes that
/// far, as the hand's, the rest as far as is plainly seen, short of wiping the picture out. Null: none shows.
/// Before all of those, [first]: the knob its weights say shows it most ([weighed]), the user's wish (11/5) that a tile
/// move by the knob that stands for it; [alone], that one or none (an effect that runs by the clock is let run).
(String, double, double)? _telling(Motolii m, int on, List<String> knobs, Map<String, double> filed, List<String> lists, String folder, {String? first, bool alone = false}) {
  if (!m.at(EffectTiles.moments[EffectTiles.still]) || !m.still('$folder/usual.png')) return null;
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

final _clock = RegExp(r'progress|completion|evolution|phase|rot_?y|進行|進捗|位相', caseSensitive: false);

final _whole = RegExp(r'progress|completion|rot_?y|進行|進捗', caseSensitive: false);

final _part = RegExp(r'_[xyzw]$'), _faint = RegExp(r'alpha|opacity|blend|mix|seed', caseSensitive: false);
