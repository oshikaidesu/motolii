// Timeline requests from the app's commands, and the ruler.
//
// - Zoom, loop and rename requests come from command_actions.dart and follow Ableton Live. The timeline keeps its own view state.
// - The ruler follows Live's scrub area and locators (Live 12 manual, chapter 6 "Arrangement View", sections 6.3 and 6.4).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
import 'package:motolii/workspace/commands/panel_requests.dart' show wsTimelineAsk, wsAskRename, wsAskTimeline, wsMarkPicked;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_drag.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_ruler.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';

mixin TimelineRequests on State<TimelinePane> {
  // The timeline state this mixin is part of: its zoom and scroll.
  TimelinePaneState get _t => this as TimelinePaneState;

  // The zoom and scroll before "selection" zoomed in. "back" returns to them, as X does in Live.
  (double, double)? _before;
  // The id of the layer row being renamed with Cmd+R, as in Live.
  String? _renaming;
  final _renameWords = TextEditingController();
  late final FocusNode _renameFocus = FocusNode()..addListener(() => _renameFocus.hasFocus ? null : _renamed());

  void hearAsks() {
    wsTimelineAsk.addListener(_heard);
    wsAskRename.addListener(_rename);
  }

  void stopAsks() {
    wsTimelineAsk.removeListener(_heard);
    wsAskRename.removeListener(_rename);
    _renameWords.dispose();
    _renameFocus.dispose();
  }

  void _heard() {
    final t = _t, ws = t.workspace, m = ws?.inside;
    if (!mounted || ws == null || m == null) return;
    switch (wsTimelineAsk.value.$1) {
      case 'loop':
        setState(() => m.looping = !m.looping);
      case 'in':
        t.setZoom(t.zoom * 1.5);
      case 'out':
        t.setZoom(t.zoom / 1.5);
      case 'fit':
        t.setZoom(1);
      // Zooms to fill the view with the selected keyframes, else the selected layer's bar, as Z does in Live.
      case 'selection':
        final frames = ws.keys.isNotEmpty
            ? [for (final k in ws.keys) k.frame]
            : [
                if (ws.layer case final l?) ...[l.inF, l.outF],
              ];
        if (frames.isEmpty) return;
        final a = frames.reduce((p, q) => p < q ? p : q), b = frames.reduce((p, q) => p > q ? p : q), span = (b - a).clamp(6, WorkspaceController.duration);
        _before ??= (t.zoom, t.scroll);
        t.setZoom(WorkspaceController.duration / (span * 1.2), anchor: a);
        setState(() => t.scroll = t.clampScroll(a - span * .1));
      case 'back':
        if (_before case (final z, final s)?) {
          _before = null;
          t.setZoom(z);
          setState(() => t.scroll = t.clampScroll(s));
        }
    }
  }

  /// Plays from frame [f]. Playback is stopped first so the clock restarts at the playhead.
  void _playAt(int f) {
    final ws = _t.workspace!;
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
  void rulerTap(Offset p) {
    final t = _t, ws = t.workspace;
    if (ws == null) return;
    final int f;
    if (t.flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      f = (flag.$1 * WorkspaceController.fps).round();
    } else {
      wsMarkPicked.value = null;
      if (p.dy <= TimelineMetrics.band + 2) return;
      f = t.view.frameAt(p.dx).round().clamp(0, WorkspaceController.duration);
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
  void rulerDouble(Offset p) {
    if (_t.flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      return _rename();
    }
    final ws = _t.workspace;
    if (ws != null && (ws.keys.isNotEmpty || ws.layer != null)) return wsAskTimeline('selection');
    _t.setZoom(1);
  }

  /// A right-click on the ruler.
  ///
  /// As in Live (6.4), the scrub area and each locator have their own context menu.
  /// On a marker it selects the marker, and the menu can rename it, play from it or delete it.
  /// Elsewhere the menu adds a marker named by its order, or one whose name field opens at once, as in Final Cut Pro.
  void rulerRight(Offset p) {
    final ws = _t.workspace, m = ws?.inside;
    if (ws == null || m == null) return;
    if (_t.flagAt(p) case final flag?) {
      wsMarkPicked.value = flag;
      return _t.rulerMenu.currentState?.show(p, [
        ContextMenuItem('Rename…', _rename, keys: '⌘R'),
        ContextMenuItem('Play from Here', () => _playAt((flag.$1 * WorkspaceController.fps).round())),
        const ContextMenuItem.rule(),
        ContextMenuItem('Delete', () {
          wsMarkPicked.value = null;
          ws.after(m.later('mark', number: flag.$1));
        }, keys: '⌫'),
        const ContextMenuItem.rule(),
        // A marker has one of the label colours, as in Premiere Pro, DaVinci Resolve and CapCut.
        ContextMenuItem.colors(
          [for (var k = 0; k < 16; k++) wsLabelColor(k)],
          (ws.markColors[flag.$1] ?? 0) - 1,
          (k) => ws.after(m.later('mark_colour', number: flag.$1, word: '${k + 1}')),
        ),
      ]);
    }
    final at = _t.view.frameAt(p.dx).round().clamp(0, WorkspaceController.duration) / WorkspaceController.fps,
        taken = ws.marks.any((k) => (k.$1 - at).abs() < 0.5 / WorkspaceController.fps);
    _t.rulerMenu.currentState?.show(p, [
      ContextMenuItem('Add Marker', taken ? null : () => _addMark(at, named: false), why: 'One is here'),
      ContextMenuItem('Add Marker and Name…', taken ? null : () => _addMark(at, named: true), why: 'One is here'),
      if (ws.beats != null)
        ContextMenuItem(
          // Starts a bar here, as in Live.
          'Set 1.1.1 Here',
          () => ws.after(m.later('set', layer: 0, name: 'bpm_from', number: at), (_, _) => ws.reread()),
        ),
    ]);
  }

  /// A right-click on a layer's bar opens the layer's context menu.
  void trackRight(Offset p) {
    final t = _t, ws = t.workspace, r = t.rowAt(p.dy);
    // Below the rows, or on a property lane, there is no bar.
    if (ws == null || r == null || r.value != null) return;
    final l = r.l, f = t.view.frameAt(p.dx);
    // Beside the bar.
    if (f < l.inF || f > l.outF) return;
    t.trackMenu.currentState?.show(p, wsThingMenu(context, ws, l));
  }

  /// The same menu, opened by a right-click on a row's name.
  void labelRight(Layer l, Offset global) {
    final menu = _t.labelMenu.currentState, ws = _t.workspace;
    if (menu == null || ws == null) return;
    menu.show((menu.context.findRenderObject() as RenderBox).globalToLocal(global), wsThingMenu(context, ws, l));
  }

  /// The Marker button, as Set Locator in Live (6.4).
  ///
  /// It adds a marker at the playhead and selects it. If a marker is already there, it deletes it (Delete Locator in Live).
  void setMark() {
    final ws = _t.workspace, m = ws?.inside;
    if (ws == null || m == null) return;
    if (ws.marks.where((k) => (k.$1 * WorkspaceController.fps).round() == ws.frame).firstOrNull case (final was, _)?) {
      wsMarkPicked.value = null;
      return ws.after(m.later('mark', number: was));
    }
    _addMark(ws.frame / WorkspaceController.fps, named: false);
  }

  void _addMark(double at, {required bool named}) {
    final ws = _t.workspace!, marks = ws.marks;
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
    final ws = _t.workspace;
    if (!mounted || ws == null) return;
    if (wsMarkPicked.value case final flag?) {
      // The selected marker's name is edited in its flag with the text selected, as in Final Cut Pro.
      setState(() => _t.naming = flag);
      _t.markWords
        ..text = flag.$2
        ..selection = TextSelection(baseOffset: 0, extentOffset: flag.$2.length);
      return _t.markFocus.requestFocus();
    }
    if (ws.layer == null) return;
    setState(() => _renaming = ws.layer!.id);
    _renameWords.text = ws.layer!.name;
    _renameWords.selection = TextSelection(baseOffset: 0, extentOffset: _renameWords.text.length);
    _renameFocus.requestFocus();
  }

  void _renamed() {
    final id = _renaming, ws = _t.workspace, words = _renameWords.text.trim();
    if (id == null) return;
    setState(() => _renaming = null);
    final t = int.tryParse(id), was = ws?.layers.where((l) => l.id == id).firstOrNull?.name;
    if (t != null && words.isNotEmpty && words != was && ws?.inside != null) ws!.after(ws.inside!.later('say', layer: t, name: 'name', word: words));
  }

  /// The name field over the row being renamed.
  /// Enter or clicking away commits the name. Esc restores the old one.
  Widget? renameField(int i, String id, double top) => _renaming != id
      ? null
      : Positioned(
          left: Shape.s(28),
          right: Shape.s(4),
          top: top + Shape.s(4),
          height: TimelineMetrics.row - Shape.s(8),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                _renameWords.text = _t.workspace?.layers.where((l) => l.id == id).firstOrNull?.name ?? '';
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
                  style: TextStyles.label(Grey.g13).copyWith(fontWeight: FontWeight.w700),
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
