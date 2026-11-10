// The workspace's commands by name, which a key, a menu item or the command line runs, and the menu bar built from them.
//
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/workspace/commands/command_actions.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/stage/stage.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension WorkspaceMenus on WorkspaceState {
  static String _clipboard(String what) => WorkspaceState.clipboard(
    what,
  ); // The class's own method, under the name the commands use.

  static const _times = [
    ('Align Starts', 'start'),
    ('Align Ends', 'end'),
    ('Move to Playhead', 'playhead'),
    ('Move End to Playhead', 'playhead_end'),
    ('Stagger', 'stagger'),
    ('Extend Start to Playhead', 'extend'),
    ('Trim End to Playhead', 'trim_end'),
  ];
  static const _aligns = [
    ('Align Left', 'left'),
    ('Align Centre', 'centre'),
    ('Align Right', 'right'),
    ('Align Top', 'top'),
    ('Align Middle', 'middle'),
    ('Align Bottom', 'bottom'),
    ('Spread Across', 'across'),
    ('Spread Down', 'down'),
  ];

  Map<String, VoidCallback> commands() {
    final m = engine!, ws = this.ws;
    // Groups the selected layers under a new null layer placed at their centre, as one undo step.
    // Like Figma's group, it is not a container of its own.
    // [mask] is 'mask' or 'exclude' (Alight Motion's Group and Mask, Group and Exclude): the top layer's shape
    // then shows the others inside it, or cuts them out. The engine side is group_mask in document/evaluate/evaluate.h.
    // See docs/design/alight_motion_ui.md.
    void group(String mask) {
      final m = engine, all = pickedLayers();
      final frames = [for (final t in all) ?m?.bounds(t)];
      if (m == null || frames.isEmpty) return;
      final c = Offset(
        frames.map((f) => f[0]).reduce((a, b) => a + b) / frames.length,
        frames.map((f) => f[1]).reduce((a, b) => a + b) / frames.length,
      );
      final order = m.layers, top = order.lastIndexWhere(all.contains);
      m.later('together', number: 1);
      // The group's row takes the place of the top layer and the rest gather under it (After Effects' Pre-compose, Figma's group).
      for (final (i, t) in order.indexed.toList().reversed) {
        final past = order
            .sublist(math.min(i, top), top)
            .where((x) => !all.contains(x))
            .length;
        if (all.contains(t) && past > 0) {
          m.later('raise', layer: t, number: past.toDouble());
        }
      }
      ws.after(
        m.later('add', name: 'shape', word: 'null'),
        null,
        (g) => ws.select('$g'),
      );
      if (top + 1 < order.length) {
        m.later(
          'raise',
          layer: -1,
          number: (top + 1 - order.length).toDouble(),
        );
      }
      m.later(
        'say',
        layer: -1,
        name: 'name',
        word: mask.isEmpty ? 'Group' : 'Group and Mask',
      );
      // The group's bar spans the bars of its layers, as a precomposed layer's does.
      final from = all.map((t) => m.value(t, 'start', 0) ?? 0).reduce(math.min),
          ends = [
            for (final t in all)
              m.lasts(t) < 0
                  ? double.infinity
                  : (m.value(t, 'start', 0) ?? 0) + m.lasts(t),
          ];
      m.later('set', layer: -1, name: 'start', number: from);
      // The group also keeps the length of its contents. Its Element card's Re-timing plays that content longer or shorter.
      // In Alight Motion a group is a scene of that length (AbsentMotion's StructureActions.kt: totalTime = end - start).
      if (ends.reduce(math.max).isFinite) {
        for (final n in const ['duration', 'element_length']) {
          m.later(
            'set',
            layer: -1,
            name: n,
            number: ends.reduce(math.max) - from,
          );
        }
      }
      if (mask.isNotEmpty) {
        m.later('say', layer: -1, name: 'group_mask', word: mask);
      }
      m.later(
        'set',
        layer: -1,
        name: 'x',
        number: (c.dx - ArtGeometry.centre.dx) / m.point,
      );
      m.later(
        'set',
        layer: -1,
        name: 'y',
        number: (ArtGeometry.centre.dy - c.dy) / m.point,
      );
      for (final t in all) {
        m.later(
          'set',
          layer: t,
          name: 'parent',
          word: 'last_added',
        ); // Each layer follows the group and stays where it is.
      }
      ws.after(m.later('together'), (_, _) => ws.reread());
    }

    void step(int by) {
      ws.playing = false;
      ws.frame = ws.frame + by;
    }

    return {
      'file.new': () {
        open(fresh());
        sizeBoxRequested.value = true; // Ask for its shape and resolution first, as Alight Motion's new-project box does.
      },
      'file.render': () =>
          renderRequested.value++, // Opens the render settings window first.
      'file.exportFrame': exportFrame,
      'file.home': () => setState(() {
        // Save the current project's picture first, so its card shows it as it is.
        keepPoster();
        home = true;
      }),
      'file.poster': () {
        // The frame the project picture is drawn at from now on (Alight Motion's Set Project Thumbnail).
        // The playhead frame is divided by 60 because the preview runs at sixty frames a second.
        if (m.set(0, 'poster_at', ws.frame / 60)) {
          ws.notice = 'Project picture: ${ws.frame}';
        }
      },
      'file.package': package,
      'edit.undo': () =>
          typed(const UndoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.after(m.later('undo')),
      'edit.redo': () =>
          typed(const RedoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.after(m.later('redo')),
      'edit.cut': () {
        // Unless the user is typing text, copy the selected layer and then remove it, as one undo step each, as Live does.
        if (typed(
          const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        )) {
          return;
        }
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        Clipboard.getData(Clipboard.kTextPlain)
            .then((said) => textWhenCopied = said?.text);
        m.later('copy', layer: t, word: _clipboard('thing'));
        m.later('together', number: 1);
        for (final held in ws.under('$t')) {
          m.later('remove', layer: int.parse(held));
        }
        m.later('remove', layer: t);
        ws.after(m.later('together'));
        ws.select(null);
      },
      'edit.copy': () {
        if (typed(CopySelectionTextIntent.copy)) return;
        copiedKeyframes = const [];
        ws.keys.isEmpty ? copy('copy', 'thing') : copyKeyframes(ws, ws.keys);
      },
      'edit.paste': () {
        if (typed(const PasteTextIntent(SelectionChangedCause.keyboard))) {
          return;
        }
        // Pastes the app's own clipboard: the copied keyframes, else the copied layer at the playhead (Live's paste at the insert marker).
        // The pasted layer is selected.
        void own() => copiedKeyframes.isNotEmpty
            ? pasteKeyframes(ws)
            : File(_clipboard('thing')).existsSync()
            ? ws.after(
                m.later(
                  'paste',
                  word: _clipboard('thing'),
                  number: ws.frame / WorkspaceController.fps,
                ),
                null,
                (made) => ws.select('$made'),
              )
            : null;
        // Code copied from the web is run by the engine's adapter (adapter.h), whatever it is written for.
        // Whatever was copied last wins.
        Clipboard.getData(Clipboard.kTextPlain).then((said) {
          final code = said?.text ?? '';
          if (code.trim().isEmpty || code == textWhenCopied) return own();
          ws.after(
            m.later(
              'adapter',
              layer: int.tryParse(ws.selected ?? '') ?? 0,
              word: code,
            ),
            (done, why) {
              if (done) return;
              why.contains('not code') ? own() : ws.notice = 'Not taken: $why';
            },
            (made) => made > 0 ? ws.select('$made') : null,
          );
        });
      },
      'edit.copyStyle': () => copy('copy_style', 'style'),
      'thing.saveLook': () {
        // Saves the layer as a preset on the Effects shelf, named after the layer (Alight Motion's Save as Preset).
        final m = engine, l = ws.layer;
        if (m == null || l == null) return;
        ws.after(m.later('keep_preset', layer: int.parse(l.id), word: l.name), (
          done,
          why,
        ) {
          m.forgetFolders();
          ws.notice = done ? 'Look kept: ${l.name}' : 'Not kept: $why';
          ws.reread();
        });
      },
      'thing.saveElement': () {
        // Saves the layer with its contents among the elements on the Create shelf (Alight Motion's Save to My Elements).
        final m = engine, l = ws.layer;
        if (m == null || l == null) return;
        ws.after(
          m.later('keep_element', layer: int.parse(l.id), word: l.name),
          (done, why) {
            m.forgetFolders();
            ws.notice = done
                ? 'Saved to My Elements: ${l.name}'
                : 'Not saved: $why';
            ws.reread();
          },
        );
      },
      'edit.pasteStyle': () {
        // Applies to every selected layer.
        final all = {...ws.many, ?ws.selected};
        if (!File(_clipboard('style')).existsSync() || all.isEmpty) return;
        for (final id in all) {
          if (int.tryParse(id) case final t?) {
            ws.after(
              m.later('paste_style', layer: t, word: _clipboard('style')),
            );
          }
        }
      },
      'edit.selectAll': () =>
          typed(const SelectAllTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.pickMany([for (final l in ws.layers) l.id]), // Unless the user is typing: all layers, as Ableton's Cmd+A in the arrangement.
      // Selects nothing, as a click below the rows does (After Effects and Premiere Pro: Edit > Deselect All).
      // This is the only way to deselect when one layer covers the whole canvas.
      'edit.deselectAll': () => ws
        ..clearKeys()
        ..select(null),
      'thing.deactivate': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        final hidden = ws.layers.any((l) => l.id == ws.selected && l.hidden);
        ws.after(
          m.later('set', layer: t, name: 'visible', number: hidden ? 1 : 0),
        );
      },
      'thing.remove': () {
        if (selectedMarker.value case (final at, _)?) {
          // A selected marker is deleted first, as Live deletes a locator like a clip.
          selectedMarker.value = null;
          return ws.after(m.later('mark', number: at));
        }
        if (ws.stretch case final s?) {
          // A selected span between keyframes resets its easing to Linear instead of deleting the layer.
          return ws.after(
            m.later(
              'easing',
              layer: int.parse(s.layer),
              name: s.name,
              number: s.at,
              word: 'Linear',
            ),
            (_, _) => ws.reread(),
          );
        }
        // Selected keyframes are removed instead of the layer.
        if (ws.keys.isNotEmpty) return removeKeyframes(ws, ws.keys.toList());
        // All selected layers are removed in one undo step.
        final all = ws.many.isNotEmpty
            ? ws.many.toList()
            : [if (ws.selected != null) ws.selected!];
        // A group is removed together with the layers it holds, as copying does.
        final ts = [
          for (final id in {for (final id in all) ...ws.under(id), ...all})
            ?int.tryParse(id),
        ];
        if (ts.isEmpty) return;
        m.later('together', number: 1);
        for (final t in ts) {
          m.later(
            'remove',
            layer: t,
          ); // Does not wait for the result. Undo brings the layer back.
        }
        ws.after(m.later('together'));
        ws.select(
          null,
        ); // Nothing stays selected, so a second Delete removes nothing else.
      },
      'thing.duplicate': () {
        final all = pickedLayers(), made = <String>[];
        if (all.isEmpty) return;
        m.later('together', number: 1);
        for (final t in all) {
          ws.after(m.later('duplicate', layer: t), null, (one) {
            made.add('$one');
            if (made.length < all.length) return;
            ws.select(
              made.last,
            ); // The new layers become selected, as in After Effects.
            if (made.length > 1) ws.pickMany(made);
          });
        }
        ws.after(m.later('together'));
      },
      'thing.outline': () {
        // Alight Motion's Convert to Outline: turns a shape into a path of the outline it shows, whose points then belong to the Pen tool (doc_to_path).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null ||
            m.word(t, 'kind') != 'shape' ||
            const ['path', 'null', 'solid'].contains(m.word(t, 'shape'))) {
          return;
        }
        ws.after(m.later('outline', layer: t), (_, _) => ws.reread());
      },
      'thing.extractSound': () {
        // Moves a video's sound to a layer of its own and mutes the video (Alight Motion's Extract Audio).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null || m.word(t, 'kind') != 'film') return;
        ws.after(
          m.later('extract_sound', layer: t),
          null,
          (made) => ws.select('$made'),
        );
      },
      'thing.group': () => group(''),
      'thing.groupMask': () => group('mask'),
      'thing.groupExclude': () => group('exclude'),
      'thing.ungroup': () {
        // Releases the layers of the selected group where they are and removes the null, as one undo step.
        final m = engine, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'shape') != 'null') return;
        final kids = [
          for (final t in m.layers)
            if ((m.value(t, 'parent', 0) ?? 0).round() == g) t,
        ];
        m.later('together', number: 1);
        for (final t in kids) {
          m.later('set', layer: t, name: 'parent', number: 0);
        }
        m.later('remove', layer: g);
        ws.after(m.later('together'), (_, _) => ws.reread());
        ws.pickMany([for (final t in kids) '$t']);
      },
      'thing.unlinkElement': () {
        // The element becomes a plain group and no longer follows its file (AbsentMotion's Unlink from Asset, ElementUi.kt).
        final m = engine, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'element').isEmpty) return;
        ws.after(
          m.later('say', layer: g, name: 'element', word: ''),
          (_, _) => ws.reread(),
        );
      },
      // Removes the work area and closes the gap (After Effects' Edit > Extract Work Area, under Split Layer).
      'edit.extractWork': () => ws.after(
        m.later('extract'),
        (done, why) => done || why.isEmpty
            ? null
            : ws.notice = 'Not taken: ${why.split(':').first}',
      ),
      // After Effects' Cmd+Opt+B: "set work area to duration of selected layers or, if no layers are selected, set
      // work area to composition duration". It brings back the whole project after Extract Work Area, which otherwise takes two drags.
      'edit.workToPicked': () {
        final picked = {for (final t in pickedLayers()) '$t'},
            bars = [
              for (final l in ws.layers)
                if (picked.contains(l.id)) l,
            ];
        final (from, to) = bars.isEmpty
            ? (0.0, m.seconds)
            : (
                bars.map((l) => l.inF).reduce(math.min) /
                    WorkspaceController.fps,
                bars.map((l) => l.outF).reduce(math.max) /
                    WorkspaceController.fps,
              );
        ws.after(m.later('work', number: from, word: '$to'));
      },
      'thing.split': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        // The part after the playhead becomes selected, as in Live.
        ws.after(
          m.later(
            'split',
            layer: t,
            number: ws.frame / WorkspaceController.fps,
          ),
          null,
          (made) => ws.select('$made'),
        );
      },
      for (final (_, how) in _aligns)
        'arrange.$how': () {
          // One selected layer aligns to the canvas, several align to their combined box.
          final all = pickedLayers();
          if (all.isNotEmpty) {
            ws.after(m.later('align', word: '$how ${all.join(' ')}'));
          }
        },
      for (final how in const ['fit', 'fill', 'stretch'])
        'arrange.$how': () =>
            eachPicked((t) => m.later('fit', layer: t, word: how)),
      for (final (_, how) in _times)
        'time.$how': () {
          // Acts on the selected layers in the order they were selected (Alight Motion's timing).
          final all = pickedLayers();
          if (all.isNotEmpty) {
            ws.after(
              m.later(
                'time_align',
                word: '$how ${all.join(' ')}',
                number: ws.frame / WorkspaceController.fps,
              ),
            );
          }
        },
      'thing.forward': () =>
          eachPicked((t) => m.later('raise', layer: t, number: 1)),
      'thing.backward': () =>
          eachPicked((t) => m.later('raise', layer: t, number: -1)),
      'arrange.flipX': () =>
          eachPicked((t) => m.later('flip', layer: t, word: 'x')),
      'arrange.flipY': () =>
          eachPicked((t) => m.later('flip', layer: t, word: 'y')),
      'layers.sequence': () => ws.after(m.later('sequence')),
      'sound.duck': () async {
        // Audacity's Auto Duck: lowers each selected video under the sound of all the other layers, whose loudness is read first.
        final m = engine, all = pickedLayers();
        if (m == null || all.isEmpty) return;
        for (final t in m.layers) {
          if (!all.contains(t)) await m.loudness(t);
        }
        for (final t in all) {
          ws.after(
            m.later('duck', layer: t),
            (done, why) => done ? null : ws.notice = 'Not ducked: $why',
          );
        }
      },
      'play.toggle': () => ws.playing = !ws.playing,
      ...abletonCommands(ws), // Ableton Live's keys: see command_actions.dart.
      ...stageToolCommands(ws), // The canvas tools: see stage.dart.
      'frame.first': () => step(-ws.frame),
      'frame.last': () => step(WorkspaceController.duration - ws.frame),
    };
  }

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
      PlatformMenu(
        label: 'Motolii',
        menus: [
          // macOS's own About panel, which shows macos/Runner/Credits.rtf (FFmpeg's LGPL notice is there).
          if (PlatformProvidedMenuItem.hasMenu(
            PlatformProvidedMenuItemType.about,
          ))
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
          if (PlatformProvidedMenuItem.hasMenu(
            PlatformProvidedMenuItemType.quit,
          ))
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
        ],
      ),
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
      ),
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
      ),
      // Modelled on Final Cut Pro's Mark menu: Go To Beginning and End, Previous and Next Frame, as its guide's
      // "Navigate within your clips" names them. Ten frames and After Effects' J and K (previous and next visible item) sit beside them.
      // Every command is in the menu bar so that the Help menu's search finds it by name (Apple's HIG).
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
      ),
      PlatformMenu(
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
                    onSelected: ColorTheme.skin == null
                        ? null
                        : () => _wear(null),
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
                  (Directory(
                    ColorTheme.skins,
                  )..createSync(recursive: true)).path,
                ]),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Arrange', // Keynote's and Figma's Align, Alight Motion's Fit and Flip.
        menus: [
          PlatformMenuItemGroup(
            members: [
              for (final (label, how) in _aligns) item(label, 'arrange.$how'),
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
      ),
      PlatformMenu(
        label: 'Animation',
        menus: [
          item('Sequence Layers', 'layers.sequence'),
          item('Auto Duck', 'sound.duck'), // Audacity's Effect menu name: makes the selected layers quieter under the other sounds.
          PlatformMenuItemGroup(
            members: [
              for (final (label, how) in _times) item(label, 'time.$how'),
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
      ),
      // A menu titled Help: macOS puts its search of every menu item there (Apple's HIG, the Help menu),
      // so a forgotten feature can be found by name. It also links the README, which lists what Motolii has.
      PlatformMenu(
        label: 'Help',
        menus: [
          PlatformMenuItem(
            label: 'Motolii (README)',
            onSelected: () => Process.run('open', [
              '${File(motoliiDir).parent.path}/README.md',
            ]),
          ),
        ],
      ),
    ];
  }
}
