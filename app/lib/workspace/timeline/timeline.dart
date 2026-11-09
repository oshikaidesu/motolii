// The workspace's Timeline panel: transport + timecode on top, layer labels beside the track area, a ruler with the work area, the playhead.
// The document lives in Ws; this panel keeps only how it looks at it (zoom, scroll, loop, the row toggles, the work area).
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart' show easeCurve;

import 'dart:async' show Timer;
import 'dart:developer' show Timeline;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout, DragStartBehavior, PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../skin/forms/forms.dart';
import '../../bridge/motolii.dart' show Motolii, mediaSecondsOf;
import '../../widgets/two_fingers.dart';
import '../commands/command_actions.dart' show wsTimelineAsk, wsAskRename, wsAskTimeline, wsMarkPicked;
import '../../widgets/timeline_painters.dart' show TpGlyph, TpGlyphPainter;
import '../../skin/tokens.dart';
import '../edits/keyframe_edits.dart';
import '../commands/keymap.dart' show CommandIntent;
import 'timeline_kept.dart';
import 'timeline_paint.dart';
import '../edits/make_relation.dart';
import '../state/state.dart';
import '../commands/context_menu.dart';
import '../../widgets/text_gestures.dart';
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
  late final VoidCallback _listener = _changed; // (one closure, added and removed: an extension's method torn off is a new closure each time, never equal to the last, so removing it took nothing off)
  final _focus = FocusNode(debugLabel: 'timeline');
  Ws? _ws;
  double _zoom = 1, _scroll = 0, _vscroll = 0, _trackW = 1000, _rowsH = 200;
  int _workIn = 12, _workOut = 228;
  int _last = -1;

  // The rows as laid: each layer's own, then, while it stands open, a lane for each of its values that moves (Ableton's
  // automation lanes, Live 12 manual 25.5: with Cmd, every automated envelope in a lane of its own). value: the lane's.
  List<({int layer, String? value, (String, String)? aim})> _order = const []; // (aim: a row saying what the layer aims at, wsTargets; its value '', no keys)

  // A layer's values that have keys, in the thing's own order of them (Ableton lays out the automated ones: "Show
  // Automated Parameters Only"; with Animate on every value is said to move, so its keys tell).
  List<String> _moving(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null) return const [];
    final moving = m.moving(t).toSet();
    return [
      for (final n in m.values(t))
        if (n.startsWith('js_line_') || moving.contains(n) && m.keyMoments(t, n).isNotEmpty) n,
    ];
  }

  // The card a lane's value stands on: the effect it is a knob of, or Transform and the like.
  String? _laneCard(Ws ws, WsLayer l, String name) => [
    for (final (title, names) in ws.inside!.cards(int.parse(l.id)))
      if (names.contains(name)) title,
  ].firstOrNull;

  // A value's lane: its keys where they are and what they hold, read from the document's picture (nothing asked of the inside).
  WtRow _laneRow(Ws ws, WsLayer l, String name) {
    final m = ws.inside!, t = int.parse(l.id), at = m.keyMoments(t, name), vs = m.keyValues(t, name);
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
      laneWays: [for (var i = 0; i + 1 < n; i++) _wayShape(ws, m.wayOf(t, name, at[i]))],
      laneOn: switch (ws.stretch) {
        final s? when s.layer == l.id && s.name == name => [for (var i = 0; i < n; i++) (at[i] * Ws.fps).round()].indexOf(s.from),
        _ => null,
      },
    );
  }

  // A way's shape from 0 to 1, as the bar's stretches are drawn.
  List<double> _wayShape(Ws ws, String way) => way.isEmpty ? const [0, 1] : easeCurve(way, ws.inside!);

  @override
  void initState() {
    super.initState();
    _hearAsks(); // (the window's keys heard: timeline_asked.dart)
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

  void _wheel(PointerSignalEvent e) {
    if (e is PointerScrollEvent) _scrollBy(e.scrollDelta);
  }

  /// A trackpad's two fingers: they carry the tracks as a wheel does, the other way (the content goes with the fingers);
  /// a pinch zooms about the frame under them (Final Cut's, Cavalry's, Theatre.js's).
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

  // Joined: a bar held by a hand: by its body it slides, by an end it is cut there. The timeline only says which part
  // is held and how many seconds the hand has gone; what that does to the thing (its limits, a film's head) is the
  // inside's, and the bar is drawn from what the inside then says.
  ({String id, String part, double grab, bool moved})? _bar;
  Set<int> _stops = const {}; // (what the hand may come to rest on, taken when it took hold: timeline_snap.dart)
  int? _restAt; // (where it has, its line drawn there)
  (int, int)? _barWhole; // (the held film whole when it was taken: timeline_slip.dart)
  final _filmSeconds = <String, double>{};
  int _barIn = 0, _barOut = 0; // (the held bar's ends when it was taken: a cut stops one frame short of nothing, since a bar cut to nothing cannot be seen, taken again, or kept: the document is as long as its longest thing)

  // The pointer over a bar says what it would do: an end cuts, the body slides, a key slides; the room between draws a box.
  MouseCursor _cursor = MouseCursor.defer;

  // A key held by a hand: it (and the keys picked with it) slides in time; the playhead shows where, let go it is so.
  ({List<WsKey> keys, int grab, int by})? _slide;
  DateTime? _lanePressed; // (when and where a lane was last pressed: a second press there is a double one)
  Offset _laneAt = Offset.zero;

  // A box drawn over the empty room of the tracks (any direction): the keys inside it are picked, else the things whose
  // bars it touches (Ableton's and After Effects' marquee). Corners, in the tracks' own points.
  (Offset, Offset)? _box;

  void _barDown(Offset p) {
    if (!_grab(p)) setState(() => _box = (p, p));
  }

  void _boxUp() {
    final b = _box;
    setState(() => _box = null);
    if (b == null) return;
    final ws = _ws!, v = _view, r = Rect.fromPoints(b.$1, b.$2);
    if (r.width < 4 && r.height < 4) return; // (a click, not a box: the tap has done it)
    final keys = <WsKey>[], things = <String>[];
    for (var i = 0; i < _order.length; i++) {
      if (_order[i].value != null) continue; // (a lane's points are not picked by a box)
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
    var by = (_view.frameAt(p.dx) - h.grab).round(); // (by whole frames)
    if (h.part == 'slip') {
      _bar = (id: h.id, part: h.part, grab: h.grab, moved: true);
      return _slip(ws, int.parse(h.id), by);
    }
    by = _rested(by, [if (h.part != 'tail') _barIn, if (h.part != 'head') _barOut]);
    if (h.part == 'tail') by = math.max(by, _barIn + 1 - _barOut);
    if (h.part == 'head') by = math.min(by, _barOut - 1 - _barIn);
    m.carry(h.part, by / Ws.fps);
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
    ws.after(m.later('let_go', number: keep && h.moved ? 1 : 0)); // (let go without waiting)
  }

  double _lift = 0; // how far a label row has been carried up or down

  int? _workDrag; // 0 in, 1 out, 2 both, null scrub
  double _workGrab = 0;

  // The document's marks on the ruler, as Ableton Live's locators (timeline_asked.dart: a right click puts one, a click
  // picks and goes to one, Cmd+R names it); one is carried along by its flag (its name kept), and carried off the
  // ruler, up or down, it is taken away. Each one step.
  (double, String)? _markHeld;
  int _markTo = 0;
  double _markGrab = 0; // (where on its flag it was taken, in frames: kept while carried, as Live's locators are dragged (6.4) and as the work area here keeps _workGrab; carried to the hand's own spot, one taken by its name's end jumped 0.47 s)
  final _rulerMenu = GlobalKey<WsMenuState>();
  final _trackMenu = GlobalKey<WsMenuState>(); // (a bar's own menu: timeline_asked.dart _trackRight)
  final _labelMenu = GlobalKey<WsMenuState>();
  bool _markOff = false;
  (double, String)? _naming;
  final _markWords = TextEditingController();
  late final FocusNode _markFocus = FocusNode()..addListener(() => _markFocus.hasFocus ? null : _named()); // (the field left: the name said)

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
        _markOff = p.dy < -WtM.ruler * .6 || p.dy > WtM.ruler * 1.6; // (carried off the ruler: taken away when let go)
      });
    }
    switch (_workDrag) {
      case 0:
        setState(
          () => _workIn = f.clamp(0, _workOut - Ws.fps ~/ 2),
        ); // (never shut to nothing: half a second at least, so the document cannot be dragged out of sight)
      case 1:
        setState(() => _workOut = f.clamp(_workIn + Ws.fps ~/ 2, Ws.duration));
      case 2:
        final len = _workOut - _workIn, a = (_view.frameAt(p.dx) - _workGrab).round().clamp(0, Ws.duration - len);
        setState(() {
          _workIn = a;
          _workOut = a + len;
        });
      default:
        final shift = HardwareKeyboard.instance.isShiftPressed; // (After Effects': Shift held while the time indicator is dragged, it rests on what it passes)
        if (shift) _stops = _ws!.stops();
        _ws!.frame = shift ? _restOn(f) ?? f : f;
    }
  }

  /// Joined: the work area carried is the document's when the hand lets go (one step).
  void _workDragEnd() {
    final m = _ws?.inside;
    if (_markHeld case (final at, final name)?) {
      _markHeld = null;
      final to = _markTo / Ws.fps;
      if (_markOff) {
        _ws!.after(m!.later('mark', number: at));
      } else if ((to - at).abs() >= 0.5 / Ws.fps) {
        // (moved: one step, its name kept)
        m!.later('together', number: 1);
        m.later('mark', number: at);
        m.later('mark', number: to, word: name);
        if (_ws!.markColours[at] case final k?) m.later('mark_colour', number: to, word: '$k'); // (its colour with it)
        _ws!.after(m.later('together'));
      } else {
        // (held and let go where it was, a hand's shake taken for a drag: a click, it goes there and picks it as _rulerTap does; golf (88))
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

  // The films' beats (their Beats value, the inside's strikes), asked again only when the document changes: a question
  // of the inside (another isolate), shown when it comes.
  (int, List<int>)? _beats;
  int? _beatsAsked;
  // A film's sound on its bar: read once on another isolate (the inside keeps it), then laid on the document's frames
  // where the film shows them, asked again only when the document changes.
  // A film's pictures on its bar: the one it plays in the middle of each sixth of it (its begin, its speed, either way),
  // made small by the inside (GStreamer, another isolate) and read as pictures; asked again only when the document changes.
  final _frames = <String, (Object, List<ui.Image>?)>{};
  final _framesAsked = <String, Object>{};
  final _waves = <String, (int, int, int, List<double>?)>{}; // (thing: document read, from, to, loudness a frame)
  final _asked = <String>{};
  final _waveAsked = <String, (int, int, int)>{};
  @override
  Widget build(BuildContext context) {
    if (_workDrag == null) {
      // (the document's work area)
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
        }; // (picked together, or moved by the relation picked, or a shut group a picked thing is in: lit with it)
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
      child: Listener(
        onPointerDown: (_) => _focus.requestFocus(),
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
