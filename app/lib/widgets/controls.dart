// Small interactive controls: press, icon button, badge, chip and segmented control.
// In every control the value is the most prominent element, the surrounding chrome is grey,
// and a family colour appears only on the things that belong to that family.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';

/// The app's basic press target, built on naked_ui's [NakedButton].
class Pressable extends StatelessWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.onTap,
  });

  /// Builds the child. The bool is true while the pointer hovers.
  final Widget Function(BuildContext, bool) builder;
  final MouseCursor cursor;

  /// Called on a press.
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => NakedButton(
    onPressed: onTap,
    mouseCursor: cursor,
    enableFeedback: false,
    builder: (context, st, _) => builder(context, st.isHovered),
  );
}

/// A small square button holding one glyph.
///
/// By default it looks like the dock's header button: raised when [on], one step lighter on hover, no fill at rest, 20 wide,
/// with a colour fade. When [rest] and [ink] are given it looks like a tool panel or stage tile instead:
/// accent fill when [on], [rest] fill and [ink] at rest, WindowTokens.radius corners, no margin and no fade.
class IconPress extends StatelessWidget {
  const IconPress(
    this.glyph, {
    super.key,
    this.onTap,
    this.on = false,
    this.lit = false,
    this.size,
    this.width,
    this.rest,
    this.ink,
  });

  /// Builds the glyph in the ink for the current state: resting, hovered or on.
  final Widget Function(Color ink) glyph;
  final VoidCallback? onTap;

  /// [on] shows the selected state. [lit] applies to tiles only and holds the tile raised in grey instead of the accent.
  final bool on, lit;

  /// Side length in design pixels (default 20, scaled). [width] defaults to [size].
  final double? size, width;
  final Color? rest, ink;

  @override
  Widget build(BuildContext context) {
    final tile = rest != null;
    return Pressable(
      // An empty callback keeps the hover state working when there is no [onTap].
      onTap: onTap ?? () {},
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      builder: (context, h) => AnimatedContainer(
        duration: tile ? Duration.zero : Motion.dur,
        curve: Motion.ease,
        width: width ?? size ?? Shape.z(20),
        height: size ?? Shape.z(20),
        margin: tile ? null : EdgeInsets.only(left: Shape.s(2)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tile
              ? (on
                    ? WindowTokens.accent
                    : (lit ? Grey.g26 : (h ? WindowTokens.raised : rest)))
              : (on ? WindowTokens.raised : (h ? WindowTokens.card : null)),
          borderRadius: BorderRadius.all(
            Shape.r(tile ? WindowTokens.radius : WindowTokens.chipRadius),
          ),
        ),
        child: glyph(
          tile
              ? (on ? WindowTokens.onAccent : (h || lit ? Grey.g95 : ink!))
              : (on || h ? Grey.g95 : Grey.g63),
        ),
      ),
    );
  }
}

/// A small filled tile holding one mark, so an item shows what it is before its name is read.
///
/// By default it is a square with chip-radius corners holding a glyph. [radius] changes the corners; half of [size] makes a circle.
/// With [onTap] it is a button.
class Badge extends StatelessWidget {
  const Badge(
    this.color, {
    super.key,
    this.child,
    this.mark,
    this.size = 20,
    this.radius,
  }) : onTap = null,
       _round = false;

  /// The stage's badge: a circle 18 across, painted with [mark].
  const Badge.round(
    this.color, {
    super.key,
    required CustomPainter this.mark,
    this.onTap,
  }) : child = null,
       size = 18,
       radius = null,
       _round = true;
  final Color color;
  final Widget? child;

  /// Paints the mark at the full size of the tile, instead of [child].
  final CustomPainter? mark;
  final double size;
  final Radius? radius;
  final VoidCallback? onTap;
  final bool _round;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(
          radius ??
              (_round
                  ? Radius.circular(size / 2)
                  : Shape.r(WindowTokens.chipRadius)),
        ),
      ),
      child: child ?? CustomPaint(size: Size.square(size), painter: mark),
    );
    return onTap == null
        ? tile
        : Pressable(
            cursor: SystemMouseCursors.basic,
            onTap: onTap,
            builder: (_, _) => tile,
          );
  }
}

/// How a [Chip] looks: sizes, fill and ink at rest, on hover and when on, the text style, and an optional edge.
///
/// Heights, paddings and the dot are in design pixels, scaled by Shape.
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
    this.edgeWidth = 1,
    this.margin,
    this.cursor,
    this.press = true,
  });
  final Color ink;
  final Color? fill, hoverFill, onFill, hoverInk, onInk;
  final TextStyle Function(Color ink) text;
  final double? height;
  final double padX, padY, radius, edgeWidth;
  final bool center, press;

  /// A ring all round, [edgeWidth] wide, drawn while the chip is not on.
  final Color? edge;
  final EdgeInsets? margin;

  /// Defaults to the click cursor when the chip can be pressed.
  final MouseCursor? cursor;

  /// The tool panel's header chip: a well that lifts on hover and takes the accent when on.
  static ChipLook get tool => ChipLook(
    height: 18,
    fill: WindowTokens.well,
    hoverFill: WindowTokens.raised,
    onFill: WindowTokens.accent,
    ink: Grey.g76,
    hoverInk: Grey.g95,
    onInk: WindowTokens.onAccent,
    text: (c) => TextStyles.micro(c),
  );

  /// A readout in a well, such as the top bar's fps or the timeline's name and tempo: 20 high and not pressable.
  /// Monospace, or the bold micro style when [mono] is false.
  static ChipLook readout({
    required Color ink,
    double size = 10,
    double radius = 4,
    bool mono = true,
  }) => ChipLook(
    height: 20,
    padX: 7,
    radius: radius,
    center: true,
    fill: WindowTokens.well,
    ink: ink,
    press: false,
    text: (c) => mono
        ? TextStyles.value(c).copyWith(fontSize: TextStyles.px(size))
        : TextStyles.micro(c).copyWith(fontWeight: FontWeight.w600),
  );

  /// A flat chip filled with a layer's colour, with its name in dark ink.
  static ChipLook flat(Color tone) => ChipLook(
    height: 16,
    center: true,
    fill: tone,
    ink: WindowTokens.onAccent,
    press: false,
    text: (c) => TextStyles.micro(c).copyWith(fontWeight: FontWeight.w700),
  );

  /// The dock's tag: filled with [hue] and dark ink, or a quiet raised grey when [hue] is null.
  /// [edge] adds a dark ring so the tag stays legible on artwork of unknown colour.
  static ChipLook tag(Color? hue, {bool edge = false}) => ChipLook(
    height: edge ? 16 : 14,
    padX: 4,
    radius: WindowTokens.chipRadius,
    center: true,
    fill: hue ?? WindowTokens.raised,
    ink: hue == null ? Grey.g76 : WindowTokens.onAccent,
    edge: edge ? WindowTokens.onAccent : null,
    edgeWidth: 1.5,
    press: false,
    text: (c) => TextStyles.micro(c)
        .copyWith(fontWeight: FontWeight.w700, letterSpacing: .4, height: 1),
  );

  /// A bare grey word that brightens on hover, such as Copy, Paste or Reset: no fill and no padding.
  static ChipLook get word => ChipLook(
    padX: 0,
    ink: Grey.g56,
    hoverInk: Grey.g95,
    text: (c) => TextStyles.label(c),
  );

  /// A word on the panel's background, not pressable. Used by the bar over the stage, which sits on a dark or light surround.
  static ChipLook get said => ChipLook(
    padX: 8,
    padY: 5,
    radius: 12,
    fill: WindowTokens.body,
    ink: Grey.g91,
    margin: EdgeInsets.only(right: Shape.s(6)),
    press: false,
    text: (c) => TextStyles.label(c),
  );

  /// An operation available between items selected together: an accent pill.
  /// It is drawn outlined, not filled as with [Chip.on], when it only shows a relation the item is in.
  static ChipLook get relate => ChipLook(
    padX: 10,
    padY: 5,
    radius: 12,
    fill: WindowTokens.body,
    onFill: WindowTokens.accent,
    ink: WindowTokens.accent,
    onInk: WindowTokens.onAccent,
    edge: WindowTokens.accent,
    cursor: SystemMouseCursors.basic,
    margin: EdgeInsets.only(right: Shape.s(4)),
    text: (c) => TextStyles.label(c),
  );
}

/// A small chip showing a label, optionally with a dot before it or a glyph in place of it.
/// [look] defaults to the tool panel's header chip. [onTap] makes the chip a button.
class Chip extends StatelessWidget {
  const Chip({
    super.key,
    required this.label,
    this.dot,
    this.glyph,
    this.onTap,
    this.on = false,
    this.look,
  });
  final String label;

  /// Colour of a round mark drawn before the label.
  final Color? dot;

  /// Drawn instead of the label.
  final Widget Function(Color ink)? glyph;
  final VoidCallback? onTap;
  final bool on;
  final ChipLook? look;

  @override
  Widget build(BuildContext context) {
    final l = look ?? ChipLook.tool;
    Widget chip(bool h) {
      final lit = h && onTap != null;
      final ink = on ? l.onInk ?? l.ink : (lit ? l.hoverInk ?? l.ink : l.ink);
      return Container(
        height: l.height == null ? null : Shape.z(l.height!),
        margin: l.margin,
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(l.padX),
          vertical: Shape.s(l.padY),
        ),
        alignment: l.center ? Alignment.center : null,
        decoration: BoxDecoration(
          color: on
              ? l.onFill ?? l.fill
              : (lit ? l.hoverFill ?? l.fill : l.fill),
          border: l.edge != null && !on
              ? Border.all(color: l.edge!, width: l.edgeWidth)
              : null,
          borderRadius: BorderRadius.all(Shape.r(l.radius)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: Shape.z(6),
                height: Shape.z(6),
                decoration: BoxDecoration(
                  color: on ? WindowTokens.onAccent : dot,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: Shape.s(5)),
            ],
            if (glyph != null)
              glyph!(ink)
            else
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: l.text(ink),
                ),
              ),
          ],
        ),
      );
    }

    if (!l.press && onTap == null) return chip(false);
    return Pressable(
      onTap: onTap,
      cursor:
          l.cursor ??
          (onTap == null ? MouseCursor.defer : SystemMouseCursors.click),
      builder: (_, h) => chip(h),
    );
  }
}

/// A row of mutually exclusive text options. The option at [index] is selected.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.glyphs,
  });
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  /// A picture for each option, drawn in a 16 x 14 box before its word with the given stroke, so the option reads
  /// by its shape (Transform's flat square, tilted card and cube for 2D, 2.5D and 3D).
  final List<void Function(Canvas c, Paint stroke)>? glyphs;

  // Every selected state uses this one style: a g20 pill with g95 text and a 1 px underline in the selection colour.
  @override
  Widget build(BuildContext context) {
    Widget seg(int i) => NakedToggleOption<int>(
      value: i,
      enableFeedback: false,
      semanticLabel: items[i],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: i == index ? Grey.g20 : null,
          borderRadius: BorderRadius.all(Shape.r(5)),
          border: Border(
            bottom: BorderSide(
              color: i == index ? Role.selected : const Color(0x00000000),
              width: 1,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyphs?.elementAtOrNull(i) case final g?) ...[
                CustomPaint(
                  size: const Size(16, 14),
                  painter: _StrokeGlyph(g, i == index ? Grey.g95 : Grey.g63),
                ),
                SizedBox(width: Shape.s(6)),
              ],
              Text(
                items[i].toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: TextStyles.micro(i == index ? Grey.g95 : Grey.g63)
                    .copyWith(letterSpacing: .4),
              ),
            ],
          ),
        ),
      ),
    );
    return NakedToggleGroup<int>(
      selectedValue: index,
      onChanged: (v) => v == null ? null : onChanged(v),
      child: Container(
        height: Shape.z(26),
        padding: EdgeInsets.all(Shape.s(2)),
        decoration: BoxDecoration(
          color: Grey.g07,
          borderRadius: BorderRadius.all(Shape.r(7)),
        ),
        child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.max,
          children: [
            for (var i = 0; i < items.length; i++) Expanded(child: seg(i)),
          ],
        ),
      ),
    );
  }
}

class _StrokeGlyph extends CustomPainter {
  const _StrokeGlyph(this.draw, this.ink);
  final void Function(Canvas c, Paint stroke) draw;
  final Color ink;
  @override
  void paint(Canvas c, Size s) => draw(
    c,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  @override
  bool shouldRepaint(_StrokeGlyph o) => o.ink != ink || o.draw != draw;
}
