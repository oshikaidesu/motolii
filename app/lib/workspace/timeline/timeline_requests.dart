// Timeline commands, ruler clicks/context menus, and renaming in place.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
import 'package:motolii/workspace/commands/keymap.dart' show keyLabel;
import 'package:motolii/workspace/workspace.dart' show WorkspaceState;
import 'package:motolii/workspace/commands/panel_requests.dart'
    show timelineRequest, renameRequested, requestTimeline, selectedMarker;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/ruler_marks.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

mixin TimelineRequests<T extends StatefulWidget> on State<T> {
  WorkspaceController? get workspace;
  TimelineViewport get viewport;
  RulerMarks get ruler;
  TimelineRows get rows;

  void setZoom(double z, {int? anchor});

  final rulerMenu = GlobalKey<ContextMenuState>();
  final trackMenu = GlobalKey<ContextMenuState>();
  final labelMenu = GlobalKey<ContextMenuState>();
  (double, String)? naming;
  final markText = ValueNotifier<String>('');

  void nameDone(String? said) {
    final was = naming, ws = workspace!, words = said?.trim() ?? '';
    if (was == null) return;
    setState(() => naming = null);
    if (words.isNotEmpty &&
        words != was.$2 &&
        timeline_service.isConnected(ws)) {
      ws.after(timeline_service.renameMarker(ws, was.$1, words));
    }
  }

  (double, double)? _before;
  int? _renaming;

  void listenForRequests() {
    timelineRequest.addListener(_heard);
    renameRequested.addListener(_rename);
  }

  void disposeRequests() {
    timelineRequest.removeListener(_heard);
    renameRequested.removeListener(_rename);
    markText.dispose();
  }

  void _heard() {
    final ws = workspace;
    if (!mounted || ws == null || !timeline_service.isConnected(ws)) return;
    switch (timelineRequest.value.$1) {
      case 'loop':
        setState(() => timeline_service.toggleLooping(ws));
      case 'in':
        setZoom(viewport.zoom * 1.5);
      case 'out':
        setZoom(viewport.zoom / 1.5);
      case 'fit':
        setZoom(1);
      case 'selection':
        final frames = ws.keys.isNotEmpty
            ? [for (final k in ws.keys) k.frame]
            : [
                if (ws.layer case final l?) ...[l.inF, l.outF],
              ];
        if (frames.isEmpty) return;
        final a = frames.reduce((p, q) => p < q ? p : q),
            b = frames.reduce((p, q) => p > q ? p : q),
            span = (b - a).clamp(6, WorkspaceController.duration);
        _before ??= (viewport.zoom, viewport.scroll);
        setZoom(WorkspaceController.duration / (span * 1.2), anchor: a);
        viewport.scrollTo(a - span * .1);
      case 'back':
        if (_before case (final z, final s)?) {
          _before = null;
          setZoom(z);
          viewport.scrollTo(s);
        }
    }
  }

  // Playback must be stopped first so the clock restarts at the new frame.
  void _playAt(int f) {
    final ws = workspace!;
    ws.playing = false;
    ws.frame = f;
    ws.playing = true;
  }

  /// On a marker: selects it. Elsewhere: moves the playhead and stops playback.
  void rulerTap(Offset p) {
    final ws = workspace;
    if (ws == null) return;
    final int f;
    if (ruler.flagAt(p) case final flag?) {
      selectedMarker.value = flag;
      f = (flag.$1 * WorkspaceController.fps).round();
    } else {
      selectedMarker.value = null;
      if (p.dy <= TimelineMetrics.band + 2) return;
      f = viewport.view
          .frameAt(p.dx)
          .round()
          .clamp(0, WorkspaceController.duration);
    }
    ws
      ..playing = false
      ..frame = f;
  }

  /// Double-click: on a marker renames it, elsewhere zooms to selection.
  void rulerDouble(Offset p) {
    if (ruler.flagAt(p) case final flag?) {
      selectedMarker.value = flag;
      return _rename();
    }
    final ws = workspace;
    if (ws != null && (ws.keys.isNotEmpty || ws.layer != null)) {
      return requestTimeline('selection');
    }
    setZoom(1);
  }

  /// Right-click on the ruler: marker menu or add-marker menu.
  void rulerRight(Offset p) {
    final ws = workspace;
    if (ws == null || !timeline_service.isConnected(ws)) return;
    if (ruler.flagAt(p) case final flag?) {
      selectedMarker.value = flag;
      return rulerMenu.currentState?.show(p, [
        ContextMenuItem(
          'Rename…',
          _rename,
          keys: keyLabel(
            context.findAncestorStateOfType<WorkspaceState>()?.keymap.keyOf(
              'thing.rename',
            ),
          ),
        ),
        ContextMenuItem(
          'Play from Here',
          () => _playAt((flag.$1 * WorkspaceController.fps).round()),
        ),
        const ContextMenuItem.rule(),
        ContextMenuItem('Delete', () {
          selectedMarker.value = null;
          ws.after(timeline_service.removeMarker(ws, flag.$1));
        }, keys: '⌫'),
        const ContextMenuItem.rule(),
        ContextMenuItem.colors(
          [for (var k = 0; k < 16; k++) labelColor(k)],
          (ws.markColors[flag.$1] ?? 0) - 1,
          (k) => ws.after(timeline_service.recolourMarker(ws, flag.$1, k + 1)),
        ),
      ]);
    }
    final at =
            viewport.view
                .frameAt(p.dx)
                .round()
                .clamp(0, WorkspaceController.duration) /
            WorkspaceController.fps,
        taken = ws.marks.any(
          (k) => (k.$1 - at).abs() < 0.5 / WorkspaceController.fps,
        );
    rulerMenu.currentState?.show(p, [
      ContextMenuItem(
        'Add Marker',
        taken ? null : () => _addMark(at, named: false),
        why: 'One is here',
      ),
      ContextMenuItem(
        'Add Marker and Name…',
        taken ? null : () => _addMark(at, named: true),
        why: 'One is here',
      ),
      if (ws.beats != null)
        ContextMenuItem(
          'Set 1.1.1 Here',
          () => ws.after(
            timeline_service.setBeatGridStart(ws, at),
            (_, _) => ws.reread(),
          ),
        ),
    ]);
  }

  void trackRight(Offset p) {
    final ws = workspace, r = rows.rowAt(p.dy);
    if (ws == null) return;
    if (r == null) {
      trackMenu.currentState?.show(p, emptyContextMenu(context, ws));
      return;
    }
    if (r.value != null) {
      trackMenu.currentState?.show(p, keyframeContextMenu(context, ws));
      return;
    }
    final l = r.l, f = viewport.view.frameAt(p.dx);
    if (f < l.inF || f > l.outF) return;
    trackMenu.currentState?.show(p, layerContextMenu(context, ws, l));
  }

  void labelRight(Layer l, Offset global) {
    final menu = labelMenu.currentState, ws = workspace;
    if (menu == null || ws == null) return;
    menu.show(
      (menu.context.findRenderObject() as RenderBox).globalToLocal(global),
      layerContextMenu(context, ws, l),
    );
  }

  /// Adds a marker at the playhead; if one is there, deletes it.
  void setMark() {
    final ws = workspace;
    if (ws == null || !timeline_service.isConnected(ws)) return;
    if (ws.marks
            .where((k) => (k.$1 * WorkspaceController.fps).round() == ws.frame)
            .firstOrNull
        case (final was, _)?) {
      selectedMarker.value = null;
      return ws.after(timeline_service.removeMarker(ws, was));
    }
    _addMark(ws.frame / WorkspaceController.fps, named: false);
  }

  void _addMark(double at, {required bool named}) {
    final ws = workspace!, marks = ws.marks;
    var n = marks.length + 1;
    while (marks.any((k) => k.$2 == 'M$n')) {
      n++;
    }
    ws.after(timeline_service.addMarker(ws, at, 'M$n'), (done, _) {
      if (!done || !mounted) return;
      selectedMarker.value = (at, 'M$n');
      if (named) _rename();
    });
  }

  void _rename() {
    final ws = workspace;
    if (!mounted || ws == null) return;
    if (selectedMarker.value case final flag?) {
      markText.value = flag.$2;
      setState(() => naming = flag);
      return;
    }
    if (ws.layer == null) return;
    setState(() => _renaming = ws.layer!.id);
  }

  void _renamed(int id, String? said) {
    final ws = workspace, words = said?.trim() ?? '';
    setState(() => _renaming = null);
    final was = ws?.layers.where((l) => l.id == id).firstOrNull?.name;
    if (words.isNotEmpty &&
        words != was &&
        ws != null &&
        timeline_service.isConnected(ws)) {
      ws.after(timeline_service.renameLayer(ws, id, words));
    }
  }

  /// The name field over the row being renamed. Enter commits; Esc cancels.
  Widget? renameField(int i, int id, double top) => _renaming != id
      ? null
      : Positioned(
          left: Shape.s(28),
          right: Shape.s(4),
          top: top + Shape.s(4),
          height: TimelineMetrics.row - Shape.s(8),
          child: Container(
            color: Grey.g91,
            padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
            alignment: Alignment.centerLeft,
            child: TypedField(
              key: ValueKey('ws-tl-rename-$id'),
              text:
                  workspace?.layers
                      .where((l) => l.id == id)
                      .firstOrNull
                      ?.name ??
                  '',
              style: TextStyles.label(Grey.g13).bold,
              cursor: Grey.g13,
              take: true,
              escapes: true,
              onDone: (said) => _renamed(id, said),
            ),
          ),
        );
}
