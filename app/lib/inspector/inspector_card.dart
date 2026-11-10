import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/rows/inspector_rows_sect.dart';

import '../skin/theme.dart';
import '../skin/tokens.dart';
import 'inspector_parts.dart';
import '../widgets/controls.dart' show Badge;
import '../widgets/timeline_painters.dart' show TpGlyph, TpGlyphView;

// ---- 10. a card ------------------------------------------------------------------------------------------------------
/// A card as the inside declares it, an effect's and a thing's own alike: a name and a WGSL uniform struct
/// (workspace/inspector_feed/cards.dart writes it from motolii_cards, card_table.h). Its fields are whatever [infer] makes of it.
class Fx {
  Fx(this.name, this.wgsl, {required this.toneOf});
  final String name, wgsl;
  final Color Function() toneOf; // (a skin's colour: read when drawn, so a card made before the skin changed wears the new one)
  Color get tone => toneOf();
  late final List<Decl> decls = parseWgsl(wgsl);
  late final List<Param> params = [for (final d in decls) infer(d)];
}

/// A thing's own card's head: its values copied, given to another, as they come (After Effects' Reset).
class CardWords extends StatelessWidget {
  const CardWords(this.name, this.ids, {super.key, this.more = const []});
  final String name;
  final List<String> ids;
  final List<(String, String, VoidCallback)> more; // (under its ⋮)
  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (word, does) in [
          if (doc.onCardCopy case final copy?) ('Copy', () => copy(ids)),
          if (doc.onCardPaste case final paste?) ('Paste', paste),
          if (doc.onCardReset case final reset?) ('Reset', () => reset(ids)),
        ])
          Hov(
            key: ValueKey('card-${word.toLowerCase()}:$name'),
            onTap: does,
            builder: (_, h) => Padding(
              padding: EdgeInsets.only(right: Shape.s(6)),
              child: Text(word, style: T.label(h ? Grey.g95 : Grey.g56)),
            ),
          ),
        if (more.isNotEmpty) CardMore(name: name, items: more),
      ],
    );
  }
}

/// Every card of the panel, drawn one way: its declaration's Params, each field a value (keyed `v_` and its name).
class ValuesCard extends StatelessWidget {
  const ValuesCard(this.card, {super.key});
  final Fx card;
  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context), doc = x.doc, ed = const Ed(), k = 'v.${card.name}', adv = doc.b['$k.adv'] ?? false, past = doc.b['$k.past'] ?? false;
    final heroes = [
          for (final p in card.params)
            if (!p.advanced) p,
        ],
        rest = [
          for (final p in card.params)
            if (p.advanced) p,
        ];
    // (the first row, then the rest folded under the name of what they are; the fold says nothing more than its glyph)
    final at = doc.movable.indexOf(card.name); // (one of its effects: up or down its stack, After Effects' dragging a card)
    final sect = Sect(
      title: card.name,
      tone: card.tone,
      trailing: (at < 0 || doc.onCardMove == null) && doc.onCardReset == null && doc.onCardCopy == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (past) // (let past its ends: its range's lock open, Houdini's range lock; a press shuts it)
                  Hov(
                    key: ValueKey('card-past:${card.name}'),
                    onTap: () => doc.flag('$k.past', false),
                    builder: (_, h) => Padding(
                      padding: EdgeInsets.only(right: Shape.s(6)),
                      child: TpGlyphView(TpGlyph.unlock, h ? Grey.g95 : Grey.g76),
                    ),
                  ),
                if (at < 0)
                  CardWords(
                    card.name,
                    [for (final p in card.params) p.id],
                    more: [('past', past ? 'Stop at Range Ends' : 'Go Past Range Ends', () => doc.flag('$k.past', !past))],
                  ),
                if (card.name == 'Script' && doc.onCardRemove != null) // (a script is put on as an effect is, and comes off the same way: golf_noise.md (123))
                  Hov(
                    key: const ValueKey('card-remove:Script'),
                    onTap: () => doc.onCardRemove!(card.name),
                    builder: (_, h) => Padding(
                      padding: EdgeInsets.only(right: Shape.s(6)),
                      child: CustomPaint(size: Size.square(Shape.z(12)), painter: _Bin(h ? Grey.g95 : Grey.g56)),
                    ),
                  ),
                if (at >= 0) ...[
                  // (an effect's card, as AbsentMotion's EffectHeader and Alight Motion's: its eye, ⋮ with the rest, the bin)
                  if (doc.onCardEye != null)
                    Hov(
                      key: ValueKey('card-${doc.cardsOff.contains(card.name) ? 'show' : 'hide'}:${card.name}'),
                      onTap: () => doc.onCardEye!(card.name),
                      builder: (_, h) => Padding(
                        padding: EdgeInsets.only(right: Shape.s(6)),
                        child: TpGlyphView(doc.cardsOff.contains(card.name) ? TpGlyph.eyeOff : TpGlyph.eye, h ? Grey.g95 : Grey.g56),
                      ),
                    ),
                  CardMore(
                    name: card.name,
                    items: [
                      // (AbsentMotion's More: Effect Info, Reset to Defaults, Copy Effect, Paste Effect Values; Alight Motion's Duplicate; and a preset of it kept)
                      (
                        'past',
                        past ? 'Stop at Range Ends' : 'Go Past Range Ends',
                        () => doc.flag('$k.past', !past),
                      ), // (as a right click on any of its numbers: PastRange)
                      if (doc.onCardInfo case final info?) ('info', 'Effect Info', () => info(card.name)),
                      if (doc.onCardReset case final reset?) ('reset', 'Reset to Defaults', () => reset([for (final p in card.params) p.id])),
                      if (doc.onCardDuplicate case final duplicate?) ('duplicate', 'Duplicate', () => duplicate(card.name)),
                      if (doc.onCardCopy case final copy?) ('copy', 'Copy Effect', () => copy([for (final p in card.params) p.id])),
                      if (doc.onCardPaste case final paste?) ('paste', 'Paste Effect Values', paste),
                      if (doc.onCardSave case final save?) ('save', 'Save as Preset', () => save(card.name, [for (final p in card.params) p.id])),
                    ],
                  ),
                  if (doc.onCardRemove != null)
                    Hov(
                      key: ValueKey('card-remove:${card.name}'),
                      onTap: () => doc.onCardRemove!(card.name),
                      builder: (_, h) => Padding(
                        padding: EdgeInsets.only(right: Shape.s(6)),
                        child: CustomPaint(size: Size.square(Shape.z(12)), painter: _Bin(h ? Grey.g95 : Grey.g56)),
                      ),
                    ),
                ],
                if (at >= 0 && doc.onCardMove != null && doc.movable.length > 1) // (Alight Motion's ≡ on an effect's row, After Effects' dragging an effect in Effect Controls: held and dragged up or down its stack)
                  Draggable<String>(
                    key: ValueKey('card-drag:${card.name}'),
                    data: card.name,
                    axis: Axis.vertical,
                    feedback: FxDragGhost(card),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: SizedBox(
                        width: Shape.z(16),
                        height: Shape.z(16),
                        child: CustomPaint(painter: _Grip(Grey.g56)),
                      ),
                    ),
                  ),
              ],
            ),
      children: [
        ParamGrid(heroes),
        if (rest.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: Hov(
              onTap: () => doc.flag('$k.adv', !adv),
              builder: (_, h) => Container(
                height: Shape.z(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ed.rule)),
                ),
                child: Row(
                  children: [
                    Text(rest.first.fold ?? 'Advanced', style: T.label(h || adv ? Grey.g95 : Grey.g63)),
                    const Spacer(),
                    FoldMark(open: adv, hot: h || adv),
                  ],
                ),
              ),
            ),
          ),
          if (adv) ParamGrid(rest),
        ],
        if (doc.cardCode?.call(card.name, [for (final p in card.params) p.id]) case final code?) ...[
          // (its code under its knobs, folded as Advanced is: the knobs are what is used, the code what they drive)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: Hov(
              key: ValueKey('card-code:${card.name}'),
              onTap: () => doc.flag('$k.code', !(doc.b['$k.code'] ?? false)),
              builder: (_, h) => Container(
                height: Shape.z(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ed.rule)),
                ),
                child: Row(
                  children: [
                    Text('Code', style: T.label(h || (doc.b['$k.code'] ?? false) ? Grey.g95 : Grey.g63)),
                    const Spacer(),
                    FoldMark(open: doc.b['$k.code'] ?? false, hot: h || (doc.b['$k.code'] ?? false)),
                  ],
                ),
              ),
            ),
          ),
          if (doc.b['$k.code'] ?? false) SizedBox(height: Shape.z(360), child: code),
        ],
      ],
    );
    final shown = PastRange(flag: '$k.past', child: sect);
    if (at < 0 || doc.onCardMove == null) return shown;
    return DragTarget<String>(
      // (an effect let go on this one's card takes its place; the line says on which side it lands)
      onWillAcceptWithDetails: (d) => d.data != card.name && doc.movable.contains(d.data),
      onAcceptWithDetails: (d) => doc.onCardMove!(d.data, at - doc.movable.indexOf(d.data)),
      builder: (context, held, _) {
        final from = held.isEmpty ? -1 : doc.movable.indexOf(held.first!);
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

/// Three short lines, ≡: an effect's card held there is dragged up or down its stack.
class _Grip extends CustomPainter {
  const _Grip(this.ink);
  final Color ink;
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final y in const [.32, .5, .68]) {
      c.drawLine(Offset(s.width * .25, s.height * y), Offset(s.width * .75, s.height * y), paint);
    }
  }

  @override
  bool shouldRepaint(_Grip o) => o.ink != ink;
}

/// An effect card's ⋮ (AbsentMotion's EffectHeader More): what else is done with it, in a short list over the panel,
/// as Chooser's lists look; one picked, it does that and closes.
class CardMore extends StatefulWidget {
  const CardMore({super.key, required this.name, required this.items, this.word = '⋮', this.above = false, this.big = false});
  final String name, word;
  final bool above, big; // (above: opened upward, for one at the window's foot: AbsentMotion's AboveAnchor)
  final List<(String key, String label, VoidCallback does)> items;
  @override
  State<CardMore> createState() => _CardMoreState();
}

class _CardMoreState extends State<CardMore> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  bool _up = false; // (no room under it: opened upward, as TinyMenuAt does)

  void _open() {
    final box = context.findRenderObject()! as RenderBox;
    final foot = box.localToGlobal(box.size.bottomLeft(Offset.zero)).dy;
    setState(() => _up = foot + widget.items.length * Shape.z(22) + 2 * Shape.s(3) + 2 > MediaQuery.sizeOf(context).height);
    _portal.toggle();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: OverlayPortal.targetsRootOverlay(
      controller: _portal,
      overlayChildBuilder: (_) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: widget.above
              ? Alignment.topLeft
              : _up
              ? Alignment.topRight
              : Alignment.bottomRight,
          followerAnchor: widget.above
              ? Alignment.bottomLeft
              : _up
              ? Alignment.bottomRight
              : Alignment.topRight,
          child: FloatShut(
            shut: _portal.hide,
            group: _link,
            child: TinyMenu(name: 'card', of: widget.name, items: widget.items, hide: _portal.hide),
          ),
        ),
      ),
      child: TapRegion(
        groupId: _link, // (a press on the ⋮ itself shuts it, by the ⋮: not shut, then opened again)
        child: Hov(
          key: ValueKey('card-more:${widget.name}'),
          onTap: widget.items.isEmpty ? null : _open,
          builder: (_, h) => Padding(
            padding: EdgeInsets.only(right: Shape.s(6)),
            child: Text(
              widget.word,
              style: T
                  .label(
                    h
                        ? Grey.g95
                        : widget.big
                        ? Grey.g76
                        : Grey.g56,
                  )
                  .copyWith(fontSize: widget.big ? T.px(20) : null, fontWeight: widget.big ? FontWeight.w700 : null),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A bin: an effect taken off by it (AbsentMotion's Trash on its header).
class _Bin extends CustomPainter {
  _Bin(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
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

  @override
  bool shouldRepaint(_Bin o) => o.color != color;
}

/// What follows the pointer while an effect is dragged: the folded head, lifted.
class FxDragGhost extends StatelessWidget {
  const FxDragGhost(this.fx, {super.key});
  final Fx fx;
  @override
  Widget build(BuildContext context) => Container(
    width: Shape.z(220),
    height: Pop.titleH + Pop.insetY * 2,
    padding: EdgeInsets.symmetric(horizontal: Pop.inset),
    decoration: BoxDecoration(
      color: Grey.g20,
      boxShadow: [BoxShadow(color: ColorTheme.of('Shadow', const Color(0x99000000)), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: Row(
      children: [
        Badge(fx.tone, size: 16, radius: const Radius.circular(16 * .32), mark: MarkPaint(Pop.onAccent)),
        SizedBox(width: Shape.s(6)),
        Text(
          fx.name,
          style: T.title(Grey.g95).copyWith(fontSize: T.px(12), fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
