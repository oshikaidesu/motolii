// Relations between layers selected together (WorkspaceController.many).
//
// Making a relation adds a behaviour layer written as a file in relations/*.js and puts the selected layers in it as
// they look now: their order, and what each was in before. A file that has a Leader makes the first layer selected its
// leader, when the layers were selected one by one.
// It is one undo step, and the new behaviour is selected once it exists.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/widgets/picks.dart';
import 'package:motolii/workspace/edits/group_moves.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The label of a relation file, as its row and card are named.
String relationLabel(String kind) {
  final name = kind.endsWith('Group.js')
      ? 'Move in'
      : kind.split('/').last.replaceAll('.js', '');
  return name[0].toUpperCase() + name.substring(1);
}

/// The layer a relation leads from: the layer its Leader names, or 0 for none.
int relationLeader(Motolii m, int t) =>
    (m.value(t, 'js_leader', 0) ?? 0).round();

/// The kind of a relation, or the script file it is written as.
String relationKindOf(Motolii m, int t) =>
    m.word(t, 'file') == 'relate' ? m.word(t, 'script') : m.word(t, 'file');

/// The selected layers a relation can hold. A relation that is selected with them, as Select All does, is left out.
List<String> relatableLayers(WorkspaceController ws) => [
  for (final id in ws.many)
    if (int.tryParse(id) case final t?
        when ws.inside?.word(t, 'kind') != 'behaviour')
      id,
];

/// The layers an expression goes on as a row: the layers selected together, or the layers in the picked group.
///
/// Fewer than two means none: the expression goes on the picked layer, as a card of its own.
List<String> expressionRow(WorkspaceController ws) {
  final m = ws.inside, picked = int.tryParse(ws.selected ?? '');
  if (relatableLayers(ws) case final many when many.length >= 2) return many;
  if (m == null || picked == null || m.word(picked, 'shape') != 'null') {
    return const [];
  }
  final inside = [
    for (final t in m.layers)
      if (m.parentOf(t) == picked) '$t',
  ];
  return inside.length >= 2 ? inside : const [];
}

/// Makes a relation of [kind] from the layers selected together, or from [of] when given.
///
/// [kind] is a file in relations/*.js, or any file with each(i, n, t, k): layer i of the row is then copy i of n.
void makeRelation(WorkspaceController ws, String kind, {List<String>? of}) {
  final m = ws.inside,
      who = of ?? relatableLayers(ws),
      ordered = of == null && ws.manyInOrder;
  if (m == null || who.length < 2) return;
  if (kind.endsWith('Group.js')) {
    return makeGroupMove(
      ws,
      who,
      (ws.frame / WorkspaceController.fps * 10).round() / 10,
    ); // A group is a move: it comes in at the playhead from where the group says.
  }
  m.later('together', number: 1); // One undo step, queued without waiting; the behaviour is the layer that add creates.
  int? made;
  // Selected as soon as it exists, which shows its card and its row.
  ws.after(m.later('add', name: 'behaviour', word: 'relate'), null, (b) {
    made = b;
    ws.select('$b');
  });
  m.later('say', layer: -1, name: 'script', word: kind);
  m.later(
    'say',
    layer: -1,
    name: 'name',
    word: relationLabel(kind),
  ); // The row and the card show which relation it is.
  m.later(
    'set',
    layer: -1,
    name: 'strength',
    number: 1,
  ); // Set explicitly so the card shows it as it works.
  m.later('relate', layer: -1, word: who.join(' '));
  ws.after(m.later('together'), (_, _) {
    ws.reread(); // Whether or not it was made, the app shows what the document holds.
    // The layers were selected one by one, so the first one selected leads, if the file has a leader.
    final b = made;
    if (ordered &&
        b != null &&
        ws.inside?.values(b).contains('js_leader') == true) {
      ws.after(
        m.later('lead', layer: b, number: double.parse(who.first)),
        (_, _) => ws.reread(),
      );
    }
  });
}

/// The layers a relation moves, when the selected layer is a relation; otherwise none.
///
/// A layer counts when any of its properties is connected to the relation. It is read from the app's snapshot of the
/// document, which asks the engine again only after a change.
Set<String> relationMembers(WorkspaceController ws) {
  final m = ws.inside, sel = int.tryParse(ws.selected ?? '');
  if (m == null ||
      sel == null ||
      m.word(sel, 'kind') != 'behaviour' ||
      !relationKinds.contains(m.word(sel, 'file'))) {
    return const {};
  }
  return {
    for (final w in m.word(sel, 'members').split(' '))
      if (int.tryParse(w) case final t? when m.layers.contains(t)) '$t',
  }; // The relation's own list, in order. A layer it moves through another relation counts too.
}

/// What a click on layer [id] does to the layers selected together, by the one rule of every selection (picks.dart):
/// a plain click selects it alone, Command (Ctrl) adds or removes it, Shift takes the rows from the last one picked to it.
/// [order] is the rows in reading order; leave it empty where there are no rows (the stage), and Shift adds like Command.
/// A layer that was selected alone joins what is picked.
void clickLayer(
  WorkspaceController ws,
  String id, {
  List<String> order = const [],
}) {
  final (:add, :span) = clickKeys();
  if (!add && !span) return ws.select(id);
  final alone = ws.selected;
  final now = ws.many.isNotEmpty
      ? {...ws.many}
      : {
          if (alone != null &&
              !relationMembers(ws).contains(alone) &&
              int.tryParse(alone) != null)
            alone,
        };
  final r = pickOnClick(
    now: now,
    lead: ws.selection.lead ?? (ws.many.isNotEmpty ? ws.many.last : alone),
    id: id,
    order: order,
    add: add,
    span: span,
  );
  ws.pickMany(r.picked, inOrder: true, lead: r.lead);
}

/// The relation that lies under relation [r] for layer [t]: the one [t] is under in it, or 0 when there is none.
int _below(Motolii m, int r, int t) {
  final members = m.word(r, 'members').split(' '),
      under = m.word(r, 'under').split(' '),
      at = members.indexOf('$t');
  return at >= 0 && at < under.length ? int.tryParse(under[at]) ?? 0 : 0;
}

/// The relation that takes effect for the selected layer: the uppermost one whose visibility is on, or null.
String? relationInEffect(WorkspaceController ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null) return null;
  for (
    var r = (m.value(t, 'x_by', 0) ?? 0).round(), n = 0;
    r > 0 && n < 8 && relationKinds.contains(m.word(r, 'file'));
    n++
  ) {
    if ((m.value(r, 'visible', 0) ?? 1) > .5) return '$r';
    r = _below(m, r, t);
  }
  return null;
}

/// The relations the selected layer is in, the topmost first: first those it leads, then the chain its position is
/// connected to. They are shown beside the layer, and a click selects one.
List<String> relationsOfSelected(WorkspaceController ws) {
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null || m.word(t, 'kind') == 'behaviour') {
    return const [];
  }
  final all = <String>[
    for (final r in m.layers) // The relations it leads.
      if (m.word(r, 'kind') == 'behaviour' &&
          relationKinds.contains(m.word(r, 'file')) &&
          relationLeader(m, r) == t)
        '$r',
  ];
  for (
    var r = (m.value(t, 'x_by', 0) ?? 0).round();
    r > 0 &&
        all.length < 8 &&
        !all.contains('$r') &&
        relationKinds.contains(m.word(r, 'file'));
  ) {
    if (!all.contains('$r')) all.add('$r');
    r = _below(m, r, t);
  }
  return all;
}
