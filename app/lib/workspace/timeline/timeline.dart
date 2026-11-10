// The workspace's Timeline panel.
//
// It has the transport and timecode on top, layer labels beside the track area, a ruler with the work area, and the playhead.
// The project lives in WorkspaceController. This panel keeps only how it is viewed: zoom, scroll, loop, the row toggles and the work area.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/ruler_marks.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_cache_painter.dart';
import 'package:motolii/workspace/timeline/timeline_header.dart';
import 'package:motolii/workspace/timeline/timeline_labels.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_overview.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_requests.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_tracks_paint.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';
import 'package:motolii/workspace/timeline/track_drag.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

class TimelinePane extends StatefulWidget {
  const TimelinePane({super.key});
  @override
  State<TimelinePane> createState() => TimelinePaneState();
}

class TimelinePaneState extends State<TimelinePane>
    with SingleTickerProviderStateMixin, TimelineRequests {
  late final Ticker ticker = createTicker(tick);
  // One closure, used for both adding and removing the listener.
  // Tearing off an extension method gives a new closure each time, so removeListener would never match.
  late final VoidCallback _listener = changed;
  final _focus = FocusNode(debugLabel: 'timeline');
  WorkspaceController? workspace;

  /// The zoom, the scroll and the size of the track area.
  final viewport = TimelineViewport(() => WorkspaceController.duration);

  /// The beats, video frames, thumbnails and waveforms read for the rows.
  final media = TimelineMediaCache();

  /// Where a trimmed video's whole source lies along its row, and the drag that slips it.
  late final slip = SlipEdit(media: media);

  /// The work area and the markers on the ruler, and the drag in hand there.
  late final ruler = RulerMarks(
    workspaceOf: () => workspace,
    viewport: viewport,
    snapTo: _snapTo,
  );

  /// The rows in the order they are laid out, and what each one shows.
  late final rows = TimelineRows(
    workspaceOf: () => workspace,
    viewport: viewport,
    media: media,
    slip: slip,
  );

  /// The bar, keyframe or selection box being dragged on the tracks, and the cursor over them.
  late final drag = TrackDrag(
    workspaceOf: () => workspace,
    viewport: viewport,
    rows: rows,
    slip: slip,
    snapTo: _snapTo,
  );
  int lastFrame = -1;

  @override
  void initState() {
    super.initState();
    viewport.addListener(_rebuild);
    media.addListener(_rebuild);
    ruler.addListener(_rebuild);
    slip.addListener(_rebuild);
    drag.addListener(_rebuild);
    // Starts listening for requests from the app's commands (timeline_requests.dart).
    hearAsks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws != workspace) {
      workspace?.on[WorkspaceAspect.playing]!.removeListener(_listener);
      workspace?.moment.removeListener(_listener);
      workspace = ws..on[WorkspaceAspect.playing]!.addListener(_listener);
      ws.moment.addListener(_listener);
      if (ws.playing) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => mounted ? changed() : null,
        );
      }
    }
  }

  @override
  void dispose() {
    workspace?.on[WorkspaceAspect.playing]!.removeListener(_listener);
    workspace?.moment.removeListener(_listener);
    ticker.dispose();
    viewport.dispose();
    media.dispose();
    ruler.dispose();
    slip.dispose();
    drag.dispose();
    _focus.dispose();
    stopAsks();
    markWords.dispose();
    markFocus.dispose();
    super.dispose();
  }

  // Draws the timeline again after one of the objects it owns has changed.
  void _rebuild() => setState(() {});

  void setZoom(double z, {int? anchor}) =>
      viewport.setZoom(z, anchor: anchor ?? workspace!.frame);

  /// Keeps the playhead in view when zoomed in: the view pages along as play or a scrub carries it off the edge.
  void follow(int f) {
    if (!mounted) return;
    viewport.follow(f);
  }

  /// A two-finger trackpad slide scrolls the tracks like a wheel, in the opposite direction, so the content follows the fingers.
  /// A pinch zooms around the frame under the fingers, as in Final Cut, Cavalry and Theatre.js.
  void fingers(Offset by, Offset _) => scrollBy(-by);
  void pinch(double by, Offset at) => setZoom(
    viewport.zoom * by,
    anchor: viewport.view
        .frameAt(at.dx)
        .round()
        .clamp(0, WorkspaceController.duration),
  );

  void scrollBy(Offset d) {
    final sideways =
        HardwareKeyboard.instance.isShiftPressed || d.dx.abs() > d.dy.abs();
    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed) {
      setZoom(viewport.zoom * math.pow(1.0015, -d.dy));
    } else if (sideways) {
      viewport.scrollBy(d.dx.abs() > d.dy.abs() ? d.dx : d.dy);
    } else {
      viewport.scrollRowsBy(d.dy);
    }
  }

  // Snapping to [stops] and the beat grid at the present zoom, or null while Cmd is held, which turns snapping off.
  // The drags on the ruler and on the tracks both ask for it.
  FrameSnap? _snapTo(Set<int> stops) => HardwareKeyboard.instance.isMetaPressed
      ? null
      : FrameSnap(
          stops: stops,
          beats: workspace!.beats,
          pixelsPerFrame: viewport.view.pixelsPerFrame,
        );

  // The context menus of the ruler, of a bar and of a row's name (see timeline_requests.dart).
  // On the ruler a right-click adds a marker, a click selects one and moves the playhead there, and Cmd+R renames it.
  final rulerMenu = GlobalKey<ContextMenuState>();
  final trackMenu = GlobalKey<ContextMenuState>();
  final labelMenu = GlobalKey<ContextMenuState>();
  // The marker whose name is being edited in its flag.
  (double, String)? naming;
  final markWords = TextEditingController();
  // Commits the marker name when the field loses focus.
  late final FocusNode markFocus = FocusNode()
    ..addListener(() => markFocus.hasFocus ? null : _named());

  void _named() {
    final was = naming, ws = workspace!, words = markWords.text.trim();
    if (was == null) return;
    setState(() => naming = null);
    if (words.isNotEmpty && words != was.$2 && ws.inside != null) {
      ws.after(ws.inside!.later('mark', number: was.$1, word: words));
    }
  }

  void overview(Offset p, double w) {
    final f = (p.dx - 4) / (w - 8) * WorkspaceController.duration;
    viewport.scrollTo(f - viewport.visible / 2);
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    ruler.takeWorkArea();
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.document,
      WorkspaceAspect.picked,
      WorkspaceAspect.animating,
    });
    final drawn = rows.layOut();
    return Focus(
      focusNode: _focus,
      child: TapRegion(
        onTapInside: (_) => _focus.requestFocus(),
        child: ColoredBox(
          color: WindowTokens.body,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimelineHeader(
                ws: ws,
                loop: ws.inside!.looping,
                zoom: viewport.zoom,
                onToggle: toggle,
                onStep: step,
                onLoop: () =>
                    setState(() => ws.inside!.looping = !ws.inside!.looping),
                onZoom: setZoom,
                onMark: setMark,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: TimelineMetrics.label,
                      child: _labels(ws, drawn),
                    ),
                    SizedBox(
                      width: TimelineMetrics.divider,
                      child: ColoredBox(color: WindowTokens.ground),
                    ),
                    Expanded(child: _tracks(ws, drawn)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The layer's row number and name, as After Effects' Parent column shows it. Several layers may share a name.
  String _numbered(WorkspaceController ws, String id) {
    final i = ws.layers.indexWhere((l) => l.id == id);
    return i < 0 ? id : '${i + 1} ${ws.layers[i].name}';
  }

  // The column of layer names beside the tracks.
  Widget _labels(WorkspaceController ws, List<TimelineRow> drawn) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TimelineLabelHeader(count: ws.layers.length, solo: RowFlags(ws).anySolo),
      Expanded(
        child: ContextMenu(
          key: labelMenu,
          child: TwoFingerGestures(
            onWheel: scrollBy,
            // The labels scroll vertically together with the track rows.
            onPan: (by, _) => scrollBy(Offset(0, -by.dy)),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, box) {
                  final top = viewport.clampVerticalScroll(drawn.length);
                  return Stack(
                    children: [
                      for (var i = 0; i < drawn.length; i++)
                        if (rows.order[i].aim case (final said, final other)?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-aim-${ws.layers[rows.order[i].layer].id}-$said-$other',
                            ),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            child: NakedButton(
                              enableFeedback: false,
                              mouseCursor: SystemMouseCursors.basic,
                              // Pressing selects the target layer, like Cavalry's connection list.
                              onPressed: () => ws.select(other),
                              child: Row(
                                children: [
                                  Text(
                                    said,
                                    maxLines: 1,
                                    style: TextStyles.label(Grey.g56),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                  Flexible(
                                    child: Text(
                                      _numbered(ws, other),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.label(Grey.g91),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // A property lane shows the property name under its layer's name, as Ableton names a lane after its control.
                        else if (rows.order[i].value case final n?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-lane-${ws.layers[rows.order[i].layer].id}-$n',
                            ),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                            // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                            child: Row(
                              children: [
                                if (rows.laneCard(
                                      ws.layers[rows.order[i].layer],
                                      n,
                                    )
                                    case final card?) ...[
                                  Flexible(
                                    child: Text(
                                      card,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.label(Grey.g56),
                                    ),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                ],
                                Text(
                                  ws.inside?.shown(n)?.label ?? n,
                                  maxLines: 1,
                                  style: TextStyles.label(Grey.g76),
                                ),
                              ],
                            ),
                          )
                        else if (ws.layers[rows.order[i].layer] case final l)
                          Positioned(
                            key: ValueKey('ws-tl-label-${l.id}'),
                            left: 0,
                            right: 0,
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            // Dragging a row up or down moves the layer forward or back by as many rows as it was dragged.
                            child: GestureDetector(
                              supportedDevices: pressingDevices,
                              onSecondaryTapDown: (d) =>
                                  labelRight(l, d.globalPosition),
                              // Count the whole drag from the pointer-down position.
                              dragStartBehavior: DragStartBehavior.down,
                              onVerticalDragStart: (_) => rows.reorderStart(),
                              onVerticalDragUpdate: (d) =>
                                  rows.reorderBy(d.delta.dy),
                              onVerticalDragEnd: (_) => rows.reorderEnd(l),
                              child: TimelineLabelRow(
                                // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                                index: rows.order[i].layer,
                                depth: ws.depth(l),
                                row: drawn[i],
                                hidden: RowFlags(ws).isHidden(l.id),
                                solo: RowFlags(ws).isSolo(l.id),
                                lanes: l.kind == LayerKind.group
                                    ? ws.groupOpen(l.id)
                                    : l.keys.isEmpty &&
                                          linkTargets(ws, l.id).isEmpty &&
                                          !l.lined
                                    ? null
                                    : ws.lanesOpen(l.id),
                                onLanes: () => l.kind == LayerKind.group
                                    ? ws.turnGroup(l.id)
                                    : ws.twirl([l.id]),
                                onSelect: () =>
                                    HardwareKeyboard.instance.isShiftPressed
                                    // Shift selects every row from the last picked one to this one, as in After Effects.
                                    ? selectRange(ws, l.id)
                                    : HardwareKeyboard.instance.isMetaPressed
                                    ? selectAlso(ws, l.id)
                                    // Cmd adds this layer to the selection, or removes it.
                                    : ws.select(l.id),
                                onEye: () => RowFlags(ws).toggleHidden(l.id),
                                onSolo: () => RowFlags(ws).toggle('solo', l.id),
                                onLock: () => RowFlags(ws).toggle('lock', l.id),
                              ),
                            ),
                          ),
                      for (var i = 0; i < drawn.length; i++)
                        if (rows.order[i].value == null)
                          // The rename field is written over the label (Cmd+R).
                          ?renameField(
                            i,
                            ws.layers[rows.order[i].layer].id,
                            i * TimelineMetrics.row - top,
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ],
  );

  // The tracks area: the ruler, the painted rows with their pointer handling, the overview strip, and the playhead
  // drawn over them.
  Widget _tracks(
    WorkspaceController ws,
    List<TimelineRow> drawn,
  ) => LayoutBuilder(
    builder: (context, box) {
      viewport.layout(
        trackWidth: box.maxWidth,
        rowsHeight: math.max(
          0,
          box.maxHeight - TimelineMetrics.ruler - TimelineMetrics.overview,
        ),
        rows: drawn.length,
      );
      final v = viewport.view;
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContextMenu(
                key: rulerMenu,
                child: GestureDetector(
                  key: const ValueKey('ws-tl-ruler'),
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: pressingDevices,
                  onTapUp: (d) => rulerTap(
                    d.localPosition,
                  ), // Like Ableton Live's scrub area.
                  onDoubleTapDown: (d) => rulerDouble(d.localPosition),
                  onDoubleTap: () {},
                  onSecondaryTapDown: (d) => rulerRight(d.localPosition),
                  onPanDown: (d) => ruler.down(d.localPosition),
                  onPanUpdate: (d) => ruler.move(d.localPosition),
                  onPanEnd: (_) => ruler.end(),
                  onPanCancel: ruler.end,
                  child: SizedBox(
                    height: TimelineMetrics.ruler,
                    child: CustomPaint(
                      painter: TimelineRulerPainter(
                        view: v,
                        fps: WorkspaceController.fps,
                        workIn: ruler.workIn,
                        workOut: ruler.workOut,
                        markers: ruler.markers,
                        markColors: ruler.markerColors,
                        beats: media.beatsOf(ws),
                        tempo: ws.beats,
                        retimed: ruler.retimed,
                      ),
                      foregroundPainter: TimelineCachePainter(
                        view: v,
                        kept: ws.kept,
                      ), // Marks the frames cached on disk for playback.
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: drag.cursor,
                  onHover: (e) => drag.hover(e.localPosition),
                  child: TwoFingerGestures(
                    onWheel: scrollBy,
                    onPan: fingers,
                    onPinch: pinch,
                    child: ContextMenu(
                      key: trackMenu,
                      child: GestureDetector(
                        key: const ValueKey('ws-tl-tracks'),
                        behavior: HitTestBehavior.opaque,
                        supportedDevices: pressingDevices,
                        dragStartBehavior: DragStartBehavior.down,
                        onTapDown: (d) => drag.tapDown(d.localPosition),
                        onSecondaryTapDown: (d) => trackRight(d.localPosition),
                        onTapUp: (d) => drag.tapUp(d.localPosition), // Only fires once the gesture is known not to be a drag.
                        onPanStart: (d) => drag.down(d.localPosition),
                        onPanUpdate: (d) => drag.move(d.localPosition),
                        onPanEnd: (_) => drag.up(),
                        onPanCancel: () => drag.up(keep: false),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: TimelineTracksPainter(
                              rows: drawn,
                              view: v,
                              fps: WorkspaceController.fps,
                              vscroll: viewport.verticalScroll,
                              restAt: drag.snappedAt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ws.moment,
                builder: (_, frame, _) => TimelineOverview(
                  from: viewport.scroll,
                  to: viewport.scroll + viewport.visible,
                  frame: frame,
                  onDrag: (p) => overview(p, box.maxWidth),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: TimelineMetrics.overview,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    painter: TimelinePlayheadPainter(
                      view: v,
                      frame: ws.frame,
                      headTop: TimelineMetrics.band + 1,
                      moment: ws.moment,
                    ), // Repainted as the playhead moves; no widgets are rebuilt.
                  ),
                ),
              ),
            ),
          ),
          if (drag.selectionBox case (final a, final b)?)
            Positioned.fromRect(
              rect: Rect.fromPoints(
                a,
                b,
              ).shift(Offset(0, TimelineMetrics.ruler)),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WindowTokens.accent.withAlpha(36),
                    border: Border.all(color: WindowTokens.accent, width: 1),
                  ),
                ),
              ),
            ),
          // The flag name is edited in place, as wide as its text, like renaming a layer in Figma.
          if (naming case (final at, _)?)
            Positioned(
              left: v.x((at * WorkspaceController.fps).round()).roundToDouble(),
              top: TimelineMetrics.band + 2,
              height: 12,
              child: ListenableBuilder(
                listenable: markWords,
                builder: (_, child) => Container(
                  width: markerFlagWidth('${markWords.text}  '),
                  color: WindowTokens.toneText,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
                child: TextGestures(
                  key: const ValueKey('ws-tl-mark-name'),
                  field: (k) => EditableText(
                    key: k,
                    rendererIgnoresPointer: true,
                    controller: markWords,
                    focusNode: markFocus,
                    style: TextStyles.micro(Grey.g13)
                        .copyWith(fontWeight: FontWeight.w700),
                    cursorColor: Grey.g13,
                    backgroundCursorColor: Grey.g38,
                    selectionColor: Grey.g13.withValues(
                      alpha: .3,
                    ), // Highlight for selected text.
                    maxLines: 1,
                    onSubmitted: (_) => markFocus.unfocus(),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
