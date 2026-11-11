// The easing as a stack of cards: what each edit of the stack makes. Each card acts on the result of the cards above it (ease_cards.dart);
// the stack is stored as one easing built from `way()`. These are the pure edits the Ease tool's cards ask for: replace, remove, move,
// insert, lay on. The tool sets what they return; nothing here draws or writes.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';

class EaseStack {
  EaseStack(this.ease, this.m)
    : cards = easeIsLaid(said(ease))
          ? [for (final c in easeCards(said(ease))) easeCard(c, m)]
          : [ease];

  /// The easing as it is now, and the engine that computes the kinds with no tile of their own.
  final Ease ease;
  final Motolii? m;

  /// The cards the easing is made of: itself alone when it is not laid.
  final List<Ease> cards;

  /// The cards of [e] as cards of this engine.
  List<Ease> _cardsOf(Ease e) => [
    for (final c in easeCards(said(e))) easeCard(c, m),
  ];

  /// The stack with card [at] replaced by [e]; a single easing is simply replaced.
  Ease replaced(int at, Ease e) =>
      cards.length > 1 ? easeLaid([...cards]..[at] = easeCard(said(e), m)) : e;

  // Over plain Linear there is nothing to layer onto, so the new easing replaces it.
  Ease laidOn(Ease e) =>
      said(ease) == 'Linear' ? e : easeLaid([...cards, ..._cardsOf(e)]);

  /// The stack without card [i]; the last card goes back to Linear.
  Ease without(int i) => cards.length > 1
      ? easeLaid([...cards]..removeAt(i))
      : easingPreset('Linear');

  /// The stack with card [from] moved to place [to].
  Ease moved(int from, int to) {
    final next = [...cards];
    next.insert(to, next.removeAt(from));
    return easeLaid(next);
  }

  /// The stack with the cards of [e] put in at place [i].
  Ease inserted(int i, Ease e) =>
      easeLaid([...cards]..insertAll(i, _cardsOf(e)));
}
