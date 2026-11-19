// The menu bar's list (workspace/commands/menu_shown.dart): what it shows is told apart from the actions behind
// it, so the list can stay with the platform while the actions are made again. The expected values follow the
// contract written there.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/commands/menu_shown.dart';

void main() {
  List<PlatformMenuItem> menus({
    String undo = 'Undo',
    VoidCallback? onUndo,
    VoidCallback? onOpen,
    bool openAllowed = true,
    LogicalKeyboardKey key = LogicalKeyboardKey.keyZ,
  }) => [
    PlatformMenu(
      label: 'File',
      menus: [
        PlatformMenu(
          label: 'Open',
          menus: [
            PlatformMenuItem(
              label: 'a.motolii',
              onSelected: openAllowed ? (onOpen ?? () {}) : null,
            ),
          ],
        ),
      ],
    ),
    PlatformMenu(
      label: 'Edit',
      menus: [
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: undo,
              shortcut: SingleActivator(key, meta: true),
              onSelected: onUndo ?? () {},
            ),
          ],
        ),
      ],
    ),
  ];

  group('menusShown', () {
    test('the same menus made again show the same', () {
      expect(menusShown(menus()), menusShown(menus()));
    });

    test('a label, a shortcut, or whether an item can be chosen is seen', () {
      final shown = menusShown(menus());
      expect(menusShown(menus(undo: 'Undo: Opacity')), isNot(shown));
      expect(menusShown(menus(key: LogicalKeyboardKey.keyY)), isNot(shown));
      expect(menusShown(menus(openAllowed: false)), isNot(shown));
    });

    test('how they nest is seen', () {
      final item = PlatformMenuItem(label: 'Solo', onSelected: () {});
      expect(
        menusShown([
          PlatformMenu(label: 'Edit', menus: [item]),
        ]),
        isNot(
          menusShown([
            PlatformMenu(
              label: 'Edit',
              menus: [
                PlatformMenuItemGroup(members: [item]),
              ],
            ),
          ]),
        ),
      );
    });
  });

  group('menusCalling', () {
    PlatformMenuItem undoOf(List<PlatformMenuItem> all) =>
        ((all[1] as PlatformMenu).menus[0] as PlatformMenuItemGroup).members[0];
    PlatformMenuItem openOf(List<PlatformMenuItem> all) =>
        ((all[0] as PlatformMenu).menus[0] as PlatformMenu).menus[0];

    test('shows what the menus it was made from show', () {
      final made = menus();
      expect(menusShown(menusCalling(made, () => made)), menusShown(made));
    });

    test('an item chosen runs the action made last, at its place', () {
      final ran = <String>[];
      var now = menus(
        onUndo: () => ran.add('first undo'),
        onOpen: () => ran.add('first open'),
      );
      final handed = menusCalling(now, () => now);
      undoOf(handed).onSelected!();
      now = menus(
        onUndo: () => ran.add('second undo'),
        onOpen: () => ran.add('second open'),
      );
      undoOf(handed).onSelected!();
      openOf(handed).onSelected!();
      expect(ran, ['first undo', 'second undo', 'second open']);
    });

    test('an item that cannot be chosen stays so', () {
      final made = menus(openAllowed: false);
      expect(openOf(menusCalling(made, () => made)).onSelected, isNull);
    });

    test('an action that is gone by the time it is chosen does nothing', () {
      var now = menus();
      final handed = menusCalling(now, () => now);
      now = const [];
      expect(() => undoOf(handed).onSelected!(), returnsNormally);
    });
  });
}
