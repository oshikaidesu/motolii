// Pan, zoom, hover, key handling and pointer gestures of the stage view.
import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiMoment, MotoliiWrites, MotoliiQuestions;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/stage/stage_view_camera.dart';
import 'package:motolii/workspace/stage/stage_view_drag.dart';
import 'package:motolii/workspace/stage/stage_view_draw.dart';
import 'package:motolii/workspace/stage/stage_view_painter.dart';
import 'package:motolii/workspace/stage/stage_view_relations.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

const _fixed = [0.0, .5, 1.0];

class StageViewState extends State<StageView> implements StageHandles {
  Offset _pan = Offset.zero;
  String? _hover;
  StageViewport? _shown; // The view as last laid out, so handle positions match the screen.

  @override
  String? hitAt(Offset global) {
    final box = context.findRenderObject() as RenderBox?, v = _shown;
    return box == null || v == null ? null : hitLocal(v, box.globalToLocal(global));
  }

  @override
  Map<String, Offset> get handles {
    final v = _shown, scene = widget.scene, b = WsArt.boxOf(scene, widget.selected), l = scene.layer(widget.selected);
    if (v == null || b == null || l == null) return const {};
    final (form, round) = _formOf();
    return selectionHandles(v.toScreen, b, knob: l.kind != WsKind.camera && l.id != 'bg', form: form, round: round, crop: _cropOf());
  }

  static const _crops = ['crop_left', 'crop_top', 'crop_right', 'crop_bottom'];

  /// The selected image's crop, as the share cut from each side, while it is being cropped; empty otherwise.
  List<double> _cropOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || _cropping != widget.selected || !_photo(m, t)) return const [];
    return [for (final n in _crops) m.value(t, n, 0) ?? 0];
  }

  static bool _photo(Motolii m, int t) =>
      m.word(t, 'kind') == 'picture' && RegExp(r'\.(jpe?g|png|webp|bmp)$', caseSensitive: false).hasMatch(m.word(t, 'file'));

  // Double-clicking a selected image starts cropping: bars appear on its sides until a click elsewhere or Enter.
  // Figma's Crop and Keynote's image editing work this way.
  String? _cropping;
  String? _tapped; // Layer id clicked a moment ago, until the double-click timeout passes.
  Timer? _tapWait;
  bool _enter(KeyEvent e) {
    // Ignored while the user is typing text.
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

  /// The selected shape's kind and corner radius, for its handles.
  (String, double) _formOf() {
    final m = WsScope.read(context).inside, t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return ('', 0);
    return (m.word(t, 'shape'), m.value(t, 'round', 0) ?? 0);
  }

  @override
  void didUpdateWidget(StageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) _pan = Offset.zero;
    if (oldWidget.make != widget.make) penning = false; // Another tool: the pen's next point starts a new shape.
  }

  // When the engine draws the whole pane, the stage sits inside it where this view puts it. The engine is told again when
  // that changes, after the frame, because it cannot be asked during build.
  int? _desk;
  StageViewport? _toldDesk;
  Motolii? _deskOf;
  double? _toldDpr;
  void _deskTo(StageViewport v) {
    final dpr = MediaQuery.devicePixelRatioOf(context), m = WsScope.read(context).inside;
    if (m != _deskOf) {
      // A different project was opened: forget the old engine view and send it again.
      _desk = null;
      _toldDesk = null;
      _toldPick = null;
    }
    if (widget.texture == null || (v == _toldDesk && dpr == _toldDpr)) return; // Also sent again when the window's pixel ratio changes.
    _toldDesk = v;
    _toldDpr = dpr;
    if ((_deskOf = m) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _toldDesk != v || _toldDpr != dpr) return;
      final m = _deskOf!;
      final ticket = m.desk(
        (v.area.width * dpr).round(),
        (v.area.height * dpr).round(),
        (v.o.dx - v.area.left) * dpr,
        (v.o.dy - v.area.top) * dpr,
        v.s * dpr,
        dpr,
      );
      void look(Duration _) {
        // Poll once per frame until the engine has drawn, so the window never blocks on it.
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

      SchedulerBinding.instance
        ..scheduleFrameCallback(look)
        ..ensureVisualUpdate();
    });
  }

  // With the engine drawing the pane: tells it which layer is selected and which is hovered whenever they change.
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
    _deskOf?.desk(0, 0, 0, 0, 0, 0); // Back to the engine's own stage view.
    dollyRest?.cancel();
    _tapWait?.cancel();
    HardwareKeyboard.instance.removeHandler(_enter);
    super.dispose();
  }

  StageViewport _view(Size size) {
    final area = Rect.fromLTRB(StageTokens.ruler, StageTokens.ruler, size.width, size.height);
    final fit = math.max(
      .02,
      math.min((area.width - StageTokens.fitMargin * 2) / WsArt.comp.width, (area.height - StageTokens.fitMargin * 2) / WsArt.comp.height),
    );
    final s = widget.zoom == 0 ? fit : _fixed[widget.zoom];
    final half = Offset(WsArt.comp.width * s, WsArt.comp.height * s) / 2;
    return StageViewport(area.center - half + _pan, s, area);
  }

  String? hitLocal(StageViewport v, Offset local) {
    // A layer off the canvas can still be grabbed by its frame and dragged back.
    final d = v.toComp(local), id = WsArt.hit(widget.scene, d), m = WsScope.read(context).inside;
    if (widget.group && m != null && id != null) {
      // Grouping: pick the outermost ancestor by following parents.
      var t = int.parse(id);
      for (var p = (m.value(t, 'parent', 0) ?? 0).round(), n = 0; p > 0 && n < 64; p = (m.value(t, 'parent', 0) ?? 0).round(), n++) {
        t = p;
      }
      return '$t';
    }
    return id;
  }

  // Dragging on the stage: the stage reports only how far the pointer moved, in canvas points. The engine decides what that
  // means for the layer (at its own depth) and for the document.
  ({Offset from, bool moved, String? by})? drag; // `by` names the handle (scale, turn or pivot); null means a plain move.
  String? heldGrip; // Handle being dragged; only it is shown, highlighted, during the drag (as in Alight Motion).

  // Snapping, as in After Effects: the left, middle and right edges (and top, middle, bottom) of the dragged layer stick to
  // the same lines of every other layer not grouped with it, of the canvas, or to a guide, within six screen points.
  // Holds the lines snapped to and the lines met.
  ({Rect box, List<(double, double)> xs, List<(double, double)> ys})? snapTo;
  (double?, double?) met = (null, null);

  // A guide being pulled out of a ruler (the top ruler gives a horizontal line, the left a vertical one) or an existing guide
  // being dragged. Released over the canvas it is saved in the document; released back over its ruler it is deleted.
  ({String axis, double? was})? pulling;

  Offset? _last;

  // A layer being drawn with the current tool, from where the pointer went down to where it is released. A rectangle or
  // ellipse fills that box, a line runs between the points, text goes where the pointer went down. A click alone creates
  // the layer at once. It is one undo step and the new layer is selected.
  Offset? drawFrom;

  // A lasso drawn on empty stage with no tool: the layers whose centres are inside are selected together (Ws.many), and the
  // actions available for them are offered beside them (make_relation.dart).
  List<Offset>? lasso;

  // The pen: each pointer-down places a point and dragging pulls out its handle; a click alone makes a corner point. The first
  // point goes to the selected layer, later ones to the path the pen created (layer -1). The engine works out the rest:
  // starting a path, closing it on its first point, adding or removing a point on a closed path.
  bool penning = false;
  List<Offset>? penWay; // Pointer path while the pen is down; a scribble rather than a handle becomes a path of its own.

  void _pen(StageViewport v, Offset down, Offset up) {
    final ws = WsScope.read(context), m = ws.inside, way = penWay;
    drawFrom = null;
    penWay = null;
    setState(() {});
    if (m == null) return;
    if (way != null && _scribbled(way, down, up)) return fit(v, way);
    final a = v.toComp(down), h = v.toComp(up) - a;
    final first = !penning;
    penning = true;
    if (first) m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later('pen', layer: first ? int.tryParse(widget.selected ?? '') ?? 0 : -1, word: '${a.dx} ${a.dy} ${h.dx} ${h.dy}'),
      null,
      (t) => made = t,
    ); // On the first point a closed selected path gains or loses a point; otherwise a new path begins.
    if (first) {
      wsInked(ws, 'shape', 'path');
      ws.after(m.later('together'), (done, _) => done && made > 0 ? ws.select('$made') : null);
    }
  }

  /// Whether the pointer path strayed more than 16 points from the straight line a handle is dragged along, so it was a
  /// freehand line, not a handle.
  static bool _scribbled(List<Offset> way, Offset down, Offset up) {
    final d = up - down, long = d.distance;
    return way.any((p) => (long < 1 ? (p - down).distance : ((p - down).dx * d.dy - (p - down).dy * d.dx).abs() / long) > 16);
  }

  // The brush stroke so far, in window points. On release the points are smoothed by perfect-freehand (MIT, Steve Ruiz; Dart
  // port by Adil Hanney), which also simulates pressure from speed. The engine keeps the stroke and builds its outline the
  // way Alight Motion's brush does. Each point's pressure is its radius here over half the brush size.
  List<Offset>? brush;
  ({double x, double y})? orbitFrom; // The camera's rotation when the drag started.
  double? dollyAt; // Its distance while the wheel turns.
  Timer? dollyRest;

  double orbitRate = .25; // Degrees of rotation per pixel dragged.
  ({double zoom, double reach, Offset middle})? lensFrom; // The frame's zoom, reach and centre when the drag started.

  void _dragUpdate(StageViewport v, Offset local) {
    final h = drag, ws = WsScope.read(context), m = ws.inside;
    if (h == null || m == null) return;
    if (h.by == 'gizmo orbit' && orbitFrom != null) {
      final d = (local - h.from) * orbitRate, o = orbitFrom!;
      m.dragUpdate('rotate_y', o.y + d.dx);
      m.dragUpdate('rotate_x', (o.x + d.dy).clamp(-89.0, 89.0));
      drag = (from: h.from, moved: true, by: h.by);
      return;
    }
    if (h.by == 'gizmo lens' && lensFrom != null) {
      // Compare the pointer's distance from the centre with where the drag began: further out is a larger frame, a wider lens.
      final l = lensFrom!;
      m.dragUpdate('zoom', (l.zoom * l.reach / math.max((local - l.middle).distance, 1)).clamp(.01, 100.0));
      drag = (from: h.from, moved: true, by: h.by);
      return;
    }
    if (h.by == 'orbit' && orbitFrom != null) {
      // Sideways rotates around the layer, up and down rotates over it: a quarter of a degree per pixel.
      final d = local - h.from, o = orbitFrom!;
      if (ws.freeEye) return ws.setView('stage.eye', [o.y - d.dx * .25, (o.x - d.dy * .25).clamp(-89.0, 89.0), ws.eye[2]]);
      m.dragUpdate('rotate_y', o.y - d.dx * .25);
      m.dragUpdate('rotate_x', (o.x - d.dy * .25).clamp(-89.0, 89.0));
      drag = (from: h.from, moved: true, by: 'orbit');
      setState(() {});
      return;
    }
    final all = (local - h.from) / v.s; // Screen pixels to canvas points.
    if (h.by case final way? when way.startsWith('crop ')) {
      // Move the side in as far as the pointer goes inward from the cut edge, leaving at least some of the image.
      final side = int.parse(way.substring(5)), c = [for (var i = 0; i < 4; i++) handles['corner $i'] ?? Offset.zero], crop = _cropOf();
      final across = side.isEven ? c[1] - c[0] : c[3] - c[0], len = math.max(1.0, across.distance), dir = across / len * (side < 2 ? 1.0 : -1.0);
      final at = handles[way] ?? h.from, inBy = ((local - at).dx * dir.dx + (local - at).dy * dir.dy) / len;
      if (crop.length == 4) m.dragUpdate(_crops[side], (crop[side] + inBy).clamp(0.0, .95 - crop[(side + 2) % 4]));
      drag = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    if (h.by case final way? when way == 'round' || way == 'points') {
      // Shape handles: corner radius or number of points follows the pointer.
      final c = [for (var i = 0; i < 4; i++) handles['corner $i'] ?? Offset.zero], g = gripOf(c), t = int.tryParse(widget.selected ?? '');
      if (way == 'round') m.dragUpdate('round', g.roundOf(local));
      if (way == 'points' && t != null) {
        m.dragUpdate(
          'points',
          ((m.value(t, 'points', 0) ?? 5) + (((local - h.from).dx * g.u.dx + (local - h.from).dy * g.u.dy) / 24).round()).clamp(3, 64).toDouble(),
        );
      }
      drag = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    if (h.by case final way?) {
      var gone = v.toComp(local) - v.toComp(h.from);
      // As in Figma: a corner handle resizes freely in both directions with the opposite side fixed; a side handle resizes that
      // way only. Shift keeps the aspect ratio or rotates in 15 degree steps; Alt scales from the centre.
      final keys = HardwareKeyboard.instance, sized = way == 'scale' || way == 'edge', even = keys.isShiftPressed && (sized || way == 'turn') ? 'even_' : '';
      if (heldGrip case final g? when way == 'edge') {
        final at = handles[g], across = handles['side ${(int.parse(g.substring(5)) + 2) % 4}'];
        if (at != null && across != null && (at - across).distance > 1) {
          final n = (at - across) / (at - across).distance;
          gone = n * (gone.dx * n.dx + gone.dy * n.dy);
        }
      }
      m.dragUpdate('$even${sized ? (keys.isAltPressed ? 'scale' : 'side') : way}', gone.dx, gone.dy);
      drag = (from: h.from, moved: true, by: way);
      setState(() {});
      return;
    }
    // The Move tool. Shift locks to horizontal or vertical, whichever the pointer has gone further, as in Illustrator and Figma.
    final axis = widget.axis == 0 && HardwareKeyboard.instance.isShiftPressed ? (all.dx.abs() >= all.dy.abs() ? 1 : 2) : widget.axis;
    final by = snapped(switch (axis) {
      1 => Offset(all.dx, 0),
      2 => Offset(0, all.dy),
      _ => all,
    }, v.s);
    m.dragUpdate('place', by.dx, by.dy);
    drag = (from: h.from, moved: true, by: null);
    setState(() {});
  }

  /// Pans by [by] (two-finger trackpad movement, or the wheel in the other direction) when zoomed in. At Fit there is nowhere to pan.
  void _panBy(Offset by, StageViewport v) {
    if (widget.zoom == 0) return;
    final lim = Offset(WsArt.comp.width * v.s / 2 + v.area.width / 2 - 60, WsArt.comp.height * v.s / 2 + v.area.height / 2 - 60);
    final p = _pan + by;
    setState(() => _pan = Offset(p.dx.clamp(-lim.dx, lim.dx), p.dy.clamp(-lim.dy, lim.dy)));
  }

  // The selected layer's motion path over time as the engine computes it (including its wave), in canvas points, drawn thin
  // with direction arrows as in Alight Motion. Recomputed only when the document or the selection changes; null when the
  // layer stays put.
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
        child: WsTwoFingers(
          onWheel: (d) => widget.make == 'camera' ? dolly(d.dy) : _panBy(-d, v),
          onPan: (by, _) => _panBy(by, v),
          child: MouseRegion(
            onHover: (e) {
              widget.cursor.value = v.toComp(e.localPosition);
              final h = hitLocal(v, e.localPosition);
              if (h != _hover) setState(() => _hover = h);
            },
            onExit: (_) {
              widget.cursor.value = null;
              if (_hover != null) setState(() => _hover = null);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              supportedDevices: wsPressing,
              onSecondaryTapDown: (d) {
                // Context menu for the layer under the pointer, same as on its bar.
                final ws = WsScope.read(context), id = hitLocal(v, d.localPosition), l = ws.layers.where((l) => l.id == id).firstOrNull;
                if (l != null) _menu.currentState?.show(d.localPosition, wsThingMenu(context, ws, l));
              },
              onTapUp: (d) {
                widget.onPoke?.call();
                if (widget.make == 'pen') return _pen(v, d.localPosition, d.localPosition); // A click makes a corner point.
                if (widget.make == 'brush') return; // A stroke is drawn, not clicked.
                if (widget.make != null) return draw(v, drawFrom = d.localPosition); // A click creates one layer there.
                final hit = hitLocal(v, d.localPosition), ws = WsScope.read(context), m = ws.inside;
                if (HardwareKeyboard.instance.isShiftPressed || HardwareKeyboard.instance.isMetaPressed) {
                  return hit == null ? null : wsPickAlso(ws, hit); // Shift or Cmd adds or removes the layer; on empty space nothing is lost.
                }
                final twice = hit != null && hit == _tapped;
                _tapWait?.cancel();
                _tapped = twice ? null : hit;
                if (!twice) _tapWait = Timer(kDoubleTapTimeout, () => _tapped = null);
                ws.select(hit);
                final crop = twice && m != null && _photo(m, int.parse(hit)) ? hit : null;
                if (crop != _cropping) setState(() => _cropping = crop);
              },
              dragStartBehavior: DragStartBehavior.down, // Grab the layer where the pointer went down, not where it had got to when the drag was recognised.
              onPanStart: (d) => dragStart(v, _last = d.localPosition),
              onPanUpdate: (d) => brush != null
                  ? setState(() => brush!.add(d.localPosition))
                  : lasso != null
                  ? setState(() => lasso!.add(d.localPosition))
                  : drawFrom != null
                  ? setState(() {
                      _last = d.localPosition; // Record the pointer position for every tool, not only the pen.
                      penWay?.add(d.localPosition);
                    })
                  : pulling != null
                  ? (widget.cursor.value = v.toComp(_last = d.localPosition))
                  : _dragUpdate(v, _last = d.localPosition),
              onPanEnd: (_) => brush != null
                  ? brushDragEnd(v)
                  : lasso != null
                  ? lassoDragEnd(v)
                  : drawFrom != null
                  ? (widget.make == 'pen' ? _pen(v, drawFrom!, _last ?? drawFrom!) : draw(v, _last ?? drawFrom!))
                  : pulling != null
                  ? pullDragEnd(v, _last!)
                  : dragEnd(),
              onPanCancel: () => brush != null
                  ? setState(() => brush = null)
                  : lasso != null
                  ? setState(() => lasso = null)
                  : drawFrom != null
                  ? setState(() => drawFrom = null)
                  : pulling != null
                  ? pulling = null
                  : dragEnd(keep: false),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: ViewPainter(
                        scene,
                        v,
                        widget.selected,
                        _hover == widget.selected ? null : _hover,
                        grid: widget.grid,
                        safe: widget.safe,
                        part: widget.texture == null ? ViewPart.all : ViewPart.under,
                        pivots: widget.pivots,
                        met: met,
                        trail: trail,
                        parent: parentOf(),
                        grip: heldGrip,
                        form: _formOf(),
                        crop: _cropOf(),
                      ),
                    ),
                  ),
                  if (_desk case final desk? when widget.texture != null) ...[
                    // The whole pane as the engine draws it: the area off the stage is half covered and the selected layer is marked.
                    Positioned.fromRect(
                      rect: v.area,
                      child: IgnorePointer(
                        child: Texture(textureId: desk, filterQuality: FilterQuality.medium),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: v.comp,
                      child: const IgnorePointer(child: SizedBox(key: ValueKey('ws-stage-comp'))),
                    ), // Where the canvas lies inside it.
                  ] else
                    Positioned.fromRect(
                      rect: v.comp,
                      child: IgnorePointer(
                        child: widget.texture == null
                            ? const SizedBox(key: ValueKey('ws-stage-comp'))
                            : ClipRect(
                                key: const ValueKey('ws-stage-comp'),
                                child: Texture(textureId: widget.texture!, filterQuality: FilterQuality.medium),
                              ),
                      ),
                    ),
                  if (widget.snapshot case final shot?) // While Show Snapshot is held, the earlier frame is drawn over the canvas.
                    Positioned.fromRect(
                      rect: v.comp,
                      child: IgnorePointer(
                        child: Image.file(File(shot), key: const ValueKey('ws-stage-snapshot'), fit: BoxFit.fill, gaplessPlayback: true),
                      ),
                    ),
                  if (int.tryParse(widget.selected ?? '') case final picked?
                      when WsScope.read(context).inside != null) // The selected path's own points, so they can be grabbed.
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: PointsPainter(
                          [for (final p in WsScope.read(context).inside!.points(picked)) v.toScreen(p)],
                          [for (final (h, o) in WsScope.read(context).inside!.handles(picked)) (v.toScreen(h), v.toScreen(o))],
                        ),
                      ),
                    ),
                  if (drawFrom case final from?
                      when _last != null &&
                          widget.make == 'pen' &&
                          penWay != null &&
                          _scribbled(penWay!, from, _last!)) // A scribble is drawn thin like the brush and becomes a path on release.
                    IgnorePointer(child: CustomPaint(painter: _BrushWay(penWay!)))
                  else if (drawFrom case final from?
                      when _last != null && widget.make == 'pen') // The pen's handle being pulled out, drawn through its point both ways.
                    IgnorePointer(
                      child: CustomPaint(size: Size.infinite, painter: PointsPainter([from], [(_last!, from), (from * 2 - _last!, from)])),
                    )
                  else if (drawFrom case final from? when _last != null) // The box of the layer being drawn.
                    Positioned.fromRect(
                      rect: Rect.fromPoints(from, _last!),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: Border.all(color: WsT.accent)),
                        ),
                      ),
                    ),
                  if (drag case final h?
                      when h.moved && _last != null) // Show the numbers beside the pointer while dragging, as Figma does; Alight Motion shows none.
                    if (heldSays(h.by) case final says?)
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
                        painter: ViewPainter(
                          scene,
                          v,
                          widget.selected,
                          _hover == widget.selected ? null : _hover,
                          grid: widget.grid,
                          safe: widget.safe,
                          part: ViewPart.over,
                          pivots: widget.pivots,
                          met: met,
                          marked: _desk != null,
                          trail: trail,
                          parent: parentOf(),
                          grip: heldGrip,
                          form: _formOf(),
                          crop: _cropOf(),
                        ),
                      ),
                    ),
                  IgnorePointer(child: CustomPaint(painter: RulerPainter(v, widget.cursor, scene))),
                  // Marks for the lasso, the layers picked together and the picked relation: its shape, handles and what it moves.
                  RelationMarks(scene: scene, v: v, lasso: lasso),
                  // The brush path so far, drawn thin; once released the stroke belongs to the engine.
                  if (brush case final way?) IgnorePointer(child: CustomPaint(painter: _BrushWay(way))),
                  Positioned(
                    left: StageTokens.ruler + StageTokens.pad,
                    bottom: StageTokens.pad,
                    child: Hud(scale: v.s, cursor: widget.cursor),
                  ),
                  if (widget.zoom != 0 && box.maxWidth > 360 && box.maxHeight > 220)
                    Positioned(
                      right: StageTokens.pad,
                      bottom: StageTokens.pad,
                      child: StageNavigator(scene: scene, view: v, texture: widget.texture),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _BrushWay extends CustomPainter {
  const _BrushWay(this.way);
  final List<Offset> way;
  @override
  void paint(Canvas c, Size s) => c.drawPoints(
    PointMode.polygon,
    way,
    Paint()
      ..color = WsT.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
  @override
  bool shouldRepaint(_BrushWay o) => true;
}
