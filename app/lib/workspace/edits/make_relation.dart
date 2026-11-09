// Joined: a relation made of the things picked together (Ws.many): a behaviour of that kind (the inside's around, row,
// follow or push) and the things put in it as they show now (the inside's relate: their order, its middle and size,
// a leader, what each was in before), one step, picked once made.
import '../../bridge/motolii.dart';
import 'group_moves.dart';
import '../state/state.dart';

const wsRelations = ['around', 'row', 'follow', 'push', 'group', 'relate'];

/// What can be pressed to make a relation: the kinds the inside knows, then each one written as a file (relations/*.js,
/// the library's and the maker's: what is put there shows here).
List<String> wsRelationChoices(Ws ws) => [
  for (final k in wsRelations)
    if (k != 'relate') k,
  for (final r in ws.inside?.relations ?? const <(String, String)>[]) r.$2,
];

/// What a relation's kind is called where it is pressed.
String wsRelationWord(String kind) {
  final name = kind == 'group' ? 'Move in' : kind.split('/').last.replaceAll('.js', '');
  return name[0].toUpperCase() + name.substring(1);
}

/// A relation's kind, or the file it is written as.
String wsRelationOf(Motolii m, int t) => m.word(t, 'file') == 'relate' ? m.word(t, 'script') : m.word(t, 'file');

/// What is picked together that a relation can hold: a relation picked with them (Select All takes it too) stays out.
List<String> wsRelatable(Ws ws) => [
  for (final id in ws.many)
    if (int.tryParse(id) case final t? when ws.inside?.word(t, 'kind') != 'behaviour') id,
];

void wsRelate(Ws ws, String kind) {
  final m = ws.inside, who = wsRelatable(ws);
  if (m == null || who.length < 2) return;
  if (kind == 'group') {
    return wsMakeMove(ws, who, (ws.frame / Ws.fps * 10).round() / 10); // (a group is a move: it comes in from where it is said to, at the playhead)
  }
  m.later('together', number: 1); // (one step, asked without waiting: the behaviour is the thing the add makes)
  final file = kind.endsWith('.js');
  ws.after(m.later('add', name: 'behaviour', word: file ? 'relate' : kind), null, (b) => ws.select('$b')); // (picked as soon as it is there: its card, its row)
  if (file) {
    m.later('say', thing: -1, name: 'script', word: kind);
    m.later('say', thing: -1, name: 'name', word: wsRelationWord(kind)); // (its row and its card say which it is)
  }
  m.later('set', thing: -1, name: 'strength', number: 1); // (said, so its card shows it as it works)
  if ((kind == 'follow' || kind == 'push') && ws.manyInOrder) {
    m.later('set', thing: -1, name: 'leader', number: double.parse(who.first)); // (picked one by one: the first leads, as it was picked first)
  }
  m.later('relate', thing: -1, word: who.join(' '));
  ws.after(m.later('together'), (_, _) => ws.reread()); // (made or not, the window shows what the document is)
}

/// The things a relation moves (any of their values connected to it), when the picked thing is a relation; else none.
/// (Read through the window's copy of the document: asked of the inside again only once it has changed.)
Set<String> wsMembersOf(Ws ws) {
  final m = ws.inside, sel = int.tryParse(ws.selected ?? '');
  if (m == null || sel == null || m.word(sel, 'kind') != 'behaviour' || !wsRelations.contains(m.word(sel, 'file'))) return const {};
  return {
    for (final w in m.word(sel, 'members').split(' '))
      if (int.tryParse(w) case final t? when m.things.contains(t)) '$t',
  }; // (its own list, in its order: one it moves through another relation counted too)
}

/// What a thing aims at: each value of it that names another thing (Parent, Leader, Join, Into...), and a relation's
/// things, with what it is called there. A number's connection in Cavalry shows at both its ends; here at the end that
/// says it, in the row's own lanes (After Effects' Parent & Link column, a row's parent named on the timeline).
List<(String, String)> wsTargets(Ws ws, String id) {
  final m = ws.inside, t = int.tryParse(id);
  if (m == null || t == null) return const [];
  return [
    for (final n in m.values(t))
      if (m.shown(n) case final s? when s.look == 'thing')
        if ((m.value(t, n, 0) ?? 0).round() case final o when m.things.contains(o)) (s.label, '$o'),
    if (m.word(t, 'kind') == 'behaviour' && wsRelations.contains(m.word(t, 'file')))
      for (final s in m.word(t, 'members').split(' '))
        if (int.tryParse(s) case final o? when m.things.contains(o)) ('Moves', '$o'),
  ];
}

/// Joined: the picked relation led by another thing, nothing moving (the old leader among its things).
void wsLead(Ws ws, String id) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? ''), t = int.tryParse(id);
  if (m == null || by == null || t == null) return;
  ws.after(m.later('lead', thing: by, number: t.toDouble()), (_, _) => ws.reread());
}

/// A thing added to those picked together (Shift or Cmd with a click): the one picked alone goes in with it.
void wsPickAlso(Ws ws, String id) {
  if (ws.many.contains(id)) return ws.pickMany({...ws.many}..remove(id), inOrder: true); // (picked already: one less)
  ws.pickMany({
    ...ws.many,
    if (ws.selected case final s? when !wsMembersOf(ws).contains(s) && ws.many.isEmpty && int.tryParse(s) != null) s,
    id,
  }, inOrder: true);
}

/// Things picked from the one picked last to [id], as their rows lie (Shift on a row, After Effects' manner).
void wsPickRange(Ws ws, String id) {
  final ids = [for (final l in ws.layers) l.id], from = ws.many.isNotEmpty ? ws.many.last : ws.selected;
  final a = from == null ? -1 : ids.indexOf(from), b = ids.indexOf(id);
  if (a < 0 || b < 0) return wsPickAlso(ws, id);
  ws.pickMany(a <= b ? ids.sublist(a, b + 1) : ids.sublist(b, a + 1).reversed, inOrder: true);
}

/// One thing out of the picked relation, where it shows now (the others stay where they are).
void wsFree(Ws ws, String id) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? ''), t = int.tryParse(id);
  if (m == null || by == null || t == null) return;
  ws.after(m.later('free', thing: t, number: by.toDouble()), (done, _) => done ? ws.reread() : null);
}

/// The picked relation let go: each of its things where it shows now, the relation gone.
void wsRelease(Ws ws) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? '');
  if (m == null || by == null) return;
  ws.after(m.later('release', thing: by), (done, _) {
    if (!done) return;
    ws.reread();
    ws.select(null);
  });
}

/// The relations the picked thing is in, the one on top first (what its place is connected to, then what each starts
/// from for it): shown beside it, a touch picks one.
/// Of the relations the picked thing is in, the one that shows: the uppermost whose eye is open (null: none).
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

List<String> wsRelationsOf(Ws ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null || m.word(t, 'kind') == 'behaviour') return const [];
  final all = <String>[
    for (final r in m.things) // (those it leads)
      if (m.word(r, 'kind') == 'behaviour' && wsRelations.contains(m.word(r, 'file')) && (m.value(r, 'leader', 0) ?? 0).round() == t) '$r',
  ];
  for (var r = (m.value(t, 'x_by', 0) ?? 0).round(); r > 0 && all.length < 8 && !all.contains('$r') && wsRelations.contains(m.word(r, 'file'));) {
    if (!all.contains('$r')) all.add('$r');
    final members = m.word(r, 'members').split(' '), under = m.word(r, 'under').split(' '), at = members.indexOf('$t');
    r = at >= 0 && at < under.length ? int.tryParse(under[at]) ?? 0 : 0;
  }
  return all;
}

/// Joined: the picked relation on or off (its strength 1 or 0): off, what it is on top of shows (After Effects' switch on
/// an expression); nothing is let go.
void wsSwitch(Ws ws) {
  final m = ws.inside, by = int.tryParse(ws.selected ?? '');
  if (m == null || by == null) return;
  final on = (m.value(by, 'visible', 0) ?? 1) > .5; // (its eye, as a row's: its strength as it was)
  ws.after(m.later('set', thing: by, name: 'visible', number: on ? 0 : 1), (_, _) => ws.reread());
}
