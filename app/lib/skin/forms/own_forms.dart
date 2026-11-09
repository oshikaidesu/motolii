// The window's own forms: the switch as the window has always drawn it.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../inspector/inspector_parts.dart';
import '../../widgets/controls.dart' show PillSwitch;
import '../tokens.dart';
import 'forms.dart';

class OwnForms extends Forms {
  const OwnForms();

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
}
