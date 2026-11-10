// Marks which frames are cached on disk for playback (see engine/stage/stage_cache.h).
// A thin line under the ruler's work-area band shows each cached range, as After Effects marks its cached frames.
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import 'timeline_paint.dart';
import '../state/state.dart';

/// Paints the cached frame ranges in [kept] as thin lines under the work-area band.
class WtKeptPainter extends CustomPainter {
  WtKeptPainter({required this.view, required this.kept}) : super(repaint: kept);
  final WtView view;
  final ValueListenable<List<(int, int)>> kept;

  @override
  void paint(Canvas c, Size s) {
    final ink = Paint()..color = WsT.accent;
    for (final (from, to) in kept.value) {
      c.drawRect(Rect.fromLTRB(view.x(from).clamp(0, s.width), WtM.band, view.x(to).clamp(0, s.width), WtM.band + Shape.z(3)), ink);
    }
  }

  @override
  bool shouldRepaint(WtKeptPainter o) => o.view != view || o.kept != kept;
}
