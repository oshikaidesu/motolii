// The window's controls, headless (React Aria's and Radix's manner): the window says what a control is and does,
// and a skin's Forms says how it looks. What a hand does (press, hover, focus) is naked_ui's.
// A skin names its forms in theme.xml (<Forms Value="own"/>). One the window does not know is [OwnForms].
import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'number_paint.dart';
import 'own_forms.dart';

/// Every form the window knows. A skin that names another gets [OwnForms].
const forms = <String, Forms>{'own': OwnForms()};

/// On or off.
class SwitchSpec {
  const SwitchSpec({required this.on, required this.onChanged, this.enabled = true});
  final bool on, enabled;
  final ValueChanged<bool> onChanged;
}

/// How a skin draws the controls the window still asks for.
abstract class Forms {
  const Forms();

  /// The forms the skin worn names (none, or one the window does not know: its own).
  static Forms get worn => _numbersBound ? (forms[ColorTheme.word('Forms', 'own')] ?? const OwnForms()) : const OwnForms();

  Widget onOff(BuildContext context, SwitchSpec s);

  /// A number's picture. The field calls [paintNumber], which was bound to this when the forms loaded.
  Widget number(BuildContext context, NumberSpec n) => usualNumber(context, n);

  /// The mark at the front of a pane's tab. The window's own mark, unless a form puts a shape there.
  Widget paneMark(BuildContext context, {required bool selected, required Widget mark}) => mark;

  /// The tab strip keeps the package's cards. A form that returns true clears them, so the mark is the tab.
  bool get plainTabs => false;
}

/// Installed as this library loads, so a number field can ask the worn form without importing it back.
final bool _numbersBound = () {
  bindNumber((context, spec) => Forms.worn.number(context, spec));
  return true;
}();
