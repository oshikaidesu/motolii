// Keyboard shortcuts and the commands they run, in the manner of VS Code's keybindings.json.
//
// The app's default table is loaded first, then the user's file ~/.motolii/keybindings.json overrides it.
// That file is a list such as {"key": "cmd+shift+z", "command": "edit.redo"}. A command starting with '-' removes the key from that command.
// Flutter's Shortcuts and Actions carry the keys, and the menus show the same keys.
// While the user is typing text, a key without cmd, ctrl or alt goes to the text field.
import 'package:re_editor/re_editor.dart' show CodeEditor;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The default keys: Ableton Live 12's (manual chapter 42; command_actions.dart says where each comes from),
/// the standard Mac ones (New, Undo, Cut, Copy, Paste, Select All), and the canvas tools.
const defaultKeys = <(String, String)>[
  ('cmd+n', 'file.new'),
  ('cmd+o', 'file.home'), // Lists the projects: the Mac's Open, as Alight Motion's home screen lists its projects.
  ('cmd+shift+r', 'file.render'), // Live 42.3: Export Audio/Video.
  ('shift+e', 'file.exportFrame'), // Premiere Pro's Export Frame.
  ('cmd+z', 'edit.undo'),
  ('cmd+shift+z', 'edit.redo'),
  ('cmd+x', 'edit.cut'),
  ('cmd+c', 'edit.copy'),
  ('cmd+v', 'edit.paste'),
  ('cmd+alt+c', 'edit.copyStyle'), // The Mac's Copy Style, as in Pages, Keynote and TextEdit.
  ('cmd+alt+v', 'edit.pasteStyle'),
  ('cmd+a', 'edit.selectAll'),
  ('cmd+shift+a', 'edit.deselectAll'), // Deselect All, as in After Effects and Premiere Pro.
  ('cmd+alt+b', 'edit.workToPicked'), // After Effects: set the work area to the selected layers, else to the whole project.
  ('cmd+d', 'thing.duplicate'), // Live 42.5.
  ('cmd+g', 'thing.group'), // Group, as in Figma and Keynote.
  ('cmd+shift+g', 'thing.ungroup'),
  ('cmd+]', 'thing.forward'), // Bring Forward and Send Backward, as in After Effects, Figma and Illustrator.
  ('cmd+[', 'thing.backward'),
  ('cmd+e', 'thing.split'), // Live 42.5: Split.
  ('[', 'time.playhead'), // After Effects: move the layer's in point, or its out point for ], to the current time.
  (']', 'time.playhead_end'),
  ('alt+[', 'time.extend'), // Final Cut Pro: Trim Start and Trim End.
  ('alt+]', 'time.trim_end'),
  ('cmd+r', 'thing.rename'), // Live 42.5 and 42.19.
  ('0', 'thing.deactivate'), // Live 42.15, 42.16 and 42.19: 0 switches a clip off and on. Here it toggles the layer's visibility.
  ('s', 'thing.solo'), // Live 42.15 and 42.19.
  ('u', 'thing.lanes'), // After Effects' U: show the keyframed properties of the selected layers.
  ('a', 'mark.animate'), // Apple Motion's A (Record Animation): every change is keyframed until it is pressed again.
  ('backspace', 'thing.remove'),
  ('delete', 'thing.remove'),
  ('space', 'play.fromStart'), // Live 42.20.
  ('shift+space', 'play.continue'), // Live 42.20.
  ('left', 'nudge.left'), // Live 42.16: nudge selection.
  ('right', 'nudge.right'),
  ('shift+left', 'nudge.left10'),
  ('shift+right', 'nudge.right10'),
  ('up', 'layer.previous'), // Live: the arrow keys move between tracks.
  ('down', 'layer.next'),
  ('cmd+l', 'loop.toggle'), // Live 42.16.
  ('=', 'zoom.in'), // Live 42.9: + and -, with + working without shift.
  ('shift+=', 'zoom.in'),
  ('-', 'zoom.out'),
  ('z', 'zoom.selection'), // Live 42.16.
  ('x', 'zoom.back'),
  ('w', 'zoom.width'),
  (',', 'frame.previous'), // Live has no frame step. These are the Rive and Jitter keys.
  ('.', 'frame.next'),
  ('j', 'frame.previousStop'), // After Effects' J and K: the previous and next visible item in the time ruler.
  ('k', 'frame.nextStop'),
  ('shift+,', 'frame.back10'),
  ('shift+.', 'frame.forward10'),
  ('home', 'frame.first'), // Live 42.20: move the insert marker to the beginning.
  ('end', 'frame.last'),
  // The canvas tools, with the letters stage.dart lists, as in After Effects and Photoshop.
  ('v', 'tool.select'),
  ('m', 'tool.move'),
  ('r', 'tool.rectangle'),
  ('e', 'tool.ellipse'),
  ('p', 'tool.pen'),
  ('t', 'tool.text'),
  ('b', 'tool.brush'),
  ('c', 'tool.camera'),
];

/// The keys in use: the defaults with the user's keybindings.json applied over them.
class Keymap {
  Keymap(this.pairs);
  final List<(SingleActivator, String)> pairs;

  static Keymap load() {
    final all = [
      for (final (k, c) in defaultKeys)
        if (activatorOf(k) case final a?) (a, c),
    ];
    final path = '${Platform.environment['HOME']}/.motolii/keybindings.json';
    try {
      final told = jsonDecode(File(path).readAsStringSync()) as List;
      for (final e in told.cast<Map>()) {
        final a = activatorOf('${e['key']}'), c = '${e['command']}';
        if (a == null) continue;
        // One key runs one command, and the user's file wins.
        all.removeWhere((p) => _same(p.$1, a));
        if (!c.startsWith('-')) all.add((a, c));
      }
    } catch (_) {} // No file, or not a list: keep the default keys.
    return Keymap(all);
  }

  /// The first key bound to [command], or null. The menus show it.
  SingleActivator? keyOf(String command) => pairs.where((p) => p.$2 == command).firstOrNull?.$1;

  static bool _same(SingleActivator a, SingleActivator b) =>
      a.trigger == b.trigger && a.meta == b.meta && a.shift == b.shift && a.control == b.control && a.alt == b.alt;
}

/// Parses a key written as "cmd+shift+z", "space" or "left" into a [SingleActivator]; null if the key is unknown.
SingleActivator? activatorOf(String said) {
  final parts = said.toLowerCase().split('+').map((p) => p.trim()).toList();
  final key = _keys[parts.last] ?? (parts.last.length == 1 ? LogicalKeyboardKey.findKeyByKeyId(parts.last.codeUnitAt(0)) : null);
  if (key == null) return null;
  final mods = parts.sublist(0, parts.length - 1).toSet();
  return SingleActivator(
    key,
    meta: mods.contains('cmd') || mods.contains('meta'),
    shift: mods.contains('shift'),
    control: mods.contains('ctrl') || mods.contains('control'),
    alt: mods.contains('alt') || mods.contains('option'),
  );
}

const _keys = {
  'space': LogicalKeyboardKey.space,
  'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
  'up': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'home': LogicalKeyboardKey.home,
  'end': LogicalKeyboardKey.end,
  'pageup': LogicalKeyboardKey.pageUp,
  'pagedown': LogicalKeyboardKey.pageDown,
  'backspace': LogicalKeyboardKey.backspace,
  'delete': LogicalKeyboardKey.delete,
  'enter': LogicalKeyboardKey.enter,
  'escape': LogicalKeyboardKey.escape,
  'tab': LogicalKeyboardKey.tab,
  'f1': LogicalKeyboardKey.f1,
  'f2': LogicalKeyboardKey.f2,
  'f3': LogicalKeyboardKey.f3,
  'f4': LogicalKeyboardKey.f4,
  'f5': LogicalKeyboardKey.f5,
  'f6': LogicalKeyboardKey.f6,
  'f7': LogicalKeyboardKey.f7,
  'f8': LogicalKeyboardKey.f8,
  'f9': LogicalKeyboardKey.f9,
  'f10': LogicalKeyboardKey.f10,
  'f11': LogicalKeyboardKey.f11,
  'f12': LogicalKeyboardKey.f12,
};

/// An intent to run the command called [name], produced by a key.
class CommandIntent extends Intent {
  const CommandIntent(this.name, this.plain);
  final String name;

  /// True for a key with no cmd, ctrl or alt, which belongs to the text field while the user is typing.
  final bool plain;
}

/// Installs the shortcuts of [keymap] over [child]. [commands] maps each command name to what it does.
class KeymapShortcuts extends StatelessWidget {
  const KeymapShortcuts({super.key, required this.keymap, required this.commands, required this.child});
  final Keymap keymap;
  final Map<String, VoidCallback> commands;
  final Widget child;
  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: {for (final (a, c) in keymap.pairs) a: CommandIntent(c, !a.meta && !a.control && !a.alt)},
    child: Actions(actions: {CommandIntent: _Command(commands)}, child: child),
  );
}

class _Command extends Action<CommandIntent> {
  _Command(this.commands);
  final Map<String, VoidCallback> commands;
  // True while focus is in a text field or a code editor.
  // re_editor's CodeEditor reads keys through its own DeltaTextInputClient with no EditableText under it,
  // so a plain key that the workspace handles would never reach it.
  static bool get _typing {
    final at = FocusManager.instance.primaryFocus?.context;
    return at?.findAncestorStateOfType<EditableTextState>() != null || at?.findAncestorWidgetOfExactType<CodeEditor>() != null;
  }

  @override
  bool isEnabled(CommandIntent intent) => commands.containsKey(intent.name) && !(intent.plain && _typing);
  @override
  Object? invoke(CommandIntent intent) {
    commands[intent.name]?.call();
    return null;
  }
}
