// The engine drawing the whole pane. When it does, the stage sits inside the pane's texture where the view puts it; the engine is told
// where, and which layer is selected and which hovered, after the frame (it cannot be asked during build). Nothing here draws.
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';

class StageDesk {
  StageDesk({required this.alive, required this.rebuild});

  /// Whether the view is still on screen, and its setState.
  final bool Function() alive;
  final void Function(VoidCallback change) rebuild;

  // Tells the engine where the stage sits when that changes (or the window's pixel ratio does).
  /// The texture id of the whole pane as the engine draws it, once it has been made.
  int? id;
  StageViewport? _toldDesk;
  Motolii? _deskOf;
  double? _toldDpr;
  void follow(
    StageViewport v, {
    required double dpr,
    required Motolii? m,
    required bool textured,
  }) {
    if (m != _deskOf) {
      // A different project was opened: forget the old engine view and send it again.
      id = null;
      _toldDesk = null;
      _toldPick = null;
    }
    if (!textured || (v == _toldDesk && dpr == _toldDpr)) {
      return; // Also sent again when the window's pixel ratio changes.
    }
    _toldDesk = v;
    _toldDpr = dpr;
    if ((_deskOf = m) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!alive() || _toldDesk != v || _toldDpr != dpr) return;
      final m = _deskOf!;
      final ticket = m.desk(
        (v.area.width * dpr).round(),
        (v.area.height * dpr).round(),
        (v.origin.dx - v.area.left) * dpr,
        (v.origin.dy - v.area.top) * dpr,
        v.scale * dpr,
        dpr,
      );
      void look(Duration _) {
        // Poll once per frame until the engine has drawn, so the window never blocks on it.
        if (!alive()) return;
        final a = m.answer(ticket);
        if (a < 0) {
          SchedulerBinding.instance.scheduleFrameCallback(look);
          return;
        }
        if (a == 0) return;
        _toldPick = null;
        if (id == null) {
          m.deskTexture().then(
            (got) => alive() && got >= 0 ? rebuild(() => id = got) : null,
          );
        }
      }

      SchedulerBinding.instance
        ..scheduleFrameCallback(look)
        ..ensureVisualUpdate();
    });
  }

  // With the engine drawing the pane: tells it which layer is selected and which is hovered whenever they change.
  (int, int)? _toldPick;
  void pick(String? selected, String? hover) {
    final m = _deskOf;
    if (id == null || m == null) return;
    final now = (
      int.tryParse(selected ?? '') ?? 0,
      int.tryParse(hover ?? '') ?? 0,
    );
    if (now == _toldPick) return;
    _toldPick = now;
    m.pick(now.$1, now.$2);
  }

  /// Back to the engine's own stage view.
  void release() => _deskOf?.desk(0, 0, 0, 0, 0, 0);
}
