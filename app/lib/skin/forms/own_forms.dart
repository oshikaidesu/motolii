// The window's own forms: each control as the window has always drawn it.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../widgets/controls.dart' show PillSwitch;
import '../svg_parts.dart';
import '../../inspector/inspector_parts.dart';
import '../tokens.dart';
import '../../workspace/state/state.dart' show WsT;
import 'forms.dart';

class OwnForms extends Forms {
  const OwnForms();

  /// A flat lime pill with dark ink (or the skin's frame for it).
  @override
  Widget action(BuildContext context, ActionSpec a) => Hov(
    onTap: a.onPressed,
    builder: (_, h) => SkinFrame(
      'render',
      hover: h,
      usual: BoxDecoration(color: h ? WsT.accentHot : WsT.accent, borderRadius: BorderRadius.all(Shape.r(13))),
      child: Container(
        height: Shape.z(26),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(14)),
        alignment: Alignment.center,
        child: Text(a.label, style: T.name(WsT.onAccent).copyWith(fontWeight: FontWeight.w800)),
      ),
    ),
  );

  /// Plates side by side, each its glyph and word, the one picked lit.
  @override
  Widget choice(BuildContext context, ChoiceSpec c) => Row(
    children: [
      for (var i = 0; i < c.labels.length; i++) ...[
        if (i > 0) SizedBox(width: Shape.s(4)),
        Expanded(
          child: GlyphPlate(c.labels[i], i < c.glyphs.length ? c.glyphs[i] : (_, _) {}, on: i == c.selected, onTap: () => c.onSelect(i)),
        ),
      ],
    ],
  );

  /// Words in a well, the one picked lit in the accent.
  @override
  Widget tabs(BuildContext context, ChoiceSpec c) => Container(
    height: Shape.z(26),
    padding: EdgeInsets.all(Shape.s(2)),
    decoration: BoxDecoration(color: WsT.well, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, s) in c.labels.indexed)
          Hov(
            onTap: () => c.onSelect(i),
            builder: (_, h) => Container(
              width: Shape.z(76),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: i == c.selected ? WsT.accent : (h ? WsT.raised : null), borderRadius: BorderRadius.all(Shape.r(WsT.radius - 2))),
              child: Text(
                s,
                style: T
                    .name(i == c.selected ? WsT.onAccent : (h ? Grey.g95 : Grey.g76))
                    .copyWith(fontWeight: i == c.selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
          ),
      ],
    ),
  );

  /// The word and a switch: the state is a word, never colour alone. The word is pressed as the switch is, the two one
  /// control, as AbsentMotion's SwitchRow (SettingsDrawer.kt: the whole row toggleable, its label with it).
  @override
  Widget onOff(BuildContext context, SwitchSpec s) => NakedToggle(
    value: s.on,
    asSwitch: true,
    enabled: s.enabled,
    enableFeedback: false,
    onChanged: s.onChanged,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Shape.z(20),
          child: Text(s.on ? 'On' : 'Off', textAlign: TextAlign.right, style: T.label(s.enabled && s.on ? Grey.g95 : Grey.g56)),
        ),
        SizedBox(width: Shape.s(8)),
        Opacity(
          opacity: s.enabled ? 1 : .5,
          child: Pop.on(context) ? PopSwitch(on: s.on) : PillSwitch(on: s.on),
        ),
      ],
    ),
  );

  /// A flat card (or the skin's frame for it).
  @override
  Widget card(BuildContext context, CardSpec c) => SkinFrame(
    'card',
    usual: BoxDecoration(color: Pop.card),
    child: c.own,
  );
}
