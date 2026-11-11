// The relations the selected layer belongs to, at the top of its inspector.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The relations the selected layer belongs to, at the top of its inspector, the one in effect first (as Blender stacks constraints).
/// Each row shows an on/off dot, the relation's kind and its leader, and an x that removes the layer from the relation.
/// Clicking a row selects that relation.
class RelationStack extends StatelessWidget {
  const RelationStack({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WorkspaceScope.read(context).on[WorkspaceAspect.document],
      WorkspaceScope.read(context).on[WorkspaceAspect.picked],
    ]),
    builder: (context, _) => _built(context),
  ); // Listens on its own so the inspector is not rebuilt when a value of another layer changes.

  Widget _built(BuildContext context) {
    final ws = WorkspaceScope.read(context), m = ws.inside, t = ws.selected;
    if (m == null || t == null) return const SizedBox.shrink();
    final rels = relationsOfSelected(ws), top = relationInEffect(ws);
    if (rels.isEmpty) return const SizedBox.shrink();
    String nameOf(int i) =>
        '${ws.layers.indexWhere((l) => l.id == '$i') + 1}. ${ws.layers.where((l) => l.id == '$i').firstOrNull?.name ?? ''}';
    return Container(
      key: const ValueKey('ws-relation-stack'),
      padding: EdgeInsets.fromLTRB(
        Shape.s(10),
        Shape.s(8),
        Shape.s(10),
        Shape.s(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rels)
            () {
              final id = int.parse(r),
                  kind = relationLabel(relationKindOf(m, id)),
                  on = (m.value(id, 'visible', 0) ?? 1) > .5;
              final lead = relationLeader(m, id), leads = '$lead' == t;
              final ink = r == top ? Grey.g95 : Grey.g56;
              return Pressable(
                key: ValueKey('ws-stack-$r'),
                cursor: SystemMouseCursors.basic,
                onTap: () => ws.select(r),
                builder: (_, _) => Padding(
                  padding: EdgeInsets.symmetric(vertical: Shape.s(3)),
                  child: Row(
                    children: [
                      Container(
                        width: Shape.z(6),
                        height: Shape.z(6),
                        decoration: BoxDecoration(
                          color: on ? ink : null,
                          border: Border.all(color: ink),
                          shape: BoxShape.circle,
                        ),
                      ), // Filled when the relation is switched on. Its eye is on the relation's own row and bar.
                      SizedBox(width: Shape.s(8)),
                      Text(kind, style: TextStyles.label(ink)),
                      SizedBox(width: Shape.s(8)),
                      Expanded(
                        child: Text(
                          leads
                              ? 'leads it'
                              : lead > 0
                              ? nameOf(lead)
                              : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.label(Grey.g56),
                        ),
                      ),
                      if (!leads)
                        Pressable(
                          key: ValueKey('ws-stack-free-$r'),
                          cursor: SystemMouseCursors.basic,
                          onTap: () => ws.after(
                            m.later(
                              'free',
                              layer: int.parse(t),
                              number: id.toDouble(),
                            ),
                            (_, _) => ws.reread(),
                          ),
                          builder: (_, _) =>
                              Text('×', style: TextStyles.label(Grey.g56)),
                        ),
                    ],
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}
