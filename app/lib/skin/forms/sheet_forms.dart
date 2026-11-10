// The sheet form set: controls drawn as plain words on an otherwise empty surface.
// The only coloured mark is the current selection or the control under the pointer.
// A card's kind is shown as a small dot, because a filled header would make every card look like a figure.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/forms/base_controls.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/forms/number_paint.dart';

enum _Mark { dot, ring, quarter }

Widget _mark(_Mark mark, Color ink) => CustomPaint(
  painter: Draw((c, s) {
    final p = Paint()..color = ink;
    final r = s.shortestSide;
    switch (mark) {
      case _Mark.dot:
        c.drawCircle(s.center(Offset.zero), r * .42, p);
      case _Mark.ring:
        c.drawCircle(
          s.center(Offset.zero),
          r * .34,
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.25,
        );
      case _Mark.quarter:
        c.drawArc(Rect.fromCircle(center: Offset(0, s.height), radius: r), -math.pi / 2, math.pi / 2, true, p);
    }
  }, (mark, ink)),
);

class SheetForms extends Forms {
  const SheetForms();

  /// A button drawn as its label and a ring. The ring becomes a quarter mark only while hovered or pressed.
  @override
  Widget action(BuildContext context, ActionSpec a) => NakedButton(
    onPressed: a.onPressed,
    builder: (context, st, _) {
      final hot = st.isHovered || st.isPressed;
      return SizedBox(
        height: Shape.z(28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.label, style: T.name(Grey.g95, 13, FontWeight.w500, 1.15)),
            SizedBox(width: Shape.s(8)),
            SizedBox.square(dimension: Shape.z(14), child: _mark(hot ? _Mark.quarter : _Mark.ring, hot ? Accent.key : Grey.g38)),
          ],
        ),
      );
    },
  );

  /// A switch drawn as the word On or Off and a circle. The accent colour appears only on hover.
  @override
  Widget onOff(BuildContext context, SwitchSpec s) => NakedToggle(
    value: s.on,
    asSwitch: true,
    enabled: s.enabled,
    onChanged: s.onChanged,
    builder: (context, st, _) => Opacity(
      opacity: s.enabled ? 1 : .4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.on ? 'On' : 'Off', style: T.name(s.on ? Grey.g95 : Grey.g56, 11, FontWeight.w500, 1.15)),
          SizedBox(width: Shape.s(6)),
          SizedBox.square(dimension: Shape.z(12), child: _mark(s.on ? _Mark.dot : _Mark.ring, st.isHovered ? Accent.key : Grey.g95)),
        ],
      ),
    ),
  );

  /// A card drawn as a title, a dot for its kind and a hairline. The rows sit on the same surface with no frame.
  @override
  Widget card(BuildContext context, CardSpec c) {
    final head = c.title == null
        ? c.head
        : NakedButton(
            onPressed: c.onToggle,
            builder: (context, st, _) => SizedBox(
              height: Shape.z(28),
              child: Row(
                children: [
                  if (c.tone != null) ...[SizedBox.square(dimension: Shape.z(6), child: _mark(_Mark.dot, c.tone!)), SizedBox(width: Shape.s(8))],
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(c.title!, maxLines: 1, style: T.name(Grey.g95, 13, FontWeight.w500, 1.15)),
                    ),
                  ),
                  ?c.trailing,
                  SizedBox.square(dimension: Shape.z(12), child: _mark(c.open ? _Mark.quarter : _Mark.ring, st.isHovered ? Accent.key : Grey.g38)),
                ],
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?head,
        if (c.title != null) ColoredBox(color: Grey.g20, child: SizedBox(height: 1)),
        if (c.open && c.body.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(6)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: c.body),
          ),
      ],
    );
  }

  /// A segmented choice drawn as labels, each beside a mark. The selected one gets an accent quarter mark.
  @override
  Widget segment(BuildContext context, ChoiceSpec c) => NakedToggleGroup<int>(
    selectedValue: c.selected,
    onChanged: (v) => v == null ? null : c.onSelect(v),
    child: SizedBox(
      height: Shape.z(22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < c.labels.length; i++)
            NakedToggleOption<int>(
              value: i,
              semanticLabel: c.labels[i],
              builder: (context, st, _) => Padding(
                padding: EdgeInsets.only(right: Shape.s(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(dimension: Shape.z(18), child: _mark(st.isSelected ? _Mark.quarter : _Mark.ring, st.isSelected ? Accent.key : Grey.g38)),
                    SizedBox(width: Shape.s(4)),
                    Text(
                      c.labels[i],
                      style: T.label(st.isSelected ? Grey.g100 : Grey.g56).copyWith(fontWeight: st.isSelected ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  /// A toggle drawn as an 18px circle, filled when on. The caller's optional icon sits beside the label.
  @override
  Widget flag(BuildContext context, FlagSpec f) => NakedButton(
    onPressed: f.onTap,
    builder: (context, st, _) {
      final ink = st.isHovered || f.on ? Accent.key : Grey.g38;
      return SizedBox(
        height: Shape.z(22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: Shape.z(18), child: _mark(f.on ? _Mark.dot : _Mark.ring, ink)),
            SizedBox(width: Shape.s(5)),
            if (f.mark != null) ...[f.mark!(f.on ? Grey.g95 : Grey.g56), SizedBox(width: Shape.s(4))],
            Text(f.label, style: T.label(f.on ? Grey.g95 : Grey.g56).copyWith(fontWeight: f.on ? FontWeight.w600 : FontWeight.w400)),
            SizedBox(width: Shape.s(8)),
          ],
        ),
      );
    },
  );

  /// Filter chips in one row. The active chip gets a dot, and each chip shows its count when it has one.
  @override
  Widget chips(BuildContext context, ChipsSpec c) => SizedBox(
    height: Shape.z(28),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
      child: Row(
        children: [
          for (final (name, n) in c.chips)
            NakedButton(
              onPressed: () => c.onPick(name),
              builder: (context, st, _) {
                final on = name == c.active;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (on) ...[SizedBox.square(dimension: Shape.z(5), child: _mark(_Mark.dot, Accent.key)), SizedBox(width: Shape.s(4))],
                      Text(name, style: T.label(on ? Grey.g100 : Grey.g56).copyWith(fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
                      if (n != null) ...[SizedBox(width: Shape.s(4)), Text('$n', style: T.value(Grey.g56).copyWith(fontSize: T.px(10)))],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );

  /// A track header drawn as its name. When selected it gets a quarter mark on the left. It has no background band.
  @override
  Widget track(BuildContext context, TrackSpec t) => Usual.track(
    context,
    t,
    banded: false,
    mark: SizedBox.square(dimension: Shape.z(16), child: _mark(t.selected ? _Mark.quarter : _Mark.ring, t.selected ? Accent.key : Grey.g38)),
    index: Grey.g56,
    ink: Grey.g95,
    rest: FontWeight.w400,
    picked: FontWeight.w600,
    left: 6,
    bottom: 0,
  );

  /// A number drawn as a mark for the axis, the value and a rule below. When the value has a range, a disc moves along the rule.
  @override
  Widget number(BuildContext context, NumberSpec n) {
    final shown = n.editing && n.editor != null ? n.editor! : n.value;
    final shape = n.live || n.hot ? Accent.key : Grey.g95;
    return SizedBox(
      height: n.height,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: n.glyph != null ? n.glyphBox : 0, bottom: n.fill == null ? 0 : 2),
            child: Row(
              children: [
                SizedBox.square(dimension: Shape.z(14), child: _mark(n.fill == null ? _Mark.quarter : _Mark.dot, shape)),
                SizedBox(width: Shape.s(6)),
                if (n.caption != null) ...[Text(n.caption!, style: T.micro(n.on ? Grey.g63 : Grey.g44)), SizedBox(width: Shape.s(6))],
                if (n.lead != null) Flexible(child: n.lead!),
                Expanded(
                  child: Align(alignment: Alignment.centerRight, child: shown),
                ),
              ],
            ),
          ),
          if (n.glyph != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: n.glyphBox,
              child: Center(child: n.glyph),
            ),
          if (n.keyDot != null) Positioned(top: 2, right: 2, child: keyDiamond(n.keyDot!, empty: n.keyEmpty)),
          if (n.fill != null)
            Positioned(
              left: Shape.z(20),
              right: 0,
              bottom: 0,
              height: Shape.z(10),
              child: CustomPaint(painter: _Range(n.fill, n.live || n.hot)),
            ),
        ],
      ),
    );
  }

  /// The selected layer is drawn as a red block and the others as a thin rule, with square corners.
  @override
  double get trackRadius => 0;

  @override
  double trackBar({required bool selected}) => Shape.z(selected ? 12 : 3);

  @override
  Color trackFill(Color kind, {required bool dim, required bool selected}) => dim ? Grey.g26 : (selected ? Accent.key : Grey.g38);

  @override
  Color trackBand(int index, bool selected) => Grey.g07;

  /// Puts a quarter mark before the pane's icon, filled when that pane is the open one.
  @override
  Widget paneMark(BuildContext context, {required bool selected, required Widget mark}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(dimension: Shape.z(14), child: _mark(selected ? _Mark.quarter : _Mark.ring, selected ? Accent.key : Grey.g38)),
      SizedBox(width: Shape.s(4)),
      mark,
    ],
  );

  @override
  bool get plainTabs => true;
}

class _Range extends CustomPainter {
  const _Range(this.fill, this.hot);
  final double? fill;
  final bool hot;

  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2;
    c.drawLine(
      Offset(0, y),
      Offset(s.width, y),
      Paint()
        ..color = Grey.g26
        ..strokeWidth = 1,
    );
    if (fill == null) return;
    c.drawCircle(Offset(4 + (s.width - 8) * fill!.clamp(0, 1), y), hot ? 4 : 3, Paint()..color = hot ? Accent.key : Grey.g95);
  }

  @override
  bool shouldRepaint(_Range o) => o.fill != fill || o.hot != hot;
}
