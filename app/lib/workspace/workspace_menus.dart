// The window's commands by name (what a key, a menu item or the command line runs) and the menu bar built from them.
// (setState from an extension on the State itself: the analyzer allows it only in a class or mixin)
// ignore_for_file: invalid_use_of_protected_member
part of 'workspace.dart';

extension _WorkspaceMenus on _WorkspaceState {
  static String _clipboard(String what) => _WorkspaceState._clipboard(what);   // (the class's own, named as the commands name it)

  static const _times = [('Align Starts', 'start'), ('Align Ends', 'end'), ('Move to Playhead', 'playhead'), ('Move End to Playhead', 'playhead_end'), ('Stagger', 'stagger'), ('Extend Start to Playhead', 'extend'), ('Trim End to Playhead', 'trim_end')];
  static const _aligns = [('Align Left', 'left'), ('Align Centre', 'centre'), ('Align Right', 'right'), ('Align Top', 'top'), ('Align Middle', 'middle'), ('Align Bottom', 'bottom'), ('Spread Across', 'across'), ('Spread Down', 'down')];

  Map<String, VoidCallback> _commands() {
    final m = _inside!, ws = _ws;
    // The picked held together by a Null they all go with, made in their middle (Figma's group, not a box of its own; one
    // step). mask 'mask' or 'exclude': Alight Motion's Group and Mask and Group and Exclude, the top one the shape the
    // others are seen in or cut out by (the inside's group_mask, doc_moment.h; docs/internal/reports/alight_motion/alight_ui.md).
    void group(String mask) {
      final m = _inside, all = _picked();
      final frames = [for (final t in all) ?m?.frame(t)];
      if (m == null || frames.isEmpty) return;
      final c = Offset(frames.map((f) => f[0]).reduce((a, b) => a + b) / frames.length, frames.map((f) => f[1]).reduce((a, b) => a + b) / frames.length);
      final order = m.things, top = order.lastIndexWhere(all.contains);
      m.later('together', number: 1);
      // (their row stands where the top one stood, the rest gathered under it: After Effects' Pre-compose, Figma's group)
      for (final (i, t) in order.indexed.toList().reversed) {
        final past = order.sublist(math.min(i, top), top).where((x) => !all.contains(x)).length;
        if (all.contains(t) && past > 0) m.later('raise', thing: t, number: past.toDouble());
      }
      ws.after(m.later('add', name: 'shape', word: 'null'), null, (g) => ws.select('$g'));
      if (top + 1 < order.length) m.later('raise', thing: -1, number: (top + 1 - order.length).toDouble());
      m.later('say', thing: -1, name: 'name', word: mask.isEmpty ? 'Group' : 'Group and Mask');
      // (its bar over theirs, as a precomposed layer's is)
      final from = all.map((t) => m.value(t, 'start', 0) ?? 0).reduce(math.min), ends = [for (final t in all) m.lasts(t) < 0 ? double.infinity : (m.value(t, 'start', 0) ?? 0) + m.lasts(t)];
      m.later('set', thing: -1, name: 'start', number: from);
      // (and as long as what it holds, kept: its Element card's Re-timing plays that longer or shorter, as Alight Motion's
      // group is a scene of its own that long: AbsentMotion's StructureActions.kt grouped, totalTime end - start)
      if (ends.reduce(math.max).isFinite) {
        for (final n in const ['duration', 'element_length']) {
          m.later('set', thing: -1, name: n, number: ends.reduce(math.max) - from);
        }
      }
      if (mask.isNotEmpty) m.later('say', thing: -1, name: 'group_mask', word: mask);
      m.later('set', thing: -1, name: 'x', number: (c.dx - WsArt.centre.dx) / m.point);
      m.later('set', thing: -1, name: 'y', number: (WsArt.centre.dy - c.dy) / m.point);
      for (final t in all) {
        m.later('set', thing: t, name: 'parent', word: 'made');   // (each goes with it, where it is)
      }
      ws.after(m.later('together'), (_, _) => ws.reread());
    }

    void step(int by) {
      ws.playing = false;
      ws.frame = ws.frame + by;
    }

    return {
      'file.new': () {
        _open(_fresh());
        wsAskSize.value = true;   // (its shape and resolution asked first, as Alight Motion's new-project box)
      },
      'file.render': () => wsAskRender.value++,   // (the settings window first)
      'file.exportFrame': _exportFrame,
      'file.home': () => setState(() {   // (its own picture kept first: its card shows it as it is)
        _keepPoster();
        _home = true;
      }),
      'file.poster': () {   // (the moment its picture is drawn at from now on: Alight Motion's Set Project Thumbnail)
        if (m.set(0, 'poster_at', ws.frame / 60)) _ws.notice = 'Project picture: ${ws.frame}';   // (the playhead as it is seen: sixty frames a second)
      },
      'file.package': _package,
      'edit.undo': () => _typed(const UndoTextIntent(SelectionChangedCause.keyboard)) ? null : ws.after(m.later('undo')),
      'edit.redo': () => _typed(const RedoTextIntent(SelectionChangedCause.keyboard)) ? null : ws.after(m.later('redo')),
      'edit.cut': () {   // (no words being written: the picked thing copied, then taken away, one step each as Live's)
        if (_typed(const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard))) return;
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        Clipboard.getData(Clipboard.kTextPlain).then((said) => _textWhenCopied = said?.text);
        m.later('copy', thing: t, word: _clipboard('thing'));
        m.later('together', number: 1);
        for (final held in ws.under('$t')) {
          m.later('remove', thing: int.parse(held));
        }
        m.later('remove', thing: t);
        ws.after(m.later('together'));
        ws.select(null);
      },
      'edit.copy': () {
        if (_typed(CopySelectionTextIntent.copy)) return;
        wsKeysKept = const [];
        ws.keys.isEmpty ? _copy('copy', 'thing') : wsCopyKeys(ws, ws.keys);
      },
      'edit.paste': () {
        if (_typed(const PasteTextIntent(SelectionChangedCause.keyboard))) return;
        void own() => wsKeysKept.isNotEmpty
            ? wsPasteKeys(ws)
            : File(_clipboard('thing')).existsSync()
            ? ws.after(m.later('paste', word: _clipboard('thing'), number: ws.frame / Ws.fps), null, (made) => ws.select('$made'))   // (at the playhead, the pasted one picked: Live's paste at the insert marker)
            : null;
        // (code copied from the net, whatever it is written for: read by the inside, door.h; what was copied last wins)
        Clipboard.getData(Clipboard.kTextPlain).then((said) {
          final code = said?.text ?? '';
          if (code.trim().isEmpty || code == _textWhenCopied) return own();
          ws.after(m.later('door', thing: int.tryParse(ws.selected ?? '') ?? 0, word: code), (done, why) {
            if (done) return;
            why.contains('not code') ? own() : ws.notice = 'Not taken: $why';
          }, (made) => made > 0 ? ws.select('$made') : null);
        });
      },
      'edit.copyStyle': () => _copy('copy_style', 'style'),
      'thing.saveLook': () {   // (kept on the Effects shelf by the layer's name: Alight Motion's Save as Preset)
        final m = _inside, l = _ws.layer;
        if (m == null || l == null) return;
        ws.after(m.later('keep_look', thing: int.parse(l.id), word: l.name), (done, why) {
          m.forgetFolders();
          _ws.notice = done ? 'Look kept: ${l.name}' : 'Not kept: $why';
          ws.reread();
        });
      },
      'thing.saveElement': () {   // (kept whole, with what it holds, among the elements on the Create shelf: Alight Motion's Save to My Elements)
        final m = _inside, l = _ws.layer;
        if (m == null || l == null) return;
        ws.after(m.later('keep_element', thing: int.parse(l.id), word: l.name), (done, why) {
          m.forgetFolders();
          _ws.notice = done ? 'Saved to My Elements: ${l.name}' : 'Not saved: $why';
          ws.reread();
        });
      },
      'edit.pasteStyle': () {   // (on every picked thing, one step)
        final all = {...ws.many, ?ws.selected};
        if (!File(_clipboard('style')).existsSync() || all.isEmpty) return;
        for (final id in all) {
          if (int.tryParse(id) case final t?) ws.after(m.later('paste_style', thing: t, word: _clipboard('style')));
        }
      },
      'edit.selectAll': () => _typed(const SelectAllTextIntent(SelectionChangedCause.keyboard)) ? null : ws.pickMany([for (final l in ws.layers) l.id]),   // (no words being written: every thing, as Ableton's Cmd+A in the arrangement)
      'edit.deselectAll': () => ws
        ..clearKeys()
        ..select(null),   // (nothing picked, as a click below the rows: After Effects' and Premiere Pro's Edit > Deselect All; with a thing over the whole stage, the one way back: golf_noise.md (63))
      'thing.deactivate': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        final hidden = ws.layers.any((l) => l.id == ws.selected && l.hidden);
        ws.after(m.later('set', thing: t, name: 'visible', number: hidden ? 1 : 0));
      },
      'thing.remove': () {
        if (wsMarkPicked.value case (final at, _)?) {   // (a picked mark first: Live's locator, deleted like a clip)
          wsMarkPicked.value = null;
          return ws.after(m.later('mark', number: at));
        }
        if (ws.stretch case final s?) return ws.after(m.later('way', thing: int.parse(s.layer), name: s.name, number: s.at, word: 'Linear'), (_, _) => ws.reread());   // (a stretch picked: its way off, straight again, not the thing)
        if (ws.keys.isNotEmpty) return wsRemoveKeys(ws, ws.keys.toList());   // (keys picked: those, not the thing)
        final all = ws.many.isNotEmpty ? ws.many.toList() : [if (ws.selected != null) ws.selected!];   // (things picked together: all of them, one step)
        final ts = [for (final id in {for (final id in all) ...ws.under(id), ...all}) if (int.tryParse(id) case final t?) t];   // (a group: with what it holds, as it is copied)
        if (ts.isEmpty) return;
        m.later('together', number: 1);
        for (final t in ts) {
          m.later('remove', thing: t);   // (without waiting; undo brings them back)
        }
        ws.after(m.later('together'));
        ws.select(null);   // (nothing picked after it: a second Delete takes nothing else)
      },
      'thing.duplicate': () {
        final all = _picked(), made = <String>[];
        if (all.isEmpty) return;
        m.later('together', number: 1);
        for (final t in all) {
          ws.after(m.later('duplicate', thing: t), null, (one) {
            made.add('$one');
            if (made.length < all.length) return;
            ws.select(made.last);   // (the new ones picked, as After Effects does)
            if (made.length > 1) ws.pickMany(made);
          });
        }
        ws.after(m.later('together'));
      },
      'thing.outline': () {   // (Alight Motion's Convert to Outline: a shape a path of the outline it shows, its points then the Pen's: doc_to_path)
        final t = int.tryParse(ws.selected ?? '');
        if (t == null || m.word(t, 'kind') != 'shape' || const ['path', 'null', 'solid'].contains(m.word(t, 'shape'))) return;
        ws.after(m.later('outline', thing: t), (_, _) => ws.reread());
      },
      'thing.extractSound': () {   // (a film's sound to a thing of its own, the film no longer heard: Alight Motion's Extract Audio)
        final t = int.tryParse(ws.selected ?? '');
        if (t == null || m.word(t, 'kind') != 'film') return;
        ws.after(m.later('extract_sound', thing: t), null, (made) => ws.select('$made'));
      },
      'thing.group': () => group(''),
      'thing.groupMask': () => group('mask'),
      'thing.groupExclude': () => group('exclude'),
      'thing.ungroup': () {   // (the picked group's things on their own again, where they are; the Null gone; one step)
        final m = _inside, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'shape') != 'null') return;
        final kids = [for (final t in m.things) if ((m.value(t, 'parent', 0) ?? 0).round() == g) t];
        m.later('together', number: 1);
        for (final t in kids) {
          m.later('set', thing: t, name: 'parent', number: 0);
        }
        m.later('remove', thing: g);
        ws.after(m.later('together'), (_, _) => ws.reread());
        ws.pickMany([for (final t in kids) '$t']);
      },
      'thing.unlinkElement': () {   // (an element put in made a group of its own, no longer following its file: AbsentMotion's Unlink from Asset, ElementUi.kt)
        final m = _inside, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'element').isEmpty) return;
        ws.after(m.later('say', thing: g, name: 'element', word: ''), (_, _) => ws.reread());
      },
      // (the work area taken out and the gap closed: After Effects' Edit > Extract Work Area, under Split Layer; golf (72))
      'edit.extractWork': () => ws.after(m.later('extract'), (done, why) => done || why.isEmpty ? null : ws.notice = 'Not taken: ${why.split(':').first}'),
      // (After Effects' Cmd+Opt+B: "set work area to duration of selected layers or, if no layers are selected, set
      // work area to composition duration"; golf (82): back to the whole after Extract Work Area took two drags)
      'edit.workToPicked': () {
        final picked = {for (final t in _picked()) '$t'}, bars = [for (final l in ws.layers) if (picked.contains(l.id)) l];
        final (from, to) = bars.isEmpty ? (0.0, m.seconds) : (bars.map((l) => l.inF).reduce(math.min) / Ws.fps, bars.map((l) => l.outF).reduce(math.max) / Ws.fps);
        ws.after(m.later('work', number: from, word: '$to'));
      },
      'thing.split': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        ws.after(m.later('split', thing: t, number: ws.frame / Ws.fps), null, (made) => ws.select('$made'));   // (the part after the playhead picked, as Live does)
      },
      for (final (_, how) in _aligns) 'arrange.$how': () {   // (the picked: one against the picture, more against their own box)
        final all = _picked();
        if (all.isNotEmpty) ws.after(m.later('align', word: '$how ${all.join(' ')}'));
      },
      for (final how in const ['fit', 'fill', 'stretch']) 'arrange.$how': () => _eachPicked((t) => m.later('fit', thing: t, word: how)),
      for (final (_, how) in _times) 'time.$how': () {   // (the picked, in the order picked: Alight Motion's timing)
        final all = _picked();
        if (all.isNotEmpty) ws.after(m.later('time_align', word: '$how ${all.join(' ')}', number: ws.frame / Ws.fps));
      },
      'thing.forward': () => _eachPicked((t) => m.later('raise', thing: t, number: 1)),
      'thing.backward': () => _eachPicked((t) => m.later('raise', thing: t, number: -1)),
      'arrange.flipX': () => _eachPicked((t) => m.later('flip', thing: t, word: 'x')),
      'arrange.flipY': () => _eachPicked((t) => m.later('flip', thing: t, word: 'y')),
      'layers.sequence': () => ws.after(m.later('sequence')),
      'sound.duck': () async {   // (Audacity's Auto Duck: each picked film under every other one's sound, read first)
        final m = _inside, all = _picked();
        if (m == null || all.isEmpty) return;
        for (final t in m.things) {
          if (!all.contains(t)) await m.loudness(t);
        }
        for (final t in all) {
          ws.after(m.later('duck', thing: t), (done, why) => done ? null : ws.notice = 'Not ducked: $why');
        }
      },   // (After Effects' Keyframe Assistant: one after another, from the top)
      'play.toggle': () => ws.playing = !ws.playing,
      ...wsAbletonCommands(ws),   // (Ableton Live's keys: ableton.dart)
      ...wsToolCommands(ws),   // (the stage's tools: stage.dart)
      'frame.first': () => step(-ws.frame),
      'frame.last': () => step(Ws.duration - ws.frame),
    };
  }

  void _wear(String? skin) => setState(() => ColorTheme.wear(skin));   // (the menus again too: the one worn is the one not offered)

  List<PlatformMenuItem> _menus() {
    final does = _commands();
    PlatformMenuItem item(String label, String command) => PlatformMenuItem(label: label, shortcut: _keymap.keyOf(command), onSelected: does[command]);
    return [
      PlatformMenu(
        label: 'Motolii',
        menus: [if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit)) const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit)],
      ),
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItemGroup(
            members: [
              item('New Document', 'file.new'),
              item('Projects…', 'file.home'),
              PlatformMenu(label: 'Open', menus: [for (final f in _beside) PlatformMenuItem(label: f.split('/').last, onSelected: f == _doc ? null : () => _open(f))]),
            ],
          ),
          item('Export Video…', 'file.render'),   // (Live's File menu: Export Audio/Video)
          item('Export Frame', 'file.exportFrame'),
          item('Package Project', 'file.package'),
          item('Use Frame as Project Picture', 'file.poster'),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItemGroup(
            members: [
              item('Undo', 'edit.undo'),
              item('Redo', 'edit.redo'),
            ],
          ),
          // (the system's own Edit menu went when these menus came: what a text box does is given back to it)
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
              item('Select Previous Layer', 'layer.previous'),   // (After Effects' names for its ⌘↑ and ⌘↓)
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
      // (Final Cut Pro's Mark menu: Go To Beginning and End, Previous and Next Frame, as its guide's "Navigate within your
      //  clips" names them; ten frames and After Effects' J and K, its previous and next visible item, beside them: every
      //  command in the menu bar, where the Help menu's search finds it by its name, Apple's HIG)
      PlatformMenu(
        label: 'Mark',
        menus: [
          PlatformMenu(label: 'Go To', menus: [item('Beginning', 'frame.first'), item('End', 'frame.last')]),
          PlatformMenu(label: 'Previous', menus: [item('Frame', 'frame.previous'), item('10 Frames', 'frame.back10'), item('Visible Item', 'frame.previousStop')]),
          PlatformMenu(label: 'Next', menus: [item('Frame', 'frame.next'), item('10 Frames', 'frame.forward10'), item('Visible Item', 'frame.nextStop')]),
          item('Animate All', 'mark.animate'),   // (Apple Motion's Mark > Record Animation)
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItemGroup(   // (Live's View menu: the arrangement's zoom)
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
                  PlatformMenuItem(label: 'Default', onSelected: ColorTheme.skin == null ? null : () => _wear(null)),
                  for (final n in ColorTheme.skinNames()) PlatformMenuItem(label: n, onSelected: n == ColorTheme.skin ? null : () => _wear(n)),
                ],
              ),
              PlatformMenuItem(label: 'Show Skins Folder', onSelected: () => Process.run('open', [(Directory(ColorTheme.skins)..createSync(recursive: true)).path])),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Arrange',   // (Keynote's and Figma's Align, Alight Motion's Fit and Flip)
        menus: [
          PlatformMenuItemGroup(members: [for (final (label, how) in _aligns) item(label, 'arrange.$how')]),
          PlatformMenuItemGroup(members: [item('Fit to Picture', 'arrange.fit'), item('Fill Picture', 'arrange.fill'), item('Stretch to Picture', 'arrange.stretch')]),
          PlatformMenuItemGroup(members: [item('Flip Horizontal', 'arrange.flipX'), item('Flip Vertical', 'arrange.flipY')]),
          PlatformMenuItemGroup(members: [item('Bring Forward', 'thing.forward'), item('Send Backward', 'thing.backward')]),
        ],
      ),
      PlatformMenu(
        label: 'Animation',
        menus: [
          item('Sequence Layers', 'layers.sequence'),
          item('Auto Duck', 'sound.duck'),   // (Audacity's Effect menu name: the picked, quieter under the other sounds)
          PlatformMenuItemGroup(members: [for (final (label, how) in _times) item(label, 'time.$how')]),
          PlatformMenuItemGroup(   // (Live 42.16's Nudge Selection Left and Right, ten frames with ⇧)
            members: [item('Nudge Selection Left', 'nudge.left'), item('Nudge Selection Right', 'nudge.right'), item('Nudge Selection Left 10 Frames', 'nudge.left10'), item('Nudge Selection Right 10 Frames', 'nudge.right10')],
          ),
        ],
      ),
      // (a menu titled Help: the Mac puts its search of every menu item in it (Apple's HIG, the Help menu), so a feature
      //  forgotten is found by its name; and Motolii's ledger of what it has, as a Help menu's own help: golf (98))
      PlatformMenu(
        label: 'Help',
        menus: [PlatformMenuItem(label: 'Motolii (README)', onSelected: () => Process.run('open', ['${File(motoliiDir).parent.path}/README.md']))],
      ),
    ];
  }
}
