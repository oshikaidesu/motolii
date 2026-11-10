// The window's own drawing of the controls a form may replace. A form that does not override these keeps this picture.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../tokens.dart';
import '../../widgets/controls.dart' show Hov;
import '../../workspace/state/state.dart' show WsT;
import 'forms.dart';

abstract final class Usual {
  /// A well of round items, the chosen one filled.
  static Widget segment(BuildContext context, ChoiceSpec c) => Container(
    height: Shape.z(20),
    padding: EdgeInsets.all(Shape.s(2)),
    decoration: BoxDecoration(color: WsT.well, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < c.labels.length; i++)
          Hov(
            onTap: () => c.onSelect(i),
            builder: (_, h) => Container(
              height: Shape.z(16),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == c.selected ? WsT.accent : (h ? WsT.raised : WsT.well),
                borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius)),
              ),
              child: Text(c.labels[i], style: T.label(i == c.selected ? WsT.onAccent : (h ? Grey.g95 : Grey.g76)).copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    ),
  );

  /// An on/off chip: raised, with the mark in the accent, when on.
  static Widget flag(BuildContext context, FlagSpec f) => Hov(
    onTap: f.onTap,
    builder: (_, h) {
      final ink = f.on ? WsT.accent : (h ? Grey.g91 : Grey.g56);
      return Container(
        height: Shape.z(20),
        padding: EdgeInsets.only(left: Shape.s(6), right: Shape.s(8)),
        decoration: BoxDecoration(color: f.on ? Grey.g26 : (h ? WsT.raised : WsT.well), borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f.mark != null) f.mark!(ink),
            if (f.mark != null) SizedBox(width: Shape.s(5)),
            Text(f.label, style: T.label(f.on || h ? Grey.g95 : Grey.g63).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    },
  );

  /// Round filter chips in a sideways scroll, moved as any sideways list on a Mac is: a trackpad's sideways swipe, or a
  /// mouse's wheel with Shift held (Flutter's own ScrollBehavior.pointerAxisModifiers); the wheel alone moves what is
  /// up and down, not this (golf_noise.md (93)). The active one is the accent.
  static Widget chips(BuildContext context, ChipsSpec c) => SizedBox(
    height: Shape.z(28),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(2), WsT.inset, Shape.s(6)),
      child: Row(
        children: [
          for (final (name, n) in c.chips) ...[
            Hov(
              onTap: () => c.onPick(name),
              builder: (_, h) {
                final on = name == c.active;
                return AnimatedContainer(
                  duration: Mo.dur,
                  curve: Mo.ease,
                  height: Shape.z(20),
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
                  decoration: BoxDecoration(color: on ? WsT.accent : (h ? WsT.raised : WsT.well), borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: T.micro(on ? WsT.onAccent : Grey.g91).copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                      if (n != null) ...[SizedBox(width: Shape.s(4)), Text('$n', style: T.value(on ? WsT.onAccent : Grey.g56).copyWith(fontSize: T.px(10)))],
                    ],
                  ),
                );
              },
            ),
            SizedBox(width: WsT.gap),
          ],
        ],
      ),
    ),
  );

  /// One timeline name: a band, an accent edge when picked, the kind and the three toggles. [banded] false is a bare row; a [mark] stands at its left.
  static Widget track(
    BuildContext context,
    TrackSpec t, {
    bool banded = true,
    Widget? mark,
    Color? index,
    Color? ink,
    FontWeight rest = FontWeight.w500,
    FontWeight picked = FontWeight.w700,
    double left = 8,
    double bottom = 1,
  }) {
    final row = Padding(
      padding: EdgeInsets.only(left: Shape.s(left), right: Shape.s(6)),
      child: Row(
        children: [
          if (mark != null) ...[mark, SizedBox(width: Shape.s(6))],
          SizedBox(
            width: 14,
            child: Text(
              '${t.index + 1}',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: T.value(index ?? (t.selected ? Grey.g91 : Grey.g56)).copyWith(fontSize: T.px(10)),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          t.kind,
          SizedBox(width: Shape.s(7)),
          Expanded(
            child: Text(
              t.name,
              style: T.name(t.dim ? Grey.g56 : (ink ?? (t.selected ? Grey.g100 : Grey.g91))).copyWith(fontWeight: t.selected ? picked : rest),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          t.eye,
          t.solo,
          t.lock,
        ],
      ),
    );
    return NakedButton(
      onPressed: t.onSelect,
      enableFeedback: false,
      child: Container(
        color: banded ? (t.selected ? Grey.g20 : (t.hot ? Grey.g15 : (t.index.isEven ? Grey.bandA : Grey.bandB))) : null,
        padding: EdgeInsets.only(bottom: Shape.s(bottom)),
        child: !banded
            ? row
            : Stack(
                children: [
                  if (t.selected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: Shape.z(3),
                      child: ColoredBox(color: WsT.accent),
                    ),
                  row,
                ],
              ),
      ),
    );
  }
}
