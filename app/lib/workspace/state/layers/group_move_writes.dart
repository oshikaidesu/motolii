// The engine's side of a move in relation (relations/Group.js): which file makes it, which layers already hold one, and the
// writes that make it. The name shown on the row is worked out by the panel and passed in.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The relation file a move is made from (its Group.js), or null when no project is open or it has none.
String? groupRelationFile(WorkspaceController ws) => ws.inside?.relations
    .map((r) => r.$2)
    .where((f) => f.endsWith('Group.js'))
    .firstOrNull;

/// The layers that a move already holds: a layer in one goes out through the next move rather than in.
Set<String> layersHeldByGroups(WorkspaceController ws) {
  final m = ws.inside!;
  return {
    for (final l in ws.layers)
      if (int.tryParse(l.id) case final b?
          when m.word(b, 'kind') == 'behaviour' &&
              m.word(b, 'script').endsWith('Group.js'))
        for (final w in m.word(b, 'members').split(' '))
          if (int.tryParse(w) case final t? when m.layers.contains(t)) '$t',
  };
}

/// Queues a move of the layers [who] in [file] as one undo step, named [name] on its row. It comes in when [coming], else
/// out, at [start]. Returns the ticket that closes the step.
int queueGroupMove(
  WorkspaceController ws,
  String file,
  List<String> who,
  bool coming,
  double start,
  String name,
) {
  final m = ws.inside!;
  groupBegin(ws);
  ws.after(
    m.later('add', name: 'behaviour', word: 'relate'),
    null,
    (b) => ws.select('$b'),
  );
  m.later('say', layer: -1, name: 'script', word: file);
  m.later('set', layer: -1, name: 'strength', number: 1);
  m.later('say', layer: -1, name: 'name', word: name);
  m.later('relate', layer: -1, word: who.join(' '));
  m.later('set', layer: -1, name: 'js_lag', number: .08);
  m.later('set', layer: -1, name: 'js_y', number: -.15);
  m.later('set', layer: -1, name: 'js_opacity', number: 0);
  m.later(
    'key',
    layer: -1,
    name: 'strength',
    word: '$start',
    number: coming ? 1 : 0,
  );
  m.later(
    'key',
    layer: -1,
    name: 'strength',
    word: '${start + .6}',
    number: coming ? 0 : 1,
  );
  m.later(
    'easing',
    layer: -1,
    name: 'strength',
    number: start,
    word: 'Bezier 0.200 0 0.2 1.000',
  );
  return groupEnd(ws);
}
