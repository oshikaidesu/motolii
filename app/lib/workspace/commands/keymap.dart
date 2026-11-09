// The window's commands by name and the keys that say them, in VS Code's manner (keybindings.json): the window's own
// table, then the maker's file over it (~/.motolii/keybindings.json, a list of {"key": "cmd+shift+z", "command":
// "edit.redo"}; a command begun with '-' takes that key from the command). Flutter's own Shortcuts and Actions carry
// them; the menus show the same keys. While words are being typed, a key with no cmd, ctrl or alt is the words'.
import 'package:re_editor/re_editor.dart' show CodeEditor;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The window's own keys: Ableton Live 12's (its manual, chapter 42; command_actions.dart says where each comes from)
/// and the standard Mac ones (New, Undo).
final defaultKeys = <(String, String)>[
  ('cmd+n', 'file.new'),
  ('shift+e', 'file.exportFrame'), // (Premiere Pro's Export Frame)
  ('cmd+z', 'edit.undo'),
  ('cmd+shift+z', 'edit.redo'),
  ('a', 'mark.animate'), // (Apple Motion's A: Record Animation, every change keyed, pressed again off)
  ('space', 'play.fromStart'), // (Live 42.20)
  ('shift+space', 'play.continue'), // (Live 42.20)
  for (final (k, c) in [('left', 'nudge.left'), ('right', 'nudge.right'), ('shift+left', 'nudge.left10'), ('shift+right', 'nudge.right10')]) (k, c), // (Live 42.16: nudge selection)
  for (final (k, c) in [('up', 'layer.previous'), ('down', 'layer.next')]) (k, c), // (Live: the arrow keys go between tracks)
  for (final (k, c) in [(',', 'frame.previous'), ('.', 'frame.next')]) (k, c), // (Live has none: Rive's and Jitter's)
  for (final (k, c) in [('j', 'frame.previousStop'), ('k', 'frame.nextStop')]) (k, c), // (After Effects': J and K)
  for (final (k, c) in [('shift+,', 'frame.back10'), ('shift+.', 'frame.forward10')]) (k, c),
  for (final (k, c) in [('home', 'frame.first'), ('end', 'frame.last')]) (k, c), // (Live 42.20: move insert marker to beginning)
];

/// The keys in use: the window's own, the maker's file over them.
class Keymap {
  Keymap(this.pairs);
  final List<(SingleActivator, String)> pairs;

  static Keymap load([String? file]) {
    final all = [
      for (final (k, c) in defaultKeys)
        if (activatorOf(k) case final a?) (a, c),
    ];
    final path = file ?? '${Platform.environment['HOME']}/.motolii/keybindings.json';
    try {
      final told = jsonDecode(File(path).readAsStringSync()) as List;
      for (final e in told.cast<Map>()) {
        final a = activatorOf('${e['key']}'), c = '${e['command']}';
        if (a == null) continue;
        all.removeWhere((p) => _same(p.$1, a)); // (one key, one command: the maker's)
        if (!c.startsWith('-')) all.add((a, c));
      }
    } catch (_) {} // (no file, or not a list: the window's own keys)
    return Keymap(all);
  }

  /// The first key that says a command (the menus show it), if any.
  SingleActivator? keyOf(String command) => pairs.where((p) => p.$2 == command).firstOrNull?.$1;

  static bool _same(SingleActivator a, SingleActivator b) =>
      a.trigger == b.trigger && a.meta == b.meta && a.shift == b.shift && a.control == b.control && a.alt == b.alt;
}

/// A key as written ("cmd+shift+z", "space", "left"...) as Flutter's own activator; null if not one it knows.
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
};

/// A command said by a key.
class CommandIntent extends Intent {
  const CommandIntent(this.name, this.plain);
  final String name;
  final bool plain; // (a key with no cmd, ctrl or alt: the words' while words are typed)
}

/// The keys over the whole window, each saying its command ([commands]: what each does).
class WsKeys extends StatelessWidget {
  const WsKeys({super.key, required this.keymap, required this.commands, required this.child});
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
  // (a field's, or code's: re_editor's CodeEditor takes its keys by its own DeltaTextInputClient, no EditableText under it,
  //  and a plain key the window answers never reaches it)
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
