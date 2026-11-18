// The workspace's Timeline panel.
//
// It has the transport and timecode on top, layer labels beside the track area, a ruler with the work area, and the playhead.
// The project lives in WorkspaceController. This panel keeps only how it is viewed, each part in an object the State owns:
// the zoom and scroll (TimelineViewport), the rows as laid out (TimelineRows), the media read for them
// (TimelineMediaCache), and the drags in hand on the ruler (RulerMarks) and on the tracks (TrackDrag, SlipEdit).
// The State itself keeps what needs a widget: the ticker, the focus, the listeners and the widget tree.
import 'package:motolii/workspace/timeline/timeline_tracks_view.dart';
import 'package:motolii/workspace/timeline/timeline_labels_view.dart';

import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/ruler_marks.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_header.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_requests.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/track_drag.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

class TimelinePane extends StatefulWidget {
  const TimelinePane({super.key});
  @override
  State<TimelinePane> createState() => _TimelinePaneState();
}

class _TimelinePaneState extends State<TimelinePane>
    with
        TickerProviderStateMixin,
        TimelineRequests<TimelinePane>,
        TimelineLabelsView<TimelinePane>,
        TimelineTracksView<TimelinePane> {
  late final Ticker _ticker = createTicker(_tick);
  // One closure, kept so that the listener removed is the one that was added.
  late final VoidCallback _listener = _changed;
  final _focus = FocusNode(debugLabel: 'timeline');

  late final _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  )..addListener(_zoomStep);
  double _zoomFrom = 1, _zoomTo = 1;
  int _zoomAnchor = 0;
  @override
  WorkspaceController? workspace;

  /// The zoom, the scroll and the size of the track area.
  @override
  final viewport = TimelineViewport(() => WorkspaceController.duration);

  /// The beats, video frames, thumbnails and waveforms read for the rows.
  @override
  final media = TimelineMediaCache();

  /// Where a trimmed video's whole source lies along its row, and the drag that slips it.
  late final _slip = SlipEdit(media: media);

  /// The work area and the markers on the ruler, and the drag in hand there.
  @override
  late final ruler = RulerMarks(
    workspaceOf: () => workspace,
    viewport: viewport,
    snapTo: _snapTo,
  );

  /// The rows in the order they are laid out, and what each one shows.
  @override
  late final rows = TimelineRows(
    workspaceOf: () => workspace,
    viewport: viewport,
    media: media,
    slip: _slip,
  );

  /// The bar, keyframe or selection box being dragged on the tracks, and the cursor over them.
  @override
  late final drag = TrackDrag(
    workspaceOf: () => workspace,
    viewport: viewport,
    rows: rows,
    slip: _slip,
    snapTo: _snapTo,
  );
  int _lastFrame = -1;

  /// The width of the layer-name column, dragged by the divider between the names and the tracks.
  late double _labelWidth = TimelineMetrics.label;

  @override
  void initState() {
    super.initState();
    // viewport, ruler and drag repaint via the painters' repaint: parameter and ListenableBuilders;
    // only media and slip still need a widget rebuild (they feed the row data that the painters draw).
    media.addListener(_rebuild);
    _slip.addListener(_rebuild);
    HardwareKeyboard.instance.addHandler(_escapeKey);
    // Starts listening for requests from the app's commands (timeline_requests.dart).
    listenForRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws != workspace) {
      workspace?.on[WorkspaceAspect.playing]!.removeListener(_listener);
      workspace = ws..on[WorkspaceAspect.playing]!.addListener(_listener);
      if (ws.playing) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => mounted ? _changed() : null,
        );
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_escapeKey);
    workspace?.on[WorkspaceAspect.playing]!.removeListener(_listener);
    _ticker.dispose();
    _zoomAnim.dispose();
    viewport.dispose();
    media.dispose();
    ruler.dispose();
    _slip.dispose();
    drag.dispose();
    _focus.dispose();
    disposeRequests();
    super.dispose();
  }

  // ---------------------------------------------------------------- play

  void _changed() {
    final ws = workspace!;
    if (ws.playing && !_ticker.isActive) {
      _ticker.start();
      _lastFrame = -1;
      if (ws.frame >= WorkspaceController.duration) {
        ws.frame = 0;
      } else if (timeline_service.isLooping(ws)) {
        // When loop is on and the playhead is outside the work area, jump to its start so playback is not silent.
        final (wFrom, wTo) = ws.work;
        final wIn = (wFrom * WorkspaceController.fps).round();
        final wOut = (wTo * WorkspaceController.fps).round();
        if (wIn < wOut && (ws.frame < wIn || ws.frame >= wOut)) {
          ws.frame = wIn;
        }
      }
    } else if (!ws.playing && _ticker.isActive) {
      _ticker.stop();
    }
    _follow(ws.frame);
  }

  // The tick is wrapped in a named span so it shows up in Flutter's timeline.
  void _tick(Duration e) => Timeline.timeSync('ws tick', () => _tickNow(e));

  void _tickNow(Duration e) {
    final ws = workspace!;
    // The engine keeps the clock. The playhead shows the time of the last frame it drew.
    _lastFrame = (timeline_service.clockSeconds(ws) * WorkspaceController.fps)
        .round()
        .clamp(0, WorkspaceController.duration);
    ws.frame = _lastFrame;
    _follow(_lastFrame);
  }

  void _toggle() {
    final ws = workspace!;
    ws.playing = !ws.playing;
  }

  void _step(int d) {
    final ws = workspace!;
    ws.playing = false;
    ws.frame = ws.frame + d;
  }

  bool _escapeKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      final had =
          (workspace?.live.isOpen ?? false) || drag.selectionBox != null;
      ruler.cancel();
      drag.up(keep: false);
      return had;
    }
    return false;
  }

  // ---------------------------------------------------------------- view

  // Draws the timeline again after one of the objects it owns has changed.
  void _rebuild() => setState(() {});

  @override
  void setZoom(double z, {int? anchor}) {
    _zoomFrom = viewport.zoom;
    _zoomTo = z.clamp(1.0, TimelineMetrics.maxZoom);
    _zoomAnchor = anchor ?? workspace!.frame;
    _zoomAnim.forward(from: 0);
  }

  void _zoomStep() {
    final t = Curves.easeOut.transform(_zoomAnim.value);
    final logFrom = math.log(_zoomFrom), logTo = math.log(_zoomTo);
    viewport.setZoom(
      math.exp(logFrom + (logTo - logFrom) * t),
      anchor: _zoomAnchor,
    );
  }

  /// Keeps the playhead in view when zoomed in: the view pages along as play or a scrub carries it off the edge.
  void _follow(int f) {
    if (!mounted) return;
    viewport.follow(f);
  }

  /// A two-finger trackpad slide scrolls the tracks like a wheel, in the opposite direction, so the content follows the fingers.
  /// A pinch zooms around the frame under the fingers, as in Final Cut, Cavalry and Theatre.js.
  @override
  void fingers(Offset by, Offset _) => scrollBy(-by);
  @override
  void pinch(double by, Offset at) => viewport.setZoom(
    viewport.zoom * by,
    anchor: viewport.view
        .frameAt(at.dx)
        .round()
        .clamp(0, WorkspaceController.duration),
  );

  @override
  void scrollBy(Offset d) {
    final sideways =
        HardwareKeyboard.instance.isShiftPressed || d.dx.abs() > d.dy.abs();
    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed) {
      viewport.setZoom(
        viewport.zoom * math.pow(1.0015, -d.dy),
        anchor: workspace!.frame,
      );
    } else if (sideways) {
      viewport.scrollBy(d.dx.abs() > d.dy.abs() ? d.dx : d.dy);
    } else {
      viewport.scrollRowsBy(d.dy);
    }
  }

  FrameSnap? _snapTo(List<SnapTarget> targets) =>
      HardwareKeyboard.instance.isMetaPressed
      ? null
      : FrameSnap(
          targets: targets,
          beats: workspace!.beats,
          pixelsPerFrame: viewport.view.pixelsPerFrame,
        );

  @override
  void overviewTo(Offset p, double w) {
    final f = (p.dx - 4) / (w - 8) * WorkspaceController.duration;
    viewport.scrollTo(f - viewport.visible / 2);
  }

  @override
  void overviewZoom(double zoom, int anchor) =>
      viewport.setZoom(zoom, anchor: anchor);

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    ruler.takeWorkArea();
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.layers,
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
                loop: timeline_service.isLooping(ws),
                zoom: viewport.zoom,
                onToggle: _toggle,
                onStep: _step,
                onLoop: () =>
                    setState(() => timeline_service.toggleLooping(ws)),
                onZoom: setZoom,
                onMark: setMark,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: Stack(
                        children: [
                          // The labels scroll with the rows via viewport, without rebuilding the whole timeline.
                          ListenableBuilder(
                            listenable: viewport,
                            builder: (_, _) => labels(ws, drawn),
                          ),
                          // The resize handle overlays the header's right edge (its empty padding), so dragging it
                          // resizes the column without adding any gap between the names and the tracks.
                          Positioned(
                            top: 0,
                            right: 0,
                            width: TimelineMetrics.grip,
                            height: TimelineMetrics.ruler,
                            child: _ResizeHandle(
                              onDrag: (dx) => setState(
                                () => _labelWidth = (_labelWidth + dx).clamp(
                                  TimelineMetrics.labelMin,
                                  TimelineMetrics.labelMax,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: TimelineMetrics.divider,
                      child: ColoredBox(color: WindowTokens.ground),
                    ),
                    Expanded(child: tracks(ws, drawn)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handle that resizes the name column, overlaid on the header's right edge (the "LAYER n" row). It is invisible until
/// hovered, when an accent line lights at the column edge beside the divider to show the grab point; dragged left or right
/// it resizes the column, as a table column is resized by its heading. It covers only the header, so the drag is only there.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.onDrag});

  /// The pointer's horizontal movement during a drag, in logical pixels.
  final ValueChanged<double> onDrag;
  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hot = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    onEnter: (_) => setState(() => _hot = true),
    onExit: (_) => setState(() => _hot = false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: _hot ? 2.0 : 0.0,
          height: double.infinity,
          color: WindowTokens.accentInk,
        ),
      ),
    ),
  );
}
