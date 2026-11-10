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
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_easing_presets.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;

// Drag data of the tile at the foot of the flow, which stands for all the cards (EaseShapes.onKeep).
const _all = -1;

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
    Widget card(int i, Ease c) => Pressable(
      // Hovering shows a x that removes the card, like the rows in Cavalry, Bitwig and Serum.
      builder: (_, h) => Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox.fromSize(
            size: side,
            child: EasingPresetTile(
              c,
              on: i == now,
              side: this.side,
              onTap: () => onPress(i),
              carried: false,
            ),
          ),
          if (h && (cards.length > 1 || c != easingPreset('Linear')))
            Positioned(
              right: -Shape.s(4),
              top: -Shape.s(3),
              child: EaseOff(
                key: ValueKey('ease.off.$i'),
                onTap: () => onOff(i),
              ),
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
          border: hot.isEmpty
              ? null
              : Border.all(color: WindowTokens.accent, width: 2),
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
    final gap = across
        ? Size(this.side * .4, side.height)
        : Size(side.width, this.side * .4);
    Widget arrow() => CustomPaint(
      size: gap,
      painter: Draw((cv, s) => _drawArrow(cv, s, across), across),
    );
    Widget by(int i) => switch (easeBy(said(cards[i]))) {
      // How the card combines with the result above it.
      EaseBy.through => arrow(),
      final how => SizedBox.fromSize(
        key: ValueKey('ease.by.$i'),
        size: gap,
        child: Center(
          child: Text(
            how == EaseBy.times ? '×' : '+',
            style: TextStyles.micro(Grey.g76)
                .copyWith(fontWeight: FontWeight.w700, height: 1),
          ),
        ),
      ),
    };
    return ColoredBox(
      color: WindowTokens.card,
      child: Flex(
        direction: axis,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: axis,
              padding: across
                  ? EdgeInsets.symmetric(horizontal: Shape.s(4))
                  : EdgeInsets.symmetric(vertical: Shape.s(4)),
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
                  Pressable(
                    key: const ValueKey('ease.slot'),
                    onTap: onSlot,
                    builder: (_, h) => EaseSlot(
                      side: this.side,
                      ink: adding
                          ? WindowTokens.accent
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
              padding: across
                  ? EdgeInsets.only(left: Shape.s(4), right: Shape.s(6))
                  : EdgeInsets.only(top: Shape.s(4), bottom: Shape.s(6)),
              child: Draggable<int>(
                data: _all,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: easeHeld(
                  EasingPresetTile(
                    w,
                    on: false,
                    side: this.side,
                    onTap: () {},
                    carried: false,
                  ),
                  this.side,
                ),
                child: SizedBox.fromSize(
                  size: side,
                  child: EasingPresetTile(
                    w,
                    key: const ValueKey('ease.whole'),
                    on: now < 0,
                    side: this.side,
                    onTap: onWhole,
                    carried: false,
                  ),
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
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, over) => Container(
      width: Shape.z(15),
      height: Shape.z(15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: over ? Grey.g95 : Grey.g38,
        shape: BoxShape.circle,
      ),
      child: Text(
        '×',
        style: TextStyles.micro(over ? Grey.g13 : Grey.g95)
            .copyWith(fontWeight: FontWeight.w700, height: 1),
      ),
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
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(side),
    painter: Draw((cv, s) => _drawSlot(cv, s, ink), ink),
  );
}

void _drawSlot(Canvas c, Size s, Color ink) {
  final k = s.width / 68,
      box = RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * k, 4 * k, 61 * k, 60 * k),
        Radius.circular(8 * k),
      );
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
