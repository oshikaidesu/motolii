// Easings stacked as cards.
//
// - Pressing a preset replaces the selected card. Dropping one on the graph or the flow adds it. Dragging a card out removes it.
// - Each card acts on the result of the cards above it, according to its kind:
//   - Most cards map the value through themselves, like GSAP's timingEase and Blender's modifier stack. Steps cards do this too.
//   - Wave cards scale with the result above, like GSAP's amplitudeEase.
//   - Shake cards add to the result above, like Blender's Noise modifier.
// - Between two cards the flow shows which of these applies: an arrow, a x or a +.
// - The document stores the stack as one custom easing built from `way()` (document/undo.h),
//   so it is saved, undone and listed like any other easing.
// - A Linear card changes nothing that passes through it.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_easing_presets.dart';
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/widgets/controls.dart' show Hov;
import 'package:motolii/widgets/media.dart' show Draw;

// An easing defined in a document is one word, so a space inside a name is written as _space.
const _over = '×', _space = '~', _turned = 'Reverse:';

// Drag data of the tile at the foot of the flow, which stands for all the cards (EaseShapes.onKeep).
const _all = -1;

/// The text form of each card in a stacked easing. An easing that is not stacked gives a list of itself.
List<String> easeCards(String said) => [for (final w in said.split(_over)) w.startsWith(_turned) || easeIsPoints(w) ? w : w.replaceAll(_space, ' ')];

bool easeIsLaid(String said) => said.contains(_over);

/// Whether [said] is an easing given by points, like CSS linear().
///
/// It is one word, so spaces are written as ~. anime.js evaluates it (document/undo.h).
bool easeIsPoints(String said) => said.startsWith('linear(');
bool easeIsTurned(String said) => said.startsWith(_turned);

/// The text form of an easing played backwards, or the original when [said] is already reversed.
///
/// AbsentMotion has a "reverse" option. The document has no such thing, so it is stored as a custom easing, like stacked easings.
String easeTurn(String said) => easeIsTurned(said) ? said.substring(_turned.length).replaceAll(_space, ' ') : '$_turned${said.replaceAll(' ', _space)}';

enum _By { through, times, plus }

/// Whether [card] maps the result of the cards above it, so its input is that result and not the time.
bool easeThrough(Ease card) => _by(said(card)) == _By.through;

// How a card combines with the cards above it.
_By _by(String word) => switch ((easeIsTurned(word) ? easeTurn(word) : word).split(' ').first) {
  'Cyclic' => _By.times,
  'Random' => _By.plus,
  _ => _By.through,
};

// The expression for the value of the stacked cards at progress u, as the document evaluates it.
String _goes(List<String> cards) {
  var went = "way('${_quoted(cards.first)}', u)";
  for (final c in cards.skip(1)) {
    final way = _quoted(c);
    went = switch (_by(c)) {
      _By.through => "way('$way', $went)",
      _By.times => "($went) * way('$way', u)",
      _By.plus => "($went) + way('$way', u) - u",
    };
  }
  return went;
}

String _quoted(String word) => word.replaceAll("'", "''");

/// The custom easings a stack needs defined before a span can use it, as (name, expression) pairs.
List<(String, String)> easeDefines(String word) => [
  for (final c in easeCards(word)) ...[
    if (easeIsTurned(c)) (c, "a + (b - a) * (1 - way('${easeTurn(c).replaceAll("'", "''")}', 1 - u))"),
    if (easeIsPoints(c))
      (c, "a + (b - a) * anime('${c.replaceAllMapped(RegExp('[^(,)]*$_space[^(,)]*'), (stop) => '"${stop[0]!.replaceAll(_space, ' ')}"')}', u)"),
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
  if (easeIsLaid(word)) return easeLaid([for (final c in easeCards(word)) easeCard(c, m)]);
  if (easeIsTurned(word)) {
    final base = easeCard(easeTurn(word), m);
    return Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), word, [for (var i = 0; i <= _steps; i++) 1 - base.at(1 - i / _steps)]);
  }
  final e = heard(word);
  if (!easeOther(e) || m == null) return e;
  if (easeIsPoints(word) && !_worked.containsKey(word) && m.easingExact(word, 1) < .5) {
    // Not defined yet, so it does not end at 1. It is drawn once it is defined.
    return e;
  }
  if (_worked.length > 256) _worked.clear();
  return Ease(e.kind, e.p1, e.p2, e.name, _worked[word] ??= [for (var i = 0; i <= _steps; i++) m.easingExact(word, i / _steps)]);
}

final _curves = <String, List<double>>{};

/// The easing sampled at evenly spaced steps, for the timeline to draw at any size.
///
/// It is computed once per text form. Many samples are needed because 17 points cannot hold eight waves.
List<double> easeCurve(String way, Motolii m) {
  if (_curves.length > 512) _curves.clear();
  return _curves[way] ??= () {
    final e = easeCard(way, m);
    return List<double>.unmodifiable([for (var i = 0; i <= _steps; i++) e.at(i / _steps)]);
  }();
}

/// The cards stacked as one easing. A single card is returned as it is.
Ease easeLaid(List<Ease> cards) => cards.length == 1
    ? cards.single
    : Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), [for (final c in cards) said(c).replaceAll(' ', _space)].join(_over), [
        for (var i = 0; i <= _steps; i++) _went(cards, i / _steps),
      ]);

// The same as _goes, but evaluated directly so the app can draw it.
double _went(List<Ease> cards, double u) {
  var went = cards.first.at(u);
  for (final c in cards.skip(1)) {
    went = switch (_by(said(c))) {
      _By.through =>
        // Outside 0..1 the value is kept, so an overshoot from a card above stays an overshoot.
        went <= 0 || went >= 1 ? went : c.at(went),
      _By.times => went * c.at(u),
      _By.plus => went + c.at(u) - u,
    };
  }
  return went;
}

/// The name shown under the graph.
String easeWord(Ease e) {
  final s = said(e);
  return easeIsPoints(s) ? 'linear()' : (easeIsTurned(s) ? easeTurn(s) : easeName(e) ?? 'Bezier').split(' ').first;
}

/// An easing as text anyone can read. A bezier is written as CSS cubic-bezier(), so it can be pasted into a web page.
String easeText(Ease e) => easeIsBezierAlone(e) ? 'cubic-bezier(${e.p1.dx}, ${e.p1.dy}, ${e.p2.dx}, ${e.p2.dy})' : said(e);

bool easeIsBezierAlone(Ease e) => said(e).startsWith('Bezier ');

/// Parses an easing from copied text: CSS cubic-bezier() and linear() (CSS Easing Functions 2), anywhere in the text
/// (a line of a page's style, cubic-bezier.com), or the form [easeText] writes. Returns null when there is none.
Ease? easeFromText(String? text, Motolii? m) {
  final t = (text ?? '').trim();
  if (RegExp(r'cubic-bezier\(([^)]*)\)').firstMatch(t) case final b?) {
    final n = [for (final x in b[1]!.split(',')) double.tryParse(x.trim())];
    // CSS requires x values in 0..1, so time only moves forward.
    if (n.length != 4 || n.contains(null) || n[0]! < 0 || n[0]! > 1 || n[2]! < 0 || n[2]! > 1) return null;
    return Ease(EaseKind.bezier, Offset(n[0]!, n[1]!), Offset(n[2]!, n[3]!));
  }
  if (RegExp(r'linear\(([^)]*)\)').firstMatch(t) case final l?) {
    final stops = [for (final s in l[1]!.split(',')) s.trim().replaceAll(RegExp(r'\s+'), _space)];
    return stops.length < 2 ? null : heard('linear(${stops.join(',')})');
  }
  return const {'Linear', 'Hold', 'Bezier', 'Bounce', 'Elastic', 'Cyclic', 'Random', 'Steps', 'ElasticSteps'}.contains(t.split(RegExp('[ ~×]')).first) ||
          easeIsTurned(t)
      ? easeCard(t, m)
      : null;
}

/// The flow of cards, top to bottom, each acting on the result above it (like Blender's modifier stack).
///
/// - An empty dashed slot under the last card shows that another can be added, as in Monster Train.
/// - The combined result is shown small at the foot. Selecting it makes the graph show the whole stack, which has no handles.
/// - Selecting a card makes the graph show that card with its handles.
/// - Dragging a card up or down moves it. Dropping a preset on a card inserts it before that card.
///   Dragging a card out of the flow removes it.
class EaseCards extends StatelessWidget {
  const EaseCards({
    super.key,
    this.adding = false,
    this.onSlot,
    required this.cards,
    required this.now,
    required this.whole,
    required this.onWhole,
    required this.onPress,
    required this.onOff,
    required this.onMove,
    required this.onLay,
    required this.onOver,
    required this.side,
    this.across = false,
  });

  /// The width and height of each card.
  final double side;

  /// Whether the cards run horizontally, under the graph in a tall panel.
  final bool across;

  /// Whether the empty slot has been pressed and the flow waits for a preset to be picked.
  final bool adding;

  /// Called when the empty slot is pressed.
  final VoidCallback? onSlot;

  /// The cards, top to bottom.
  final List<Ease> cards;

  /// The index of the selected card, or a negative number when the whole stack is selected.
  final int now;

  /// The combined result shown at the foot, or null for none.
  final Ease? whole;

  /// Called when the combined result is pressed.
  final VoidCallback onWhole;

  /// Called with a card's index when it is pressed or removed.
  final ValueChanged<int> onPress, onOff;

  /// Called when a card is dragged from one index to another.
  final void Function(int from, int to) onMove;

  /// Called when a preset is dropped on the card at the index.
  final void Function(Ease shape, int at) onLay;

  /// Called while a preset hovers over a card, and with null when it leaves, so the result can be previewed before the drop.
  final void Function(Ease? shape, int at) onOver;

  @override
  Widget build(BuildContext context) {
    final side = Size.square(this.side);
    Widget card(int i, Ease c) => Hov(
      // Hovering shows a x that removes the card, like the rows in Cavalry, Bitwig and Serum.
      builder: (_, h) => Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox.fromSize(
            size: side,
            child: EasingPresetTile(c, on: i == now, side: this.side, onTap: () => onPress(i), carried: false),
          ),
          if (h && (cards.length > 1 || c != easingPreset('Linear')))
            Positioned(
              right: -Shape.s(4),
              top: -Shape.s(3),
              child: EaseOff(key: ValueKey('ease.off.$i'), onTap: () => onOff(i)),
            ),
        ],
      ),
    );
    Widget place(int i, Widget child) => DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        if (d.data case final Ease e) onOver(e, i);
        return d.data != i && d.data != _all;
      },
      onLeave: (d) => d is Ease ? onOver(null, i) : null,
      onAcceptWithDetails: (d) {
        if (d.data case final Ease e) onLay(e, i);
        if (d.data case final int from) onMove(from, i);
      },
      builder: (_, hot, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Shape.r(5)),
          border: hot.isEmpty ? null : Border.all(color: WsT.accent, width: 2),
        ),
        child: child,
      ),
    );
    Widget carried(int i, Ease c) => Draggable<int>(
      key: ValueKey('ease.card.$i'),
      data: i,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: easeHeld(card(i, c), this.side),
      childWhenDragging: Opacity(opacity: .3, child: card(i, c)),
      // Dropped on the flow or the graph, the drop target accepts it and the card stays.
      // Dropped on the presets, the card stays too. Dropped anywhere else, it is removed.
      onDraggableCanceled: (_, _) => onOff(i),
      child: card(i, c),
    );
    final axis = across ? Axis.horizontal : Axis.vertical;
    final gap = across ? Size(this.side * .4, side.height) : Size(side.width, this.side * .4);
    Widget arrow() => CustomPaint(size: gap, painter: Draw((cv, s) => _drawArrow(cv, s, across), across));
    Widget by(int i) => switch (_by(said(cards[i]))) {
      // How the card combines with the result above it.
      _By.through => arrow(),
      final how => SizedBox.fromSize(
        key: ValueKey('ease.by.$i'),
        size: gap,
        child: Center(
          child: Text(how == _By.times ? '×' : '+', style: T.micro(Grey.g76).copyWith(fontWeight: FontWeight.w700, height: 1)),
        ),
      ),
    };
    return ColoredBox(
      color: WsT.card,
      child: Flex(
        direction: axis,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: axis,
              padding: across ? EdgeInsets.symmetric(horizontal: Shape.s(4)) : EdgeInsets.symmetric(vertical: Shape.s(4)),
              child: Flex(
                direction: axis,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, c) in cards.indexed) ...[
                    if (i > 0) by(i),
                    if (cards.length > 1)
                      place(i, carried(i, c))
                    else if (c == easingPreset('Linear'))
                      card(i, c)
                    else
                      // A lone Linear card has nothing to drag.
                      carried(i, c),
                  ],
                  arrow(),
                  Hov(
                    key: const ValueKey('ease.slot'),
                    onTap: onSlot,
                    builder: (_, h) => EaseSlot(
                      side: this.side,
                      ink: adding
                          ? WsT.accent
                          : h
                          ? Grey.g76
                          : Grey.g38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (whole case final w?)
            Padding(
              padding: across ? EdgeInsets.only(left: Shape.s(4), right: Shape.s(6)) : EdgeInsets.only(top: Shape.s(4), bottom: Shape.s(6)),
              child: Draggable<int>(
                data: _all,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: easeHeld(EasingPresetTile(w, on: false, side: this.side, onTap: () {}, carried: false), this.side),
                child: SizedBox.fromSize(
                  size: side,
                  child: EasingPresetTile(w, key: const ValueKey('ease.whole'), on: now < 0, side: this.side, onTap: onWhole, carried: false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A round x button that removes an item, like the rows in Cavalry, Bitwig and Serum.
class EaseOff extends StatelessWidget {
  const EaseOff({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Hov(
    onTap: onTap,
    builder: (_, over) => Container(
      width: Shape.z(15),
      height: Shape.z(15),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: over ? Grey.g95 : Grey.g38, shape: BoxShape.circle),
      child: Text('×', style: T.micro(over ? Grey.g13 : Grey.g95).copyWith(fontWeight: FontWeight.w700, height: 1)),
    ),
  );
}

void _drawArrow(Canvas c, Size s, bool across) {
  if (across) {
    // Rotate the arrow to point along the row.
    c.translate(0, s.height);
    c.rotate(-math.pi / 2);
    s = Size(s.height, s.width);
  }
  final x = s.width / 2,
      p = Paint()
        ..color = Grey.g56
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
  c.drawLine(Offset(x, 1), Offset(x, s.height - 2), p);
  c.drawPath(
    Path()
      ..moveTo(x - 3, s.height - 5)
      ..lineTo(x, s.height - 2)
      ..lineTo(x + 3, s.height - 5),
    p,
  );
}

/// A dashed empty frame showing that another card can be added, as in Monster Train.
class EaseSlot extends StatelessWidget {
  const EaseSlot({super.key, required this.side, required this.ink});

  /// The width and height of the frame.
  final double side;

  /// The color of the dashed outline.
  final Color ink;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(side), painter: Draw((cv, s) => _drawSlot(cv, s, ink), ink));
}

void _drawSlot(Canvas c, Size s, Color ink) {
  final k = s.width / 68, box = RRect.fromRectAndRadius(Rect.fromLTWH(3 * k, 4 * k, 61 * k, 60 * k), Radius.circular(8 * k));
  final line = Paint()
    ..color = ink
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  for (final m in (Path()..addRRect(box)).computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 7) {
      c.drawPath(m.extractPath(d, d + 4), line);
    }
  }
}
