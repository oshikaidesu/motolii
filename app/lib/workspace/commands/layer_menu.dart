import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/menu.dart' show WsMenuItem;
import 'package:motolii/workspace/commands/keymap.dart' show CommandIntent;
import 'package:motolii/workspace/state/state.dart';

/// The context menu for layer [l], opened by a right-click on its bar, its row or the stage.
///
/// It follows Ableton Live's clip menu (Rename, Duplicate, Split, Deactivate, Delete) and Figma's right-click on a layer.
/// Each row runs the same command as the menu bar and the keys. The layer is selected first, so the commands act on it.
List<WsMenuItem> wsThingMenu(BuildContext context, Ws ws, WsLayer l) {
  ws.select(l.id);
  void say(String c) => Actions.maybeInvoke(context, CommandIntent(c, false));
  return [
    WsMenuItem('Rename…', () => say('thing.rename'), keys: '⌘R'),
    WsMenuItem('Duplicate', () => say('thing.duplicate'), keys: '⌘D'),
    WsMenuItem('Split', ws.frame > l.inF && ws.frame < l.outF ? () => say('thing.split') : null, keys: '⌘E', why: 'The playhead is not inside it'),
    const WsMenuItem.rule(),
    WsMenuItem(l.hidden ? 'Activate' : 'Deactivate', () => say('thing.deactivate'), keys: '0'),
    WsMenuItem('Delete', () => say('thing.remove'), keys: '⌫'),
  ];
}
