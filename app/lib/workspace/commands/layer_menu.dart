import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/context_menu.dart' show ContextMenuItem;
import 'package:motolii/workspace/commands/keymap.dart' show CommandIntent;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The context menu for layer [l], opened by a right-click on its bar, its row or the stage.
///
/// It follows Ableton Live's clip menu (Rename, Duplicate, Split, Deactivate, Delete) and Figma's right-click on a layer.
/// Each row runs the same command as the menu bar and the keys. The layer is selected first, so the commands act on it.
List<ContextMenuItem> layerContextMenu(BuildContext context, WorkspaceController ws, Layer l) {
  ws.select(l.id);
  void say(String c) => Actions.maybeInvoke(context, CommandIntent(c, false));
  return [
    ContextMenuItem('Rename…', () => say('thing.rename'), keys: '⌘R'),
    ContextMenuItem('Duplicate', () => say('thing.duplicate'), keys: '⌘D'),
    ContextMenuItem('Split', ws.frame > l.inF && ws.frame < l.outF ? () => say('thing.split') : null, keys: '⌘E', why: 'The playhead is not inside it'),
    const ContextMenuItem.rule(),
    ContextMenuItem(l.hidden ? 'Activate' : 'Deactivate', () => say('thing.deactivate'), keys: '0'),
    ContextMenuItem('Delete', () => say('thing.remove'), keys: '⌫'),
  ];
}
