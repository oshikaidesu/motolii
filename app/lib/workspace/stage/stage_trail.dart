// The selected layer's motion path over time as the engine computes it (including its wave), in canvas points, for the stage to draw.
// Asked of the engine again only when the document or the selection changes.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class StageTrail {
  StageTrail({required this.alive, required this.rebuild});

  /// Whether the view is still on screen, and its setState.
  final bool Function() alive;
  final void Function(VoidCallback change) rebuild;

  // The selected layer's motion path over time as the engine computes it (including its wave), in canvas points, drawn thin
  // with direction arrows as in Alight Motion. Recomputed only when the document or the selection changes; null when the
  // layer stays put.
  (Object?, List<Offset>?) _trail = (null, null);
  List<Offset>? of(WorkspaceController ws, String? selected) {
    final m = ws.inside, t = int.tryParse(selected ?? '');
    if (m == null ||
        t == null ||
        const {'behaviour', 'camera', 'light'}.contains(m.word(t, 'kind'))) {
      return null;
    }
    final key = (ws.rev, t);
    if (_trail.$1 != key) {
      _trail = (key, null);
      final start = m.value(t, 'start', 0) ?? 0,
          lasts = m.lasts(t),
          end = lasts > 0 ? start + lasts : m.seconds;
      if (end > start) {
        m.path(t, from: start, to: end, n: 90).then((p) {
          if (!alive() || _trail.$1 != key || p == null) return;
          final c = ArtGeometry.centre,
              pts = [
                for (var i = 0; i + 1 < p.length; i += 4)
                  c + Offset(p[i], -p[i + 1]) * m.point,
              ];
          rebuild(
            () => _trail = (
              key,
              pts.any((q) => (q - pts.first).distance > 1) ? pts : null,
            ),
          );
        });
      }
    }
    return _trail.$2;
  }
}
