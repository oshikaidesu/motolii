// Relations between layers selected together (Ws.many).
//
// Making a relation adds a behaviour layer of the chosen kind (the engine's around, row, follow or push) and puts the
// selected layers in it as they look now: their order, the middle and size, a leader, and what each was in before.
// It is one undo step, and the new behaviour is selected once it exists.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/edits/group_moves.dart';
import 'package:motolii/workspace/state/state.dart';

const wsRelations = ['around', 'row', 'follow', 'push', 'group', 'relate'];

/// The relation kinds the user can choose: the kinds the engine knows, then each one written as a file in relations/*.js.
/// The files come from the library and from the user, so a file added there shows up here.
List<String> wsRelationChoices(Ws ws) => [
  for (final k in wsRelations)
    if (k != 'relate') k,
  for (final r in ws.inside?.relations ?? const <(String, String)>[]) r.$2,
];

/// The label of a relation kind in the menu.
String wsRelationWord(String kind) {
  final name = kind == 'group' ? 'Move in' : kind.split('/').last.replaceAll('.js', '');
  return name[0].toUpperCase() + name.substring(1);
}

/// The kind of a relation, or the script file it is written as.
String wsRelationOf(Motolii m, int t) => m.word(t, 'file') == 'relate' ? m.word(t, 'script') : m.word(t, 'file');

/// The selected layers a relation can hold. A relation that is selected with them, as Select All does, is left out.
List<String> wsRelatable(Ws ws) => [
  for (final id in ws.many)
    if (int.tryParse(id) case final t? when ws.inside?.word(t, 'kind') != 'behaviour') id,
];

/// Makes a relation of [kind] from the layers selected together.
void wsRelate(Ws ws, String kind) {
  final m = ws.inside, who = wsRelatable(ws);
  if (m == null || who.length < 2) return;
  if (kind == 'group') {
    return wsMakeMove(ws, who, (ws.frame / Ws.fps * 10).round() / 10); // A group is a move: it comes in at the playhead from where the group says.
  }
  m.later('together', number: 1); // One undo step, queued without waiting; the behaviour is the layer that add creates.
  final file = kind.endsWith('.js');
  // Selected as soon as it exists, which shows its card and its row.
  ws.after(m.later('add', name: 'behaviour', word: file ? 'relate' : kind), null, (b) => ws.select('$b'));
  if (file) {
    m.later('say', layer: -1, name: 'script', word: kind);
    m.later('say', layer: -1, name: 'name', word: wsRelationWord(kind)); // The row and the card show which relation it is.
  }
  m.later('set', layer: -1, name: 'strength', number: 1); // Set explicitly so the card shows it as it works.
  if ((kind == 'follow' || kind == 'push') && ws.manyInOrder) {
    m.later('set', layer: -1, name: 'leader', number: double.parse(who.first)); // The layers were selected one by one, so the first one selected leads.
  }
  m.later('relate', layer: -1, word: who.join(' '));
  ws.after(m.later('together'), (_, _) => ws.reread()); // Whether or not it was made, the app shows what the document holds.
}

/// The layers a relation moves, when the selected layer is a relation; otherwise none.
///
/// A layer counts when any of its properties is connected to the relation. It is read from the app's snapshot of the
/// document, which asks the engine again only after a change.
Set<String> wsMembersOf(Ws ws) {
  final m = ws.inside, sel = int.tryParse(ws.selected ?? '');
  if (m == null || sel == null || m.word(sel, 'kind') != 'behaviour' || !wsRelations.contains(m.word(sel, 'file'))) return const {};
  return {
    for (final w in m.word(sel, 'members').split(' '))
      if (int.tryParse(w) case final t? when m.layers.contains(t)) '$t',
  }; // The relation's own list, in order. A layer it moves through another relation counts too.
}

/// The layers a layer points at, each with its label.
///
/// These are the layers named by its properties (Parent, Leader, Join, Into and so on), and the layers of a relation.
/// Cavalry shows a connection at both ends. Here it shows only at the end that names the target, in the row's own
/// lanes, like the Parent & Link column of After Effects.
List<(String, String)> wsTargets(Ws ws, String id) {
  final m = ws.inside, t = int.tryParse(id);
  if (m == null || t == null) return const [];
  return [
    for (final n in m.values(t))
      if (m.shown(n) case final s? when s.look == 'thing')
        if ((m.value(t, n, 0) ?? 0).round() case final o when m.layers.contains(o)) (s.label, '$o'),
    if (m.word(t, 'kind') == 'behaviour' && wsRelations.contains(m.word(t, 'file')))
      for (final s in m.word(t, 'members').split(' '))
        if (int.tryParse(s) case final o? when m.layers.contains(o)) ('Moves', '$o'),
  ];
}

/// Makes the layer [id] the leader of the selected relation without moving anything. The old leader stays among the relation's layers.
void wsLead(Ws ws, String id) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? ''), t = int.tryParse(id);
  if (m == null || by == null || t == null) return;
  ws.after(m.later('lead', layer: by, number: t.toDouble()), (_, _) => ws.reread());
}

/// Adds [id] to the layers selected together (Shift or Cmd with a click). A layer that was selected alone joins it.
void wsPickAlso(Ws ws, String id) {
  if (ws.many.contains(id)) return ws.pickMany({...ws.many}..remove(id), inOrder: true); // Already selected, so it is removed.
  ws.pickMany({
    ...ws.many,
    if (ws.selected case final s? when !wsMembersOf(ws).contains(s) && ws.many.isEmpty && int.tryParse(s) != null) s,
    id,
  }, inOrder: true);
}

/// Selects the layers from the one selected last to [id], in row order (Shift on a row, as in After Effects).
void wsPickRange(Ws ws, String id) {
  final ids = [for (final l in ws.layers) l.id], from = ws.many.isNotEmpty ? ws.many.last : ws.selected;
  final a = from == null ? -1 : ids.indexOf(from), b = ids.indexOf(id);
  if (a < 0 || b < 0) return wsPickAlso(ws, id);
  ws.pickMany(a <= b ? ids.sublist(a, b + 1) : ids.sublist(b, a + 1).reversed, inOrder: true);
}

/// Takes the layer [id] out of the selected relation, leaving it where it shows now. The other layers stay in.
void wsFree(Ws ws, String id) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? ''), t = int.tryParse(id);
  if (m == null || by == null || t == null) return;
  ws.after(m.later('free', layer: t, number: by.toDouble()), (done, _) => done ? ws.reread() : null);
}

/// Releases the selected relation: each of its layers stays where it shows now and the relation is deleted.
void wsRelease(Ws ws) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? '');
  if (m == null || by == null) return;
  ws.after(m.later('release', layer: by), (done, _) {
    if (!done) return;
    ws.reread();
    ws.select(null);
  });
}

/// The relation that takes effect for the selected layer: the uppermost one whose visibility is on, or null.
String? wsWinner(Ws ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null) return null;
  for (var r = (m.value(t, 'x_by', 0) ?? 0).round(), n = 0; r > 0 && n < 8 && wsRelations.contains(m.word(r, 'file')); n++) {
    if ((m.value(r, 'visible', 0) ?? 1) > .5) return '$r';
    final members = m.word(r, 'members').split(' '), under = m.word(r, 'under').split(' '), at = members.indexOf('$t');
    r = at >= 0 && at < under.length ? int.tryParse(under[at]) ?? 0 : 0;
  }
  return null;
}

/// The relations the selected layer is in, the topmost first: first those it leads, then the chain its position is
/// connected to. They are shown beside the layer, and a click selects one.
List<String> wsRelationsOf(Ws ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null || m.word(t, 'kind') == 'behaviour') return const [];
  final all = <String>[
    for (final r in m.layers) // The relations it leads.
      if (m.word(r, 'kind') == 'behaviour' && wsRelations.contains(m.word(r, 'file')) && (m.value(r, 'leader', 0) ?? 0).round() == t) '$r',
  ];
  for (var r = (m.value(t, 'x_by', 0) ?? 0).round(); r > 0 && all.length < 8 && !all.contains('$r') && wsRelations.contains(m.word(r, 'file'));) {
    if (!all.contains('$r')) all.add('$r');
    final members = m.word(r, 'members').split(' '), under = m.word(r, 'under').split(' '), at = members.indexOf('$t');
    r = at >= 0 && at < under.length ? int.tryParse(under[at]) ?? 0 : 0;
  }
  return all;
}

/// Turns the selected relation on or off by setting its strength to 1 or 0. When it is off, what lies under it shows,
/// like the switch on an expression in After Effects. No layer is released.
void wsSwitch(Ws ws) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? '');
  if (m == null || by == null) return;
  final on = (m.value(by, 'visible', 0) ?? 1) > .5; // Its visibility, as for any row, which holds the strength it had.
  ws.after(m.later('set', layer: by, name: 'visible', number: on ? 0 : 1), (_, _) => ws.reread());
}
