// The workspace's Timeline panel.
//
// It has the transport and timecode on top, layer labels beside the track area, a ruler with the work area, and the playhead.
// The project lives in WorkspaceController. This panel keeps only how it is viewed: zoom, scroll, loop, the row toggles and the work area.
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/ruler_marks.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_drag.dart';
import 'package:motolii/workspace/timeline/timeline_header.dart';
import 'package:motolii/workspace/timeline/timeline_media.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_requests.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_tracks.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';
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
  int lastFrame = -1;

  // The rows as laid out: each layer's own row, then, while it is expanded, a lane for each of its animated properties.
  // This follows Ableton's automation lanes (Live 12 manual 25.5), where Cmd shows every automated envelope in its own lane.
  // `value` is the property a lane shows. `aim` is a row naming the layer's target (linkTargets), with an empty value and no keyframes.
  List<({int layer, String? value, (String, String)? aim})> order = const [];

  // The properties of [l] that have keyframes, in the layer's own order.
  // Ableton does the same with "Show Automated Parameters Only". With Animate on, every property counts as moving, so its keyframes decide.
  List<String> _moving(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null) return const [];
    final moving = m.moving(t).toSet();
    return [
      for (final n in m.values(t))
        if (n.startsWith('js_line_') ||
            moving.contains(n) && m.keyTimes(t, n).isNotEmpty)
          n,
    ];
  }

  // The title of the inspector card that holds a property: an effect, or Transform and the like.
  String? laneCard(WorkspaceController ws, Layer l, String name) => [
    for (final (title, names) in ws.inside!.cards(int.parse(l.id)))
      if (names.contains(name)) title,
  ].firstOrNull;

  // The lane for one property: its keyframe times and values, read from the project snapshot without asking the engine.
  TimelineRow laneRow(WorkspaceController ws, Layer l, String name) {
    final m = ws.inside!,
        t = int.parse(l.id),
        at = m.keyTimes(t, name),
        vs = m.keyValues(t, name),
        flags = RowFlags(ws);
    final n = math.min(at.length, vs.length);
    final lo = vs.take(n).fold(double.infinity, math.min),
        hi = vs.take(n).fold(-double.infinity, math.max);
    return TimelineRow(
      name: name,
      kind: l.kind,
      inF: l.inF,
      outF: l.outF,
      keys: [
        for (var i = 0; i < n; i++) (at[i] * WorkspaceController.fps).round(),
      ],
      picked: const {},
      tone: l.tone,
      dim: flags.isHidden(l.id) || (flags.anySolo && !flags.isSolo(l.id)),
      locked: flags.isLocked(l.id),
      lane: [
        for (var i = 0; i < n; i++)
          (
            (at[i] * WorkspaceController.fps).round(),
            hi > lo ? (vs[i] - lo) / (hi - lo) : .5,
          ),
      ],
      laneWays: [
        for (var i = 0; i + 1 < n; i++)
          _wayShape(ws, m.easingOf(t, name, at[i])),
      ],
      laneOn: switch (ws.stretch) {
        final s? when s.layer == l.id && s.name == name => [
          for (var i = 0; i < n; i++) (at[i] * WorkspaceController.fps).round(),
        ].indexOf(s.from),
        _ => null,
      },
    );
  }

  // An easing's curve from 0 to 1, as drawn between keyframes.
  List<double> _wayShape(WorkspaceController ws, String way) =>
      way.isEmpty ? const [0, 1] : easeCurve(way, ws.inside!);

  @override
  void initState() {
    super.initState();
    viewport.addListener(_rebuild);
    media.addListener(_rebuild);
    ruler.addListener(_rebuild);
    slip.addListener(_rebuild);
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

  // The bar being dragged. Dragging the body slides it, and dragging an end trims it.
  // The timeline only records which part was grabbed and how far the pointer moved.
  // What that does to the layer (its limits, a video's start) is decided by the engine, and the bar is drawn from the engine's answer.
  ({String id, String part, double grab, bool moved})? bar;
  // The frames the drag can snap to, collected when the drag starts.
  Set<int> stops = const {};
  // The frame the drag has snapped to, where a guide line is drawn.
  int? restAt;

  // Snapping to [stops] and the beat grid at the present zoom, or null while Cmd is held, which turns snapping off.
  FrameSnap? _snapTo(Set<int> stops) => HardwareKeyboard.instance.isMetaPressed
      ? null
      : FrameSnap(
          stops: stops,
          beats: workspace!.beats,
          pixelsPerFrame: viewport.view.pixelsPerFrame,
        );

  // The drag distance [by] adjusted so that the nearest of [ends] lands on a snap stop, if one is close enough.
  // Where it landed is kept in [restAt].
  int _snapped(int by, List<int> ends) {
    final snapped = _snapTo(stops)?.snap(by, ends);
    restAt = snapped?.at;
    return snapped?.by ?? by;
  }

  // The dragged bar's in and out frames when the drag started.
  // A trim stops one frame short of an empty bar, because an empty bar cannot be seen, grabbed again or kept.
  // The project is as long as its longest layer.
  int barIn = 0, barOut = 0;

  // The cursor over the tracks shows what a drag would do: an end trims, the body slides, a keyframe slides, empty space draws a box.
  MouseCursor cursor = MouseCursor.defer;

  // The keyframe being dragged, together with the other selected keyframes. They slide in time while the playhead shows the position.
  ({List<SelectedKeyframe> keys, int grab, int by})? slide;
  // When and where a lane was last clicked, to detect a double-click.
  DateTime? lanePressed;
  Offset laneAt = Offset.zero;

  // The selection box dragged over empty track space, in any direction. Its corners are in track coordinates.
  // It selects the keyframes inside it, or else the layers whose bars it touches, like the marquee in Ableton and After Effects.
  (Offset, Offset)? selectionBox;

  void barDown(Offset p) {
    if (!grab(p)) setState(() => selectionBox = (p, p));
  }

  void _boxUp() {
    final b = selectionBox;
    setState(() => selectionBox = null);
    if (b == null) return;
    final ws = workspace!, v = viewport.view, r = Rect.fromPoints(b.$1, b.$2);
    // A click, not a box: the tap handler has already dealt with it.
    if (r.width < 4 && r.height < 4) return;
    final keys = <SelectedKeyframe>[], things = <String>[];
    for (var i = 0; i < order.length; i++) {
      // A box does not select points on a lane.
      if (order[i].value != null) continue;
      final l = ws.layers[order[i].layer],
          top = i * TimelineMetrics.row - viewport.verticalScroll;
      if (top + TimelineMetrics.row < r.top ||
          top > r.bottom ||
          RowFlags(ws).isLocked(l.id)) {
        continue;
      }
      for (final k in l.keys) {
        if (v.x(k) >= r.left && v.x(k) <= r.right) {
          keys.add((layer: l.id, frame: k));
        }
      }
      if (v.x(l.outF) >= r.left && v.x(l.inF) <= r.right) things.add(l.id);
    }
    if (keys.isNotEmpty) {
      ws.pickKeys(keys);
    } else if (things.isNotEmpty) {
      ws.clearKeys();
      ws.pickMany(things, inOrder: false);
    }
  }

  void barMove(Offset p) {
    if (selectionBox case (final from, _)?) {
      return setState(() => selectionBox = (from, p));
    }
    if (slide case final s?) {
      final by = _snapped(viewport.view.frameAt(p.dx).round() - s.grab, [
        s.grab,
      ]);
      setState(() => slide = (keys: s.keys, grab: s.grab, by: by));
      workspace!.frame = (s.grab + by).clamp(0, WorkspaceController.duration);
      return;
    }
    final h = bar, ws = workspace!, m = ws.inside;
    if (h == null || m == null) return;
    // Moves by whole frames.
    var by = (viewport.view.frameAt(p.dx) - h.grab).round();
    if (h.part == 'slip') {
      bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
      return slip.slipBy(ws, int.parse(h.id), by, barIn: barIn, barOut: barOut);
    }
    by = _snapped(by, [
      if (h.part != 'tail') barIn,
      if (h.part != 'head') barOut,
    ]);
    if (h.part == 'tail') by = math.max(by, barIn + 1 - barOut);
    if (h.part == 'head') by = math.min(by, barOut - 1 - barIn);
    m.dragUpdate(h.part, by / WorkspaceController.fps);
    bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
    ws.respan(h.id);
  }

  void barUp({bool keep = true}) {
    if (restAt != null) setState(() => restAt = null);
    if (selectionBox != null) {
      return keep ? _boxUp() : setState(() => selectionBox = null);
    }
    if (slide case final s?) {
      slide = null;
      if (keep) slideKeyframes(workspace!, s.keys, s.by);
      return;
    }
    final h = bar, ws = workspace!, m = ws.inside;
    bar = null;
    if (h == null || m == null) return;
    // Does not wait for the engine.
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0));
  }

  double lift = 0; // how far a label row has been carried up or down

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
    final away = ws.foldedAway, flags = RowFlags(ws);
    final sel = ws.selected,
        picks = ws.keys,
        lit = {
          ...ws.many,
          ...relationMembers(ws),
          for (final p in [?sel, ...ws.many]) ?away[p],
        };
    // The lit layers are those selected together, those moved by the selected relation, and the closed group a selected layer is in.

    order = [
      for (final (i, l) in ws.layers.indexed)
        if (!away.containsKey(l.id)) ...[
          (layer: i, value: null, aim: null),
          if (ws.aimsOpen(l.id))
            for (final a in linkTargets(ws, l.id))
              (layer: i, value: '', aim: a),
          if (ws.lanesOpen(l.id))
            for (final n in _moving(ws, l)) (layer: i, value: n, aim: null),
        ],
    ];
    final rows = <TimelineRow>[
      for (final o in order)
        if (o.value case final n?)
          laneRow(ws, ws.layers[o.layer], n)
        else if (ws.layers[o.layer] case final l)
          TimelineRow(
            name: l.name,
            kind: l.kind,
            inF: l.inF,
            outF: l.outF,
            keys: l.keys,
            stretches: l.stretches,
            picked: {
              for (final k in picks)
                if (k.layer == l.id) k.frame,
            },
            selected: l.id == sel || lit.contains(l.id),
            dim: flags.isHidden(l.id) || (flags.anySolo && !flags.isSolo(l.id)),
            locked: flags.isLocked(l.id),
            clipped: l.clipped,
            wave: media.waveOf(ws, l),
            frames: media.framesOf(ws, l),
            form: formOf(ws, l)?.$1,
            fill: formOf(ws, l)?.$2,
            outline: formOf(ws, l)?.$3 ?? false,
            tone: l.tone,
            mix: mixOf(ws, l.id),
            whole: slip.wholeOf(ws, l),
          ),
    ];
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
                      child: labels(ws, rows),
                    ),
                    SizedBox(
                      width: TimelineMetrics.divider,
                      child: ColoredBox(color: WindowTokens.ground),
                    ),
                    Expanded(child: tracks(ws, rows)),
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

// ---------------------------------------------------------------- header strip
