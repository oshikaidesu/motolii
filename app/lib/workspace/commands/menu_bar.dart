// The window's commands by name (what a key or a menu item runs) and the menu bar built from them.
// ignore_for_file: invalid_use_of_protected_member
part of '../workspace.dart';

extension _WorkspaceMenus on _WorkspaceState {
  Map<String, VoidCallback> _commands() {
    final m = _inside!, ws = _ws;
    void step(int by) {
      ws.playing = false;
      ws.frame = ws.frame + by;
    }

    return {
      'file.new': () => _open(_fresh()),
      'file.exportFrame': _exportFrame,
      'file.poster': () => m.set(0, 'poster_at', ws.frame / 60),
      'file.package': _package,
      'edit.undo': () => _typed(const UndoTextIntent(SelectionChangedCause.keyboard)) ? null : ws.after(m.later('undo')),
      'edit.redo': () => _typed(const RedoTextIntent(SelectionChangedCause.keyboard)) ? null : ws.after(m.later('redo')),
      ...wsAbletonCommands(ws),
      'frame.first': () => step(-ws.frame),
      'frame.last': () => step(Ws.duration - ws.frame),
    };
  }

  void _wear(String? skin) => setState(() => ColorTheme.wear(skin));

  List<PlatformMenuItem> _menus() {
    final does = _commands();
    PlatformMenuItem item(String label, String command) => PlatformMenuItem(label: label, shortcut: _keymap.keyOf(command), onSelected: does[command]);
    return [
      PlatformMenu(
        label: 'Motolii',
        menus: [
          if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit)) const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
        ],
      ),
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItemGroup(
            members: [
              item('New Document', 'file.new'),
              PlatformMenu(
                label: 'Open',
                menus: [for (final f in _beside) PlatformMenuItem(label: f.split('/').last, onSelected: f == _doc ? null : () => _open(f))],
              ),
            ],
          ),
          item('Export Frame', 'file.exportFrame'),
          item('Package Project', 'file.package'),
          item('Use Frame as Project Picture', 'file.poster'),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [PlatformMenuItemGroup(members: [item('Undo', 'edit.undo'), item('Redo', 'edit.redo')])],
      ),
      PlatformMenu(
        label: 'Mark',
        menus: [
          item('Beginning', 'frame.first'),
          item('End', 'frame.last'),
          item('Play / Stop', 'play.fromStart'),
          item('Continue Play', 'play.continue'),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenu(
            label: 'Skin',
            menus: [
              PlatformMenuItemGroup(
                members: [
                  PlatformMenuItem(label: 'Default', onSelected: ColorTheme.skin == null ? null : () => _wear(null)),
                  for (final n in ColorTheme.skinNames()) PlatformMenuItem(label: n, onSelected: n == ColorTheme.skin ? null : () => _wear(n)),
                ],
              ),
              PlatformMenuItem(
                label: 'Show Skins Folder',
                onSelected: () => Process.run('open', [(Directory(ColorTheme.skins)..createSync(recursive: true)).path]),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
