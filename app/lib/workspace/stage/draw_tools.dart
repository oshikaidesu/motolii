// The stage's drawing tools: the lasso, a dragged-out rectangle, ellipse, line or text, the pen with its fitted
// scribble, and the freehand brush. Each keeps the stroke while the pointer is down and makes the layer on release.
import 'dart:math' as math;
import 'dart:ui' show Offset, Path, Rect;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:perfect_freehand/perfect_freehand.dart'
    show getStrokeOutlinePoints, getStrokePoints, PointVector, StrokeOptions;
import 'package:perfect_freehand/src/get_stroke_radius.dart'
    show getStrokeRadius; // How wide the pressure makes a point. The package keeps it private, so it is imported from src.

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/widgets/text_gestures.dart' show textToType;
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The strokes of the stage's drawing tools: the lasso, the shape and text tools, the pen and the brush.
///
/// The view decides which tool a press begins and calls that tool's methods here. Listeners are told when a stroke
/// has changed what the stage draws.
class DrawTools extends ChangeNotifier {
  /// The drawing tools of the view [_stage].
  DrawTools(this._stage);

  final StageContext _stage;

  /// Where the pointer went down to draw a layer with the current tool, or null when none is being drawn.
  ///
  /// A rectangle or ellipse fills the box from there to where the pointer is released, a line runs between the
  /// points, text goes where the pointer went down. A click alone creates the layer at once. It is one undo step and
  /// the new layer is selected.
  Offset? get drawFrom => _drawFrom;
  Offset? _drawFrom;

  /// The lasso being drawn on empty stage with no tool, in the stage's own coordinates, or null.
  ///
  /// The layers whose centres are inside are selected together, and the actions available for them are offered
  /// beside them.
  List<Offset>? get lasso => _lasso;
  List<Offset>? _lasso;

  // The pen: each pointer-down places a point and dragging pulls out its handle; a click alone makes a corner point. The first
  // point goes to the selected layer, later ones to the path the pen created (layer -1). The engine works out the rest:
  // starting a path, closing it on its first point, adding or removing a point on a closed path.
  bool _penning = false;

  /// The pointer's path while the pen is down, or null. A scribble rather than a handle becomes a path of its own.
  List<Offset>? get penWay => _penWay;
  List<Offset>? _penWay;

  /// The brush stroke so far, in the stage's own coordinates, or null when the brush is not down.
  ///
  /// On release the points are smoothed by perfect-freehand (MIT, Steve Ruiz; Dart port by Adil Hanney), which also
  /// simulates pressure from speed. The engine keeps the stroke and builds its outline the way Alight Motion's brush
  /// does. Each point's pressure is its radius here over half the brush size.
  List<Offset>? get brush => _brush;
  List<Offset>? _brush;

  /// Ends the path the pen is drawing, so that its next point starts a new one.
  void endPenPath() {
    _penning = false;
  }

  /// Starts a brush stroke at [local].
  void brushDragStart(Offset local) {
    _brush = [local];
    notifyListeners();
  }

  /// Adds [local] to the brush stroke.
  void brushDragUpdate(Offset local) {
    _brush!.add(local);
    notifyListeners();
  }

  /// Gives up the brush stroke.
  void brushDragCancel() {
    _brush = null;
    notifyListeners();
  }

  /// Starts a lasso at [local].
  void lassoDragStart(Offset local) {
    _lasso = [local];
    notifyListeners();
  }

  /// Adds [local] to the lasso.
  void lassoDragUpdate(Offset local) {
    _lasso!.add(local);
    notifyListeners();
  }

  /// Gives up the lasso.
  void lassoDragCancel() {
    _lasso = null;
    notifyListeners();
  }

  /// Starts drawing a layer with the current tool from [local]. The pen also starts recording the pointer's path.
  void drawDragStart(Offset local) {
    if (_stage.tool.make == 'pen') _penWay = [local];
    _drawFrom = local;
    notifyListeners();
  }

  /// Carries the drawing on to [local]: the pen's path grows, and the stage draws the box or the handle again.
  void drawDragUpdate(Offset local) {
    _penWay?.add(local);
    notifyListeners();
  }

  /// Gives up the layer being drawn.
  void drawDragCancel() {
    _drawFrom = null;
    notifyListeners();
  }

  /// Creates one layer of the current tool's kind at [local], at its default size: a click with the tool.
  void drawAt(StageViewport v, Offset local) =>
      drawDragEnd(v, _drawFrom = local);

  /// Selects the layers whose centre lies inside the lasso.
  void lassoDragEnd(StageViewport v) {
    final round = _lasso, ws = _stage.workspace;
    _lasso = null;
    notifyListeners();
    if (round == null || round.length < 3) return;
    // A nearly straight drag selects the box between its ends, as in Figma and After Effects. Otherwise the drawn
    // outline is used.
    final a = round.first, z = round.last, along = z - a;
    final straight =
        along.distance > 4 &&
        round.every(
          (p) =>
              ((p - a).dx * along.dy - (p - a).dy * along.dx).abs() /
                  along.distance <
              12,
        );
    final path = straight
        ? (Path()..addRect(Rect.fromPoints(a, z)))
        : (Path()..addPolygon(round, true));
    ws.pickMany([
      for (final l in _stage.scene.layers)
        if (_stage.scene.box(l.id) case final b?
            when path.contains(v.toScreen(b.c)))
          l.id,
    ]);
  }

  /// Creates a layer of the active tool's kind from a drag that started at [drawFrom] and ended at [to].
  /// A drag shorter than 6 screen pixels creates the layer at its default size.
  void drawDragEnd(StageViewport v, Offset to) {
    final from = _drawFrom,
        ws = _stage.workspace,
        m = ws.inside,
        kind = _stage.tool.make;
    _drawFrom = null;
    notifyListeners();
    if (from == null || m == null || kind == null) return;
    final a = v.toComposition(from),
        b = v.toComposition(to),
        p = m.point,
        c = ArtGeometry.comp;
    // Drawn out from its centre: twice the drag, centred on where the drag started.
    final centred = kind == 'circle' && _stage.tool.fromCentre;
    final mid = centred ? a : (a + b) / 2,
        d = centred ? (b - a) * 2 : b - a,
        tiny = d.distance < 6 / v.scale;
    final x = ((kind == 'text' || tiny ? a.dx : mid.dx) - c.width / 2) / p,
        y = (c.height / 2 - (kind == 'text' || tiny ? a.dy : mid.dy)) / p;
    final cut = _stage.tool.mask ? int.tryParse(ws.selected ?? '') : null;
    // Queue everything as one undo step. Layer -1 refers to the layer just added, which is selected once it exists.
    final before = m.layers.length;
    m.later('together', number: 1);
    var made = 0;
    // Text uses the body font, as a text box does in PowerPoint.
    ws.after(
      m.later(
        'add',
        name: kind == 'text' ? '' : 'shape',
        word: kind == 'text' ? ws.bodyFace : kind,
      ),
      null,
      (t) => made = t,
    );
    m
      ..later('set', layer: -1, name: 'x', number: x)
      ..later('set', layer: -1, name: 'y', number: y);
    // Apply the current drawing colours.
    applyChosenInks(ws, kind == 'text' ? 'text' : 'shape', kind);
    if (kind == 'text') {
      // The text starts where the drag started, as point text does in After Effects, Figma and Illustrator.
      m.later('set', layer: -1, name: 'anchor_x', number: -1);
    }
    if (cut != null) {
      // Mask: the new layer sits just behind the selected layer, which it clips. It is invisible itself and only cuts,
      // like an After Effects matte.
      final all = m.layers;
      if (all.contains(cut)) {
        m
          ..later(
            'raise',
            layer: -1,
            number: (all.indexOf(cut) - before).toDouble(),
          )
          ..later('set', layer: cut, name: 'clip', number: 1)
          ..later('set', layer: -1, name: 'opacity', number: 0);
      }
    }
    if (!tiny && kind != 'text') {
      if (kind == 'line') {
        // A line is 1/25 of a unit thick, as long as the drag and rotated to match it.
        m
          ..later('set', layer: -1, name: 'wide', number: d.distance / p / .04)
          ..later(
            'set',
            layer: -1,
            name: 'rotate',
            number: math.atan2(d.dy, d.dx) * 180 / math.pi,
          );
      } else {
        m
          ..later('set', layer: -1, name: 'size', number: d.dy.abs() / p)
          ..later(
            'set',
            layer: -1,
            name: 'wide',
            number: d.dx.abs() / math.max(d.dy.abs(), 1e-3),
          );
      }
    }
    ws.after(m.later('together'), (done, _) {
      if (!done || made <= 0) return;
      // The new text's field takes the keyboard at once (see inspector_parameter_controls_tile.dart).
      if (kind == 'text') textToType = true;
      ws.select('$made');
    });
    // Back to the select tool after one shape, as in Alight Motion's Add and Figma. After Effects keeps the tool.
    ws.setView('stage.tool', 0);
  }

  /// Places a pen point at [down] with its handle pulled out to [up]; a click, where the two are the same, makes a
  /// corner point. A scribble between them becomes a fitted path instead.
  void pen(StageViewport v, Offset down, Offset up) {
    final ws = _stage.workspace, m = ws.inside, way = _penWay;
    _drawFrom = null;
    _penWay = null;
    notifyListeners();
    if (m == null) return;
    if (way != null && scribbled(way, down, up)) return _fit(v, way);
    final a = v.toComposition(down), h = v.toComposition(up) - a;
    final first = !_penning;
    _penning = true;
    if (first) m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later(
        'pen',
        layer: first ? int.tryParse(_stage.selected ?? '') ?? 0 : -1,
        word: '${a.dx} ${a.dy} ${h.dx} ${h.dy}',
      ),
      null,
      (t) => made = t,
    ); // On the first point a closed selected path gains or loses a point; otherwise a new path begins.
    if (first) {
      applyChosenInks(ws, 'shape', 'path');
      ws.after(
        m.later('together'),
        (done, _) => done && made > 0 ? ws.select('$made') : null,
      );
    }
  }

  /// Whether the pointer path strayed more than 16 points from the straight line a handle is dragged along, so it was a
  /// freehand line, not a handle.
  static bool scribbled(List<Offset> way, Offset down, Offset up) {
    final d = up - down, long = d.distance;
    return way.any(
      (p) =>
          (long < 1
              ? (p - down).distance
              : ((p - down).dx * d.dy - (p - down).dy * d.dx).abs() / long) >
          16,
    );
  }

  /// Fits one smooth path to the pen scribble [way], as curve-fit-nd does.
  ///
  /// The fit stays within 8 screen pixels of the scribble, like Blender's Draw Curve tool (editcurve_paint.cc). The
  /// result has ordinary pen anchors and handles that the user can move. A scribble that ends where it began becomes
  /// a closed, filled path. Otherwise it becomes an open stroke in the current ink.
  void _fit(StageViewport v, List<Offset> way) {
    final ws = _stage.workspace, m = ws.inside!;
    // The fitted path is complete, so the next pen click starts a new one.
    _penning = false;
    final points = [for (final p in way) v.toComposition(p)],
        error = (v.toComposition(way.first + const Offset(8, 0)) - points.first)
            .distance;
    final closed = (points.first - points.last).distance < 4 * error;
    m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later(
        'curve',
        word: '$error ${[for (final p in points) '${p.dx} ${p.dy}'].join(' ')}',
      ),
      (done, why) => done ? null : ws.notice = why,
      (t) => made = t,
    );
    if (closed) {
      applyChosenInks(ws, 'shape', 'path');
    } else {
      m
        ..later('say', layer: -1, name: 'fill', word: 'none')
        ..later(
          'say',
          layer: -1,
          name: 'stroke',
          word: ws.ink.isEmpty || ws.ink.contains(' ') ? 'ffffff' : ws.ink,
        )
        ..later('set', layer: -1, name: 'stroke_width', number: 6);
    }
    ws.after(
      m.later('together'),
      (done, _) => done && made > 0 ? ws.select('$made') : null,
    );
  }

  /// Turns the brush stroke into a drawing layer, or erases from the selected drawing with the eraser.
  void brushDragEnd(StageViewport v) {
    final way = _brush, ws = _stage.workspace, m = ws.inside;
    _brush = null;
    notifyListeners();
    if (way == null || way.length < 2 || m == null) return;
    final options = StrokeOptions(
      size: _stage.tool.brushSize,
      simulatePressure: true,
      isComplete: true,
    );
    final points = getStrokePoints([
      for (final p in way) PointVector.fromOffset(offset: v.toComposition(p)),
    ], options: options);
    if (points.length < 2) return;
    getStrokeOutlinePoints(
      points,
      options: options,
      rememberSimulatedPressure: true,
    );
    final said = [
      for (final p in points)
        '${p.point.x} ${p.point.y} ${2 * getStrokeRadius(options.size, options.thinning, p.pressure, options.easing) / options.size}',
    ];
    if (_stage.tool.brushTool == 3) {
      // The eraser removes from the selected drawing, as Alight Motion's eraser does from the drawing layer it is in.
      final into = int.tryParse(ws.selected ?? '');
      if (into == null) {
        ws.notice = 'Pick a drawing to erase from';
        return;
      }
      ws.after(
        m.later(
          'brush',
          layer: into,
          word: '3 ${options.size} ${said.join(' ')}',
        ),
        (done, why) {
          if (!done) ws.notice = why;
        },
      );
      return;
    }
    m.later('together', number: 1);
    var made = 0;
    ws.after(
      m.later(
        'brush',
        word: '${_stage.tool.brushTool} ${options.size} ${said.join(' ')}',
      ),
      null,
      (t) => made = t,
    );
    // An outline with no fill shows nothing, so use white when no ink is chosen, as drawing apps do.
    m.later(
      'say',
      layer: -1,
      name: 'fill',
      word: ws.ink.isEmpty ? 'ffffff' : ws.ink,
    );
    ws.after(
      m.later('together'),
      (done, _) => done && made > 0 ? ws.select('$made') : null,
    );
  }
}
