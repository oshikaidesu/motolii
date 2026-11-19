// The menu bar is handed the same list for as long as what it shows is the same: each new list has macOS build its
// whole menu bar again, on the thread the window draws on.
import 'package:flutter/widgets.dart';

/// What a menu bar shows of [menus]: how they nest, their labels and shortcuts, and which can be chosen.
String menusShown(List<PlatformMenuItem> menus) {
  final said = StringBuffer();
  void say(PlatformMenuItem item) {
    switch (item) {
      case PlatformMenu(:final label, :final menus):
        said.write('[$label');
        menus.forEach(say);
        said.write(']');
      case PlatformMenuItemGroup(:final members):
        said.write('(');
        members.forEach(say);
        said.write(')');
      case PlatformProvidedMenuItem(:final type, :final enabled):
        said.write('<${type.name} $enabled>');
      default:
        // A shortcut's own text names the object, not its keys: the form the platform is sent does.
        said.write(
          '{${item.label}|${item.shortcut?.serializeForMenu().toChannelRepresentation()}'
          '|${item.onSelected != null}|${item.onSelectedIntent}}',
        );
    }
  }

  menus.forEach(say);
  return said.toString();
}

/// [menus] with each action replaced by one that, when chosen, runs whatever [now] holds at the same place.
///
/// The list can then stay with the menu bar while the actions behind it are made again.
List<PlatformMenuItem> menusCalling(
  List<PlatformMenuItem> menus,
  List<PlatformMenuItem> Function() now,
) {
  PlatformMenuItem? at(List<int> path) {
    var items = now();
    PlatformMenuItem? item;
    for (final i in path) {
      if (i >= items.length) return null;
      item = items[i];
      items = switch (item) {
        PlatformMenu(:final menus) => menus,
        PlatformMenuItemGroup(:final members) => members,
        _ => const [],
      };
    }
    return item;
  }

  List<PlatformMenuItem> calling(
    List<PlatformMenuItem> items,
    List<int> path,
  ) => [
    for (final (i, item) in items.indexed)
      switch (item) {
        PlatformMenu(:final label, :final menus) => PlatformMenu(
          label: label,
          onOpen: item.onOpen,
          onClose: item.onClose,
          menus: calling(menus, [...path, i]),
        ),
        PlatformMenuItemGroup(:final members) => PlatformMenuItemGroup(
          members: calling(members, [...path, i]),
        ),
        PlatformProvidedMenuItem() => item,
        _ => PlatformMenuItem(
          label: item.label,
          shortcut: item.shortcut,
          onSelected: item.onSelected == null
              ? null
              : () => at([...path, i])?.onSelected?.call(),
          onSelectedIntent: item.onSelectedIntent,
        ),
      },
  ];

  return calling(menus, const []);
}
