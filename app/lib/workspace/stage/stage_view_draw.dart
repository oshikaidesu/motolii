// The stage's drawing tools, as the hand lets go on the view: the lasso's pick, a rectangle or ellipse dragged out, a
// pen scribble fitted to a curve, the brush's freehand way.
// (setState from an extension on the State itself: the analyzer allows it only in a class or mixin)
// ignore_for_file: invalid_use_of_protected_member
part of 'stage_view.dart';

extension _StageViewDraw on _StageViewState {
  void _lassoDragEnd(_View v) {
    final round = _lasso, ws = WsScope.read(context);
    setState(() => _lasso = null);
    if (round == null || round.length < 3) return;
    // (drawn straight, it is a box from where the hand came down to where it let go (Figma's, AE's); else the line it drew round)
    final a = round.first, z = round.last, along = z - a;
    final straight = along.distance > 4 && round.every((p) => ((p - a).dx * along.dy - (p - a).dy * along.dx).abs() / along.distance < 12);
    final path = straight ? (Path()..addRect(Rect.fromPoints(a, z))) : (Path()..addPolygon(round, true));
    ws.pickMany([
      for (final l in widget.scene.layers)
        if (widget.scene.box(l.id) case final b? when path.contains(v.toScreen(WsArt.toView(widget.scene, b.c)))) l.id,
    ]);
  }

  void _draw(_View v, Offset to) {
    final from = _drawFrom, ws = WsScope.read(context), m = ws.inside, kind = widget.make;
    _drawFrom = null;
    setState(() {});
    if (from == null || m == null || kind == null) return;
    final a = v.toComp(from), b = v.toComp(to), p = m.point, c = WsArt.comp;
    final centred = kind == 'circle' && widget.fromCentre; // (drawn out from its middle: twice as large about where the hand came down)
    final mid = centred ? a : (a + b) / 2, d = centred ? (b - a) * 2 : b - a, tiny = d.distance < 6 / v.s;
    final x = ((kind == 'text' || tiny ? a.dx : mid.dx) - c.width / 2) / p, y = (c.height / 2 - (kind == 'text' || tiny ? a.dy : mid.dy)) / p;
    final cut = widget.mask ? int.tryParse(ws.selected ?? '') : null;
    // (one step, asked without waiting: the new thing is the one the add made (thing -1), picked once it is there)
    final before = m.layers.length;
    m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later('add', name: kind == 'text' ? '' : 'shape', word: kind == 'text' ? ws.bodyFace : kind),
      null,
      (t) => made = t,
    ); // (a text in the body's font, as a text box is in PowerPoint's Body font)
    m
      ..later('set', layer: -1, name: 'x', number: x)
      ..later('set', layer: -1, name: 'y', number: y);
    wsInked(ws, kind == 'text' ? 'text' : 'shape', kind); // (the drawing inks)
    if (kind == 'text') {
      m.later('set', layer: -1, name: 'anchor_x', number: -1); // (the words begin where the hand came down: After Effects' point text, Figma's, Illustrator's)
    }
    if (cut != null) {
      // (Mask: it lies just behind the picked thing, and that one is clipped by it; not seen itself: it only cuts, as After Effects' matte)
      final all = m.layers;
      if (all.contains(cut)) {
        m
          ..later('raise', layer: -1, number: (all.indexOf(cut) - before).toDouble())
          ..later('set', layer: cut, name: 'clip', number: 1)
          ..later('set', layer: -1, name: 'opacity', number: 0);
      }
    }
    if (!tiny && kind != 'text') {
      if (kind == 'line') {
        // (a line is a twenty-fifth of a unit thick: as long as drawn, turned as drawn)
        m
          ..later('set', layer: -1, name: 'wide', number: d.distance / p / .04)
          ..later('set', layer: -1, name: 'rotate', number: math.atan2(d.dy, d.dx) * 180 / math.pi);
      } else {
        m
          ..later('set', layer: -1, name: 'size', number: d.dy.abs() / p)
          ..later('set', layer: -1, name: 'wide', number: d.dx.abs() / math.max(d.dy.abs(), 1e-3));
      }
    }
    ws.after(m.later('together'), (done, _) {
      if (!done || made <= 0) return;
      if (kind == 'text') textToType = true; // (typed at once: the Text card takes the keys, inspector_material.dart)
      ws.select('$made');
    });
    ws.setView('stage.tool', 0); // (one drawn, the hand is free: Alight Motion's Add is one act and Figma's tool goes back to select; After Effects' stays, so they part and Alight Motion decides: golf_noise.md head, ㊼)
  }

  /// The pen's scribble made one smooth path (the user, 11/5: drawn wobbly, then made right, as curve-fit-nd makes it):
  /// within 8 points of the window of the hand's way, as Blender's Draw Curve tool fits its stroke (its error 8 of the
  /// screen's, editcurve_paint.cc), its anchors and handles then the pen's own to move. Back where it began: closed and
  /// filled as the pen's are; else a line of the ink.
  void _fit(_View v, List<Offset> way) {
    final ws = WsScope.read(context), m = ws.inside!;
    _penning = false; // (a path of its own: the pen's next point begins another)
    final points = [for (final p in way) _doc(v, p)], error = (_doc(v, way.first + const Offset(8, 0)) - points.first).distance;
    final closed = (points.first - points.last).distance < 4 * error;
    m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later('curve', word: '$error ${[for (final p in points) '${p.dx} ${p.dy}'].join(' ')}'),
      (done, why) => done ? null : ws.notice = why,
      (t) => made = t,
    );
    if (closed) {
      wsInked(ws, 'shape', 'path');
    } else {
      m
        ..later('say', layer: -1, name: 'fill', word: 'none')
        ..later('say', layer: -1, name: 'stroke', word: ws.ink.isEmpty || ws.ink.contains(' ') ? 'ffffff' : ws.ink)
        ..later('set', layer: -1, name: 'stroke_width', number: 6);
    }
    ws.after(m.later('together'), (done, _) => done && made > 0 ? ws.select('$made') : null);
  }

  void _brushDragEnd(_View v) {
    final way = _brush, ws = WsScope.read(context), m = ws.inside;
    setState(() => _brush = null);
    if (way == null || way.length < 2 || m == null) return;
    final options = StrokeOptions(size: widget.brushSize, simulatePressure: true, isComplete: true);
    final points = getStrokePoints([for (final p in way) PointVector.fromOffset(offset: _doc(v, p))], options: options);
    if (points.length < 2) return;
    getStrokeOutlinePoints(points, options: options, rememberSimulatedPressure: true);
    final said = [
      for (final p in points) '${p.point.x} ${p.point.y} ${2 * getStrokeRadius(options.size, options.thinning, p.pressure, options.easing) / options.size}',
    ];
    if (widget.brushTool == 3) {
      // (an eraser: taken from the picked drawing, as Alight Motion's eraser takes from the drawing layer it is in)
      final into = int.tryParse(ws.selected ?? '');
      if (into == null) {
        ws.notice = 'Pick a drawing to erase from';
        return;
      }
      ws.after(m.later('brush', layer: into, word: '3 ${options.size} ${said.join(' ')}'), (done, why) {
        if (!done) ws.notice = why;
      });
      return;
    }
    m.later('together', number: 1);
    var made = 0;
    ws.after(m.later('brush', word: '${widget.brushTool} ${options.size} ${said.join(' ')}'), null, (t) => made = t);
    m.later(
      'say',
      layer: -1,
      name: 'fill',
      word: ws.ink.isEmpty ? 'ffffff' : ws.ink,
    ); // (an outline with no fill shows nothing: white, as a drawing app's brush begins, when no ink is chosen)
    ws.after(m.later('together'), (done, _) => done && made > 0 ? ws.select('$made') : null);
  }
}
