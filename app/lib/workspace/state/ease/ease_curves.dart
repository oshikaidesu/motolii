// The curve of an easing as the engine evaluates it: a card's exact curve, and the samples drawn on the timeline.
// The stacking itself is pure and lives in workspace/easing/ease_stacks.dart.
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_stacks.dart';
import 'package:motolii/workspace/easing/ease_text.dart';

// Each card's curve, computed once so that only the card being dragged is recomputed.
final _worked = <String, List<double>>{};

/// The easing for one card, given its text form.
Ease easeCard(String word, Motolii? m) {
  if (easeIsLaid(word)) {
    return easeLaid([for (final c in easeCards(word)) easeCard(c, m)]);
  }
  if (easeIsTurned(word)) {
    final base = easeCard(easeTurn(word), m);
    return Ease(
      EaseKind.bezier,
      Offset.zero,
      const Offset(1, 1),
      word,
      [for (var i = 0; i <= easeSteps; i++) 1 - base.at(1 - i / easeSteps)],
      // Exact, so reversing a steep stack stays a smooth climb rather than the samples' steps.
      (u) => 1 - base.at(1 - u),
    );
  }
  final e = heard(word);
  if (!easeOther(e) || m == null) return e;
  if (easeIsPoints(word) &&
      !_worked.containsKey(word) &&
      m.easingExact(word, 1) < .5) {
    // Not defined yet, so it does not end at 1. It is drawn once it is defined.
    return e;
  }
  if (_worked.length > 256) _worked.clear();
  return Ease(
    e.kind,
    e.p1,
    e.p2,
    e.name,
    _worked[word] ??= [
      for (var i = 0; i <= easeSteps; i++) m.easingExact(word, i / easeSteps),
    ],
  );
}

final _curves = <String, List<double>>{};

/// The easing sampled at evenly spaced steps, for the timeline to draw at any size.
///
/// It is computed once per text form. Many samples are needed because 17 points cannot hold eight waves.
List<double> easeCurve(String way, Motolii m) {
  if (_curves.length > 512) _curves.clear();
  return _curves[way] ??= () {
    final e = easeCard(way, m);
    return List<double>.unmodifiable([
      for (var i = 0; i <= easeSteps; i++) e.at(i / easeSteps),
    ]);
  }();
}

/// Parses an easing from copied text: CSS cubic-bezier() and linear() (CSS Easing Functions 2), anywhere in the text
/// (a line of a page's style, cubic-bezier.com), or the form [easeText] writes. Returns null when there is none.
Ease? easeFromText(String? text, Motolii? m) {
  final t = (text ?? '').trim();
  if (RegExp(r'cubic-bezier\(([^)]*)\)').firstMatch(t) case final b?) {
    final n = [for (final x in b[1]!.split(',')) double.tryParse(x.trim())];
    // CSS requires x values in 0..1, so time only moves forward.
    if (n.length != 4 ||
        n.contains(null) ||
        n[0]! < 0 ||
        n[0]! > 1 ||
        n[2]! < 0 ||
        n[2]! > 1) {
      return null;
    }
    return Ease(EaseKind.bezier, Offset(n[0]!, n[1]!), Offset(n[2]!, n[3]!));
  }
  if (RegExp(r'linear\(([^)]*)\)').firstMatch(t) case final l?) {
    final stops = [
      for (final s in l[1]!.split(','))
        s.trim().replaceAll(RegExp(r'\s+'), easeSpaceMark),
    ];
    return stops.length < 2 ? null : heard('linear(${stops.join(',')})');
  }
  return const {
            'Linear',
            'Hold',
            'Bezier',
            'Bounce',
            'Elastic',
            'Cyclic',
            'Random',
            'Steps',
            'ElasticSteps',
          }.contains(t.split(RegExp('[ ~×]')).first) ||
          easeIsTurned(t)
      ? easeCard(t, m)
      : null;
}
