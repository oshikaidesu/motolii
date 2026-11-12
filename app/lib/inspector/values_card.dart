import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/card_words.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/effect_drag_ghost.dart';
import 'package:motolii/inspector/host_cards.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/rows/section.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/media.dart' show Draw, glyph;
import 'package:motolii/widgets/more_menu.dart';
import 'package:motolii/widgets/timeline_painters.dart' show TimelineGlyphs;

/// Draws every card of the panel the same way: one field per Parameter of its declaration, keyed `v_` plus the param name.
class ValuesCard extends StatelessWidget {
  const ValuesCard(this.card, {super.key});
  final CardDeclaration card;
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context),
        doc = x.doc,
        k = 'v.${card.name}',
        adv = doc.flags['$k.adv'] ?? false,
        past = doc.flags['$k.past'] ?? false;
    // A card the window draws itself shows its picture first; its values the picture does not hold stay blocks.
    final host = hostCards[card.name];
    final heroes = [
          for (final p in card.params)
            if (!p.advanced && !(host?.drawn.contains(p.id) ?? false)) p,
        ],
        rest = [
          for (final p in card.params)
            if (p.advanced) p,
        ];
    // The main params show first. The advanced ones are folded under a row named for what they are.
    // The index of this card among the movable effects, or -1. Effects can be dragged up or down their stack, as in After Effects.
    final at = doc.layer.movable.indexOf(card.name);
    final sect = Section(
      title: card.name,
      tone: card.tone,
      trailing:
          (at < 0 || doc.actions.onCardMove == null) &&
              doc.actions.onCardReset == null &&
              doc.actions.onCardCopy == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The range lock is open, so values may go past the range ends, as with Houdini's range lock. A press closes it.
                if (past)
                  Pressable(
                    key: ValueKey('card-past:${card.name}'),
                    onTap: () => doc.flag('$k.past', false),
                    builder: (_, h) => Padding(
                      padding: EdgeInsets.only(right: Shape.s(6)),
                      child: Glyph(
                        TimelineGlyphs.unlock,
                        size: 12,
                        color: h ? Grey.g95 : Grey.g76,
                        fade: true,
                      ),
                    ),
                  ),
                if (at < 0)
                  CardWords(
                    card.name,
                    [for (final p in card.params) p.id],
                    more: [
                      (
                        'past',
                        past ? 'Stop at Range Ends' : 'Go Past Range Ends',
                        () => doc.flag('$k.past', !past),
                      ),
                    ],
                  ),
                // A script is added like an effect and removed the same way.
                if (card.name == 'Script' && doc.actions.onCardRemove != null)
                  _bin(doc.actions, card.name),
                if (at >= 0) ...[
                  // An effect's header has the eye, the ⋮ menu with the rest, and the bin, as in AbsentMotion's EffectHeader and Alight Motion.
                  if (doc.actions.onCardEye != null)
                    Pressable(
                      key: ValueKey(
                        'card-${doc.layer.cardsOff.contains(card.name) ? 'show' : 'hide'}:${card.name}',
                      ),
                      onTap: () => doc.actions.onCardEye!(card.name),
                      builder: (_, h) => Padding(
                        padding: EdgeInsets.only(right: Shape.s(6)),
                        child: Glyph(
                          doc.layer.cardsOff.contains(card.name)
                              ? TimelineGlyphs.eyeOff
                              : TimelineGlyphs.eye,
                          size: 12,
                          color: h ? Grey.g95 : Grey.g56,
                          fade: true,
                        ),
                      ),
                    ),
                  CardMore(
                    name: card.name,
                    items: [
                      // The items follow AbsentMotion's More menu (Effect Info, Reset to Defaults, Copy Effect, Paste Effect Values),
                      // Alight Motion's Duplicate, and saving the effect as a preset.
                      // The first item does the same as a right click on any of its numbers (PastRange).
                      (
                        'past',
                        past ? 'Stop at Range Ends' : 'Go Past Range Ends',
                        () => doc.flag('$k.past', !past),
                      ),
                      if (doc.actions.onCardInfo case final info?)
                        ('info', 'Effect Info', () => info(card.name)),
                      if (doc.actions.onCardReset case final reset?)
                        (
                          'reset',
                          'Reset to Defaults',
                          () => reset([for (final p in card.params) p.id]),
                        ),
                      if (doc.actions.onCardDuplicate case final duplicate?)
                        ('duplicate', 'Duplicate', () => duplicate(card.name)),
                      if (doc.actions.onCardCopy case final copy?)
                        (
                          'copy',
                          'Copy Effect',
                          () => copy([for (final p in card.params) p.id]),
                        ),
                      if (doc.actions.onCardPaste case final paste?)
                        ('paste', 'Paste Effect Values', paste),
                      if (doc.actions.onCardSave case final save?)
                        (
                          'save',
                          'Save as Preset',
                          () => save(card.name, [
                            for (final p in card.params) p.id,
                          ]),
                        ),
                    ],
                  ),
                  if (doc.actions.onCardRemove != null)
                    _bin(doc.actions, card.name),
                ],
                // The ≡ grip drags an effect up or down its stack, as in Alight Motion and After Effects' Effect Controls.
                if (at >= 0 &&
                    doc.actions.onCardMove != null &&
                    doc.layer.movable.length > 1)
                  Draggable<String>(
                    key: ValueKey('card-drag:${card.name}'),
                    data: card.name,
                    axis: Axis.vertical,
                    feedback: EffectDragGhost(card),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: SizedBox(
                        width: Shape.z(16),
                        height: Shape.z(16),
                        child: CustomPaint(
                          painter: Draw(
                            (c, s) => _drawGrip(c, s, Grey.g56),
                            Grey.g56,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      children: [
        ?host?.body(card),
        if (heroes.isNotEmpty) ParameterGrid(heroes),
        if (rest.isNotEmpty) ...[
          _FoldRow(
            rest.first.fold ?? 'Advanced',
            adv,
            () => doc.flag('$k.adv', !adv),
          ),
          if (adv) ParameterGrid(rest),
        ],
        if (doc.actions.cardEdit?.call(card.name, [
              for (final p in card.params) p.id,
            ])
            case final edit?)
          // The card's code is in the Code tab, one text for both. The sliders are what is edited here and the code is what they drive.
          _FoldRow(
            'Edit code',
            false,
            edit,
            key: ValueKey('card-code:${card.name}'),
          ),
      ],
    );
    final shown = PastRange(flag: '$k.past', child: sect);
    if (at < 0 || doc.actions.onCardMove == null) return shown;
    return DragTarget<String>(
      // An effect dropped on this card takes its place. The line shows on which side it lands.
      onWillAcceptWithDetails: (d) =>
          d.data != card.name && doc.layer.movable.contains(d.data),
      onAcceptWithDetails: (d) => doc.actions.onCardMove!(
        d.data,
        at - doc.layer.movable.indexOf(d.data),
      ),
      builder: (context, held, _) {
        final from = held.isEmpty ? -1 : doc.layer.movable.indexOf(held.first!);
        final below = from >= 0 && from < at;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            shown,
            if (from >= 0)
              Positioned(
                left: 0,
                right: 0,
                top: below ? null : 0,
                bottom: below ? 0 : null,
                height: Shape.z(2),
                child: ColoredBox(color: card.tone),
              ),
          ],
        );
      },
    );
  }
}

/// A card's fold row: 24px high with a rule above. The label is lit while hovered or open, with a [DisclosureTriangle] at the right.
class _FoldRow extends StatelessWidget {
  const _FoldRow(this.label, this.open, this.onTap, {super.key});
  final String label;
  final bool open;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Shape.s(4)),
    child: Pressable(
      onTap: onTap,
      builder: (_, h) => Container(
        height: Shape.z(24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const InspectorHairline().rule),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyles.label(h || open ? Grey.g95 : Grey.g63),
            ),
            const Spacer(),
            DisclosureTriangle(open: open, hot: h || open),
          ],
        ),
      ),
    ),
  );
}

/// Draws the ≡ grip, three short lines. Dragging an effect card by it moves the effect up or down its stack.
void _drawGrip(Canvas c, Size s, Color ink) {
  final paint = Paint()
    ..color = ink
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  for (final y in const [.32, .5, .68]) {
    c.drawLine(
      Offset(s.width * .25, s.height * y),
      Offset(s.width * .75, s.height * y),
      paint,
    );
  }
}

/// Draws the bin that removes an effect, like AbsentMotion's Trash on its header.
void _drawBin(Canvas c, Size s, Color color) {
  final p = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final w = s.width;
  c.drawLine(Offset(w * .15, w * .25), Offset(w * .85, w * .25), p);
  c.drawLine(Offset(w * .4, w * .12), Offset(w * .6, w * .12), p);
  c.drawPath(
    Path()
      ..moveTo(w * .25, w * .3)
      ..lineTo(w * .3, w * .9)
      ..lineTo(w * .7, w * .9)
      ..lineTo(w * .75, w * .3),
    p,
  );
}

/// The bin at the head of an effect's card: a press takes the card away.
Widget _bin(CardActions actions, String name) => Pressable(
  key: ValueKey('card-remove:$name'),
  onTap: () => actions.onCardRemove!(name),
  builder: (_, h) => Padding(
    padding: EdgeInsets.only(right: Shape.s(6)),
    child: glyph(
      Shape.z(12),
      (c, s) => _drawBin(c, s, h ? Grey.g95 : Grey.g56),
      h,
    ),
  ),
);
