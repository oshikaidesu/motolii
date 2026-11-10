// The curve of an easing: stacked cards, their expressions in the document, and samples for drawing.
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';

enum EaseBy { through, times, plus }

/// Whether [card] maps the result of the cards above it, so its input is that result and not the time.
bool easeThrough(Ease card) => easeBy(said(card)) == EaseBy.through;

// How a card combines with the cards above it.
EaseBy easeBy(String word) =>
    switch ((easeIsTurned(word) ? easeTurn(word) : word).split(' ').first) {
      'Cyclic' => EaseBy.times,
      'Random' => EaseBy.plus,
      _ => EaseBy.through,
    };

// The expression for the value of the stacked cards at progress u, as the document evaluates it.
String _goes(List<String> cards) {
  var went = "way('${_quoted(cards.first)}', u)";
  for (final c in cards.skip(1)) {
    final way = _quoted(c);
    went = switch (easeBy(c)) {
      EaseBy.through => "way('$way', $went)",
      EaseBy.times => "($went) * way('$way', u)",
      EaseBy.plus => "($went) + way('$way', u) - u",
    };
  }
  return went;
}

String _quoted(String word) => word.replaceAll("'", "''");

/// The custom easings a stack needs defined before a span can use it, as (name, expression) pairs.
List<(String, String)> easeDefines(String word) => [
  for (final c in easeCards(word)) ...[
    if (easeIsTurned(c))
      (
        c,
        "a + (b - a) * (1 - way('${easeTurn(c).replaceAll("'", "''")}', 1 - u))",
      ),
    if (easeIsPoints(c))
      (
        c,
        "a + (b - a) * anime('${c.replaceAllMapped(RegExp('[^(,)]*$easeSpaceMark[^(,)]*'), (stop) => '"${stop[0]!.replaceAll(easeSpaceMark, ' ')}"')}', u)",
      ),
    // A stop with a position is passed to anime.js linear() as a string.
  ],
  if (easeIsLaid(word)) (word, 'a + (b - a) * (${_goes(easeCards(word))})'),
];

// Samples per curve, enough to keep the peaks of a large curve intact.
const _steps = 192;

// Each card's curve, computed once so that only the card being dragged is recomputed.
final _worked = <String, List<double>>{};

/// The easing for one card, given its text form.
Ease easeCard(String word, Motolii? m) {
  if (easeIsLaid(word)) {
    return easeLaid([for (final c in easeCards(word)) easeCard(c, m)]);
  }
  if (easeIsTurned(word)) {
    final base = easeCard(easeTurn(word), m);
    return Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), word, [
      for (var i = 0; i <= _steps; i++) 1 - base.at(1 - i / _steps),
    ]);
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
      for (var i = 0; i <= _steps; i++) m.easingExact(word, i / _steps),
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
      for (var i = 0; i <= _steps; i++) e.at(i / _steps),
    ]);
  }();
}

/// The cards stacked as one easing. A single card is returned as it is.
Ease easeLaid(List<Ease> cards) => cards.length == 1
    ? cards.single
    : Ease(
        EaseKind.bezier,
        Offset.zero,
        const Offset(1, 1),
        [for (final c in cards) said(c).replaceAll(' ', easeSpaceMark)]
            .join(easeStackMark),
        [for (var i = 0; i <= _steps; i++) _went(cards, i / _steps)],
      );

// The same as _goes, but evaluated directly so the app can draw it.
double _went(List<Ease> cards, double u) {
  var went = cards.first.at(u);
  for (final c in cards.skip(1)) {
    went = switch (easeBy(said(c))) {
      EaseBy.through =>
        // Outside 0..1 the value is kept, so an overshoot from a card above stays an overshoot.
        went <= 0 || went >= 1 ? went : c.at(went),
      EaseBy.times => went * c.at(u),
      EaseBy.plus => went + c.at(u) - u,
    };
  }
  return went;
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
