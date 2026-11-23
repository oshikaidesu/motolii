// The stage's drawing tools: lasso, shape/text tools, pen and freehand brush.
import 'dart:math' as math;
import 'dart:ui' show Offset, Path, Rect;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:perfect_freehand/perfect_freehand.dart'
    show getStrokeOutlinePoints, getStrokePoints, PointVector;
// The package does not export getStrokeRadius (how wide the pressure makes a
// point), so it is imported from src.
// ignore: implementation_imports
import 'package:perfect_freehand/src/get_stroke_radius.dart'
    show getStrokeRadius;

import 'package:motolii/widgets/text_gestures.dart' show textToType;
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/stroke_smooth.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class DrawTools extends ChangeNotifier {
  DrawTools(this._stage);

  final StageContext _stage;

  /// Where the pointer went down to draw, or null.
  Offset? get drawFrom => _drawFrom;
  Offset? _drawFrom;

  /// The lasso being drawn, in stage coordinates, or null.
  List<Offset>? get lasso => _lasso;
  List<Offset>? _lasso;

  // First pen point goes to the selected layer; later ones to layer -1 (the
  // path the pen created). The engine handles close/add/remove.
  bool _penning = false;

  /// The pointer's path while the pen is down, or null. A scribble rather than a handle becomes a path of its own.
  List<Offset>? get penWay => _penWay == null
      ? null
      : StrokeStabilizer.liveSmooth(_penWay!, _stage.tool.smooth);
  List<Offset>? _penWay;

  /// The brush stroke so far, in stage coordinates, or null.
  /// Live-stabilized during drag and corner-preserving smoothed on release.
  List<Offset>? get brush => _brush == null
      ? null
      : StrokeStabilizer.liveSmooth(_brush!, _stage.tool.smooth);
  List<Offset>? _brush;

  void endPenPath() {
    _penning = false;
  }

  void brushDragStart(Offset local) {
    _brush = [local];
    notifyListeners();
  }

  void brushDragUpdate(Offset local) {
    _brush!.add(local);
    notifyListeners();
  }

  void brushDragCancel() {
    _brush = null;
    notifyListeners();
  }

  void lassoDragStart(Offset local) {
    _lasso = [local];
    notifyListeners();
  }

  void lassoDragUpdate(Offset local) {
    _lasso!.add(local);
    notifyListeners();
  }

  void lassoDragCancel() {
    _lasso = null;
    notifyListeners();
  }

  void drawDragStart(Offset local) {
    if (_stage.tool.make == 'pen') _penWay = [local];
    _drawFrom = local;
    notifyListeners();
  }

  void drawDragUpdate(Offset local) {
    _penWay?.add(local);
    notifyListeners();
  }

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
    // A nearly straight drag selects the box between its ends.
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
    final from = _drawFrom, ws = _stage.workspace, kind = _stage.tool.make;
    _drawFrom = null;
    notifyListeners();
    if (from == null || !stageConnected(ws) || kind == null) return;
    final a = v.toComposition(from),
        b = v.toComposition(to),
        p = stagePointsPerUnit(ws),
        c = ArtGeometry.comp;
    // Drawn out from its centre: twice the drag, centred on where the drag started.
    final centred = kind == 'circle' && _stage.tool.fromCentre;
    final mid = centred ? a : (a + b) / 2,
        d = centred ? (b - a) * 2 : b - a,
        tiny = d.distance < 6 / v.scale;
    final x = ((kind == 'text' || tiny ? a.dx : mid.dx) - c.width / 2) / p,
        y = (c.height / 2 - (kind == 'text' || tiny ? a.dy : mid.dy)) / p;
    final cut = _stage.tool.mask ? ws.selected : null;
    // Queue everything as one undo step. Layer -1 refers to the layer just added, which is selected once it exists.
    final before = stageLayers(ws).length;
    stageBeginUndoStep(ws);
    var made = 0;
    ws.after(
      stageAddLayer(
        ws,
        name: kind == 'text' ? '' : 'shape',
        word: kind == 'text' ? ws.bodyFace : kind,
      ),
      null,
      (t) => made = t,
    );
    stageSetValue(ws, layer: -1, name: 'x', number: x);
    stageSetValue(ws, layer: -1, name: 'y', number: y);
    // Apply the current drawing colours.
    applyChosenInks(ws, kind == 'text' ? 'text' : 'shape', kind);
    if (kind == 'text') {
      // The text starts at the drag origin (anchor_x = -1 = left edge).
      stageSetValue(ws, layer: -1, name: 'anchor_x', number: -1);
    }
    if (cut != null) {
      // Mask: sits behind the selected layer and clips it. Invisible itself.
      final all = stageLayers(ws);
      if (all.contains(cut)) {
        stageRaiseLayer(
          ws,
          layer: -1,
          number: (all.indexOf(cut) - before).toDouble(),
        );
        stageSetValue(ws, layer: cut, name: 'clip', number: 1);
        stageSetValue(ws, layer: -1, name: 'opacity', number: 0);
      }
    }
    if (!tiny && kind != 'text') {
      if (kind == 'line') {
        // A line is 1/25 of a unit thick, as long as the drag and rotated to match it.
        stageSetValue(
          ws,
          layer: -1,
          name: 'wide',
          number: d.distance / p / .04,
        );
        stageSetValue(
          ws,
          layer: -1,
          name: 'rotate',
          number: math.atan2(d.dy, d.dx) * 180 / math.pi,
        );
      } else {
        stageSetValue(ws, layer: -1, name: 'size', number: d.dy.abs() / p);
        stageSetValue(
          ws,
          layer: -1,
          name: 'wide',
          number: d.dx.abs() / math.max(d.dy.abs(), 1e-3),
        );
      }
    }
    ws.after(stageEndUndoStep(ws), (done, _) {
      if (!done || made <= 0) return;
      // The new text's field takes the keyboard at once (see parameter_tile.dart).
      if (kind == 'text') textToType = true;
      ws.select(made);
    });
    // Back to the select tool after one shape.
    ws.setView('stage.tool', 0);
  }

  /// Places a pen point at [down] with its handle pulled out to [up]; a click, where the two are the same, makes a
  /// corner point. A scribble between them becomes a fitted path instead.
  void pen(StageViewport v, Offset down, Offset up) {
    final ws = _stage.workspace, way = _penWay;
    _drawFrom = null;
    _penWay = null;
    notifyListeners();
    if (!stageConnected(ws)) return;
    if (way != null && scribbled(way, down, up)) return _fit(v, way);
    final a = v.toComposition(down), h = v.toComposition(up) - a;
    final first = !_penning;
    _penning = true;
    if (first) stageBeginUndoStep(ws);
    var made = 0;
    ws.after(
      stagePenPoint(
        ws,
        layer: first ? _stage.selected ?? 0 : -1,
        word: '${a.dx} ${a.dy} ${h.dx} ${h.dy}',
      ),
      null,
      (t) => made = t,
    ); // On the first point a closed selected path gains or loses a point; otherwise a new path begins.
    if (first) {
      applyChosenInks(ws, 'shape', 'path');
      ws.after(
        stageEndUndoStep(ws),
        (done, _) => done && made > 0 ? ws.select(made) : null,
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

  /// Fits a smooth path to the pen scribble [way] according to the active Smooth level.
  /// A closed scribble becomes a filled path; an open one becomes a stroke.
  void _fit(StageViewport v, List<Offset> way) {
    final ws = _stage.workspace;
    // The fitted path is complete, so the next pen click starts a new one.
    _penning = false;
    final smooth = _stage.tool.smooth;
    final cleanWay = StrokeStabilizer.finishSmooth(way, smooth);
    final errPx = StrokeStabilizer.curveErrorPx(smooth);
    final points = [for (final p in cleanWay) v.toComposition(p)],
        error =
            (v.toComposition(cleanWay.first + Offset(errPx, 0)) - points.first)
                .distance;
    final closed = (points.first - points.last).distance < 4 * error;
    stageBeginUndoStep(ws);
    var made = 0;
    ws.after(
      stageFitCurve(
        ws,
        '$error ${[for (final p in points) '${p.dx} ${p.dy}'].join(' ')}',
      ),
      (done, why) => done ? null : ws.notice = why,
      (t) => made = t,
    );
    if (closed) {
      applyChosenInks(ws, 'shape', 'path');
    } else {
      stageSetWord(ws, layer: -1, name: 'fill', word: 'none');
      stageSetWord(
        ws,
        layer: -1,
        name: 'stroke',
        word: ws.ink.isEmpty || ws.ink.contains(' ') ? 'ffffff' : ws.ink,
      );
      stageSetValue(ws, layer: -1, name: 'stroke_width', number: 6);
    }
    ws.after(
      stageEndUndoStep(ws),
      (done, _) => done && made > 0 ? ws.select(made) : null,
    );
  }

  /// Turns the brush stroke into a drawing layer, or erases from the selected drawing with the eraser.
  void brushDragEnd(StageViewport v) {
    final way = _brush, ws = _stage.workspace;
    _brush = null;
    notifyListeners();
    if (way == null || way.length < 2 || !stageConnected(ws)) return;
    final smooth = _stage.tool.smooth;
    final stabilized = StrokeStabilizer.finishSmooth(way, smooth);
    final options = StrokeStabilizer.brushOptions(
      _stage.tool.brushSize,
      smooth,
    );
    final points = getStrokePoints([
      for (final p in stabilized)
        PointVector.fromOffset(offset: v.toComposition(p)),
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
      // The eraser removes from the selected drawing.
      final into = ws.selected;
      if (into == null) {
        ws.notice = 'Pick a drawing to erase from';
        return;
      }
      ws.after(
        stageBrushStroke(
          ws,
          layer: into,
          word: '3 ${options.size} ${said.join(' ')}',
        ),
        (done, why) {
          if (!done) ws.notice = why;
        },
      );
      return;
    }
    stageBeginUndoStep(ws);
    var made = 0;
    ws.after(
      stageBrushStroke(
        ws,
        word: '${_stage.tool.brushTool} ${options.size} ${said.join(' ')}',
      ),
      null,
      (t) => made = t,
    );
    // An outline with no fill shows nothing, so default to white.
    stageSetWord(
      ws,
      layer: -1,
      name: 'fill',
      word: ws.ink.isEmpty ? 'ffffff' : ws.ink,
    );
    ws.after(
      stageEndUndoStep(ws),
      (done, _) => done && made > 0 ? ws.select(made) : null,
    );
  }
}
