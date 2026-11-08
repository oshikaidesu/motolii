// timeline_hand.dart: a hand on the tracks: what the pointer would do over a bar, a bar or a key taken.
part of 'timeline.dart';

extension _WsTimelineHand on _WsTimelineState {
  // ---------------------------------------------------------------- input

  // The row under a height: its place, its layer, and the value whose lane it is (null: the layer's own row).
  ({int i, WsLayer l, String? value})? _rowAt(double y) {
    var i = 0;
    if (_pin > 0 && y < _panelH + _grip) {   // (the group's room on top, or its edge)
      if (y >= _panelH) return null;
      for (var top = 0.0; i < _pin && top + _tall(i) <= y + _pscroll; i++) {
        top += _tall(i);
      }
      if (i >= _pin) return null;
    } else {
      i = _pin + ((y - _panelH - _grip + _vscroll) / WtM.row).floor();
    }
    if (i < 0 || i >= _order.length) return null;
    return (i: i, l: _ws!.layers[_order[i].layer], value: _order[i].value);
  }

  // A press on a value's lane: on a breakpoint it is taken away, as on Ableton's envelope (Live 12 manual 25.5.2). Between
  // two it picks that stretch, as Theatre.js's connector (the maker, 10/31: Live's line takes a breakpoint at one press, and
  // "区間を選択できない"), and a second press in the same place puts a key there, as Live's double click off the line.
  void _laneTap(Offset p) {
    final ws = _ws!, m = ws.inside, r = _rowAt(p.dy), v = _view;
    if (m == null || r == null || r.value == null || _isLocked(ws, r.l.id)) return;
    final t = int.parse(r.l.id), name = r.value!, row = _laneRow(ws, r.l, name), pts = row.lane ?? const [];
    if (pts.isEmpty) return;
    for (final k in m.keyMoments(t, name)) {
      if ((v.x((k * Ws.fps).round()) - p.dx).abs() <= WtM.keyPicked + 2) return ws.after(m.later('unkey', thing: t, name: name, number: k));
    }
    final now = DateTime.now(), twice = _lanePressed != null && now.difference(_lanePressed!) < kDoubleTapTimeout && (p - _laneAt).distance < kDoubleTapSlop;
    _lanePressed = twice ? null : now;
    _laneAt = p;
    final f = v.frameAt(p.dx);
    if (twice) return ws.after(m.later('key_here', thing: t, name: name, number: f.round().clamp(0, Ws.duration) / Ws.fps));
    final from = pts.where((q) => q.$1 <= f).lastOrNull?.$1;
    if (from == null || !pts.any((q) => q.$1 > f)) return ws.clearKeys();
    if (r.l.kind == WsKind.group) return _offer(ws, r.l, name, from, p);
    ws.pickStretch(r.l.id, name, from);
  }

  // A group's stretch pressed: three small boxes where it was pressed, each a picture of what it works (the user's
  // drawing, 11/8: graph D's stretch, three boxes out of it; their pictures graphs A, C, B), then the existing Ease desk.
  // Value and time are of the array, so only here.
  void _offer(Ws ws, WsLayer l, String name, int from, Offset p) {
    _offering((layer: l.id, name: name, from: from));
    const steps = {WsEaseMode.stretch: Offset.zero, WsEaseMode.value: Offset(0, .1), WsEaseMode.time: Offset(.1, 0)};
    _trackMenu.currentState?.show(p, [
      WsMenuItem.pictures([for (final s in steps.values) CustomPaint(painter: EaseSpreadIcon(s, Grey.g91))], (k) => ws.pickStretch(l.id, name, from, mode: steps.keys.elementAt(k))),
    ], shut: () => mounted ? _offering(null) : null);
  }

  void _trackDown(Offset p) {
    final ws = _ws!, v = _view;
    final r = _rowAt(p.dy);
    if (r == null) { // (below the rows: nothing picked, After Effects' manner; joined, the inspector is then the whole picture's)
      if (ws.entered != null && _twice('')) return ws.enter(ws.layers.where((l) => l.id == ws.entered).firstOrNull?.parent);   // (pressed twice: out of the group, to the one it is in)
      ws.clearKeys();
      ws.select(null);
      return;
    }
    if (r.value != null) return;   // (a lane: its tap is the lane's, on the hand's way up)
    final i = r.i, l = r.l;
    final cy = _rowY(i) + WtM.row / 2;
    if (!_isLocked(ws, l.id) && (p.dy - cy).abs() <= WtM.bar / 2 + 2) {
      int? best;
      var bd = WtM.keyPicked + 2;
      for (final k in l.keys) {
        final d = (v.x(k) - p.dx).abs();
        if (d <= bd) {
          bd = d;
          best = k;
        }
      }
      if (best != null) return ws.pickKey((layer: l.id, frame: best), add: HardwareKeyboard.instance.isShiftPressed);
    }
    final f = v.frameAt(p.dx);
    if (f >= l.inF && f <= l.outF) {
      if (_roomy(ws, l) && l.id != ws.entered && _twice(l.id)) return ws.enter(l.id);   // (a group's bar pressed twice, or one with copies: into it)
      ws.select(l.id);
    } else {
      ws.clearKeys();
    }
  }

  bool _onPale(Ws ws, WsLayer l, Offset p) {
    final w = _wholeOf(ws, l);
    return w != null && p.dx >= _view.x(w.$1) && p.dx <= _view.x(w.$2);
  }

  MouseCursor _cursorAt(Offset p) {
    if (_onGrip(p.dy)) return SystemMouseCursors.resizeUpDown;
    final ws = _ws!, v = _view, r = _rowAt(p.dy);
    if (r == null) return MouseCursor.defer;
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    if (r.value case final n?) {   // (a lane: over a breakpoint, it is taken by a click)
      final t = int.parse(l.id);
      final at = ws.inside!.keyMoments(t, n), f = v.frameAt(p.dx) / Ws.fps;
      return at.any((k) => (v.x((k * Ws.fps).round()) - p.dx).abs() <= WtM.keyPicked + 2) || (at.isNotEmpty && f > at.first && f < at.last) ? SystemMouseCursors.click : SystemMouseCursors.precise;
    }
    if (_isLocked(ws, l.id) || p.dx < a - 6 || p.dx > b + 6) return _onPale(ws, l, p) ? SystemMouseCursors.grab : SystemMouseCursors.precise;
    if (l.keys.any((k) => (v.x(k) - p.dx).abs() <= WtM.keyPicked + 2)) return SystemMouseCursors.click;
    return (p.dx - a).abs() <= 6 || (p.dx - b).abs() <= 6 ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.grab;
  }

  bool _grab(Offset p) {
    final ws = _ws!, v = _view, m = ws.inside;
    final r = _rowAt(p.dy);
    if (m == null || r == null) return false;
    if (r.value != null) {   // (a lane: nothing carried, and no box drawn from it; a key of a group's place, how far apart there)
      _pullApart(ws, r, p);
      return true;
    }
    final l = r.l, a = v.x(l.inF), b = v.x(l.outF);
    final off = p.dx < a - 6 || p.dx > b + 6;
    if (_isLocked(_ws!, l.id) || (off && !_onPale(ws, l, p))) return false;
    for (final k in l.keys) {
      if ((v.x(k) - p.dx).abs() > WtM.keyPicked + 2) continue;
      final held = (layer: l.id, frame: k), all = ws.keys.contains(held) ? ws.keys.toList() : [held];
      if (!ws.keys.contains(held)) ws.pickKey(held);
      if (ws.playing) ws.playing = false;
      _slide = (keys: all, grab: k, by: 0);
      _stops = ws.stops(skip: {l.id})..add(ws.frame);
      return true;
    }
    m.take(int.parse(l.id));
    ws.select(l.id);
    if (ws.playing) ws.playing = false;
    _barIn = l.inF;
    _barOut = l.outF;
    _stops = ws.stops(skip: {l.id, ...ws.many})..add(ws.frame);
    _barWhole = _wholeOf(ws, l);
    if (off && (ws.frame < l.inF || ws.frame >= l.outF)) ws.frame = l.inF;
    _bar = (id: l.id, part: off ? 'slip' : (p.dx - b).abs() <= 6 ? 'tail' : ((p.dx - a).abs() <= 6 ? 'head' : 'bar'), grab: v.frameAt(p.dx), moved: false);
    return true;
  }
}
