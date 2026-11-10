// The app's default forms: each control drawn the way the app has always drawn it.
import 'package:motolii/widgets/switch_track.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/widgets/skin_frame.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/widgets/controls.dart' show Hov;

class OwnForms extends Forms {
  const OwnForms();

  /// A flat lime pill with dark text, or the skin's frame for it.
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

  /// The word On or Off next to a switch, so the state is never shown by colour alone.
  ///
  /// The word and the switch are one control, as in AbsentMotion's SwitchRow (SettingsDrawer.kt): pressing either toggles it.
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
          child: PopSwitch(on: s.on),
        ),
      ],
    ),
  );

  /// A flat card, or the skin's frame for it.
  @override
  Widget card(BuildContext context, CardSpec c) => SkinFrame(
    'card',
    usual: BoxDecoration(color: Pop.card),
    child: c.own,
  );
}
