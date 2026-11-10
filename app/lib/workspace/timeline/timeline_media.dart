// What the timeline reads from the project for a row and for the ruler, without caching: the selected layer's retimed
// ends and a shape's form.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline.dart';

extension TimelinePaneMedia on TimelinePaneState {
  /// Frames where the selected group's intro ends and its outro starts, for marking on the ruler.
  ///
  /// They are the End of intro and Start of outro values of the group's Element card (the engine's doc_element_clock).
  List<int> retimedOf(WorkspaceController ws) {
    final m = ws.inside, t = int.tryParse(ws.selected ?? '');
    if (m == null || t == null) return const [];
    final start = m.value(t, 'start', 0) ?? 0;
    return [
      for (final n in const ['retime_in', 'retime_out'])
        if ((m.value(t, n, 0) ?? 0) > 0)
          ((start + m.value(t, n, 0)!) * WorkspaceController.fps).round(),
    ];
  }

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
