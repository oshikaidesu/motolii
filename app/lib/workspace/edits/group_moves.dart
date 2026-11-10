// Moves of a group behaviour: layers animate in or out together.
//
// A move is defined by:
// - which layers it moves, in order;
// - when it runs: two keyframes on the group's strength, with each layer starting one lag after the previous one;
// - where it goes: the group's own x, y, spread, scatter, size, opacity and rotation are one end, the layers' own
//   positions the other;
// - the easing between the two keyframes.
//
// The move is read from the document and queued on the engine without waiting. The position of a layer at the other
// end is asked of the engine (where it shows at full strength) and is never computed here.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

/// The name of a move on its row: its direction and its layers, for example 'in · TURN IN TIME'.
String wsMoveName(Ws ws, Iterable<String> who, bool coming) {
  final names = [for (final id in who) ws.layers.where((l) => l.id == id).firstOrNull?.name ?? id];
  final all = names.length > 4 ? '${names.take(3).join(' ')} +${names.length - 3}' : names.join(' ');
  return '${coming ? 'in' : 'out'} · $all';
}

/// Makes a move of the layers [who] as one undo step and selects it.
///
/// The layers come in at [start] from a little below, transparent, each a little later than the one before.
/// Layers that already come in through another move go out through this one instead.
/// A move made later in the video leaves the earlier part alone.
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
    if (!done) ws.notice = 'No move made: $why'; // The whole undo step is undone; the top bar shows why.
    ws.reread();
  });
}
