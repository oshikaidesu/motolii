import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/commands/keymap.dart' show keyLabel;
import 'package:motolii/workspace/workspace.dart' show WorkspaceState;

/// The key now bound to [command], as the menus and tooltips write it (⌘Z on the Mac, Ctrl+Z elsewhere). Empty when none.
String keysOf(BuildContext context, String command) => keyLabel(
  context.findAncestorStateOfType<WorkspaceState>()?.keymap.keyOf(command),
);
