// The stacking of easings: how each card combines with the cards above it, the expressions the document evaluates for a
// stack, and the value of a stack for drawing. Pure; the samples the engine gives are in state/ease_curves.dart.
import 'package:flutter/widgets.dart';
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

/// Samples per curve, enough to keep the peaks of a large curve intact.
const easeSteps = 192;

/// The cards stacked as one easing. A single card is returned as it is.
/// The stack carries both the even samples (to fit the view) and an exact evaluator, so the curve is drawn as steeply as it
/// really is — a stack of steep beziers is near vertical, and reading it from the samples alone would show it as steps.
Ease easeLaid(List<Ease> cards) => cards.length == 1
    ? cards.single
    : Ease(
        EaseKind.bezier,
        Offset.zero,
        const Offset(1, 1),
        [for (final c in cards) said(c).replaceAll(' ', easeSpaceMark)]
            .join(easeStackMark),
        [for (var i = 0; i <= easeSteps; i++) _went(cards, i / easeSteps)],
        (u) => _went(cards, u),
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
