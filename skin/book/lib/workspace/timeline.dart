// The workspace's Timeline seat: transport + timecode on top, layer labels beside the track area, a ruler with the work area, the playhead.
// The document lives in Ws; this seat keeps only how it looks at it (zoom, scroll, loop, the row toggles, the work area).
import 'package:lab_book/workspace/desk_ease_cards.dart' show easeCurve;
import 'dart:async' show Timer;
import 'dart:developer' show Timeline;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout, DragStartBehavior, PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/forms.dart';
import '../motolii.dart' show Motolii, mediaSecondsOf;
import 'two_fingers.dart';
import 'ableton.dart' show wsTimelineAsk, wsAskRename, wsAskTimeline, wsMarkPicked;
import '../sets/panels/timeline_parts_parts.dart' show TpGlyph, TpGlyphPainter;
import '../tokens.dart';
import 'key_drag.dart';
import 'keys.dart' show CommandIntent;
import 'timeline_kept.dart';
import 'timeline_paint.dart';
import 'thumbs.dart';
import 'relate.dart';
import 'ws.dart';
import 'ws_menu.dart';
import '../sets/foundations/text_hand.dart';
part 'timeline_asked.dart';
part 'timeline_view.dart';
part 'timeline_hand.dart';
part 'timeline_rows.dart';
part 'timeline_ruler.dart';
part 'timeline_snap.dart';
part 'timeline_slip.dart';
part 'timeline_header.dart';
part 'timeline_labels.dart';
part 'timeline_overview.dart';

class WsTimeline extends StatefulWidget {
  const WsTimeline({super.key});
  @override
  State<WsTimeline> createState() => _WsTimelineState();
}

class _WsTimelineState extends State<WsTimeline> with TickerProviderStateMixin, _TimelineAsked {
  late final Ticker _ticker = createTicker(_tick);
  late final VoidCallback _listener = _changed;   // (one closure, added and removed: an extension's method torn off is a new closure each time, never equal to the last, so removing it took nothing off)
  final _focus = FocusNode(debugLabel: 'timeline');
  Ws? _ws;
  double _zoom = 1, _scroll = 0, _vscroll = 0, _trackW = 1000, _rowsH = 200, _areaH = 200;

  // Inside a group: its rows stand in a room of their own on top, under the ruler they share, and the whole document's
  // rows stay below (Ableton Live's Clip View: opened by a double click, sized by its edge, dragged shut to close it;
  // docs/notes/GROUP_FOCUS_new.md 上からスッと出る段). _pin: how many of _order's rows are that room's (0: none open).
  int _pin = 0;
  double _pscroll = 0;   // (the room's rows scrolled, apart from the whole's)
  double? _panelWant;   // (the height the room's edge was pulled to, kept for the next time it opens; null: half the timeline, never as short as its rows (the maker, 11/6: 高さはユーザーハンドルで決める))
  (double, double)? _gripFrom;   // (the edge held: where the hand took it, and the room's height then)
  String? _wasEntered;
  late final _opening = AnimationController(vsync: this, duration: const Duration(milliseconds: 160))..addListener(() => setState(() {}));

  double get _grip => _pin == 0 ? 0 : Shape.z(8);
  double get _panelH => _pin == 0 ? 0 : (_panelWant ?? _areaH / 2).clamp(0.0, math.max(0.0, _areaH - _grip - 2 * WtM.row)).toDouble() * Curves.easeOut.transform(_opening.value);

  // A row's height: a lane in the group's room shares what the room's other rows leave of it, a row at least, so the
  // room is the group's graph, time across and value up, as tall as its edge is pulled (GROUP_FOCUS_new.md:
  // グループタイムラインビュー＝配列対応グラフビュー); every other row a row's.
  int _roomLanes = 0;
  double get _laneH => math.max(WtM.row, (_panelH - (_pin - _roomLanes) * WtM.row) / math.max(1, _roomLanes));
  double _tall(int i) => i < _pin && (_order[i].value ?? '').isNotEmpty ? _laneH : WtM.row;
  double _roomTop(int i) {
    var y = 0.0;
    for (var j = 0; j < i; j++) {
      y += _tall(j);
    }
    return y;
  }

  // A row's top on the tracks: the room's under the ruler, the whole's under the room's edge.
  double _rowY(int i) => i < _pin ? _roomTop(i) - _pscroll : _panelH + _grip + (i - _pin) * WtM.row - _vscroll;
  bool _onGrip(double y) => _pin > 0 && y >= _panelH && y < _panelH + _grip;

  void _gripTo(double y) {
    if (_gripFrom case (final from, final h)?) setState(() => _panelWant = math.max(0, h + y - from));
  }

  // Let go: pulled almost shut, the room shuts, and the timeline is the whole document's again.
  void _gripUp() {
    if (_gripFrom == null) return;
    _gripFrom = null;
    if ((_panelWant ?? WtM.row) < WtM.row / 2) {
      _panelWant = null;
      _ws!.enter(null);
    }
    setState(() {});
  }
  int _workIn = 12, _workOut = 228;
  int _last = -1;

  // The rows as laid: each layer's own, then, while it stands open, a lane for each of its values that moves (Ableton's
  // automation lanes, Live 12 manual 25.5: with Cmd, every automated envelope in a lane of its own). value: the lane's.
  List<({int layer, String? value, (String, String)? aim})> _order = const [];   // (aim: a row saying what the layer aims at, wsTargets; its value '', no keys)

  // A layer's values that have keys, in the thing's own order of them (Ableton lays out the automated ones: "Show
  // Automated Parameters Only"; with Animate on every value is said to move, so its keys tell).
  List<String> _moving(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null) return const [];
    final moving = m.moving(t).toSet();
    return [for (final n in m.values(t)) if (n.startsWith('js_line_') || moving.contains(n) && m.keyMoments(t, n).isNotEmpty) n];
  }

  // The card a lane's value stands on: the effect it is a knob of, or Transform and the like.
  String? _laneCard(Ws ws, WsLayer l, String name) => [for (final (title, names) in ws.inside!.cards(int.parse(l.id))) if (names.contains(name)) title].firstOrNull;

  // A group's stretch pressed on its lane, while what of it to work on is asked (_offer): lit as a picked one is.
  ({String layer, String name, int from})? _offered;

  // The entered group's instances, each its own way over the group's bar as the inside places it (motolii_path: its
  // things, the copies dealt them, each as late as it goes): asked again only when the document, or the group's keys of
  // x and y and their ways, change, as the stage's motion path is (stage_view_2.dart _trailOf). Four numbers a moment,
  // _crowdN moments; at most _crowdMost of them, every so many in their order.
  static const _crowdMost = 128, _crowdN = 120;
  (Object?, List<List<double>>?) _crowd = (null, null);
  List<List<double>>? _instancesOf(Ws ws, WsLayer g) {
    final m = ws.inside!, t = int.parse(g.id);
    final key = (ws.rev, g.id, g.inF, g.outF, [for (final n in const ['x', 'y']) for (final a in m.keyMoments(t, n)) '$n $a ${m.wayOf(t, n, a)}', for (final n in const ['x', 'y']) ...m.keyValues(t, n), m.value(t, 'stagger', 0), m.wayOf(t, 'stagger', 0), for (final c in m.things) if ((m.value(c, 'parent', 0) ?? 0).round() == t) '${m.value(c, 'x', 0)} ${m.value(c, 'y', 0)}'].join(';'));
    if (_crowd.$1 != key) {
      _crowd = (key, null);
      final who = [
        for (final c in m.things)
          if ((m.value(c, 'parent', 0) ?? 0).round() == t && m.word(c, 'kind') != 'behaviour')
            for (var j = 0; j < math.max(1, m.members(c)); j++) (c, j),
      ];
      final every = math.max(1, (who.length / _crowdMost).ceil());
      m.paths([for (var i = 0; i < who.length; i += every) who[i]], from: g.inF / Ws.fps, to: g.outF / Ws.fps, n: _crowdN).then((all) {
        if (mounted && _crowd.$1 == key) setState(() => _crowd = (key, [for (final p in all) ?p]));
      });
    }
    return _crowd.$2;
  }

  // (each lane's share of them, laid between its lowest and highest: the same lists while nothing changes, so the
  //  painter is not asked again)
  final _crowdLanes = <String, (Object, double, double, List<List<(double, double)>>)>{};
  List<List<(double, double)>> _crowdLane(WsLayer g, String name, List<List<double>> crowd, int axis, double lo, double hi) {
    if (_crowdLanes[name] case (final c, final a, final b, final kept) when identical(c, crowd) && a == lo && b == hi) return kept;
    double norm(double v) => hi > lo ? (v - lo) / (hi - lo) : .5;
    final laid = [
      for (final p in crowd) [for (var i = 0; 4 * i + axis < p.length; i++) (g.inF + (g.outF - g.inF) * i / _crowdN, norm(p[4 * i + axis]))],
    ];
    _crowdLanes[name] = (crowd, lo, hi, laid);
    return laid;
  }

  // A value's lane: its keys where they are and what they hold, read from the document's picture (nothing asked of the inside).
  // (the entered group's x and y: its instances laid over it, as many curves as there are, the lane as tall as they all
  //  reach; GROUP_FOCUS: グループタイムラインビュー＝配列対応グラフビュー)
  WtRow _laneRow(Ws ws, WsLayer l, String name, {double? tall}) {
    final m = ws.inside!, t = int.parse(l.id), at = m.keyMoments(t, name), vs = m.keyValues(t, name);
    final n = math.min(at.length, vs.length), axis = const {'x': 0, 'y': 1}[name];
    final crowd = l.kind == WsKind.group && l.id == ws.entered && axis != null ? _instancesOf(ws, l) : null;
    final all = [...vs.take(n), for (final p in crowd ?? const <List<double>>[]) for (var i = axis ?? 0; i < p.length; i += 4) p[i]];
    final lo = all.fold(double.infinity, math.min), hi = all.fold(-double.infinity, math.max);
    final on = switch (ws.stretch) { final s? when s.layer == l.id && s.name == name => s.from, _ => _offered?.layer == l.id && _offered?.name == name ? _offered!.from : null };
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
      laneOn: on == null ? null : [for (var i = 0; i < n; i++) (at[i] * Ws.fps).round()].indexOf(on),
      instances: crowd == null ? null : _crowdLane(l, name, crowd, axis!, lo, hi),
      tall: tall,
    );
  }

  // What has a room of its own, entered by a second press: a group, or anything with more than one member (its copies,
  // its letters: Motolii.members), as a group is an array (docs/notes/GROUP_FOCUS_new.md 土台: グループもふつうのレイヤー).
  bool _roomy(Ws ws, WsLayer l) => l.kind == WsKind.group || (ws.inside?.members(int.parse(l.id)) ?? 1) > 1;

  // A way's shape from 0 to 1, as the bar's stretches are drawn.
  List<double> _wayShape(Ws ws, String way) => way.isEmpty ? const [0, 1] : easeCurve(way, ws.inside!);

  @override
  void initState() {
    super.initState();
    _hearAsks();   // (the window's keys heard: timeline_asked.dart)
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
    _opening.dispose();
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
    if (e is PointerScrollEvent) _scrollBy(e.scrollDelta, at: e.localPosition.dy);
  }

  /// A trackpad's two fingers: they carry the tracks as a wheel does, the other way (the content goes with the fingers);
  /// a pinch zooms about the frame under them (Final Cut's, Cavalry's, Theatre.js's).
  void _fingers(Offset by, Offset at) => _scrollBy(-by, at: at.dy);
  void _pinch(double by, Offset at) => _setZoom(_zoom * by, anchor: _view.frameAt(at.dx).round().clamp(0, Ws.duration));

  void _scrollBy(Offset d, {double at = double.infinity}) {
    final sideways = HardwareKeyboard.instance.isShiftPressed || d.dx.abs() > d.dy.abs();
    if (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed) {
      _setZoom(_zoom * math.pow(1.0015, -d.dy));
    } else if (sideways) {
      setState(() => _scroll = _clampScroll(_scroll + (d.dx.abs() > d.dy.abs() ? d.dx : d.dy) / _view.ppf));
    } else if (_pin > 0 && at < _panelH) {   // (over the group's room: its rows, not the whole's)
      setState(() => _pscroll = (_pscroll + d.dy).clamp(0.0, math.max(0.0, _roomTop(_pin) - _panelH)).toDouble());
    } else {
      setState(() => _vscroll = _vscroll + d.dy);
    }
  }

  // Joined: a bar held by a hand: by its body it slides, by an end it is cut there. The timeline only says which part
  // is held and how many seconds the hand has gone; what that does to the thing (its limits, a film's head) is the
  // inside's, and the bar is drawn from what the inside then says.
  ({String id, String part, double grab, bool moved})? _bar;
  Set<int> _stops = const {};   // (what the hand may come to rest on, taken when it took hold: timeline_snap.dart)
  int? _restAt;   // (where it has, its line drawn there)
  (int, int)? _barWhole;   // (the held film whole when it was taken: timeline_slip.dart)
  final _filmSeconds = <String, double>{};
  int _barIn = 0, _barOut = 0;   // (the held bar's ends when it was taken: a cut stops one frame short of nothing, since a bar cut to nothing cannot be seen, taken again, or kept: the document is as long as its longest thing)

  // The pointer over a bar says what it would do: an end cuts, the body slides, a key slides; the room between draws a box.
  MouseCursor _cursor = MouseCursor.defer;

  // A key held by a hand: it (and the keys picked with it) slides in time; the playhead shows where, let go it is so.
  ({List<WsKey> keys, int grab, int by})? _slide;
  DateTime? _lanePressed;   // (when and where a lane was last pressed: a second press there is a double one)
  Offset _laneAt = Offset.zero;

  // A row pressed twice (its label or its bar, within a double press's time): a group's is entered, the room under the
  // rows' is left. Told by its own clock, as a lane's is, so a single press is not held back for a second (Flutter's
  // onDoubleTap waits kDoubleTapTimeout before a tap is one).
  DateTime? _rowPressed;
  String? _rowWas;
  bool _twice(String id) {
    final now = DateTime.now(), yes = _rowWas == id && _rowPressed != null && now.difference(_rowPressed!) < kDoubleTapTimeout;
    _rowPressed = yes ? null : now;
    _rowWas = id;
    return yes;
  }

  // A box drawn over the empty room of the tracks (any direction): the keys inside it are picked, else the things whose
  // bars it touches (Ableton's and After Effects' marquee). Corners, in the tracks' own points.
  (Offset, Offset)? _box;

  void _barDown(Offset p) {
    if (_onGrip(p.dy)) {   // (the room's edge taken: Live's Clip View sized by its border)
      _gripFrom = (p.dy, _panelH);
      return;
    }
    if (!_grab(p)) setState(() => _box = (p, p));
  }

  void _boxUp() {
    final b = _box;
    setState(() => _box = null);
    if (b == null) return;
    final ws = _ws!, v = _view, r = Rect.fromPoints(b.$1, b.$2);
    if (r.width < 4 && r.height < 4) return;   // (a click, not a box: the tap has done it)
    final keys = <WsKey>[], things = <String>[];
    for (var i = 0; i < _order.length; i++) {
      if (_order[i].value != null) continue;   // (a lane's points are not picked by a box)
      final l = ws.layers[_order[i].layer], top = _rowY(i);
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
      ws.pickMany(things, byHand: false);
    }
  }

  void _barMove(Offset p) {
    if (_gripFrom != null) return _gripTo(p.dy);
    if (_box case (final from, _)?) return setState(() => _box = (from, p));
    if (_slide case final s?) {
      final by = _rested(_view.frameAt(p.dx).round() - s.grab, [s.grab]);
      setState(() => _slide = (keys: s.keys, grab: s.grab, by: by));
      _ws!.frame = (s.grab + by).clamp(0, Ws.duration);
      return;
    }
    final h = _bar, ws = _ws!, m = ws.inside;
    if (h == null || m == null) return;
    var by = (_view.frameAt(p.dx) - h.grab).round();   // (by whole frames)
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
    if (_gripFrom != null) return _gripUp();
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
    ws.after(m.later('let_go', number: keep && h.moved ? 1 : 0));   // (let go without waiting)
  }

  double _lift = 0; // how far a label row has been carried up or down

  int? _workDrag; // 0 in, 1 out, 2 both, null scrub
  double _workGrab = 0;

  // The document's marks on the ruler, as Ableton Live's locators (timeline_asked.dart: a right click puts one, a click
  // picks and goes to one, Cmd+R names it); one is carried along by its flag (its name kept), and carried off the
  // ruler, up or down, it is taken away. Each one step.
  (double, String)? _markHeld;
  int _markTo = 0;
  double _markGrab = 0;   // (where on its flag it was taken, in frames: kept while carried, as Live's locators are dragged (6.4) and as the work area here keeps _workGrab; carried to the hand's own spot, one taken by its name's end jumped 0.47 s)
  final _rulerMenu = GlobalKey<WsMenuState>();
  final _trackMenu = GlobalKey<WsMenuState>();   // (a bar's own menu: timeline_asked.dart _trackRight)
  final _labelMenu = GlobalKey<WsMenuState>();
  bool _markOff = false;
  (double, String)? _naming;
  final _markWords = TextEditingController();
  late final FocusNode _markFocus = FocusNode()..addListener(() => _markFocus.hasFocus ? null : _named());   // (the field left: the name said)

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
        _markOff = p.dy < -WtM.ruler * .6 || p.dy > WtM.ruler * 1.6;   // (carried off the ruler: taken away when let go)
      });
    }
    switch (_workDrag) {
      case 0:
        setState(() => _workIn = f.clamp(0, _workOut - Ws.fps ~/ 2));   // (never shut to nothing: half a second at least, so the document cannot be dragged out of sight)
      case 1:
        setState(() => _workOut = f.clamp(_workIn + Ws.fps ~/ 2, Ws.duration));
      case 2:
        final len = _workOut - _workIn, a = (_view.frameAt(p.dx) - _workGrab).round().clamp(0, Ws.duration - len);
        setState(() {
          _workIn = a;
          _workOut = a + len;
        });
      default:
        final shift = HardwareKeyboard.instance.isShiftPressed;   // (After Effects': Shift held while the time indicator is dragged, it rests on what it passes)
        if (shift) _stops = _ws!.stops();
        _ws!.frame = shift ? _restOn(f) ?? f : f;
    }
  }

  /// Joined: the work area carried is the document's when the hand lets go (one step).
  void _workLetGo() {
    final m = _ws?.inside;
    if (_markHeld case (final at, final name)?) {
      _markHeld = null;
      final to = _markTo / Ws.fps;
      if (_markOff) {
        _ws!.after(m!.later('mark', number: at));
      } else if ((to - at).abs() >= 0.5 / Ws.fps) {   // (moved: one step, its name kept)
        m!.later('together', number: 1);
        m.later('mark', number: at);
        m.later('mark', number: to, word: name);
        if (_ws!.markColours[at] case final k?) m.later('mark_colour', number: to, word: '$k');   // (its colour with it)
        _ws!.after(m.later('together'));
      } else {   // (held and let go where it was, a hand's shake taken for a drag: a click, it goes there and picks it as _rulerTap does; golf (88))
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
  // The picked group's end of intro and start of outro, kept with it as an element (its Element card's End of intro,
  // Start of outro: doc_element_clock), where they fall on the ruler.
  List<int> _retimedOf(Ws ws) {
    final m = ws.inside, t = int.tryParse(ws.selected ?? '');
    if (m == null || t == null) return const [];
    final start = m.value(t, 'start', 0) ?? 0;
    return [for (final n in const ['retime_in', 'retime_out']) if ((m.value(t, n, 0) ?? 0) > 0) ((start + m.value(t, n, 0)!) * Ws.fps).round()];
  }

  List<int> _beatsOf(Ws ws) {
    final m = ws.inside;
    if (m == null) return const [];
    if (_beats case (final r, final b) when r == ws.reads) return b;
    if (_beatsAsked == ws.reads) return _beats?.$2 ?? const [];
    final asks = <Future<List<double>>>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id), rise = t == null ? 0.0 : m.value(t, 'beats', 0) ?? 0;
      if (rise > 0 && _waveOf(ws, l) != null) asks.add(m.strikes(t!, rise));   // (only once its sound is read)
    }
    final reads = _beatsAsked = ws.reads;
    Future.wait(asks).then((all) => mounted ? setState(() => _beats = (reads, ws.strikes = [for (final s in all) for (final at in s) (at * Ws.fps).round()])) : null);
    return _beats?.$2 ?? const [];
  }

  // A thing's small picture at the head of its row (thumbs.dart: a film's pictures, a photo, a shape's form), kept
  // there and drawn again as each comes in.
  late final _thumbs = WsThumbs(onLoaded: () => setState(() {}), mounted: () => mounted);
  List<ui.Image>? _framesOf(Ws ws, WsLayer l) => _thumbs.framesOf(ws, l);
  (String, Color?, bool)? _formOf(Ws ws, WsLayer l) => _thumbs.formOf(ws, l);

  // A film's sound on its bar: read once on another isolate (the inside keeps it), then laid on the document's frames
  // where the film shows them, asked again only when the document changes.
  final _waves = <String, (int, int, int, List<double>?)>{};   // (thing: document read, from, to, loudness a frame)
  final _asked = <String>{};
  final _waveAsked = <String, (int, int, int)>{};
  List<double>? _waveOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final key = (ws.reads, l.inF, l.outF);
    final had = _waves[l.id];
    if (had case (final r, final a, final b, final w) when (r, a, b) == key) return w;
    if (_waveAsked[l.id] != key) {   // (a question of the inside, another isolate: laid on the bar when it comes)
      _waveAsked[l.id] = key;
      m.loudnessOver(t, l.inF / Ws.fps, l.outF / Ws.fps, l.outF - l.inF).then((w) {
        if (!mounted) return;
        if (w == null) {
          if (_asked.add(l.id)) m.loudness(t).then((_) => mounted ? setState(() => (_waveAsked.remove(l.id), _beats = null, _beatsAsked = null)) : null);
          return;
        }
        setState(() => (_waves[l.id] = (key.$1, key.$2, key.$3, w.isEmpty ? null : w), _beats = null, _beatsAsked = null));   // (its sound now read: the beats asked again)
      });
    }
    return had?.$4;
  }

  @override
  Widget build(BuildContext context) {
    if (_workDrag == null) {   // (the document's work area)
      final (from, to) = _ws!.work;
      _workIn = (from * Ws.fps).round();
      _workOut = (to * Ws.fps).round();
    }
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked, WsAspect.animating});
    final away = ws.foldedAway;
    final sel = ws.selected, picks = ws.keys, lit = {...ws.many, ...wsMembersOf(ws), for (final p in [?sel, ...ws.many]) ?away[p]};   // (picked together, or moved by the relation picked, or a shut group a picked thing is in: lit with it)
    // (inside a group: its own row first, then its relations (the behaviours in it) and the things in
    //  it that are named: picked, or with keys of their own. The rest of what it holds goes as the relations say, and is
    //  not here; the rest of the document neither. docs/notes/GROUP_FOCUS_new.md: 関係の行と、名指しで出した物の行だけ)
    // (inside a group, its room on top: its own row, then its relations (the behaviours in it) and
    //  the things in it that are named: picked, or with keys of their own; the rest of what it holds goes as the
    //  relations say. Below it the whole document as ever, the group one row there. GROUP_FOCUS_new.md: 関係の行と、名指しで
    //  出した物の行だけ; 置き換えではなく上からスッと出る段)
    final entered = ws.entered, head = entered == null ? -1 : ws.layers.indexWhere((l) => l.id == entered), m = ws.inside!;
    if (entered != _wasEntered) {
      final opened = _wasEntered == null;
      _wasEntered = entered;
      if (entered == null) {
        _opening.value = 0;
      } else if (opened) {
        _pscroll = 0;
        SchedulerBinding.instance.addPostFrameCallback((_) => mounted ? _opening.forward(from: 0) : null);
      }
    }
    bool named(WsLayer l) => m.word(int.parse(l.id), 'kind') == 'behaviour' || l.keys.isNotEmpty || l.id == sel || ws.many.contains(l.id);
    final inner = head < 0 ? const <int>[] : [head, for (final (i, l) in ws.layers.indexed) if (l.parent == entered && named(l)) i];
    final whole = [for (final (i, l) in ws.layers.indexed) if (!away.containsKey(l.id)) i];
    List<({int layer, String? value, (String, String)? aim})> rowsOf(List<int> shown, {bool room = false}) => [
      for (final i in shown) if (ws.layers[i] case final l) ...[
        (layer: i, value: null, aim: null),
        // (a group's count is on its Copies card in the inspector, as any thing's is, not a row of its room. The user, 11/8)
        if ((room || l.id != entered) && ws.aimsOpen(l.id))   // (the group entered: its lanes in its room, once, not again in the whole below)
          for (final a in wsTargets(ws, l.id)) (layer: i, value: '', aim: a),
        if ((room || l.id != entered) && ws.lanesOpen(l.id))
          for (final n in _moving(ws, l)) (layer: i, value: n, aim: null),
      ],
    ];
    final room = rowsOf(inner, room: true);
    _pin = room.length;
    _roomLanes = room.where((o) => (o.value ?? '').isNotEmpty).length;
    _order = [...room, ...rowsOf(whole)];
    final rows = <WtRow>[
      for (final (j, o) in _order.indexed)
        if (o.value case final n?)
          _laneRow(ws, ws.layers[o.layer], n, tall: j < _pin && n.isNotEmpty ? _laneH : null)
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
          head: j < _pin && o.layer == head,
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
              _Header(ws: ws, loop: ws.inside!.looping, zoom: _zoom, onToggle: _toggle, onStep: _step, onLoop: () => setState(() => ws.inside!.looping = !ws.inside!.looping), onZoom: _setZoom, onMark: _setMark),
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

  // The group's room's lower edge: taken and pulled it sizes the room, pulled shut it closes it (Live's Clip View).
  Widget _roomEdge({Key? key}) => MouseRegion(
    cursor: SystemMouseCursors.resizeUpDown,
    child: Container(   // (a bar the room stands on, with a grip at its middle: what can be taken is seen as such, macOS's split view divider)
      key: key,
      height: _grip,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Grey.g26, border: Border(bottom: BorderSide(color: Grey.g07))),
      child: Container(width: Shape.s(28), height: 2, color: Grey.g56),
    ),
  );

  Widget _tracks(Ws ws, List<WtRow> rows) => LayoutBuilder(
    builder: (context, box) {
      _trackW = box.maxWidth;
      _areaH = math.max(0, box.maxHeight - WtM.ruler - WtM.overview);
      _rowsH = math.max(0, _areaH - _panelH - _grip);
      _scroll = _clampScroll(_scroll);
      _vscroll = _clampV(rows.length - _pin);
      _pscroll = _pscroll.clamp(0.0, math.max(0.0, _roomTop(_pin) - _panelH)).toDouble();
      final v = _view;
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WsMenu(
                key: _rulerMenu,
                child: GestureDetector(
                key: const ValueKey('ws-tl-ruler'),
                behavior: HitTestBehavior.opaque,
                supportedDevices: wsPressing,
                onTapUp: (d) => _rulerTap(d.localPosition),   // (Live's scrub area: timeline_asked.dart)
                onDoubleTapDown: (d) => _rulerDouble(d.localPosition),
                onDoubleTap: () {},
                onSecondaryTapDown: (d) => _rulerRight(d.localPosition),
                onPanDown: (d) => _rulerDown(d.localPosition),
                onPanUpdate: (d) => _rulerMove(d.localPosition),
                onPanEnd: (_) => _workLetGo(),
                onPanCancel: _workLetGo,
                child: SizedBox(
                  height: WtM.ruler,
                  child: CustomPaint(
                    painter: WtRulerPainter(view: v, fps: Ws.fps, workIn: _workIn, workOut: _workOut, markers: _marksOf(_ws!), markColours: _markColoursOf(_ws!), beats: _beatsOf(ws), tempo: ws.beats, retimed: _retimedOf(ws)),
                    foregroundPainter: WtKeptPainter(view: v, kept: ws.kept), // (the pictures kept on disk for playing)
                  ),
                ),
              ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: _cursor,
                  onHover: (e) {
                    final c = _cursorAt(e.localPosition);
                    if (c != _cursor) setState(() => _cursor = c);
                  },
                  child: Listener(
                  onPointerSignal: _wheel,
                  child: WsTwoFingers(
                  onPan: _fingers,
                  onPinch: _pinch,
                  child: WsMenu(
                  key: _trackMenu,
                  child: GestureDetector(
                    key: const ValueKey('ws-tl-tracks'),
                    behavior: HitTestBehavior.opaque,
                    supportedDevices: wsPressing,
                    dragStartBehavior: DragStartBehavior.down,
                    onTapDown: (d) => _trackDown(d.localPosition),
                    onSecondaryTapDown: (d) => _trackRight(d.localPosition),
                    onTapUp: (d) => _laneTap(d.localPosition),   // (a lane's tap, once it is known not to be a drag)
                    onPanStart: (d) => _barDown(d.localPosition),
                    onPanUpdate: (d) => _barMove(d.localPosition),
                    onPanEnd: (_) => _barUp(),
                    onPanCancel: () => _barUp(keep: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_pin > 0) ...[
                          SizedBox(
                            key: const ValueKey('ws-tl-room'),
                            height: _panelH,
                            child: RepaintBoundary(
                              child: CustomPaint(painter: WtTracksPainter(rows: rows.sublist(0, _pin), view: v, fps: Ws.fps, vscroll: _pscroll, tempo: ws.beats, restAt: _restAt, room: true)),
                            ),
                          ),
                          _roomEdge(),
                        ],
                        Expanded(
                          child: RepaintBoundary(
                            child: CustomPaint(painter: WtTracksPainter(rows: rows.sublist(_pin), view: v, fps: Ws.fps, vscroll: _vscroll, tempo: ws.beats, restAt: _restAt)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  ),
                ),
                ),
              ),
              ValueListenableBuilder<int>(valueListenable: ws.moment, builder: (_, frame, _) => _Overview(from: _scroll, to: _scroll + _visible, frame: frame, onDrag: (p) => _overview(p, box.maxWidth))),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: WtM.overview,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    painter: WtPlayheadPainter(view: v, frame: ws.frame, headTop: WtM.band + 1, moment: ws.moment),   // (painted again as the playhead moves, nothing built)
                  ),
                ),
              ),
            ),
          ),
          if (_box case (final a, final b)?)
            Positioned.fromRect(
              rect: Rect.fromPoints(a, b).shift(Offset(0, WtM.ruler)),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: WsT.accent.withAlpha(36), border: Border.all(color: WsT.accent, width: 1)),
                ),
              ),
            ),
          if (_naming case (final at, _)?)   // (the flag itself written in, as wide as its words, as Figma's layer name is written where it stands)
            Positioned(
              left: v.x((at * Ws.fps).round()).roundToDouble(),
              top: WtM.band + 2,
              height: 12,
              child: ListenableBuilder(
                listenable: _markWords,
                builder: (_, child) => Container(
                  width: wtFlagWidth('${_markWords.text}  '),
                  color: WsT.toneText,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
                child: TextHand(key: const ValueKey('ws-tl-mark-name'), field: (k) => EditableText(key: k, rendererIgnoresPointer: true,
                  controller: _markWords,
                  focusNode: _markFocus,
                  style: T.micro(Grey.g13).copyWith(fontWeight: FontWeight.w700),
                  cursorColor: Grey.g13,
                  backgroundCursorColor: Grey.g38,
                  selectionColor: Grey.g13.withValues(alpha: .3),   // (its words picked, seen as picked)
                  maxLines: 1,
                  onSubmitted: (_) => _markFocus.unfocus(),
                )),
              ),
            ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------- header strip
