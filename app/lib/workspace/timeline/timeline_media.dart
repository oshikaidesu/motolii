// What the timeline reads from the project for a shape's row: its form and colour.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline.dart';

extension TimelinePaneMedia on TimelinePaneState {
  /// A shape's form name, colour and whether it is an outline, as stored in the project, for the small icon at the row's left.
  /// With no fill, the outline is drawn in the stroke colour.
  (String, Color?, bool)? formOf(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) =>
        hex.length == 6 && int.tryParse(hex, radix: 16) != null
        ? Color(0xFF000000 | int.parse(hex, radix: 16))
        : null;
    final outline = m.word(t, 'fill') == 'none';
    return (
      m.word(t, 'shape'),
      colour(m.word(t, outline ? 'stroke' : 'fill')),
      outline,
    );
  }
}
