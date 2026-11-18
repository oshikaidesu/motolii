// Headless controls. The app defines behaviour; a skin's [Forms] draws them.
// A skin names its forms in theme.xml, e.g. `<Forms Value="poster"/>`.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/forms/base_controls.dart';
import 'package:motolii/widgets/forms/lighttable_forms.dart';
import 'package:motolii/widgets/forms/own_forms.dart';
import 'package:motolii/widgets/forms/poster_forms.dart';
import 'package:motolii/widgets/forms/sheet_forms.dart';
import 'package:motolii/widgets/number_field_look.dart';

/// Every form the app knows, by the name a skin uses.
const forms = <String, Forms>{
  'own': OwnForms(),
  'poster': PosterForms(),
  'lighttable': LightTableForms(),
  'sheet': SheetForms(),
};

class ActionSpec {
  const ActionSpec(this.label, this.onPressed);
  final String label;
  final VoidCallback? onPressed;
}

class ChoiceSpec {
  const ChoiceSpec({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
}

class SwitchSpec {
  const SwitchSpec({
    required this.on,
    required this.onChanged,
    this.enabled = true,
  });
  final bool on, enabled;
  final ValueChanged<bool> onChanged;
}

/// An inspector card spec. [head] and [own] are the app's default header/card.
class CardSpec {
  const CardSpec({
    this.title,
    this.tone,
    required this.open,
    this.onToggle,
    this.trailing,
    required this.body,
    this.head,
    required this.own,
  });
  final String? title;
  final Color? tone;
  final bool open;
  final VoidCallback? onToggle;
  final Widget? trailing, head;
  final List<Widget> body;
  final Widget own;
}

class FlagSpec {
  const FlagSpec({
    required this.label,
    required this.on,
    required this.onTap,
    this.mark,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  final Widget Function(Color ink)? mark;
}

class ChipsSpec {
  const ChipsSpec({
    required this.chips,
    required this.active,
    required this.onPick,
  });
  final List<(String, int?)> chips;
  final String active;
  final ValueChanged<String> onPick;
}

/// One layer row in the timeline.
class TrackSpec {
  const TrackSpec({
    required this.index,
    required this.name,
    required this.selected,
    required this.dim,
    required this.hot,
    required this.onSelect,
    required this.kind,
    required this.eye,
    required this.solo,
    required this.lock,
    required this.clip,
  });
  final int index;
  final String name;
  final bool selected, dim, hot;
  final VoidCallback onSelect;
  final Widget kind, eye, solo, lock, clip;
}

/// How a skin draws the app's controls.
abstract class Forms {
  const Forms();

  /// The current skin's forms, or [OwnForms] as fallback.
  static Forms get worn => _numbersBound
      ? (forms[ColorTheme.word('Forms', 'own')] ?? const OwnForms())
      : const OwnForms();

  Widget action(BuildContext context, ActionSpec a);
  Widget onOff(BuildContext context, SwitchSpec s);
  Widget card(BuildContext context, CardSpec c);

  Widget segment(BuildContext context, ChoiceSpec c) =>
      BaseControls.segment(context, c);

  Widget flag(BuildContext context, FlagSpec f) =>
      BaseControls.flag(context, f);

  Widget chips(BuildContext context, ChipsSpec c) =>
      BaseControls.chips(context, c);

  Widget track(BuildContext context, TrackSpec t) =>
      BaseControls.track(context, t);

  /// A number field's appearance.
  Widget number(BuildContext context, NumberSpec n) => usualNumber(context, n);

  /// Timeline bar: fill colour, height, corner radius and row band.
  Color trackFill(Color kind, {required bool dim, required bool selected}) =>
      dim
      ? Grey.g26
      : (selected ? Color.lerp(kind, const Color(0xFFFFFFFF), .18)! : kind);
  double get trackRadius => 4;
  double trackBar({required bool selected}) => Shape.z(18);
  Color trackBand(int index, bool selected) => selected
      ? Color.lerp(Grey.g20, Accent.fill, .08)!
      : (index.isEven ? Grey.bandA : Grey.bandB);

  /// The mark at the front of a pane's tab.
  Widget paneMark(
    BuildContext context, {
    required bool selected,
    required Widget mark,
  }) => mark;

  bool get plainTabs => false;
}

/// Binds paintNumber to the current form on first load.
final bool _numbersBound = () {
  bindNumber((context, spec) => Forms.worn.number(context, spec));
  return true;
}();
