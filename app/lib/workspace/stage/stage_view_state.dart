// Part of stage_view.dart: the view's state: pan, zoom, hover, keys and hands.
part of 'stage_view.dart';

class _StageViewState extends State<StageView> implements StageHandles {
  Offset _pan = Offset.zero;
  String? _hover;
  _View? _shown; // (the view as last laid out: where the handles are now)

  @override
  String? hitAt(Offset global) {
    final box = context.findRenderObject() as RenderBox?, v = _shown;
    return box == null || v == null ? null : _hit(v, box.globalToLocal(global));
  }

  @override
  Map<String, Offset> get handles {
    final v = _shown, scene = widget.scene, b = WsArt.boxOf(scene, widget.selected), l = scene.layer(widget.selected);
    if (v == null || b == null || l == null) return const {};
    final (form, round) = _formOf();
    return _handles((d) => v.toScreen(WsArt.toView(scene, d)), b, knob: l.kind != WsKind.camera && l.id != 'bg', form: form, round: round, crop: _cropOf());
  }

  static const _crops = ['crop_left', 'crop_top', 'crop_right', 'crop_bottom'];
  /// The picked photo's crop, each side's share cut in (the inside's), while it is being cropped: none otherwise.
  List<double> _cropOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || _cropping != widget.selected || !_photo(m, t)) return const [];
    return [for (final n in _crops) m.value(t, n, 0) ?? 0];
  }

  static bool _photo(Motolii m, int t) => m.word(t, 'kind') == 'picture' && RegExp(r'\.(jpe?g|png|webp|bmp)$', caseSensitive: false).hasMatch(m.word(t, 'file'));

  // (a picked photo pressed twice is cropped, its crop's bars on its sides, till a press anywhere or Enter: Figma's Crop
  //  an image; Keynote's images, double-clicked; Alight Motion's crop takes a hand only while its own card is open)
  String? _cropping;
  String? _tapped;   // (the one pressed a moment ago, till the wait for a second press is over: Flutter's double tap's own wait)
  Timer? _tapWait;
  bool _enter(KeyEvent e) {   // (while no words are being typed)
    if (_cropping == null || e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.enter) return false;
    if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return false;
    setState(() => _cropping = null);
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_enter);
  }

  /// The picked shape's form and how round its corners are (the inside's), for its own handles.
  (String, double) _formOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return ('', 0);
    return (m.word(t, 'shape'), m.value(t, 'round', 0) ?? 0);
  }

  @override
  void didUpdateWidget(StageView o) {
    super.didUpdateWidget(o);
    if (o.zoom != widget.zoom) _pan = Offset.zero;
    if (o.make != widget.make) _penning = false; // (another tool: the pen's next point begins a new shape)
  }

  // Joined: the inside draws the whole pane (the desk), the stage lying in it where this view puts it; told again when
  // that changes (after the frame: the inside is not asked while building).
  int? _desk;
  _View? _toldDesk;
  Motolii? _deskOf;
  double? _toldDpr;
  void _deskTo(_View v) {
    final dpr = MediaQuery.devicePixelRatioOf(context), m = WsScope.read(context).inside;
    if (m != _deskOf) {   // (another document opened in its place: its own desk told and its picture asked; the last one's was kept, and the stage stood still on it: golf_noise.md (73))
      _desk = null;
      _toldDesk = null;
      _toldPick = null;
    }
    if (widget.texture == null || (v == _toldDesk && dpr == _toldDpr)) return; // (told again when the window's zoom changes its pixels too)
    _toldDesk = v;
    _toldDpr = dpr;
    if ((_deskOf = m) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _toldDesk != v || _toldDpr != dpr) return;
      final m = _deskOf!;
      final ticket = m.desk((v.area.width * dpr).round(), (v.area.height * dpr).round(), (v.o.dx - v.area.left) * dpr, (v.o.dy - v.area.top) * dpr, v.s * dpr, dpr);
      void look(Duration _) {   // (a picture at a time till the inside has made the desk: the window never stands still for it)
        if (!mounted) return;
        final a = m.answer(ticket);
        if (a < 0) {
          SchedulerBinding.instance.scheduleFrameCallback(look);
          return;
        }
        if (a == 0) return;
        _toldPick = null;
        if (_desk == null) m.deskTexture().then((id) => mounted && id >= 0 ? setState(() => _desk = id) : null);
      }
      SchedulerBinding.instance..scheduleFrameCallback(look)..ensureVisualUpdate();
    });
  }

  // Joined, the desk on: which thing is picked and which is under the hand, told when it changes (the inside marks them).
  (int, int)? _toldPick;
  void _pickTo() {
    final m = _deskOf;
    if (_desk == null || m == null) return;
    final now = (int.tryParse(widget.selected ?? '') ?? 0, int.tryParse(_hover ?? '') ?? 0);
    if (now == _toldPick) return;
    _toldPick = now;
    m.pick(now.$1, now.$2);
  }

  @override
  void dispose() {
    _deskOf?.desk(0, 0, 0, 0, 0, 0); // (the stage's own picture again)
    _dollyRest?.cancel();
    _tapWait?.cancel();
    HardwareKeyboard.instance.removeHandler(_enter);
    super.dispose();
  }

  _View _view(Size size) {
    final area = Rect.fromLTRB(_V.ruler, _V.ruler, size.width, size.height);
    final fit = math.max(.02, math.min((area.width - _V.fitMargin * 2) / WsArt.comp.width, (area.height - _V.fitMargin * 2) / WsArt.comp.height));
    final s = widget.zoom == 0 ? fit : _fixed[widget.zoom];
    final half = Offset(WsArt.comp.width * s, WsArt.comp.height * s) / 2;
    return _View(area.center - half + _pan, s, area);
  }

  Offset _doc(_View v, Offset local) => WsArt.toDoc(widget.scene, v.toComp(local));

  String? _hit(_View v, Offset local) {
    // (a thing that lies off the picture can still be held by its frame and carried back)
    final d = _doc(v, local), id = WsArt.hit(widget.scene, d), m = WsScope.read(context).inside;
    if (widget.group && m != null && id != null) { // (Group: the outermost of the things it goes with, by the document's parent)
      var t = int.parse(id);
      for (var p = (m.value(t, 'parent', 0) ?? 0).round(), n = 0; p > 0 && n < 64; p = (m.value(t, 'parent', 0) ?? 0).round(), n++) {
        t = p;
      }
      return '$t';
    }
    return id;
  }

  // Joined: a thing held on the stage, carried, and let go. The stage only says how far the hand has gone, in points of
  // the picture; where that puts the thing (at its own depth), and what it is to the document, is the inside's.
  ({Offset from, bool moved, String? by})? _held;   // (by: a handle's way of carrying it, scale, turn or pivot; null: placed)
  String? _grip;   // (the handle in hand, by its name: it alone shown, lit, while it is carried: Alight Motion's)

  // Joined, Snap (the past repository's, After Effects' snapping): the held thing's left, middle and right (top, middle,
  // bottom) stick to the nearest of the same three lines of every other thing it does not go with and of the picture,
  // or to a guide, within six points of the screen. What it holds to, and the lines it met.
  ({Rect box, List<(double, double)> xs, List<(double, double)> ys})? _snapTo;
  (double?, double?) _met = (null, null);

  // Joined: a guide pulled out of a ruler (from the top one, a level line; from the left one, an upright one) or taken
  // hold of where it lies; let go on the picture it is the document's there, let go back over its ruler it is gone.
  ({String axis, double? was})? _pulling;

  Offset? _last;

  // Joined: a thing drawn with the tool in hand: from where the hand came down to where it is let go (a rect or a
  // circle that box, a line from the one point to the other, a text where it came down); only come down, one as it
  // comes. One step; it is picked.
  Offset? _drawFrom;

  // Joined: drawn round on the stage where no thing is (no tool in hand): the things whose middles it goes round are
  // picked together (Ws.many), and what they may do together is offered beside them (relate.dart).
  List<Offset>? _lasso;

  // Joined: the pen: a point where the hand came down, its handle drawn out as far as the hand was dragged (a tap: a
  // corner). Its first goes to the picked thing, the rest to the one the pen made (thing -1); the inside reckons all of
  // it (a new path begun, closed on its first point, a point put on or taken off a closed one) from where the hand is.
  bool _penning = false;
  List<Offset>? _penWay;   // (the hand's way while the pen is down: a scribble, not a handle drawn out, is made a path of its own)

  void _pen(_View v, Offset down, Offset up) {
    final ws = WsScope.read(context), m = ws.inside, way = _penWay;
    _drawFrom = null;
    _penWay = null;
    setState(() {});
    if (m == null) return;
    if (way != null && _scribbled(way, down, up)) return _fit(v, way);
    final a = _doc(v, down), h = _doc(v, up) - a;
    final first = !_penning;
    _penning = true;
    if (first) m.later('together', number: 1);
    var made = 0;
    ws.after(m.later('pen', thing: first ? int.tryParse(widget.selected ?? '') ?? 0 : -1, word: '${a.dx} ${a.dy} ${h.dx} ${h.dy}'), null, (t) => made = t); // (first on the picked thing: a closed path gains or loses a point, anything else begins a new one)
    if (first) {
      wsInked(ws, 'shape', 'path');
      ws.after(m.later('together'), (done, _) => done && made > 0 ? ws.select('$made') : null);
    }
  }

  /// Whether the pen's way strayed from the straight line a handle is drawn along: more than 16 points of the window off
  /// it, the hand drew a line, not a handle.
  static bool _scribbled(List<Offset> way, Offset down, Offset up) {
    final d = up - down, long = d.distance;
    return way.any((p) => (long < 1 ? (p - down).distance : ((p - down).dx * d.dy - (p - down).dy * d.dx).abs() / long) > 16);
  }

  // (the Brush's way so far, in points of the window; when let go, its points as perfect-freehand (MIT, Steve Ruiz; Dart
  //  port, Adil Hanney) evens them and the pressure it simulates from their speed, given to the inside, which keeps the
  //  stroke and has AbsentMotion make its outline as Alight Motion's brush does (doc_brush): each point's pressure, as
  //  AbsentMotion's brush reads it, its radius here over half the brush)
  List<Offset>? _brush;
  ({double x, double y})? _orbitFrom;   // (the camera's turn when the hand took hold)
  double? _dollyAt;   // (its distance while the wheel turns)
  Timer? _dollyRest;

  double _orbitRate = .25;   // (degrees a pixel)
  ({double zoom, double reach, Offset middle})? _lensFrom;   // (the frame's size when the hand took hold)

  void _carry(_View v, Offset local) {
    final h = _held, ws = WsScope.read(context), m = ws.inside;
    if (h == null || m == null) return;
    if (h.by == 'gizmo orbit' && _orbitFrom != null) {   // (it goes the way the hand does)
      final d = (local - h.from) * _orbitRate, o = _orbitFrom!;
      m.carry('rotate_y', o.y + d.dx);
      m.carry('rotate_x', (o.x + d.dy).clamp(-89.0, 89.0));
      _held = (from: h.from, moved: true, by: h.by);
      return;
    }
    if (h.by == 'gizmo lens' && _lensFrom != null) {   // (as far from the middle as the hand now is, against where it took hold: a larger frame, a wider lens)
      final l = _lensFrom!;
      m.carry('zoom', (l.zoom * l.reach / math.max((local - l.middle).distance, 1)).clamp(.01, 100.0));
      _held = (from: h.from, moved: true, by: h.by);
      return;
    }
    if (h.by == 'orbit' && _orbitFrom != null) {   // (sideways round it, up and down over it: a quarter of a degree a pixel)
      final d = local - h.from, o = _orbitFrom!;
      if (ws.freeEye) return ws.setView('stage.eye', [o.y - d.dx * .25, (o.x - d.dy * .25).clamp(-89.0, 89.0), ws.eye[2]]);
      m.carry('rotate_y', o.y - d.dx * .25);
      m.carry('rotate_x', (o.x - d.dy * .25).clamp(-89.0, 89.0));
      _held = (from: h.from, moved: true, by: 'orbit');
      setState(() {});
      return;
    }
    final all = (local - h.from) / v.s; // (screen px -> points of the picture)
    if (h.by case final way? when way.startsWith('crop ')) {   // (a photo's side cut in as far as the hand goes in from where it is cut, no further than leaves some of it)
      final side = int.parse(way.substring(5)), c = [for (var i = 0; i < 4; i++) handles['corner $i'] ?? Offset.zero], crop = _cropOf();
      final across = side.isEven ? c[1] - c[0] : c[3] - c[0], len = math.max(1.0, across.distance), dir = across / len * (side < 2 ? 1.0 : -1.0);
      final at = handles[way] ?? h.from, inBy = ((local - at).dx * dir.dx + (local - at).dy * dir.dy) / len;
      if (crop.length == 4) m.carry(_crops[side], (crop[side] + inBy).clamp(0.0, .95 - crop[(side + 2) % 4]));
      _held = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    if (h.by case final way? when way == 'round' || way == 'points') {   // (a shape's own: its corners' roundness, or its points, as far as the hand goes)
      final c = [for (var i = 0; i < 4; i++) handles['corner $i'] ?? Offset.zero], g = _gripOf(c), t = int.tryParse(widget.selected ?? '');
      if (way == 'round') m.carry('round', g.roundOf(local));
      if (way == 'points' && t != null) m.carry('points', ((m.value(t, 'points', 0) ?? 5) + (((local - h.from).dx * g.u.dx + (local - h.from).dy * g.u.dy) / 24).round()).clamp(3, 64).toDouble());
      _held = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    if (h.by case final way?) {
      var gone = _doc(v, local) - _doc(v, h.from);
      // (Figma's: a corner sizes it both ways freely, the side across staying; a side's middle that way only, the hand's
      //  travel across it; ⇧ keeps its width to its height, or turns it 15° at a time; ⌥ about its pivot, from the middle)
      final keys = HardwareKeyboard.instance, sized = way == 'scale' || way == 'edge', even = keys.isShiftPressed && (sized || way == 'turn') ? 'even_' : '';
      if (_grip case final g? when way == 'edge') {
        final at = handles[g], across = handles['side ${(int.parse(g.substring(5)) + 2) % 4}'];
        if (at != null && across != null && (at - across).distance > 1) {
          final n = (at - across) / (at - across).distance;
          gone = n * (gone.dx * n.dx + gone.dy * n.dy);
        }
      }
      m.carry('$even${sized ? (keys.isAltPressed ? 'scale' : 'side') : way}', gone.dx, gone.dy);
      _held = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    // (the Move tool's way; ⇧ held, across or down only, whichever the hand has gone further: Illustrator's and Figma's)
    final axis = widget.axis == 0 && HardwareKeyboard.instance.isShiftPressed ? (all.dx.abs() >= all.dy.abs() ? 1 : 2) : widget.axis;
    final by = _snapped(switch (axis) { 1 => Offset(all.dx, 0), 2 => Offset(0, all.dy), _ => all }, v.s);
    m.carry('place', by.dx, by.dy);
    _held = (from: h.from, moved: true, by: null);
    setState(() {});
  }

  void _scroll(PointerSignalEvent e, _View v) {
    if (e is PointerScrollEvent && widget.make == 'camera') return _dolly(e.scrollDelta.dy);
    if (e is PointerScrollEvent) _panBy(-e.scrollDelta, v);
  }

  /// Panned by (a trackpad's two fingers as they go, a wheel the other way), when zoomed in; at Fit there is nowhere to go.
  void _panBy(Offset by, _View v) {
    if (widget.zoom == 0) return;
    final lim = Offset(WsArt.comp.width * v.s / 2 + v.area.width / 2 - 60, WsArt.comp.height * v.s / 2 + v.area.height / 2 - 60);
    final p = _pan + by;
    setState(() => _pan = Offset(p.dx.clamp(-lim.dx, lim.dx), p.dy.clamp(-lim.dy, lim.dy)));
  }

  // The picked thing's way over its time: where the inside places it, moment by moment (motolii_path, its wave and all),
  // in points of the picture, drawn thin with arrows the way it goes (Alight Motion's motion path). Asked again only
  // when the document or the pick changes; none when it stays put.
  (Object?, List<Offset>?) _trail = (null, null);
  List<Offset>? _trailOf() {
    final ws = WsScope.read(context), m = ws.inside, t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || const {'behaviour', 'camera', 'light'}.contains(m.word(t, 'kind'))) return null;
    final key = (ws.rev, t);
    if (_trail.$1 != key) {
      _trail = (key, null);
      final start = m.value(t, 'start', 0) ?? 0, lasts = m.lasts(t), end = lasts > 0 ? start + lasts : m.seconds;
      if (end > start) {
        m.path(t, from: start, to: end, n: 90).then((p) {
          if (!mounted || _trail.$1 != key || p == null) return;
          final c = WsArt.centre, pts = [for (var i = 0; i + 1 < p.length; i += 4) c + Offset(p[i], -p[i + 1]) * m.point];
          setState(() => _trail = (key, pts.any((q) => (q - pts.first).distance > 1) ? pts : null));
        });
      }
    }
    return _trail.$2;
  }

  final _menu = GlobalKey<WsMenuState>();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final v = _shown = _view(box.biggest), scene = widget.scene, trail = _trailOf();
      _deskTo(v);
      _pickTo();
      return WsMenu(
        key: _menu,
        child: Listener(
        onPointerSignal: (e) => _scroll(e, v),
        child: WsTwoFingers(
        onPan: (by, _) => _panBy(by, v),
        child: MouseRegion(
          onHover: (e) {
            widget.cursor.value = v.toComp(e.localPosition);
            final h = _hit(v, e.localPosition);
            if (h != _hover) setState(() => _hover = h);
          },
          onExit: (_) {
            widget.cursor.value = null;
            if (_hover != null) setState(() => _hover = null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            supportedDevices: wsPressing,
            onSecondaryTapDown: (d) {   // (the thing under the hand, its menu as on its bar)
              final ws = WsScope.read(context), id = _hit(v, d.localPosition), l = ws.layers.where((l) => l.id == id).firstOrNull;
              if (l != null) _menu.currentState?.show(d.localPosition, wsThingMenu(context, ws, l));
            },
            onTapUp: (d) {
              widget.onPoke?.call();
              if (widget.make == 'pen') return _pen(v, d.localPosition, d.localPosition); // (a tap: a corner)
              if (widget.make == 'brush') return; // (a stroke is drawn, not tapped)
              if (widget.make != null) return _draw(v, _drawFrom = d.localPosition); // (only come down: one as it comes, there)
              final hit = _hit(v, d.localPosition), ws = WsScope.read(context), m = ws.inside;
              if (HardwareKeyboard.instance.isShiftPressed || HardwareKeyboard.instance.isMetaPressed) return hit == null ? null : wsPickAlso(ws, hit); // (Shift or Cmd: one more picked together, or one less; on nothing, nothing lost)
              final twice = hit != null && hit == _tapped;
              _tapWait?.cancel();
              _tapped = twice ? null : hit;
              if (!twice) _tapWait = Timer(kDoubleTapTimeout, () => _tapped = null);
              ws.select(hit);
              final crop = twice && m != null && _photo(m, int.parse(hit)) ? hit : null;
              if (crop != _cropping) setState(() => _cropping = crop);
            },
            dragStartBehavior: DragStartBehavior.down, // (a thing is held where the hand came down, not where it had got to when the drag was known for one)
            onPanStart: (d) => _hold(v, _last = d.localPosition),
            onPanUpdate: (d) => _brush != null
                ? setState(() => _brush!.add(d.localPosition))
                : _lasso != null
                ? setState(() => _lasso!.add(d.localPosition))
                : _drawFrom != null
                ? setState(() {
                    _last = d.localPosition;   // (where the hand is, for every tool: inside `_penWay?.add(…)` it was skipped with the pen's list, and a rect was made where the hand came down)
                    _penWay?.add(d.localPosition);
                  })
                : _pulling != null
                ? (widget.cursor.value = v.toComp(_last = d.localPosition))
                : _carry(v, _last = d.localPosition),
            onPanEnd: (_) => _brush != null
                ? _brushLetGo(v)
                : _lasso != null
                ? _lassoLetGo(v)
                : _drawFrom != null
                ? (widget.make == 'pen' ? _pen(v, _drawFrom!, _last ?? _drawFrom!) : _draw(v, _last ?? _drawFrom!))
                : _pulling != null
                ? _pullLetGo(v, _last!)
                : _letGo(),
            onPanCancel: () => _brush != null ? setState(() => _brush = null) : _lasso != null ? setState(() => _lasso = null) : _drawFrom != null ? setState(() => _drawFrom = null) : _pulling != null ? _pulling = null : _letGo(keep: false),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _ViewPainter(scene, v, widget.selected, _hover == widget.selected ? null : _hover, grid: widget.grid, safe: widget.safe, part: widget.texture == null ? _Part.all : _Part.under, pivots: widget.pivots, met: _met, trail: trail, parent: _parentOf(), grip: _grip, form: _formOf(), crop: _cropOf()),
                  ),
                ),
                if (_desk case final desk? when widget.texture != null) ...[ // (the whole pane as the inside draws it: off the stage covered half way, the picked thing marked)
                  Positioned.fromRect(rect: v.area, child: IgnorePointer(child: Texture(textureId: desk, filterQuality: FilterQuality.medium))),
                  Positioned.fromRect(rect: v.comp, child: const IgnorePointer(child: SizedBox(key: ValueKey('ws-stage-comp')))), // (where the picture lies in it)
                ] else
                Positioned.fromRect(
                  rect: v.comp,
                  child: IgnorePointer(
                    child: widget.texture == null
                        ? const SizedBox(key: ValueKey('ws-stage-comp'))
                        : ClipRect(key: const ValueKey('ws-stage-comp'), child: Texture(textureId: widget.texture!, filterQuality: FilterQuality.medium)),
                  ),
                ),
                if (widget.snapshot case final shot?)   // (Show Snapshot held: the earlier picture where the picture lies)
                  Positioned.fromRect(rect: v.comp, child: IgnorePointer(child: Image.file(File(shot), key: const ValueKey('ws-stage-snapshot'), fit: BoxFit.fill, gaplessPlayback: true))),
                if (int.tryParse(widget.selected ?? '') case final picked? when WsScope.read(context).inside != null) // (the picked path's own points, to be taken hold of)
                  IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _PointsPainter([for (final p in WsScope.read(context).inside!.points(picked)) v.toScreen(WsArt.toView(widget.scene, p))],
                      [for (final (h, o) in WsScope.read(context).inside!.handles(picked)) (v.toScreen(WsArt.toView(widget.scene, h)), v.toScreen(WsArt.toView(widget.scene, o)))]))),
                if (_drawFrom case final from? when _last != null && widget.make == 'pen' && _penWay != null && _scribbled(_penWay!, from, _last!)) // (a scribble: its way, thin, as the brush's; made a path when let go)
                  IgnorePointer(child: CustomPaint(painter: _BrushWay(_penWay!, WsT.accent)))
                else if (_drawFrom case final from? when _last != null && widget.make == 'pen') // (the pen's handle being drawn out: through its point, both ways)
                  IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _HandlePainter(from, _last!)))
                else if (_drawFrom case final from? when _last != null) // (what is being drawn: its box)
                  Positioned.fromRect(
                    rect: Rect.fromPoints(from, _last!),
                    child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: WsT.accent)))),
                  ),
                if (_held case final h? when h.moved && _last != null)   // (the numbers while a hand moves it, by the hand, as Figma shows them; Alight Motion shows none)
                  if (_heldSays(h.by) case final says?)
                    Positioned(
                      left: _last!.dx + 16,
                      top: _last!.dy + 16,
                      child: IgnorePointer(
                        child: Container(
                          key: const ValueKey('ws-held-says'),
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(6), vertical: Shape.s(3)),
                          decoration: BoxDecoration(color: WsT.raised, borderRadius: BorderRadius.all(Shape.r(3))),
                          child: Text(says, style: T.micro(Grey.g95)),
                        ),
                      ),
                    ),
                if (widget.texture != null)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ViewPainter(scene, v, widget.selected, _hover == widget.selected ? null : _hover, grid: widget.grid, safe: widget.safe, part: _Part.over, pivots: widget.pivots, met: _met, marked: _desk != null, trail: trail, parent: _parentOf(), grip: _grip, form: _formOf(), crop: _cropOf()),
                    ),
                  ),
                IgnorePointer(child: CustomPaint(painter: _RulerPainter(v, widget.cursor, scene))),
                _RelationMarks(scene: scene, v: v, lasso: _lasso),
                if (_brush case final way?) IgnorePointer(child: CustomPaint(painter: _BrushWay(way, WsT.accent))), // (the way drawn so far, thin: the stroke itself is the inside's once let go) // (drawn round, the things picked together, the relation picked: its shape, its handles, what it moves)
                Positioned(
                  left: _V.ruler + _V.pad,
                  bottom: _V.pad,
                  child: _Hud(scale: v.s, cursor: widget.cursor),
                ),
                if (widget.zoom != 0 && box.maxWidth > 360 && box.maxHeight > 220)
                  Positioned(
                    right: _V.pad,
                    bottom: _V.pad,
                    child: _Navigator(scene: scene, view: v, texture: widget.texture),
                  ),
              ],
            ),
          ),
        ),
        ),
        ),
      );
    },
  );
}

class _BrushWay extends CustomPainter {
  const _BrushWay(this.way, this.ink);
  final List<Offset> way;
  final Color ink;
  @override
  void paint(Canvas c, Size s) => c.drawPoints(PointMode.polygon, way, Paint()
    ..color = ink
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round);
  @override
  bool shouldRepaint(_BrushWay o) => true;
}
