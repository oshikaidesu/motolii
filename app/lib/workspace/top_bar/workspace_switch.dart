// The top bar's workspaces, as After Effects' workspace bar and Blender's workspace tabs: one press puts the panes
// in the arrangement for a kind of work (workspaces, workspace_panes.dart); the window keeps what was made of each.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Segmented;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/workspace_panes.dart' show workspaces;

class WorkspaceSwitch extends StatelessWidget {
  const WorkspaceSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.view});
    final names = workspaces.keys.toList();
    final now = ws.viewOf('workspace', names.first);
    return SizedBox(
      width: Shape.z(72) * names.length,
      child: Segmented(
        items: names,
        index: names.indexOf(now),
        onChanged: (i) => ws.setView('workspace', names[i]),
      ),
    );
  }
}
