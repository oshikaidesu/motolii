// Joined: a group's move, as the code that makes it reads: who (its things, in its order), when (its strength's two
// keys; each thing its lag later than the one before), from where to where (the group's own x, y, spread, scatter,
// size, opacity and turns are the other end; the things' own places their homes), how (the way of the stretch between
// the two keys). Read from the document, told to it without waiting; where a thing is at the other end is asked of the
// inside (where it shows while the strength is whole), never worked out here.
import '../../bridge/motolii.dart';
import '../state/state.dart';

/// What a move is called on its row: which way and its things ('in · TURN IN TIME').
String wsMoveName(Ws ws, Iterable<String> who, bool coming) {
  final names = [for (final id in who) ws.layers.where((l) => l.id == id).firstOrNull?.name ?? id];
  final all = names.length > 4 ? '${names.take(3).join(' ')} +${names.length - 3}' : names.join(' ');
  return '${coming ? 'in' : 'out'} · $all';
}

/// A move made of [who]: they come in at [start] from a little below, clear, each a little later; one step, picked.
/// Things that came in by a move already go out by this one (made later in the film, it leaves what is before alone).
void wsMakeMove(Ws ws, List<String> who, double start) {
  final m = ws.inside;
  if (m == null || who.isEmpty) return;
  final held = {
    for (final l in ws.layers)
      if (int.tryParse(l.id) case final b? when m.word(b, 'kind') == 'behaviour' && m.word(b, 'file') == 'group')
        for (final w in m.word(b, 'members').split(' '))
          if (int.tryParse(w) case final t? when m.layers.contains(t)) '$t',
  };
  final coming = !who.any(held.contains);
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
  m.later('easing', layer: -1, name: 'strength', number: start, word: 'Bezier 0.200 0 0.2 1.000');
  ws.after(m.later('together'), (done, why) {
    if (!done) ws.notice = 'No move made: $why'; // (the step undone as a whole: why, on the top bar)
    ws.reread();
  });
}
