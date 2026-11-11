// The menu bar, built from the workspace's commands (menu_bar.dart): the items, their shortcuts, and the skins offered.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/workspace/workspace.dart';
import 'package:motolii/workspace/commands/command_arrange.dart'
    show workspaceAligns, workspaceTimes;
import 'package:motolii/workspace/commands/menu_bar.dart' show WorkspaceMenus;

extension WorkspaceMenuItems on WorkspaceState {
  void _wear(String? skin) => setState(
    () => ColorTheme.wear(skin),
  ); // Also rebuilds the menus, because the skin in use is the one not offered.

  List<PlatformMenuItem> menus() {
    final does = commands();
    PlatformMenuItem item(String label, String command) => PlatformMenuItem(
      label: label,
      shortcut: keymap.keyOf(command),
      onSelected: does[command],
    );
    return [
      _motoliiMenu(),
      _fileMenu(item),
      _editMenu(item),
      _markMenu(item),
      _viewMenu(item),
      _arrangeMenu(item),
      _animationMenu(item),
      _helpMenu(),
    ];
  }

  PlatformMenu _motoliiMenu() => PlatformMenu(
    label: 'Motolii',
    menus: [
      // macOS's own About panel, which shows macos/Runner/Credits.rtf (FFmpeg's LGPL notice is there).
      if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about))
        const PlatformProvidedMenuItem(
          type: PlatformProvidedMenuItemType.about,
        ),
      if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
        const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
    ],
  );

  PlatformMenu _fileMenu(PlatformMenuItem Function(String, String) item) =>
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItemGroup(
            members: [
              item('New Document', 'file.new'),
              item('Projects…', 'file.home'),
              PlatformMenu(
                label: 'Open',
                menus: [
                  for (final f in beside)
                    PlatformMenuItem(
                      label: f.split('/').last,
                      onSelected: f == documentPath ? null : () => open(f),
                    ),
                ],
              ),
            ],
          ),
          item(
            'Export Video…',
            'file.render',
          ), // Live's File menu: Export Audio/Video.
          item('Export Frame', 'file.exportFrame'),
          item('Package Project', 'file.package'),
          item('Use Frame as Project Picture', 'file.poster'),
        ],
      );

  PlatformMenu _editMenu(PlatformMenuItem Function(String, String) item) =>
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItemGroup(
            members: [item('Undo', 'edit.undo'), item('Redo', 'edit.redo')],
          ),
          // These menus replace the system's Edit menu, so text boxes handle their own editing keys.
          PlatformMenuItemGroup(
            members: [
              item('Cut', 'edit.cut'),
              item('Copy', 'edit.copy'),
              item('Paste', 'edit.paste'),
              item('Copy Style', 'edit.copyStyle'),
              item('Paste Style', 'edit.pasteStyle'),
              item('Save Look', 'thing.saveLook'),
              item('Save to My Elements', 'thing.saveElement'),
              item('Select All', 'edit.selectAll'),
              item('Deselect All', 'edit.deselectAll'),
              item(
                'Select Previous Layer',
                'layer.previous',
              ), // After Effects' names for its ⌘↑ and ⌘↓.
              item('Select Next Layer', 'layer.next'),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              item('Duplicate', 'thing.duplicate'),
              item('Convert to Outline', 'thing.outline'),
              item('Group', 'thing.group'),
              item('Group and Mask', 'thing.groupMask'),
              item('Group and Exclude', 'thing.groupExclude'),
              item('Ungroup', 'thing.ungroup'),
              item('Unlink from Element', 'thing.unlinkElement'),
              item('Split', 'thing.split'),
              item('Extract Work Area', 'edit.extractWork'),
              item('Set Work Area to Selected', 'edit.workToPicked'),
              item('Extract Sound', 'thing.extractSound'),
              item('Rename', 'thing.rename'),
              item('Remove', 'thing.remove'),
            ],
          ),
          item('Solo', 'thing.solo'),
          item('Keyed Values', 'thing.lanes'),
          item('Deactivate', 'thing.deactivate'),
        ],
      );

  // Modelled on Final Cut Pro's Mark menu: Go To Beginning and End, Previous and Next Frame, as its guide's
  // "Navigate within your clips" names them. Ten frames and After Effects' J and K (previous and next visible item) sit beside them.
  // Every command is in the menu bar so that the Help menu's search finds it by name (Apple's HIG).
  PlatformMenu _markMenu(PlatformMenuItem Function(String, String) item) =>
      PlatformMenu(
        label: 'Mark',
        menus: [
          PlatformMenu(
            label: 'Go To',
            menus: [
              item('Beginning', 'frame.first'),
              item('End', 'frame.last'),
            ],
          ),
          PlatformMenu(
            label: 'Previous',
            menus: [
              item('Frame', 'frame.previous'),
              item('10 Frames', 'frame.back10'),
              item('Visible Item', 'frame.previousStop'),
            ],
          ),
          PlatformMenu(
            label: 'Next',
            menus: [
              item('Frame', 'frame.next'),
              item('10 Frames', 'frame.forward10'),
              item('Visible Item', 'frame.nextStop'),
            ],
          ),
          item(
            'Animate All',
            'mark.animate',
          ), // Apple Motion's Mark > Record Animation.
        ],
      );

  PlatformMenu _viewMenu(
    PlatformMenuItem Function(String, String) item,
  ) => PlatformMenu(
    label: 'View',
    menus: [
      PlatformMenuItemGroup(
        // Live's View menu: zoom of the arrangement.
        members: [
          item('Zoom In', 'zoom.in'),
          item('Zoom Out', 'zoom.out'),
          item('Zoom to Selection', 'zoom.selection'),
          item('Zoom Back', 'zoom.back'),
          item('Optimize Width', 'zoom.width'),
        ],
      ),
      PlatformMenuItemGroup(
        members: [
          item('Play / Stop', 'play.fromStart'),
          item('Continue Play', 'play.continue'),
          item('Loop', 'loop.toggle'),
        ],
      ),
      PlatformMenu(
        label: 'Skin',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Default',
                onSelected: ColorTheme.skin == null ? null : () => _wear(null),
              ),
              for (final n in ColorTheme.skinNames())
                PlatformMenuItem(
                  label: n,
                  onSelected: n == ColorTheme.skin ? null : () => _wear(n),
                ),
            ],
          ),
          PlatformMenuItem(
            label: 'Show Skins Folder',
            onSelected: () => Process.run('open', [
              (Directory(ColorTheme.skins)..createSync(recursive: true)).path,
            ]),
          ),
        ],
      ),
    ],
  );

  PlatformMenu _arrangeMenu(
    PlatformMenuItem Function(String, String) item,
  ) => PlatformMenu(
    label:
        'Arrange', // Keynote's and Figma's Align, Alight Motion's Fit and Flip.
    menus: [
      PlatformMenuItemGroup(
        members: [
          for (final (label, how) in workspaceAligns)
            item(label, 'arrange.$how'),
        ],
      ),
      PlatformMenuItemGroup(
        members: [
          item('Fit to Picture', 'arrange.fit'),
          item('Fill Picture', 'arrange.fill'),
          item('Stretch to Picture', 'arrange.stretch'),
        ],
      ),
      PlatformMenuItemGroup(
        members: [
          item('Flip Horizontal', 'arrange.flipX'),
          item('Flip Vertical', 'arrange.flipY'),
        ],
      ),
      PlatformMenuItemGroup(
        members: [
          item('Bring Forward', 'thing.forward'),
          item('Send Backward', 'thing.backward'),
        ],
      ),
    ],
  );

  PlatformMenu _animationMenu(PlatformMenuItem Function(String, String) item) =>
      PlatformMenu(
        label: 'Animation',
        menus: [
          item('Sequence Layers', 'layers.sequence'),
          item('Auto Duck', 'sound.duck'), // Audacity's Effect menu name: makes the selected layers quieter under the other sounds.
          PlatformMenuItemGroup(
            members: [
              for (final (label, how) in workspaceTimes)
                item(label, 'time.$how'),
            ],
          ),
          PlatformMenuItemGroup(
            // Live 42.16's Nudge Selection Left and Right, ten frames with ⇧.
            members: [
              item('Nudge Selection Left', 'nudge.left'),
              item('Nudge Selection Right', 'nudge.right'),
              item('Nudge Selection Left 10 Frames', 'nudge.left10'),
              item('Nudge Selection Right 10 Frames', 'nudge.right10'),
            ],
          ),
        ],
      );

  // A menu titled Help: macOS puts its search of every menu item there (Apple's HIG, the Help menu),
  // so a forgotten feature can be found by name. It also links the README, which lists what Motolii has.
  PlatformMenu _helpMenu() => PlatformMenu(
    label: 'Help',
    menus: [
      PlatformMenuItem(
        label: 'Motolii (README)',
        onSelected: () =>
            Process.run('open', ['${File(motoliiDir).parent.path}/README.md']),
      ),
    ],
  );
}
