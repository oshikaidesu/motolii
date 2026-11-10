// The app's controls, headless in the manner of React Aria and Radix.
//
// The app decides what a control is and does: its label, its value, what a press does.
// A skin's [Forms] decides how it looks and how it is put together, in Dart.
// Press, hover, focus and selection are handled by naked_ui, so a form only draws and never reimplements behaviour.
//
// A skin names its forms in theme.xml, for example <Forms Value="poster"/>.
// A new form is a file in lib/widgets/forms plus a line in [forms]. Saved while the app runs through live.sh, it shows at once.
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

/// A single prominent action, such as Render.
class ActionSpec {
  const ActionSpec(this.label, this.onPressed);
  final String label;
  final VoidCallback? onPressed;
}

/// One choice out of a few, such as Fit, 50% or 100%. Each option is a label.
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

/// An on/off switch.
class SwitchSpec {
  const SwitchSpec({
    required this.on,
    required this.onChanged,
    this.enabled = true,
  });
  final bool on, enabled;
  final ValueChanged<bool> onChanged;
}

/// A card of the inspector.
///
/// It carries the title, the colour of its kind, whether it is open, the callback that toggles it, a widget at the end
/// of the header, and the body rows. [head] and [own] are the app's default header and the whole default card.
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

/// A small on/off chip with a label, such as Snap, Safe or Grid.
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

  /// The app's icon for the chip, drawn in the colour the form chooses.
  final Widget Function(Color ink)? mark;
}

/// A shelf's filter chips: a name, an optional count, and which chip is active.
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

/// One layer name in the timeline. The app supplies the kind icon and the three toggles, because their behaviour is not the form's.
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
  });
  final int index;
  final String name;
  final bool selected, dim, hot;
  final VoidCallback onSelect;
  final Widget kind, eye, solo, lock;
}

/// How a skin draws the app's controls.
///
/// Dragging a number, typing it and dragging a timeline row stay in the app. A form is given the pieces and returns the widget.
abstract class Forms {
  const Forms();

  /// The forms the current skin names. Falls back to [OwnForms] when it names none or an unknown one.
  static Forms get worn => _numbersBound
      ? (forms[ColorTheme.word('Forms', 'own')] ?? const OwnForms())
      : const OwnForms();

  Widget action(BuildContext context, ActionSpec a);
  Widget onOff(BuildContext context, SwitchSpec s);
  Widget card(BuildContext context, CardSpec c);

  /// Fit, Layer/Group and the other small choices. The default is the app's own well.
  Widget segment(BuildContext context, ChoiceSpec c) =>
      BaseControls.segment(context, c);

  /// Snap, Safe, Grid and the other small on/off chips.
  Widget flag(BuildContext context, FlagSpec f) =>
      BaseControls.flag(context, f);

  /// A shelf's row of filter chips.
  Widget chips(BuildContext context, ChipsSpec c) =>
      BaseControls.chips(context, c);

  /// One layer name in the timeline.
  Widget track(BuildContext context, TrackSpec t) =>
      BaseControls.track(context, t);

  /// A number field's appearance. The field calls [paintNumber], which is bound to this method when the forms load.
  Widget number(BuildContext context, NumberSpec n) => usualNumber(context, n);

  /// The bar of a layer in the timeline: its fill colour, height and corner radius, and the band behind its row.
  ///
  /// The bar keeps its kind colour, as clips do in Ableton, and is a little lighter when selected.
  Color trackFill(Color kind, {required bool dim, required bool selected}) =>
      dim
      ? Grey.g26
      : (selected ? Color.lerp(kind, const Color(0xFFFFFFFF), .18)! : kind);
  double get trackRadius => 4;
  double trackBar({required bool selected}) => Shape.z(18);
  Color trackBand(int index, bool selected) =>
      selected ? Grey.g20 : (index.isEven ? Grey.bandA : Grey.bandB);

  /// The mark at the front of a pane's tab. The app's own mark, unless a form draws a different shape.
  Widget paneMark(
    BuildContext context, {
    required bool selected,
    required Widget mark,
  }) => mark;

  /// Whether the tab strip drops the package's cards. When true, the mark alone is the tab.
  bool get plainTabs => false;
}

/// Runs once when this library loads, so a number field can ask the current form without importing it back.
final bool _numbersBound = () {
  bindNumber((context, spec) => Forms.worn.number(context, spec));
  return true;
}();
