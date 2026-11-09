// The camera on the stage: which thing is the camera, its gizmo taken by the hand (turned or its frame sized), and
// the wheel's dolly.
part of 'stage_view.dart';

extension _StageViewCamera on _StageViewState {
  /// The camera the Camera tool turns: the picked one, else the document's first.
  int? _cameraOf(Ws ws) {
    final m = ws.inside, picked = int.tryParse(widget.selected ?? '');
    if (m == null) return null;
    if (picked != null && m.word(picked, 'kind') == 'camera') return picked;
    for (final l in ws.layers) {
      if (int.tryParse(l.id) case final t? when m.word(t, 'kind') == 'camera') return t;
    }
    return null;
  }

  /// After Effects' Unified Camera tool's wheel: the camera nearer or further from where it looks, the wheel's turning
  /// one step once it rests (golf_noise.md ㊲: no hand on the stage turned or brought the camera).
  void _dolly(double by) {
    final ws = WsScope.read(context), m = ws.inside, cam = _cameraOf(ws);
    if (m == null || cam == null) return;
    if (ws.freeEye) {
      return ws.setView('stage.eye', [
        ws.eye[0],
        ws.eye[1],
        (ws.eye[2] * math.exp(by * .002)).clamp(.01, 100.0),
      ]); // (After Effects' working views: the tool moves the view, not the camera)
    }
    if (_dollyAt == null) {
      m.take(cam);
      _dollyAt = m.value(cam, 'distance', ws.frame / Ws.fps) ?? 1;
    }
    _dollyAt = (_dollyAt! * math.exp(by * .002)).clamp(.01, 100.0);
    m.dragUpdate('distance', _dollyAt!);
    _dollyRest?.cancel();
    _dollyRest = Timer(const Duration(milliseconds: 300), () {
      _dollyAt = null;
      ws.after(m.later('drag_end', number: 1));
    });
  }

  /// A hand on a camera in the working eye: where it is goes round the point it looks at (After Effects' camera and point
  /// of interest), a picked one's corner sizes the frame, which is the lens (AbsentMotion's withCameraFrameScaled), and
  /// the frame or that point moves it (cameraGesture). [inside]: anywhere in the frame, or only on its marks.
  bool _gizmoDragStart(_View v, Offset local, {required bool inside}) {
    final ws = WsScope.read(context), m = ws.inside!, scene = widget.scene, at = ws.frame / Ws.fps;
    for (final id in scene.gizmos.keys) {
      final g = [for (final p in scene.gizmo(id)) p == null ? null : v.toScreen(WsArt.toView(scene, p))], cam = int.parse(id);
      if (g.length < 6) continue;
      final frame = [g[0], g[1], g[2], g[3]].nonNulls.toList();
      bool on(Offset? p, double reach) => p != null && (p - local).distance <= reach;
      final String by;
      if (on(g[5], 10)) {
        by = 'gizmo orbit';
        _orbitRate = g[4] == null
            ? .25
            : 180 / math.pi / math.max((g[5]! - g[4]!).distance, 60); // (a turn as far as the hand has gone on the circle it goes round)
        _orbitFrom = (x: m.value(cam, 'rotate_x', at) ?? 0, y: m.value(cam, 'rotate_y', at) ?? 0);
      } else if (widget.selected == id && frame.any((p) => on(p, 8)) && g[4] != null) {
        by = 'gizmo lens';
        _lensFrom = (zoom: m.value(cam, 'zoom', at) ?? 1, reach: (local - g[4]!).distance, middle: g[4]!);
      } else if (on(g[4], 10) || (inside && frame.length == 4 && (Path()..addPolygon(frame, true)).contains(local))) {
        by = 'place';
      } else {
        continue;
      }
      m.take(cam);
      ws.select(id);
      if (ws.playing) ws.playing = false;
      _drag = (from: local, moved: false, by: by == 'place' ? null : by);
      return true;
    }
    return false;
  }
}
