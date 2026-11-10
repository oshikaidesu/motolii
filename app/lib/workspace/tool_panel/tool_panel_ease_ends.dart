// The two ends of a stretch, pulled up and down their bars outside the square (the maker, 10/31, drawn on a picture of it).
part of 'tool_panel_ease_state.dart';

/// Of each stretch whose ends a hand has moved, each value as its two keys first were and the measure of its bars: the
/// ends stand where they were left, read from the keys, so an undo takes them back (the user, 10/31: "確定してもその位置のままで").
final _endsFrom = Expando<Map<String, Map<String, (double, double, double)>>>();

mixin _EaseEnds on State<EaseTool> {
  String? _trouble;

  // (each value keyed at both ends of the stretch: its keys' frames and values, and the index of the key at the end pulled;
  //  with Jump on, a key a frame outside first keeps the key's value as it was. One step.)
  Iterable<(String, List<int>, List<double>, int)> _ends(Ws ws, EaseSpan span, bool start) sync* {
    final m = ws.inside!, t = int.parse(span.layer.id);
    for (final name in m.moving(t)) {
      if (ws.stretch case final s? when s.name != name) continue; // (a line picked: that value's ends alone)
      final at = [for (final s in m.keyTimes(t, name)) (s * Ws.fps).round()], vs = m.keyValues(t, name);
      final i = at.indexOf(span.from), j = at.indexOf(span.to), k = start ? i : j;
      if (i < 0 || j < 0 || k >= vs.length || j >= vs.length) continue;
      yield (name, at, vs, k);
    }
  }

  Map<String, (double, double, double)> _from(Ws ws, EaseSpan span) => (_endsFrom[ws] ??= {}).putIfAbsent('${spanId(span)}:${span.to}', () => {});

  // (where the two ends stand on their bars)
  (double, double) _endsOf(Ws ws, EaseSpan? span) {
    if (ws.inside == null || span == null || _from(ws, span).isEmpty) return (0, 1);
    final from = _from(ws, span);
    for (final (name, at, vs, _) in _ends(ws, span, true)) {
      if (from[name] case (final a, final b, final scale)?) return ((vs[at.indexOf(span.from)] - a) / scale, 1 + (vs[at.indexOf(span.to)] - b) / scale);
    }
    return (0, 1);
  }

  // (an end pulled, told as it goes: all one step, the newest one at a time, as _live; what the keys were when it was taken
  //  held, the document's own moving under it. With Jump on, a key a frame outside first keeps the key's value as it was.)
  List<(String, List<int>, List<double>, int)>? _pull;
  double? _pullNext;
  bool _pullGoing = false, _pullDone = false;
  double _toward(Motolii m, EaseSpan span, Ws ws, String name, double was, double by) {
    final shown = m.shown(name), lo = shown?.low ?? -double.infinity, hi = shown?.high ?? double.infinity;
    return (was + by * _from(ws, span)[name]!.$3).clamp(math.min(lo, was), math.max(hi, was));
  }

  void _toEnd(Ws ws, EaseSpan? span, bool start, double by, {bool done = false}) {
    final m = ws.inside;
    if (m == null || span == null) return;
    if (_pullGoing) {
      _pullNext = by;
      _pullDone = _pullDone || done;
      return;
    }
    if (_pull == null && done && by.abs() < 1e-4) return;
    final t = int.parse(span.layer.id), key = start ? span.from : span.to, outside = start ? span.from - 1 : span.to + 1;
    if (_pull == null) {
      for (final (name, at, vs, _) in _ends(ws, span, start)) {
        // (the measure of the bars, as the keys are now, once)
        final i = at.indexOf(span.from), j = at.indexOf(span.to), shown = m.shown(name);
        _from(ws, span).putIfAbsent(name, () => (vs[i], vs[j], (vs[j] - vs[i]).abs() > 1e-9 ? vs[j] - vs[i] : (shown == null ? 1.0 : shown.high - shown.low)));
      }
      _pull = [..._ends(ws, span, start)];
      m.later('together', number: 1);
      for (final (name, at, vs, k) in _pull!) {
        if (easeJump && outside >= 0 && !at.contains(outside)) {
          m.later(
            'key',
            layer: t,
            name: name,
            word: '${outside / Ws.fps}',
            number: vs[k],
          ); // (the key's value before it moved: a frame off, what the value was there)
        }
      }
    }
    for (final (name, _, vs, k) in _pull!) {
      m.later('key', layer: t, name: name, word: '${key / Ws.fps}', number: _toward(m, span, ws, name, vs[k], by));
    }
    if (done) {
      final told = _pull!.length;
      _pull = null;
      ws.after(m.later('together'), (ok, why) => mounted ? setState(() => _trouble = ok ? (told == 0 ? 'No value keyed at both ends' : null) : why) : null);
      return;
    }
    _pullGoing = true;
    ws.after(m.later('show', layer: t), (_, _) {
      _pullGoing = false;
      final next = _pullNext, last = _pullDone;
      _pullNext = null;
      _pullDone = false;
      if (next != null) _toEnd(ws, span, start, next, done: last);
    });
  }

  // (what the end pulled [by] makes the first value keyed at both ends, as the inspector shows it: its name, its number
  //  in its units; After Effects' value graph shows the value of the point a hand pulls: golf_noise.md (70))
  String? _endSays(Ws ws, EaseSpan? span, bool start, double by) {
    final m = ws.inside;
    if (m == null || span == null) return null;
    final t = int.parse(span.layer.id);
    for (final (name, _, vs, i) in _pull ?? [..._ends(ws, span, start)]) {
      final now = _from(ws, span).containsKey(name) ? _toward(m, span, ws, name, vs[i], by) : vs[i];
      final (k, f) = m.reading(t, name);
      final v = now * k + f, shown = m.shown(name);
      return '${shown?.label ?? name} ${v.toStringAsFixed(v.abs() >= 100 ? 0 : 2)}${shown?.unit ?? ''}';
    }
    return null;
  }
}
