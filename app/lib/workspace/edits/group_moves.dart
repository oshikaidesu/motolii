// Joined: a group's move, as the code that makes it reads: who (its things, in its order), when (its strength's two
// keys; each thing its lag later than the one before), from where to where (the group's own x, y, spread, scatter,
// size, opacity and turns are the other end; the things' own places their homes), how (the way of the stretch between
// the two keys). Read from the document, told to it without waiting; where a thing is at the other end is asked of the
// inside (where it shows while the strength is whole), never worked out here.
import 'dart:math' as math;

import '../../bridge/motolii.dart';
import '../state/state.dart';

/// The group's values that make its other end, as they come.
const wsMoveEnd = {'x': 0.0, 'y': 0.0, 'spread': 1.0, 'scatter': 0.0, 'size': 1.0, 'opacity': 1.0, 'rotate': 0.0, 'rotate_y': 0.0};

class WsMove {
  WsMove(this.by, this.who, this.start, this.length, this.coming, this.lag, this.end, this.out, this.over);
  final int by;
  final List<int> who;
  final double start, length, lag;
  final bool coming; // (from the other end to the homes; else from the homes out to it)
  final Map<String, double> end;
  final double out, over; // (how it eases: 0 even, 1 slowing hard at the end; past the home and back, 0 none)

  double get last => start + length + lag * math.max(0, who.length - 1); // (when the last of them is there)

  /// A moment the strength is whole for every one of them: they all show at the other end.
  double get away => coming ? start - 1e-3 : last + 1e-3;
}

/// The document's groups as moves, in the order they lie.
List<WsMove> wsMoves(Ws ws) {
  final m = ws.inside;
  if (m == null) return const [];
  return [
    for (final l in ws.layers)
      if (int.tryParse(l.id) case final t? when wsMoveOf(m, t) != null) wsMoveOf(m, t)!,
  ];
}

WsMove? wsMoveOf(Motolii m, int by) {
  if (m.word(by, 'kind') != 'behaviour' || m.word(by, 'file') != 'group') return null;
  final who = [
    for (final w in m.word(by, 'members').split(' '))
      if (int.tryParse(w) case final t? when m.layers.contains(t)) t,
  ];
  final keys = m.keyTimes(by, 'strength');
  final start = keys.isEmpty ? 0.0 : keys.first, end = keys.length > 1 ? keys[1] : start + .6;
  final coming = keys.length < 2 || (m.value(by, 'strength', start) ?? 1) >= (m.value(by, 'strength', end) ?? 0);
  final way = m.easingOf(by, 'strength', start).split(' ');
  final bez = way.first == 'Bezier' && way.length == 5 ? [for (final w in way.skip(1)) double.tryParse(w) ?? 0] : null;
  return WsMove(
    by,
    who,
    start,
    end - start,
    coming,
    m.value(by, 'lag', 0) ?? 0,
    {for (final e in wsMoveEnd.entries) e.key: m.value(by, e.key, 0) ?? e.value},
    bez == null ? .5 : ((.6 - bez[0]) / .5).clamp(0.0, 1.0),
    bez == null ? 0 : (bez[3] - 1).clamp(0.0, .6),
  );
}

/// What a move is called on its row: which way and its things ('in · TURN IN TIME').
String wsMoveName(Ws ws, Iterable<String> who, bool coming) {
  final names = [for (final id in who) ws.layers.where((l) => l.id == id).firstOrNull?.name ?? id];
  final all = names.length > 4 ? '${names.take(3).join(' ')} +${names.length - 3}' : names.join(' ');
  return '${coming ? 'in' : 'out'} · $all';
}

/// The way a move eases, said as the inside says a stretch: a Bezier slowing as much as [out], past the home by [over].
String wsMoveWay(double out, double over) => 'Bezier ${(.6 - .5 * out).toStringAsFixed(3)} 0 0.2 ${(1 + over).toStringAsFixed(3)}';

/// A move made of [who]: they come in at [start] from a little below, clear, each a little later; one step, picked.
/// Things that came in by a move already go out by this one (made later in the film, it leaves what is before alone).
void wsMakeMove(Ws ws, List<String> who, double start) {
  final m = ws.inside;
  if (m == null || who.isEmpty) return;
  final coming = !wsMoves(ws).any((o) => o.who.any((t) => who.contains('$t')));
  m.later('together', number: 1);
  ws.after(m.later('add', name: 'behaviour', word: 'group'), null, (b) => ws.select('$b'));
  m.later('set', layer: -1, name: 'strength', number: 1);
  m.later('say', layer: -1, name: 'name', word: wsMoveName(ws, who, coming));
  m.later('relate', layer: -1, word: who.join(' '));
  m.later('set', layer: -1, name: 'lag', number: .08);
  m.later('set', layer: -1, name: 'y', number: -.15);
  m.later('set', layer: -1, name: 'opacity', number: 0);
  m.later('key', layer: -1, name: 'strength', word: '$start', number: coming ? 1 : 0);
  m.later('key', layer: -1, name: 'strength', word: '${start + .6}', number: coming ? 0 : 1);
  m.later('easing', layer: -1, name: 'strength', number: start, word: wsMoveWay(.8, 0));
  ws.after(m.later('together'), (done, why) {
    if (!done) ws.notice = 'No move made: $why'; // (the step undone as a whole: why, on the top bar)
    ws.reread();
  });
}

/// The same at any moment: a question of the inside (docs/app/BRIDGE.md Q), answered later.
Future<({double x, double y, double size, double opacity, double flip})> wsShowsAt(Motolii m, int t, double at) async {
  final v = await m.shownAt([
    for (final n in const ['x', 'y', 'size', 'opacity', 'rotate_y']) (t, n, at),
  ]);
  return (x: v[0] ?? 0, y: v[1] ?? 0, size: v[2] ?? 1, opacity: v[3] ?? 1, flip: v[4] ?? 0);
}
