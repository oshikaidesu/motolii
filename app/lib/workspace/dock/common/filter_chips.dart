// The row of filter chips at the top of a shelf.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/forms/forms.dart';

/// A row of round filter chips with counts; the active one is the accent. Scrolls sideways when the shelf is narrow.
class FilterChips extends StatelessWidget {
  const FilterChips(
    this.chips, {
    super.key,
    required this.active,
    required this.onPick,
  });
  final List<(String, int?)> chips;
  final String active;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) => Forms.worn.chips(
    context,
    ChipsSpec(chips: chips, active: active, onPick: onPick),
  );
}
