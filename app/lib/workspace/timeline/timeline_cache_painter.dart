// Marks which frames are cached on disk for playback (see engine/stage/stage_cache.h).
// A thin line under the ruler's work-area band shows each cached range, as After Effects marks its cached frames.
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// Paints the cached frame ranges in [kept] as thin lines under the work-area band.
///
/// Repaints from [viewport] and [kept] via [repaint].
class TimelineCachePainter extends CustomPainter {
  TimelineCachePainter({required this.viewport, required this.kept})
    : view = viewport.view,
      super(repaint: Listenable.merge([kept, viewport]));
  final TimelineViewport viewport;
  final TimelineView view;
  final ValueListenable<List<(int, int)>> kept;

  @override
  void paint(Canvas c, Size s) {
    final view = viewport.view;
    final ink = Paint()..color = WindowTokens.accent;
    for (final (from, to) in kept.value) {
      c.drawRect(
        Rect.fromLTRB(
          view.x(from).clamp(0, s.width),
          TimelineMetrics.band,
          view.x(to).clamp(0, s.width),
          TimelineMetrics.band + Shape.z(3),
        ),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(TimelineCachePainter o) =>
      o.viewport != viewport || o.kept != kept;
}
