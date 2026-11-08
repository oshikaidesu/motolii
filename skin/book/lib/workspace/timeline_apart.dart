// timeline_apart.dart: a key of the entered group's place pulled on its lane: how far apart its things are there.
part of 'timeline.dart';

extension _WsTimelineApart on _WsTimelineState {
  // A key of the entered group's place, taken on its lane in the room and pulled (GROUP_FOCUS_new.md いまの考え: 量は
  // グラフの上でつまんで引く): up and down, its things' values apart there (`x_spread`, so much higher and lower); left and
  // right, their moments apart (`x_lag`, so many seconds later, the first at the key). Each key holds its own, as After Effects'
  // text animator keys its Amount; between two keys it goes as their stretch's way, the Ease desk's value and time boxes.
  // Which of the two, the first pixels say, as Flutter's own drag recognisers take the axis whose slop is crossed first.
  // The engine deals it among the things (doc_place, doc_spread_share); the lane's copies spread as it goes, its measure
  // held (timeline.dart _laneRow), so its outermost follows the hand.
  bool _pullApart(Ws ws, ({int i, WsLayer l, String? value}) r, Offset p) {
    final l = r.l, name = r.value ?? '', m = ws.inside!;
    if (l.kind != WsKind.group || l.id != ws.entered || !const {'x', 'y', 'z'}.contains(name) || _isLocked(ws, l.id)) return false;
    final t = int.parse(l.id), at = m.keyMoments(t, name).where((k) => (_view.x((k * Ws.fps).round()) - p.dx).abs() <= WtM.keyPicked + 2).firstOrNull;
    if (at == null) return false;
    final (lo, hi) = _laneSpan['${l.id}:$name'] ?? (0.0, 1.0);
    _apart = (thing: t, name: name, at: at, from: p, span: (lo, hi), perPx: (hi - lo) / math.max(1.0, _tall(r.i) - 9), amount: null, was: 0.0);   // (the lane's measure as it was taken, held while pulled: as the lane drew it, lowest at its foot)
    m.later('together', number: 1);   // (the pull, its keys, let go: one step)
    if (ws.playing) ws.playing = false;
    return true;
  }

  void _pullApartTo(Offset p) {
    final a = _apart!, m = _ws!.inside!, d = p - a.from;
    var amount = a.amount, was = a.was;
    if (amount == null) {
      if (d.distance < 4) return;
      amount = '${a.name}${d.dx.abs() > d.dy.abs() ? '_lag' : '_spread'}';
      for (final k in m.keyMoments(a.thing, a.name)) {
        m.later('key_here', thing: a.thing, name: amount, number: k);   // (every key of the place holds one: as it is there, none where there was none)
      }
      final i = m.keyMoments(a.thing, amount).indexWhere((k) => (k - a.at).abs() < 1e-6);
      was = i < 0 ? 0.0 : m.keyValues(a.thing, amount)[i];
      _apart = (thing: a.thing, name: a.name, at: a.at, from: a.from, span: a.span, perPx: a.perPx, amount: amount, was: was);
    }
    _sendApart(amount.endsWith('_lag') ? was + d.dx / _view.ppf / Ws.fps : was - d.dy * a.perPx);
  }

  // (told as the hand goes, the newest one at a time, as the Ease desk's ends are)
  void _sendApart(double to) {
    final a = _apart!, ws = _ws!, m = ws.inside!;
    if (_apartGoing) {
      _apartNext = to;
      return;
    }
    _apartGoing = true;
    m.later('key', thing: a.thing, name: a.amount!, word: '${a.at}', number: to);
    ws.after(m.later('show', thing: a.thing), (_, _) {
      _apartGoing = false;
      final next = _apartNext;
      _apartNext = null;
      if (next != null && _apart != null) _sendApart(next);
    });
  }

  void _pullApartUp(bool keep) {
    final a = _apart!, ws = _ws!, m = ws.inside!;
    _apart = null;
    if (_apartNext case final to? when keep) m.later('key', thing: a.thing, name: a.amount!, word: '${a.at}', number: to);
    _apartNext = null;
    ws.after(m.later('together', number: keep && a.amount != null ? 0 : -1), (_, _) => ws.reread());   // (let go: kept, one step; given up or not moved: none)
  }
}
