// Controls. One rule: the value is the loudest thing in a control, the chrome around it is grey, the family colour marks only what it belongs to.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../inspector/inspector_small.dart' show Hov;
import '../skin/tokens.dart';
import '../workspace/state/state.dart' show WsT;

/// A small square press holding one glyph; [glyph] is given the ink for the moment (resting, hovered, on). The default look is the dock's
/// header button: raised when on, a step up on hover, no fill at rest, 20 wide, faded. Given [rest] and [ink] it is the tool panel's and the
/// stage's tile: accent when on, [rest] fill and [ink] at rest, WsT.radius corners, no margin, no fade.
class IconPress extends StatelessWidget {
  const IconPress(this.glyph, {super.key, this.onTap, this.on = false, this.size, this.rest, this.ink});
  final Widget Function(Color ink) glyph;
  final VoidCallback? onTap;
  final bool on;
  final double? size; // (none: 20, scaled)
  final Color? rest, ink;

  @override
  Widget build(BuildContext context) {
    final tile = rest != null;
    return Hov(
      onTap: onTap ?? () {}, // (a press that does nothing still shows the hover)
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      builder: (context, h) => AnimatedContainer(
        duration: tile ? Duration.zero : Mo.dur,
        curve: Mo.ease,
        width: size ?? Shape.z(20),
        height: size ?? Shape.z(20),
        margin: tile ? null : EdgeInsets.only(left: Shape.s(2)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tile ? (on ? WsT.accent : (h ? WsT.raised : rest)) : (on ? WsT.raised : (h ? WsT.card : null)),
          borderRadius: BorderRadius.all(Shape.r(tile ? WsT.radius : WsT.chipRadius)),
        ),
        child: glyph(tile ? (on ? WsT.onAccent : (h ? Grey.g95 : ink!)) : (on || h ? Grey.g95 : Grey.g63)),
      ),
    );
  }
}

/// A small filled tile holding one mark: how a thing says what it is before its name is read. The dock's is a square (chip radius)
/// with a glyph; [radius] rounds it otherwise (a circle: half of [size]); given [onTap] it is a press.
class Badge extends StatelessWidget {
  const Badge(this.color, {super.key, this.child, this.mark, this.size = 20, this.radius})
    : onTap = null,
      cursor = SystemMouseCursors.click,
      _round = false,
      assert((child == null) != (mark == null));

  /// The stage's: a circle, 18 across, the arrow kept over it.
  const Badge.round(this.color, {super.key, required CustomPainter this.mark, this.onTap})
    : child = null,
      size = 18,
      radius = null,
      cursor = SystemMouseCursors.basic,
      _round = true;
  final Color color;
  final Widget? child;

  /// The mark as a painting, as large as the tile (instead of [child]): painted here, in the one place.
  final CustomPainter? mark;
  final double size;
  final Radius? radius;
  final VoidCallback? onTap;
  final MouseCursor cursor;
  final bool _round;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(radius ?? (_round ? Radius.circular(size / 2) : Shape.r(WsT.chipRadius)))),
      child: child ?? CustomPaint(size: Size.square(size), painter: mark),
    );
    return onTap == null ? tile : Hov(cursor: cursor, onTap: onTap, builder: (_, _) => tile);
  }
}

/// How a [Chip] looks. The chips of the panels differed only in these: sizes, the fill and ink at rest, hovered and on, the text, an edge.
/// Heights, paddings and the dot are in design pixels (scaled by Shape).
class ChipLook {
  const ChipLook({
    required this.ink,
    required this.text,
    this.height,
    this.padX = 6,
    this.padY = 0,
    this.radius = 4,
    this.center = false,
    this.fill,
    this.hoverFill,
    this.onFill,
    this.hoverInk,
    this.onInk,
    this.edge,
    this.dotSize = 6,
    this.dotGap = 5,
    this.softWrap = false,
    this.margin,
    this.cursor,
    this.press = true,
  });
  final Color ink;
  final Color? fill, hoverFill, onFill, hoverInk, onInk;
  final TextStyle Function(Color ink) text;
  final double? height;
  final double padX, padY, radius, dotSize, dotGap;
  final bool center, softWrap, press;
  final Color? edge; // (a 1px ring all round, while not on)
  final EdgeInsets? margin;
  final MouseCursor? cursor; // (none: a hand when it can be pressed)

  /// The tool panel's header chip: a well that lifts on hover, the accent when on.
  static ChipLook get tool => ChipLook(
    height: 18,
    fill: WsT.well,
    hoverFill: WsT.raised,
    onFill: WsT.accent,
    ink: Grey.g76,
    hoverInk: Grey.g95,
    onInk: WsT.onAccent,
    text: (c) => T.micro(c),
  );

  /// A folded card's summary value: a g20 tag (g15 and quiet when [dim]), not a press.
  static ChipLook brief({bool dim = false}) => ChipLook(
    height: 16,
    radius: 8,
    center: true,
    fill: dim ? Grey.g15 : Grey.g20,
    ink: dim ? Grey.g56 : Grey.g95,
    dotSize: 8,
    dotGap: 4,
    softWrap: true,
    press: false,
    text: (c) => T.label().copyWith(fontWeight: FontWeight.w600, height: 1, color: c),
  );

  /// A readout in a well (the top bar's fps, the timeline's name and tempo): 20 high, not a press. Mono, or the micro bold word.
  static ChipLook readout({required Color ink, double size = 10, double radius = 4, bool mono = true}) => ChipLook(
    height: 20,
    padX: 7,
    radius: radius,
    center: true,
    fill: WsT.well,
    ink: ink,
    press: false,
    text: (c) => mono ? T.value(c).copyWith(fontSize: T.px(size)) : T.micro(c).copyWith(fontWeight: FontWeight.w600),
  );

  /// A flat chip in a layer's hue with its name in dark ink.
  static ChipLook flat(Color tone) => ChipLook(
    height: 16,
    center: true,
    fill: tone,
    ink: WsT.onAccent,
    press: false,
    text: (c) => T.micro(c).copyWith(fontWeight: FontWeight.w700),
  );

  /// What things picked together may do together: the accent pill, outlined (not [Chip.on]) when it is only a relation a thing is in.
  static ChipLook get relate => ChipLook(
    padX: 10,
    padY: 5,
    radius: 12,
    fill: WsT.body,
    onFill: WsT.accent,
    ink: WsT.accent,
    onInk: WsT.onAccent,
    edge: WsT.accent,
    cursor: SystemMouseCursors.basic,
    margin: EdgeInsets.only(right: Shape.s(4)),
    text: (c) => T.label(c),
  );
}

/// A small chip: a word, a dot before it or a glyph for it. The default [look] is the tool panel's header chip; [onTap] makes it a press.
class Chip extends StatelessWidget {
  const Chip({super.key, required this.label, this.dot, this.glyph, this.onTap, this.on = false, this.look});
  final String label;
  final Color? dot; // (a round mark before the word)
  final Widget Function(Color ink)? glyph; // (drawn instead of the word)
  final VoidCallback? onTap;
  final bool on;
  final ChipLook? look;

  /// The colour a "#RRGGBB" word names, for a chip's [dot].
  static Color? swatch(String t) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(t) ? Color(int.parse(t.substring(1), radix: 16) | 0xFF000000) : null;

  /// The chip's laid-out width, so a row can drop the chips that would not fit whole.
  static double width(String t, ChipLook look) =>
      (TextPainter(
        text: TextSpan(text: t, style: look.text(look.ink)),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout()).width +
      look.padX * 2 +
      (swatch(t) != null ? look.dotSize + look.dotGap : 0);

  @override
  Widget build(BuildContext context) {
    final l = look ?? ChipLook.tool;
    Widget chip(bool h) {
      final lit = h && onTap != null;
      final ink = on ? l.onInk ?? l.ink : (lit ? l.hoverInk ?? l.ink : l.ink);
      return Container(
        height: l.height == null ? null : Shape.z(l.height!),
        margin: l.margin,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(l.padX), vertical: Shape.s(l.padY)),
        alignment: l.center ? Alignment.center : null,
        decoration: BoxDecoration(
          color: on ? l.onFill ?? l.fill : (lit ? l.hoverFill ?? l.fill : l.fill),
          border: l.edge != null && !on ? Border.all(color: l.edge!) : null,
          borderRadius: BorderRadius.all(Shape.r(l.radius)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: Shape.z(l.dotSize),
                height: Shape.z(l.dotSize),
                decoration: BoxDecoration(color: on ? WsT.onAccent : dot, shape: BoxShape.circle),
              ),
              SizedBox(width: Shape.s(l.dotGap)),
            ],
            if (glyph != null)
              glyph!(ink)
            else
              Flexible(
                child: Text(label, maxLines: 1, softWrap: l.softWrap, overflow: TextOverflow.ellipsis, style: l.text(ink)),
              ),
          ],
        ),
      );
    }

    if (!l.press && onTap == null) return chip(false);
    return Hov(onTap: onTap, cursor: l.cursor ?? (onTap == null ? MouseCursor.defer : SystemMouseCursors.click), builder: (_, h) => chip(h));
  }
}

class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, this.onChanged, this.expand = false});
  final List<String> items;
  final int index;
  final bool expand;
  final ValueChanged<int>? onChanged;

  /// One selected style across the lab: a g20 pill with g95 text and a 1px accent underline (critique 2026-10-02: four selected styles were found).
  @override
  Widget build(BuildContext context) {
    Widget seg(int i) => NakedToggleOption<int>(
      value: i,
      enableFeedback: false,
      semanticLabel: items[i],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: expand ? Shape.s(6) : Shape.s(12)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: i == index ? Grey.g20 : null,
          borderRadius: BorderRadius.all(Shape.r(5)),
          border: Border(bottom: BorderSide(color: i == index ? Role.selected : const Color(0x00000000), width: 1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(items[i].toUpperCase(), maxLines: 1, softWrap: false, style: T.micro(i == index ? Grey.g95 : Grey.g63).copyWith(letterSpacing: .4)),
        ),
      ),
    );
    return NakedToggleGroup<int>(
      selectedValue: index,
      onChanged: onChanged == null ? null : (v) => v == null ? null : onChanged!(v),
      child: Container(
        height: Shape.z(26),
        padding: EdgeInsets.all(Shape.s(2)),
        decoration: BoxDecoration(color: Grey.g07, borderRadius: BorderRadius.all(Shape.r(7))),
        child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [for (var i = 0; i < items.length; i++) expand ? Expanded(child: seg(i)) : seg(i)],
        ),
      ),
    );
  }
}
