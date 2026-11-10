// The parameter that stands for an effect on its tile, and how far it is turned.
import 'dart:io';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/effect_tiles_seen.dart';

/// Picks the parameter that stands for an effect on its tile, and the two values it moves between.
///
/// Candidates are tried in this order, and the first one that visibly changes the picture wins:
/// 1. [first], the parameter the weights in [EffectTiles.weighed] say shows the effect most.
/// 2. Parameters named like a clock: progress, rotY, evolution, phase (After Effects has Evolution and Transition Completion).
/// 3. The parameters in [filed], whose values the effect table set: the one that changes the picture most.
/// 4. The remaining parameters in file order, single numbers before the parts of a vector. Parameters that only fade
///    the effect, redraw it at every value or pick from a list are skipped.
///
/// Each candidate is tried half way to the far end of its range, at most eight times, and the change is measured
/// with ffmpeg as in shelves/effects/sources/fx_first.sh. For an angle the far end is where it began, so half way is
/// used. A progress or rotY then goes the whole way. Any other parameter goes only as far as the change is plainly
/// visible, short of wiping the picture out.
///
/// If [alone] is set only [first] is tried, because an effect that runs by the clock is left to run.
/// Returns null when no parameter shows the effect.
(String, double, double)? tellingKnob(
  Motolii m,
  int on,
  List<String> knobs,
  Map<String, double> filed,
  List<String> lists,
  String folder, {
  String? first,
  bool alone = false,
}) {
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
    if (_faint.hasMatch(k) ||
        range == null ||
        from == null ||
        const ['onoff', 'seed'].contains(span?.look) ||
        m.words(on, k).isNotEmpty ||
        lists.any(k.endsWith) ||
        tried++ == 8) {
      return null;
    }
    final (low, high) = span != null && span.high > span.low ? (span.low, span.high) : range;
    final half = from + (((high - from).abs() >= (from - low).abs() ? high : low) - from) / 2;
    if (change(k, half, from) <= _plain) return null;
    if (says(_whole, k)) return (k, from, half);
    final steps = [
      if (says(_clock, k)) ...[1 / 512, 1 / 128],
      1 / 32,
      1 / 8,
      1 / 2,
      1.0,
      2.0,
    ]; // Ranges go up to 4000 in an AviUtl2 script, and what shows is often far short of half way.
    final at = [for (final s in steps) from + (half - from) * s];
    for (final (i, v) in at.indexed) {
      m.set(on, k, v);
      m.still('$folder/try_$i.png');
    }
    m.set(on, k, from);
    final fine = _changes(folder), ways = [for (final (i, v) in at.indexed) (v, fine.elementAtOrNull(i)?.$2 ?? 0)];
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
  for (final k in [...knobs.where((k) => !vectorPart.hasMatch(k)), ...knobs.where(vectorPart.hasMatch)]) {
    if (turned(k) case final knob?) return knob;
  }
  return null;
}

/// How far each try differs from the usual picture, as (try number, mean squared error from ffmpeg psnr), in one run.
List<(int, double)> _changes(String folder) {
  final r = ffmpeg([
    '-loop',
    '1',
    '-i',
    '$folder/usual.png',
    '-i',
    '$folder/try_%d.png',
    '-lavfi',
    '[0:v][1:v]psnr=shortest=1:stats_file=-',
    '-f',
    'null',
    '-',
  ]);
  for (var i = 0; File('$folder/try_$i.png').existsSync(); i++) {
    File('$folder/try_$i.png').deleteSync(); // The next effect may have fewer tries.
  }
  if (r == null) return const []; // ffmpeg is missing where the app was started from, so nothing is measured.
  return [
    for (final l in '${r.stdout}'.split('\n'))
      if (RegExp(r'n:(\d+) mse_avg:([\d.]+)').firstMatch(l) case final w?) (int.parse(w.group(1)!) - 1, double.parse(w.group(2)!)),
  ];
}

// _plain is the mean squared error at 40 dB, below which a change is not seen. _clear is the error at 24 dB, which is
// plainly visible with the picture still there, as measured on these tiles.
final _plain = 255 * 255 / 10000.0, _clear = 255 * 255 / 251.0;

final _clock = RegExp(r'progress|completion|evolution|phase|rot_?y|進行|進捗|位相', caseSensitive: false);

final _whole = RegExp(r'progress|completion|rot_?y|進行|進捗', caseSensitive: false);

final vectorPart = RegExp(r'_[xyzw]$'), _faint = RegExp(r'alpha|opacity|blend|mix|seed', caseSensitive: false);
