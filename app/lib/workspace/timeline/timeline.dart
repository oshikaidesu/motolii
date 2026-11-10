// The workspace's Timeline panel.
//
// It has the transport and timecode on top, layer labels beside the track area, a ruler with the work area, and the playhead.
// The project lives in Ws. This panel keeps only how it is viewed: zoom, scroll, loop, the row toggles and the work area.
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async' show Timer;
import 'dart:developer' show Timeline;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout, DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiMoment, MotoliiWrites, MotoliiQuestions, MotoliiShelves, mediaSecondsOf;
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, IconPress;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/commands/command_actions.dart' show wsTimelineAsk, wsAskRename, wsAskTimeline, wsMarkPicked;
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/timeline_painters.dart' show TpGlyph;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/timeline/timeline_kept.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
part 'timeline_asked.dart';
part 'timeline_view.dart';
part 'timeline_drag.dart';
part 'timeline_rows.dart';
part 'timeline_ruler.dart';
part 'timeline_snap.dart';
part 'timeline_slip.dart';
part 'timeline_header.dart';
part 'timeline_labels.dart';
part 'timeline_overview.dart';
part 'timeline_media.dart';
part 'timeline_tracks.dart';

class WsTimeline extends StatefulWidget {
  const WsTimeline({super.key});
  @override
  State<WsTimeline> createState() => _WsTimelineState();
}

class _WsTimelineState extends State<WsTimeline> with SingleTickerProviderStateMixin, _TimelineAsked {
  late final Ticker _ticker = createTicker(_tick);
  // One closure, used for both adding and removing the listener.
  // Tearing off an extension method gives a new closure each time, so removeListener would never match.
  late final VoidCallback _listener = _changed;
  final _focus = FocusNode(debugLabel: 'timeline');
  Ws? _ws;
  double _zoom = 1, _scroll = 0, _vscroll = 0, _trackW = 1000, _rowsH = 200;
  int _workIn = 12, _workOut = 228;
  int _last = -1;

  // The rows as laid out: each layer's own row, then, while it is expanded, a lane for each of its animated properties.
  // This follows Ableton's automation lanes (Live 12 manual 25.5), where Cmd shows every automated envelope in its own lane.
  // `value` is the property a lane shows. `aim` is a row naming the layer's target (wsTargets), with an empty value and no keyframes.
  List<({int layer, String? value, (String, String)? aim})> _order = const [];

  // The properties of [l] that have keyframes, in the layer's own order.
  // Ableton does the same with "Show Automated Parameters Only". With Animate on, every property counts as moving, so its keyframes decide.
  List<String> _moving(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null) return const [];
    final moving = m.moving(t).toSet();
    return [
      for (final n in m.values(t))
        if (n.startsWith('js_line_') || moving.contains(n) && m.keyTimes(t, n).isNotEmpty) n,
    ];
  }

  // The title of the inspector card that holds a property: an effect, or Transform and the like.
  String? _laneCard(Ws ws, WsLayer l, String name) => [
    for (final (title, names) in ws.inside!.cards(int.parse(l.id)))
      if (names.contains(name)) title,
  ].firstOrNull;

  // The lane for one property: its keyframe times and values, read from the project snapshot without asking the engine.
  WtRow _laneRow(Ws ws, WsLayer l, String name) {
    final m = ws.inside!, t = int.parse(l.id), at = m.keyTimes(t, name), vs = m.keyValues(t, name);
    final n = math.min(at.length, vs.length);
    final lo = vs.take(n).fold(double.infinity, math.min), hi = vs.take(n).fold(-double.infinity, math.max);
    return WtRow(
      name: name,
      kind: l.kind,
      inF: l.inF,
      outF: l.outF,
      keys: [for (var i = 0; i < n; i++) (at[i] * Ws.fps).round()],
      picked: const {},
      tone: l.tone,
      dim: _isHidden(ws, l.id) || (_anySolo(ws) && !_isSolo(ws, l.id)),
      locked: _isLocked(ws, l.id),
      lane: [for (var i = 0; i < n; i++) ((at[i] * Ws.fps).round(), hi > lo ? (vs[i] - lo) / (hi - lo) : .5)],
      laneWays: [for (var i = 0; i + 1 < n; i++) _wayShape(ws, m.easingOf(t, name, at[i]))],
      laneOn: switch (ws.stretch) {
        final s? when s.layer == l.id && s.name == name => [for (var i = 0; i < n; i++) (at[i] * Ws.fps).round()].indexOf(s.from),
        _ => null,
      },
    );
  }

  // An easing's curve from 0 to 1, as drawn between keyframes.
  List<double> _wayShape(Ws ws, String way) => way.isEmpty ? const [0, 1] : easeCurve(way, ws.inside!);

  @override
  void initState() {
    super.initState();
    // Starts listening for requests from the app's commands (timeline_asked.dart).
    _hearAsks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WsScope.read(context);
    if (ws != _ws) {
      _ws?.on[WsAspect.playing]!.removeListener(_listener);
      _ws?.moment.removeListener(_listener);
      _ws = ws..on[WsAspect.playing]!.addListener(_listener);
      ws.moment.addListener(_listener);
      if (ws.playing) SchedulerBinding.instance.addPostFrameCallback((_) => mounted ? _changed() : null);
    }
  }

  @override
  void dispose() {
    _ws?.on[WsAspect.playing]!.removeListener(_listener);
    _ws?.moment.removeListener(_listener);
    _ticker.dispose();
    _focus.dispose();
    _stopAsks();
    _markWords.dispose();
    _markFocus.dispose();
    super.dispose();
  }

  void _setZoom(double z, {int? anchor}) {
    final nz = z.clamp(1.0, WtM.maxZoom);
    final a = anchor ?? _ws!.frame, ax = _view.x(a);
    setState(() {
      _zoom = nz;
      _scroll = _clampScroll(a - (ax - WtM.padL) / (_fit * nz));
    });
  }

  /// Keeps the playhead in view when zoomed in: the view pages along as play or a scrub carries it off the edge.
  void _follow(int f) {
    if (_zoom <= 1 || !mounted) return;
    final v = _view, x = v.x(f);
    if (x >= 0 && x <= _trackW - WtM.padR) return;
    setState(() => _scroll = _clampScroll(f - _visible * .1));
  }

  /// A two-finger trackpad slide scrolls the tracks like a wheel, in the opposite direction, so the content follows the fingers.
  /// A pinch zooms around the frame under the fingers, as in Final Cut, Cavalry and Theatre.js.
  void _fingers(Offset by, Offset _) => _scrollBy(-by);
  void _pinch(double by, Offset at) => _setZoom(_zoom * by, anchor: _view.frameAt(at.dx).round().clamp(0, Ws.duration));

  void _scrollBy(Offset d) {
    final sideways = HardwareKeyboard.instance.isShiftPressed || d.dx.abs() > d.dy.abs();
    if (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed) {
      _setZoom(_zoom * math.pow(1.0015, -d.dy));
    } else if (sideways) {
      setState(() => _scroll = _clampScroll(_scroll + (d.dx.abs() > d.dy.abs() ? d.dx : d.dy) / _view.ppf));
    } else {
      setState(() => _vscroll = _vscroll + d.dy);
    }
  }

  // The bar being dragged. Dragging the body slides it, and dragging an end trims it.
  // The timeline only records which part was grabbed and how far the pointer moved.
  // What that does to the layer (its limits, a video's start) is decided by the engine, and the bar is drawn from the engine's answer.
  ({String id, String part, double grab, bool moved})? _bar;
  // The frames the drag can snap to, collected when the drag starts (timeline_snap.dart).
  Set<int> _stops = const {};
  // The frame the drag has snapped to, where a guide line is drawn.
  int? _restAt;
  // The whole video's extent when the drag started (timeline_slip.dart).
  (int, int)? _barWhole;
  final _filmSeconds = <String, double>{};
  // The dragged bar's in and out frames when the drag started.
  // A trim stops one frame short of an empty bar, because an empty bar cannot be seen, grabbed again or kept.
  // The project is as long as its longest layer.
  int _barIn = 0, _barOut = 0;

  // The cursor over the tracks shows what a drag would do: an end trims, the body slides, a keyframe slides, empty space draws a box.
  MouseCursor _cursor = MouseCursor.defer;

  // The keyframe being dragged, together with the other selected keyframes. They slide in time while the playhead shows the position.
  ({List<WsKey> keys, int grab, int by})? _slide;
  // When and where a lane was last clicked, to detect a double-click.
  DateTime? _lanePressed;
  Offset _laneAt = Offset.zero;

  // The selection box dragged over empty track space, in any direction. Its corners are in track coordinates.
  // It selects the keyframes inside it, or else the layers whose bars it touches, like the marquee in Ableton and After Effects.
  (Offset, Offset)? _box;

  void _barDown(Offset p) {
    if (!_grab(p)) setState(() => _box = (p, p));
  }

  void _boxUp() {
    final b = _box;
    setState(() => _box = null);
    if (b == null) return;
    final ws = _ws!, v = _view, r = Rect.fromPoints(b.$1, b.$2);
    // A click, not a box: the tap handler has already dealt with it.
    if (r.width < 4 && r.height < 4) return;
    final keys = <WsKey>[], things = <String>[];
    for (var i = 0; i < _order.length; i++) {
      // A box does not select points on a lane.
      if (_order[i].value != null) continue;
      final l = ws.layers[_order[i].layer], top = i * WtM.row - _vscroll;
      if (top + WtM.row < r.top || top > r.bottom || _isLocked(ws, l.id)) continue;
      for (final k in l.keys) {
        if (v.x(k) >= r.left && v.x(k) <= r.right) keys.add((layer: l.id, frame: k));
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

  void _barMove(Offset p) {
    if (_box case (final from, _)?) return setState(() => _box = (from, p));
    if (_slide case final s?) {
      final by = _rested(_view.frameAt(p.dx).round() - s.grab, [s.grab]);
      setState(() => _slide = (keys: s.keys, grab: s.grab, by: by));
      _ws!.frame = (s.grab + by).clamp(0, Ws.duration);
      return;
    }
    final h = _bar, ws = _ws!, m = ws.inside;
    if (h == null || m == null) return;
    // Moves by whole frames.
    var by = (_view.frameAt(p.dx) - h.grab).round();
    if (h.part == 'slip') {
      _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
      return _slip(ws, int.parse(h.id), by);
    }
    by = _rested(by, [if (h.part != 'tail') _barIn, if (h.part != 'head') _barOut]);
    if (h.part == 'tail') by = math.max(by, _barIn + 1 - _barOut);
    if (h.part == 'head') by = math.min(by, _barOut - 1 - _barIn);
    m.dragUpdate(h.part, by / Ws.fps);
    _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
    ws.respan(h.id);
  }

  void _barUp({bool keep = true}) {
    if (_restAt != null) setState(() => _restAt = null);
    if (_box != null) return keep ? _boxUp() : setState(() => _box = null);
    if (_slide case final s?) {
      _slide = null;
      if (keep) wsSlideKeys(_ws!, s.keys, s.by);
      return;
    }
    final h = _bar, ws = _ws!, m = ws.inside;
    _bar = null;
    if (h == null || m == null) return;
    // Does not wait for the engine.
    ws.after(m.later('drag_end', number: keep && h.moved ? 1 : 0));
  }

  double _lift = 0; // how far a label row has been carried up or down

  int? _workDrag; // 0 in, 1 out, 2 both, null scrub
  double _workGrab = 0;

  // The project's markers on the ruler, which work like Ableton Live's locators (see timeline_asked.dart).
  // A right-click adds one, a click selects it and moves the playhead there, and Cmd+R renames it.
  // A marker can be dragged by its flag and keeps its name. Dragging it off the ruler, up or down, deletes it.
  // Each of these is one undo step.
  (double, String)? _markHeld;
  int _markTo = 0;
  // Where on its flag the marker was grabbed, in frames.
  // It is kept during the drag, as Live does for locators (6.4) and as _workGrab does for the work area.
  // Without it the marker jumped to the pointer, and one grabbed by the end of its name moved 0.47 s.
  double _markGrab = 0;
  final _rulerMenu = GlobalKey<WsMenuState>();
  // The context menu of a bar (see _trackRight in timeline_asked.dart).
  final _trackMenu = GlobalKey<WsMenuState>();
  final _labelMenu = GlobalKey<WsMenuState>();
  bool _markOff = false;
  (double, String)? _naming;
  final _markWords = TextEditingController();
  // Commits the marker name when the field loses focus.
  late final FocusNode _markFocus = FocusNode()..addListener(() => _markFocus.hasFocus ? null : _named());

  void _named() {
    final was = _naming, ws = _ws!, words = _markWords.text.trim();
    if (was == null) return;
    setState(() => _naming = null);
    if (words.isNotEmpty && words != was.$2 && ws.inside != null) ws.after(ws.inside!.later('mark', number: was.$1, word: words));
  }

  void _rulerMove(Offset p) {
    final f = _view.frameAt(p.dx).round();
    if (_markHeld != null) {
      return setState(() {
        _markTo = (_view.frameAt(p.dx) - _markGrab).round().clamp(0, Ws.duration);
        // Dragged off the ruler: the marker is deleted on release.
        _markOff = p.dy < -WtM.ruler * .6 || p.dy > WtM.ruler * 1.6;
      });
    }
    switch (_workDrag) {
      case 0:
        // The work area is at least half a second long, so it cannot be dragged out of sight.
        setState(() => _workIn = f.clamp(0, _workOut - Ws.fps ~/ 2));
      case 1:
        setState(() => _workOut = f.clamp(_workIn + Ws.fps ~/ 2, Ws.duration));
      case 2:
        final len = _workOut - _workIn, a = (_view.frameAt(p.dx) - _workGrab).round().clamp(0, Ws.duration - len);
        setState(() {
          _workIn = a;
          _workOut = a + len;
        });
      default:
        // As in After Effects, holding Shift while dragging the time indicator snaps it to what it passes.
        final shift = HardwareKeyboard.instance.isShiftPressed;
        if (shift) _stops = _ws!.stops();
        _ws!.frame = shift ? _restOn(f) ?? f : f;
    }
  }

  /// Ends a drag on the ruler. The work area becomes the project's on release, as one undo step.
  void _workDragEnd() {
    final m = _ws?.inside;
    if (_markHeld case (final at, final name)?) {
      _markHeld = null;
      final to = _markTo / Ws.fps;
      if (_markOff) {
        _ws!.after(m!.later('mark', number: at));
      } else if ((to - at).abs() >= 0.5 / Ws.fps) {
        // Moved: one undo step, and the name is kept.
        m!.later('together', number: 1);
        m.later('mark', number: at);
        m.later('mark', number: to, word: name);
        // The colour moves with the marker.
        if (_ws!.markColors[at] case final k?) m.later('mark_colour', number: to, word: '$k');
        _ws!.after(m.later('together'));
      } else {
        // Released where it was grabbed, so a small shake is not a drag. Treated as a click, like _rulerTap.
        wsMarkPicked.value = (at, name);
        _ws!
          ..playing = false
          ..frame = _markTo;
      }
      setState(() {});
      return;
    }
    if (_workDrag != null) _ws!.after(m!.later('work', number: _workIn / Ws.fps, word: '${_workOut / Ws.fps}'));
    _workDrag = null;
  }

  void _overview(Offset p, double w) {
    final f = (p.dx - 4) / (w - 8) * Ws.duration;
    setState(() => _scroll = _clampScroll(f - _visible / 2));
  }

  // ---------------------------------------------------------------- build

  // The videos' beats (from their Beats property, computed by the engine).
  // They are requested from the engine on another isolate, only when the project changes, and shown when they arrive.
  (int, List<int>)? _beats;
  int? _beatsAsked;
  // A video's waveform on its bar: read once on another isolate, then laid on the project's frames where the video plays.
  // It is requested again only when the project changes.
  // A video's thumbnails on its bar: one frame from the middle of each sixth of the video, whatever its start or speed.
  // The engine makes them small (GStreamer, on another isolate) and the app reads them as images.
  // They are requested again only when the project changes.
  final _frames = <String, (Object, List<ui.Image>?)>{};
  final _framesAsked = <String, Object>{};
  // Per layer id: the project read, the from and to frames, and the loudness of each frame.
  final _waves = <String, (int, int, int, List<double>?)>{};
  final _asked = <String>{};
  final _waveAsked = <String, (int, int, int)>{};
  @override
  Widget build(BuildContext context) {
    if (_workDrag == null) {
      // Takes the project's work area.
      final (from, to) = _ws!.work;
      _workIn = (from * Ws.fps).round();
      _workOut = (to * Ws.fps).round();
    }
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked, WsAspect.animating});
    final away = ws.foldedAway;
    final sel = ws.selected,
        picks = ws.keys,
        lit = {
          ...ws.many,
          ...wsMembersOf(ws),
          for (final p in [?sel, ...ws.many]) ?away[p],
        };
    // The lit layers are those selected together, those moved by the selected relation, and the closed group a selected layer is in.

    _order = [
      for (final (i, l) in ws.layers.indexed)
        if (!away.containsKey(l.id)) ...[
          (layer: i, value: null, aim: null),
          if (ws.aimsOpen(l.id))
            for (final a in wsTargets(ws, l.id)) (layer: i, value: '', aim: a),
          if (ws.lanesOpen(l.id))
            for (final n in _moving(ws, l)) (layer: i, value: n, aim: null),
        ],
    ];
    final rows = <WtRow>[
      for (final o in _order)
        if (o.value case final n?)
          _laneRow(ws, ws.layers[o.layer], n)
        else if (ws.layers[o.layer] case final l)
          WtRow(
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
            dim: _isHidden(ws, l.id) || (_anySolo(ws) && !_isSolo(ws, l.id)),
            locked: _isLocked(ws, l.id),
            clipped: l.clipped,
            wave: _waveOf(ws, l),
            frames: _framesOf(ws, l),
            form: _formOf(ws, l)?.$1,
            fill: _formOf(ws, l)?.$2,
            outline: _formOf(ws, l)?.$3 ?? false,
            tone: l.tone,
            mix: _mixOf(ws, l.id),
            whole: _wholeOf(ws, l),
          ),
    ];
    return Focus(
      focusNode: _focus,
      child: TapRegion(
        onTapInside: (_) => _focus.requestFocus(),
        child: ColoredBox(
          color: WsT.body,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                ws: ws,
                loop: ws.inside!.looping,
                zoom: _zoom,
                onToggle: _toggle,
                onStep: _step,
                onLoop: () => setState(() => ws.inside!.looping = !ws.inside!.looping),
                onZoom: _setZoom,
                onMark: _setMark,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: WtM.label, child: _labels(ws, rows)),
                    SizedBox(
                      width: WtM.divider,
                      child: ColoredBox(color: WsT.ground),
                    ),
                    Expanded(child: _tracks(ws, rows)),
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
