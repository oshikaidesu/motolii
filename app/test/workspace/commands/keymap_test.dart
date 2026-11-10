// activatorOf and Keymap: a key as the keybindings file writes it ("cmd+shift+z"), and the key a menu shows for a
// command. The expected values are what the code gave when this was written, so a move that changes one fails here.
// Needs no engine. Keymap.load reads the maker's own ~/.motolii/keybindings.json and is not tested here.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/commands/keymap.dart';

/// The key and its cmd, shift, ctrl and alt, in that order.
(LogicalKeyboardKey, bool, bool, bool, bool)? _read(String said) => switch (activatorOf(said)) {
  final a? => (a.trigger, a.meta, a.shift, a.control, a.alt),
  null => null,
};

void main() {
  test('a key is its modifiers, then the key, joined by +', () {
    expect(_read('cmd+shift+z'), (LogicalKeyboardKey.keyZ, true, true, false, false));
    expect(_read('ctrl+alt+f5'), (LogicalKeyboardKey.f5, false, false, true, true));
    expect(_read('z'), (LogicalKeyboardKey.keyZ, false, false, false, false));
  });

  test('capitals and spaces do not matter, and each modifier has a second name', () {
    expect(_read(' Cmd + Shift + Z '), _read('cmd+shift+z'));
    expect(_read('meta+control+option+a'), (LogicalKeyboardKey.keyA, true, false, true, true));
  });

  test('a key is a word (space, left, backspace) or the one character it types', () {
    expect(_read('space')?.$1, LogicalKeyboardKey.space);
    expect(_read('left')?.$1, LogicalKeyboardKey.arrowLeft);
    expect(_read('backspace')?.$1, LogicalKeyboardKey.backspace);
    expect(_read('[')?.$1, LogicalKeyboardKey.bracketLeft);
    expect(_read(',')?.$1, LogicalKeyboardKey.comma);
    expect(_read('0')?.$1, LogicalKeyboardKey.digit0);
  });

  test('an unknown key is null', () {
    expect(activatorOf('cmd+nonsense'), isNull);
    expect(activatorOf(''), isNull);
  });

  test('every default key can be read', () {
    for (final (key, command) in defaultKeys) {
      expect(activatorOf(key), isNotNull, reason: '$key ($command)');
    }
  });

  test('keyOf gives the first key bound to a command, or null', () {
    final back = activatorOf('backspace')!;
    final keys = Keymap([(activatorOf('cmd+z')!, 'edit.undo'), (back, 'thing.remove'), (activatorOf('delete')!, 'thing.remove')]);
    expect(keys.keyOf('thing.remove'), same(back));
    expect(keys.keyOf('no.such.command'), isNull);
  });
}
