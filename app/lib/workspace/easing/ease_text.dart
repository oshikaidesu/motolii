// The text form of an easing, as the document stores it and as a person reads it.
import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/easing/ease.dart';

// An easing defined in a document is one word, so a space inside a name is written as easeSpaceMark.
const easeStackMark = '×', easeSpaceMark = '~', _turned = 'Reverse:';

/// Converts an [Ease] to the text the document stores, and [heard] converts it back.
/// Three of the nine built-in kinds have a tile in the tool panel.
String said(Ease e) => easeOther(e)
    ? e.name!
    : switch (e.kind) {
        EaseKind.hold => 'Hold',
        EaseKind.bezier => e.name == 'Linear' ? 'Linear' : 'Bezier ${e.p1.dx} ${e.p1.dy} ${e.p2.dx} ${e.p2.dy}',
      };
Ease heard(String said) {
  // The engine returns an easing as the kind's name followed by all its numbers.
  final w = said.split(' '), n = [for (final x in w.skip(1)) double.tryParse(x) ?? 0];
  return switch (w.first) {
    'Hold' => easingPreset('Hold'),
    'Linear' => easingPreset('Linear'),
    'Bezier' when n.length == 4 => Ease(EaseKind.bezier, Offset(n[0], n[1]), Offset(n[2], n[3])),
    // A kind with no tile yet is kept by its text, over a straight line.
    _ => Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), said),
  };
}

/// The text form of each card in a stacked easing. An easing that is not stacked gives a list of itself.
List<String> easeCards(String said) => [
  for (final w in said.split(easeStackMark)) w.startsWith(_turned) || easeIsPoints(w) ? w : w.replaceAll(easeSpaceMark, ' '),
];

bool easeIsLaid(String said) => said.contains(easeStackMark);

/// Whether [said] is an easing given by points, like CSS linear().
///
/// It is one word, so spaces are written as ~. anime.js evaluates it (document/undo.h).
bool easeIsPoints(String said) => said.startsWith('linear(');
bool easeIsTurned(String said) => said.startsWith(_turned);

/// The text form of an easing played backwards, or the original when [said] is already reversed.
///
/// AbsentMotion has a "reverse" option. The document has no such thing, so it is stored as a custom easing, like stacked easings.
String easeTurn(String said) =>
    easeIsTurned(said) ? said.substring(_turned.length).replaceAll(easeSpaceMark, ' ') : '$_turned${said.replaceAll(' ', easeSpaceMark)}';

/// The name shown under the graph.
String easeWord(Ease e) {
  final s = said(e);
  return easeIsPoints(s) ? 'linear()' : (easeIsTurned(s) ? easeTurn(s) : easeName(e) ?? 'Bezier').split(' ').first;
}

/// An easing as text anyone can read. A bezier is written as CSS cubic-bezier(), so it can be pasted into a web page.
String easeText(Ease e) => easeIsBezierAlone(e) ? 'cubic-bezier(${e.p1.dx}, ${e.p1.dy}, ${e.p2.dx}, ${e.p2.dy})' : said(e);

bool easeIsBezierAlone(Ease e) => said(e).startsWith('Bezier ');
