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

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/window_tokens.dart';
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
        SingleTickerProviderStateMixin,
        TimelineRequests<TimelinePane>,
        TimelineLabelsView<TimelinePane>,
        TimelineTracksView<TimelinePane> {
  late final Ticker _ticker = createTicker(_tick);
  // One closure, kept so that the listener removed is the one that was added.
  late final VoidCallback _listener = _changed;
  final _focus = FocusNode(debugLabel: 'timeline');
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

  @override
  void initState() {
    super.initState();
    viewport.addListener(_rebuild);
    media.addListener(_rebuild);
    ruler.addListener(_rebuild);
    _slip.addListener(_rebuild);
    drag.addListener(_rebuild);
    // Starts listening for requests from the app's commands (timeline_requests.dart).
    listenForRequests();
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
          (_) => mounted ? _changed() : null,
        );
      }
    }
  }

  @override
  void dispose() {
    workspace?.on[WorkspaceAspect.playing]!.removeListener(_listener);
    workspace?.moment.removeListener(_listener);
    _ticker.dispose();
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
      if (ws.frame >= WorkspaceController.duration) ws.frame = 0;
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
    _lastFrame = (ws.inside!.now * WorkspaceController.fps).round().clamp(
      0,
      WorkspaceController.duration,
    );
    ws.frame = _lastFrame;
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

  // ---------------------------------------------------------------- view

  // Draws the timeline again after one of the objects it owns has changed.
  void _rebuild() => setState(() {});

  @override
  void setZoom(double z, {int? anchor}) =>
      viewport.setZoom(z, anchor: anchor ?? workspace!.frame);

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
  void pinch(double by, Offset at) => setZoom(
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

  @override
  void overviewTo(Offset p, double w) {
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
                onToggle: _toggle,
                onStep: _step,
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
                      child: labels(ws, drawn),
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
