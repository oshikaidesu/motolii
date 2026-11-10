// The hand on the stage: what a press takes (a thing, a handle, a crop's edge), how far it carries, the edges and
// middles it snaps to, a handle pulled out of a shape, and what is kept when it lets go.
// (setState from an extension on the State itself: the analyzer allows it only in a class or mixin)
// ignore_for_file: invalid_use_of_protected_member
part of 'stage_view.dart';

extension _StageViewDrag on _StageViewState {
  Rect _bounds(ArtBox b) {
    final p = b.corners;
    return p.skip(1).fold(Rect.fromPoints(p[0], p[0]), (r, q) => r.expandToInclude(Rect.fromPoints(q, q)));
  }

  void _snapFrom(String id) {
    final boxes = widget.scene.boxes, m = WsScope.read(context).inside;
    final held = boxes[id];
    if (!widget.snap || held == null || m == null) return _snapTo = null;
    int top(int t) {
      for (var p = (m.value(t, 'parent', 0) ?? 0).round(), n = 0; p > 0 && n < 64; p = (m.value(t, 'parent', 0) ?? 0).round(), n++) {
        t = p;
      }
      return t;
    }

    final mine = top(int.parse(id)), c = WsArt.comp;
    final xs = <(double, double)>[(0, c.width)], ys = <(double, double)>[(0, c.height)];
    for (final g in widget.scene.guidesX) {
      xs.add((g, g));
    }
    for (final g in widget.scene.guidesY) {
      ys.add((g, g));
    }
    for (final MapEntry(:key, :value) in boxes.entries) {
      if (top(int.parse(key)) == mine) continue;
      final r = _bounds(value);
      xs.add((r.left, r.right));
      ys.add((r.top, r.bottom));
    }
    _snapTo = (box: _bounds(held), xs: xs, ys: ys);
  }

  Offset _snapped(Offset by, double s) {
    final to = _snapTo;
    if (to == null) return by;
    (double, double?) one(double lo, double size, double d, List<(double, double)> lines) {
      (double, double)? best;
      for (final (a, b) in lines) {
        for (final line in [a, (a + b) / 2, b]) {
          for (final mine in [lo + d, lo + d + size / 2, lo + d + size]) {
            final diff = line - mine;
            if (diff.abs() <= 6 / s && (best == null || diff.abs() < best.$1.abs())) best = (diff, line);
          }
        }
      }
      return best == null ? (d, null) : (d + best.$1, best.$2);
    }

    final (x, mx) = widget.axis == 2 ? (by.dx, null) : one(to.box.left, to.box.width, by.dx, to.xs);
    final (y, my) = widget.axis == 1 ? (by.dy, null) : one(to.box.top, to.box.height, by.dy, to.ys);
    _met = (mx, my);
    return Offset(x, y);
  }

  bool _pull(_View v, Offset local) {
    final ws = WsScope.read(context), m = ws.inside;
    if (m == null) return false;
    final at = v.toComp(local), tol = 4 / v.s;
    if (local.dy < _V.ruler || local.dx < _V.ruler) {
      _pulling = (axis: local.dy < _V.ruler ? 'y' : 'x', was: null);
      return true;
    }
    for (final (axis, g) in m.guides) {
      if (((axis == 'x' ? at.dx : at.dy) - g).abs() > tol) continue;
      _pulling = (axis: axis, was: g);
      return true;
    }
    return false;
  }

  void _pullDragEnd(_View v, Offset local) {
    final p = _pulling, ws = WsScope.read(context), m = ws.inside;
    _pulling = null;
    if (p == null || m == null) return;
    final over = p.axis == 'y' ? local.dy < _V.ruler : local.dx < _V.ruler, at = v.toComp(local);
    m.later('together', number: 1); // (one step, without waiting)
    if (p.was != null) m.later('guide', name: p.axis, number: p.was!, word: 'off');
    if (!over) m.later('guide', name: p.axis, number: ((p.axis == 'x' ? at.dx : at.dy)).roundToDouble());
    ws.after(m.later('together'));
  }

  void _dragStart(_View v, Offset local) {
    if (widget.make == 'camera') {
      // (After Effects' Unified Camera tool: a drag turns the camera round where it looks)
      final ws = WsScope.read(context), m = ws.inside, cam = _cameraOf(ws);
      if (m == null || cam == null) {
        ws.notice = 'No camera: add one from Create › Layers';
        return;
      }
      if (ws.freeEye) {
        _orbitFrom = (x: ws.eye[1], y: ws.eye[0]);
        _drag = (from: local, moved: false, by: 'orbit');
        return;
      }
      final at = ws.frame / Ws.fps;
      m.take(cam);
      if (ws.playing) ws.playing = false;
      _orbitFrom = (x: m.value(cam, 'rotate_x', at) ?? 0, y: m.value(cam, 'rotate_y', at) ?? 0);
      _drag = (from: local, moved: false, by: 'orbit');
      return;
    }
    if (widget.make == 'brush') {
      setState(() => _brush = [local]);
      return;
    }
    if (widget.make != null) {
      if (widget.make == 'pen') _penWay = [local];
      setState(() => _drawFrom = local);
      return;
    }
    final ws = WsScope.read(context), m = ws.inside;
    // (joined: a hand on one of the picked thing's handles carries it the handle's way: the inside reckons it from where it took hold)
    final picked = int.tryParse(widget.selected ?? '');
    if (m != null && picked != null) {
      String? by, grip;
      var near = 8.0;
      for (final MapEntry(:key, :value) in handles.entries) {
        final d = (value - local).distance;
        if (d > near) continue;
        near = d;
        by = switch (key.split(' ').first) {
          'corner' => 'scale',
          'side' => 'edge',
          'turn' => 'turn',
          'anchor' => 'pivot',
          'round' => 'round',
          'points' => 'points',
          'crop' => key,
          _ => null,
        };
        grip = key;
      }
      for (final p in [...m.points(picked), for (final (h, _) in m.handles(picked)) h]) {
        // (a path's own point, moved with its handles; or a handle alone: the inside takes the nearest)
        final d = (v.toScreen(p) - local).distance;
        if (d > near) continue;
        near = d;
        by = 'point';
        grip = null;
      }
      // (just outside a corner it is turned: Figma's "Hover just outside one of the layer's bounds"; how far out,
      //  tldraw's rotate corners, SelectionForegroundOverlayUtil.ts: a square 2 × 1.62 × 4.5 px out from each corner)
      for (var i = 0; by == null && handles.containsKey('turn') && i < 4; i++) {
        final (c, a, b) = (handles['corner $i'], handles['corner ${(i + 1) % 4}'], handles['corner ${(i + 3) % 4}']);
        if (c == null || a == null || b == null || (c - a).distance < 1 || (c - b).distance < 1) continue;
        final p = local - c, u = (c - a) / (c - a).distance, w = (c - b) / (c - b).distance, s = p.dx * u.dx + p.dy * u.dy, r = p.dx * w.dx + p.dy * w.dy;
        if (s >= 0 && r >= 0 && s <= 14.58 && r <= 14.58) (by, grip) = ('turn', 'turn');
      }
      if (by != null) {
        m.take(picked);
        final at = v.toComp(local); // (points of the picture, as the inside counts them)
        m.dragUpdate('grip', at.dx, at.dy);
        if (ws.playing) ws.playing = false;
        _drag = (from: local, moved: false, by: by);
        if (grip != _grip) setState(() => _grip = grip);
        return;
      }
    }
    if (m != null && _gizmoDragStart(v, local, inside: false)) return;
    if (_pull(v, local)) return; // (a guide out of a ruler, or one taken hold of: after the handles, which lie over everything)
    final id = m == null ? null : _hit(v, local), t = int.tryParse(id ?? '');
    if (m != null && t == null && _gizmoDragStart(v, local, inside: true)) return; // (AbsentMotion's TopLayerAt: the things first, then the frame they lie in)
    if (m != null && t == null) {
      // (where no thing is: drawn round)
      ws.select(null);
      setState(() => _lasso = [local]);
      return;
    }
    if (m == null || t == null) return;
    m.take(t);
    ws.select(id);
    if (ws.playing) ws.playing = false; // (a hand on a thing stops the play)
    _drag = (from: local, moved: false, by: null);
    _snapFrom(id!);
  }

  void _dragEnd({bool keep = true}) {
    final h = _drag, ws = WsScope.read(context), m = ws.inside, free = h?.by == 'orbit' && ws.freeEye;
    _drag = null;
    _orbitFrom = null;
    _lensFrom = null;
    _snapTo = null;
    if (_grip != null) setState(() => _grip = null);
    if (_met != (null, null)) setState(() => _met = (null, null));
    if (h == null || m == null || free) return;
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0)); // (let go without waiting: the document read again once the inside has it)
  }

  /// The picked thing's parent, by its id (null: none).
  String? _parentOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    final p = m == null || t == null ? 0 : (m.value(t, 'parent', 0) ?? 0).round();
    return p > 0 ? '$p' : null;
  }

  /// What the hand is changing, as the stage shows it now (its frame, carried values and all): where it is, how wide and
  /// high, how far turned, or where it turns about (points of the picture, degrees clockwise as seen).
  String? _heldSays(String? by) {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    final f = m == null || t == null ? null : m.bounds(t);
    if (f == null) return null;
    return switch (by) {
      null => '${f[0].round()}, ${f[1].round()}',
      'scale' => '${f[2].round()} × ${f[3].round()}',
      'turn' => '${(f[4] % 360).round()}°',
      'pivot' => '${f[5].round()}, ${f[6].round()}',
      _ => null,
    };
  }
}
