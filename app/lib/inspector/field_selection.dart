import 'dart:math' as math;

import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:motolii/widgets/picks.dart' show pickOnClick;

/// The number fields of the Inspector that are selected together, so that an edit of one changes them all.
///
/// Shift-click selects a rectangle of the grid of fields, one row per card with its fields in order, like a spreadsheet.
class FieldSelection {
  /// Creates an empty selection.
  ///
  /// [rows] gives the ids of the fields, one list per card; it is read once, at the first [pick].
  /// [onChanged] is called whenever what shows as selected changes.
  FieldSelection({required this._rows, required this._onChanged});

  final List<List<String>> Function() _rows;
  final VoidCallback _onChanged;

  /// The ids of the selected fields. One field alone is held here but does not show as selected (see [isPicked]).
  final Set<String> picked = {};
  String? _pickFrom;

  /// Whether the field [id] shows as selected, which takes more than one selected field.
  bool isPicked(String id) => picked.length > 1 && picked.contains(id);

  /// Selects the field [id] alone. With [add] it joins the selected fields, or leaves them if it was one (the rule of picks.dart).
  /// With [span] the rectangle of fields from the one selected alone last to this one is selected, which is how a grid is spanned;
  /// with [span] and [add] that rectangle joins the selected fields.
  void pick(String id, {bool span = false, bool add = false}) {
    final from = _pickFrom,
        a = from == null ? null : _cell(from),
        b = _cell(id),
        shown = picked.length > 1;
    if (span && a != null && b != null) {
      if (!add) picked.clear();
      for (var r = math.min(a.$1, b.$1); r <= math.max(a.$1, b.$1); r++) {
        final row = _grid[r];
        for (
          var c = math.min(a.$2, b.$2);
          c <= math.max(a.$2, b.$2) && c < row.length;
          c++
        ) {
          picked.add(row[c]);
        }
      }
    } else {
      // A span with no field picked first, or to a field that is in no row, picks that field as a plain click does (as a spreadsheet's does).
      final r = pickOnClick(now: picked, lead: from, id: id, add: add);
      picked
        ..clear()
        ..addAll(r.picked);
      _pickFrom = r.lead;
    }
    // Selecting one field shows nothing, because [isPicked] needs several. Notify only when the selection was or becomes visible,
    // otherwise pressing a parameter control rebuilt the whole inspector for no change.
    if (shown || picked.length > 1) _onChanged();
  }

  /// Selects nothing.
  void unpick() {
    if (picked.isEmpty) return;
    picked.clear();
    _onChanged();
  }

  late final _grid = _rows();
  (int, int)? _cell(String id) {
    for (var r = 0; r < _grid.length; r++) {
      final c = _grid[r].indexOf(id);
      if (c >= 0) return (r, c);
    }
    return null;
  }
}
