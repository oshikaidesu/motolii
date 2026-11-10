// Timeline requests from the app's commands, and the ruler.
//
// - Zoom, loop and rename requests come from command_actions.dart and follow Ableton Live. The timeline keeps its own view state.
// - The ruler follows Live's scrub area and locators (Live 12 manual, chapter 6 "Arrangement View", sections 6.3 and 6.4).
part of 'timeline.dart';

mixin _TimelineAsked on State<WsTimeline> {
  // The timeline state this mixin is part of: its zoom and scroll.
  _WsTimelineState get _t => this as _WsTimelineState;

  // The zoom and scroll before "selection" zoomed in. "back" returns to them, as X does in Live.
  (double, double)? _before;
  // The id of the layer row being renamed with Cmd+R, as in Live.
  String? _renaming;
  final _renameWords = TextEditingController();
  late final FocusNode _renameFocus = FocusNode()..addListener(() => _renameFocus.hasFocus ? null : _renamed());

  void _hearAsks() {
    wsTimelineAsk.addListener(_heard);
    wsAskRename.addListener(_rename);
  }

  void _stopAsks() {
    wsTimelineAsk.removeListener(_heard);
    wsAskRename.removeListener(_rename);
    _renameWords.dispose();
    _renameFocus.dispose();
  }

  void _heard() {
    final t = _t, ws = t._ws, m = ws?.inside;
    if (!mounted || ws == null || m == null) return;
    switch (wsTimelineAsk.value.$1) {
      case 'loop':
        setState(() => m.looping = !m.looping);
      case 'in':
        t._setZoom(t._zoom * 1.5);
      case 'out':
        t._setZoom(t._zoom / 1.5);
      case 'fit':
        t._setZoom(1);
      // Zooms to fill the view with the selected keyframes, else the selected layer's bar, as Z does in Live.
      case 'selection':
        final frames = ws.keys.isNotEmpty
            ? [for (final k in ws.keys) k.frame]
            : [
                if (ws.layer case final l?) ...[l.inF, l.outF],
              ];
        if (frames.isEmpty) return;
        final a = frames.reduce((p, q) => p < q ? p : q), b = frames.reduce((p, q) => p > q ? p : q), span = (b - a).clamp(6, Ws.duration);
        _before ??= (t._zoom, t._scroll);
        t._setZoom(Ws.duration / (span * 1.2), anchor: a);
        setState(() => t._scroll = t._clampScroll(a - span * .1));
      case 'back':
        if (_before case (final z, final s)?) {
          _before = null;
          t._setZoom(z);
          setState(() => t._scroll = t._clampScroll(s));
        }
    }
  }

  /// Plays from frame [f]. Playback is stopped first so the clock restarts at the playhead.
  void _playAt(int f) {
    final ws = _t._ws!;
    ws.playing = false;
    ws.frame = f;
    ws.playing = true;
  }

  /// A click on the ruler.
  ///
  /// On a marker it selects the marker. Anywhere else it moves the playhead there and stops playback.
  /// Any touch of Alight Motion's timeline stops playback too. There the playhead stays in the middle and the timeline moves.
  /// On desktop the playhead moves, as in Audacity, whose "Click ruler to start playback" setting is off by default.
  /// The work area band handles its own clicks.
  void _rulerTap(Offset p) {
    final t = _t, ws = t._ws;
    if (ws == null) return;
    final int f;
    if (t._flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      f = (flag.$1 * Ws.fps).round();
    } else {
      wsMarkPicked.value = null;
      if (p.dy <= WtM.band + 2) return;
      f = t._view.frameAt(p.dx).round().clamp(0, Ws.duration);
    }
    ws
      ..playing = false
      ..frame = f;
  }

  /// A double-click on the ruler.
  ///
  /// On a marker it renames the marker, as Premiere Pro, DaVinci Resolve and Final Cut Pro do.
  /// Live plays from the marker instead, so here "Play from Here" is in the right-click menu.
  /// Elsewhere it zooms to the selection, or to the whole project when nothing is selected, as in Live.
  void _rulerDouble(Offset p) {
    if (_t._flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      return _rename();
    }
    final ws = _t._ws;
    if (ws != null && (ws.keys.isNotEmpty || ws.layer != null)) return wsAskTimeline('selection');
    _t._setZoom(1);
  }

  /// A right-click on the ruler.
  ///
  /// As in Live (6.4), the scrub area and each locator have their own context menu.
  /// On a marker it selects the marker, and the menu can rename it, play from it or delete it.
  /// Elsewhere the menu adds a marker named by its order, or one whose name field opens at once, as in Final Cut Pro.
  void _rulerRight(Offset p) {
    final ws = _t._ws, m = ws?.inside;
    if (ws == null || m == null) return;
    if (_t._flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      return _t._rulerMenu.currentState?.show(p, [
        WsMenuItem('Rename…', _rename, keys: '⌘R'),
        WsMenuItem('Play from Here', () => _playAt((flag.$1 * Ws.fps).round())),
        const WsMenuItem.rule(),
        WsMenuItem('Delete', () {
          wsMarkPicked.value = null;
          ws.after(m.later('mark', number: flag.$1));
        }, keys: '⌫'),
        const WsMenuItem.rule(),
        // A marker has one of the label colours, as in Premiere Pro, DaVinci Resolve and CapCut.
        WsMenuItem.colors(
          [for (var k = 0; k < 16; k++) wsLabelColor(k)],
          (ws.markColors[flag.$1] ?? 0) - 1,
          (k) => ws.after(m.later('mark_colour', number: flag.$1, word: '${k + 1}')),
        ),
      ]);
    }
    final at = _t._view.frameAt(p.dx).round().clamp(0, Ws.duration) / Ws.fps, taken = ws.marks.any((k) => (k.$1 - at).abs() < 0.5 / Ws.fps);
    _t._rulerMenu.currentState?.show(p, [
      WsMenuItem('Add Marker', taken ? null : () => _addMark(at, named: false), why: 'One is here'),
      WsMenuItem('Add Marker and Name…', taken ? null : () => _addMark(at, named: true), why: 'One is here'),
      if (ws.beats != null)
        WsMenuItem(
          // Starts a bar here, as in Live.
          'Set 1.1.1 Here',
          () => ws.after(m.later('set', layer: 0, name: 'bpm_from', number: at), (_, _) => ws.reread()),
        ),
    ]);
  }

  /// A right-click on a layer's bar opens the layer's context menu.
  void _trackRight(Offset p) {
    final t = _t, ws = t._ws, r = t._rowAt(p.dy);
    // Below the rows, or on a property lane, there is no bar.
    if (ws == null || r == null || r.value != null) return;
    final l = r.l, f = t._view.frameAt(p.dx);
    // Beside the bar.
    if (f < l.inF || f > l.outF) return;
    t._trackMenu.currentState?.show(p, wsThingMenu(context, ws, l));
  }

  /// The same menu, opened by a right-click on a row's name.
  void _labelRight(WsLayer l, Offset global) {
    final menu = _t._labelMenu.currentState, ws = _t._ws;
    if (menu == null || ws == null) return;
    menu.show((menu.context.findRenderObject() as RenderBox).globalToLocal(global), wsThingMenu(context, ws, l));
  }

  /// The Marker button, as Set Locator in Live (6.4).
  ///
  /// It adds a marker at the playhead and selects it. If a marker is already there, it deletes it (Delete Locator in Live).
  void _setMark() {
    final ws = _t._ws, m = ws?.inside;
    if (ws == null || m == null) return;
    if (ws.marks.where((k) => (k.$1 * Ws.fps).round() == ws.frame).firstOrNull case (final was, _)?) {
      wsMarkPicked.value = null;
      return ws.after(m.later('mark', number: was));
    }
    _addMark(ws.frame / Ws.fps, named: false);
  }

  void _addMark(double at, {required bool named}) {
    final ws = _t._ws!, marks = ws.marks;
    var n = marks.length + 1;
    while (marks.any((k) => k.$2 == 'M$n')) {
      n++;
    }
    ws.after(ws.inside!.later('mark', number: at, word: 'M$n'), (done, _) {
      if (!done || !mounted) return;
      wsMarkPicked.value = (at, 'M$n');
      if (named) _rename();
    });
  }

  void _rename() {
    final ws = _t._ws;
    if (!mounted || ws == null) return;
    if (wsMarkPicked.value case final flag?) {
      // The selected marker's name is edited in its flag with the text selected, as in Final Cut Pro.
      setState(() => _t._naming = flag);
      _t._markWords
        ..text = flag.$2
        ..selection = TextSelection(baseOffset: 0, extentOffset: flag.$2.length);
      return _t._markFocus.requestFocus();
    }
    if (ws.layer == null) return;
    setState(() => _renaming = ws.layer!.id);
    _renameWords.text = ws.layer!.name;
    _renameWords.selection = TextSelection(baseOffset: 0, extentOffset: _renameWords.text.length);
    _renameFocus.requestFocus();
  }

  void _renamed() {
    final id = _renaming, ws = _t._ws, words = _renameWords.text.trim();
    if (id == null) return;
    setState(() => _renaming = null);
    final t = int.tryParse(id), was = ws?.layers.where((l) => l.id == id).firstOrNull?.name;
    if (t != null && words.isNotEmpty && words != was && ws?.inside != null) ws!.after(ws.inside!.later('say', layer: t, name: 'name', word: words));
  }

  /// The name field over the row being renamed.
  /// Enter or clicking away commits the name. Esc restores the old one.
  Widget? _renameField(int i, String id, double top) => _renaming != id
      ? null
      : Positioned(
          left: Shape.s(28),
          right: Shape.s(4),
          top: top + Shape.s(4),
          height: WtM.row - Shape.s(8),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                _renameWords.text = _t._ws?.layers.where((l) => l.id == id).firstOrNull?.name ?? '';
                _renameFocus.unfocus();
              },
            },
            child: Container(
              color: Grey.g91,
              padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
              alignment: Alignment.centerLeft,
              child: TextGestures(
                key: ValueKey('ws-tl-rename-$id'),
                field: (k) => EditableText(
                  key: k,
                  rendererIgnoresPointer: true,
                  controller: _renameWords,
                  focusNode: _renameFocus,
                  style: T.label(Grey.g13).copyWith(fontWeight: FontWeight.w700),
                  cursorColor: Grey.g13,
                  backgroundCursorColor: Grey.g38,
                  maxLines: 1,
                  onSubmitted: (_) => _renameFocus.unfocus(),
                ),
              ),
            ),
          ),
        );
}
