// The stage's drawing tools, run when the pointer is released: lasso selection, a dragged-out rectangle or ellipse, a
// pen scribble fitted to a curve, and the freehand brush.
//
// setState is called from an extension on the State itself, which the analyzer allows only in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:perfect_freehand/perfect_freehand.dart' show getStrokeOutlinePoints, getStrokePoints, PointVector, StrokeOptions;
import 'package:perfect_freehand/src/get_stroke_radius.dart'
    show getStrokeRadius; // How wide the pressure makes a point. The package keeps it private, so it is imported from src.

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/widgets/text_gestures.dart' show textToType;
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/stage/stage_view_state.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

extension StageViewDraw on StageViewState {
  /// Selects the layers whose centre lies inside the lasso.
  void lassoDragEnd(StageViewport v) {
    final round = lasso, ws = WsScope.read(context);
    setState(() => lasso = null);
    if (round == null || round.length < 3) return;
    // A nearly straight drag selects the box between its ends, as in Figma and After Effects. Otherwise the drawn
    // outline is used.
    final a = round.first, z = round.last, along = z - a;
    final straight = along.distance > 4 && round.every((p) => ((p - a).dx * along.dy - (p - a).dy * along.dx).abs() / along.distance < 12);
    final path = straight ? (Path()..addRect(Rect.fromPoints(a, z))) : (Path()..addPolygon(round, true));
    ws.pickMany([
      for (final l in widget.scene.layers)
        if (widget.scene.box(l.id) case final b? when path.contains(v.toScreen(b.c))) l.id,
    ]);
  }

  /// Creates a layer of the active tool's kind from a drag that started at [drawFrom] and ended at [to].
  /// A drag shorter than 6 screen pixels creates the layer at its default size.
  void draw(StageViewport v, Offset to) {
    final from = drawFrom, ws = WsScope.read(context), m = ws.inside, kind = widget.make;
    drawFrom = null;
    setState(() {});
    if (from == null || m == null || kind == null) return;
    final a = v.toComp(from), b = v.toComp(to), p = m.point, c = WsArt.comp;
    // Drawn out from its centre: twice the drag, centred on where the drag started.
    final centred = kind == 'circle' && widget.fromCentre;
    final mid = centred ? a : (a + b) / 2, d = centred ? (b - a) * 2 : b - a, tiny = d.distance < 6 / v.s;
    final x = ((kind == 'text' || tiny ? a.dx : mid.dx) - c.width / 2) / p, y = (c.height / 2 - (kind == 'text' || tiny ? a.dy : mid.dy)) / p;
    final cut = widget.mask ? int.tryParse(ws.selected ?? '') : null;
    // Queue everything as one undo step. Layer -1 refers to the layer just added, which is selected once it exists.
    final before = m.layers.length;
    m.later('together', number: 1);
    var made = 0;
    // Text uses the body font, as a text box does in PowerPoint.
    ws.after(m.later('add', name: kind == 'text' ? '' : 'shape', word: kind == 'text' ? ws.bodyFace : kind), null, (t) => made = t);
    m
      ..later('set', layer: -1, name: 'x', number: x)
      ..later('set', layer: -1, name: 'y', number: y);
    // Apply the current drawing colours.
    wsInked(ws, kind == 'text' ? 'text' : 'shape', kind);
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
          ..later('raise', layer: -1, number: (all.indexOf(cut) - before).toDouble())
          ..later('set', layer: cut, name: 'clip', number: 1)
          ..later('set', layer: -1, name: 'opacity', number: 0);
      }
    }
    if (!tiny && kind != 'text') {
      if (kind == 'line') {
        // A line is 1/25 of a unit thick, as long as the drag and rotated to match it.
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
      // The new text's field takes the keyboard at once (see inspector_param_controls_tile.dart).
      if (kind == 'text') textToType = true;
      ws.select('$made');
    });
    // Back to the select tool after one shape, as in Alight Motion's Add and Figma. After Effects keeps the tool.
    ws.setView('stage.tool', 0);
  }

  /// Fits one smooth path to the pen scribble [way], as curve-fit-nd does.
  ///
  /// The fit stays within 8 screen pixels of the scribble, like Blender's Draw Curve tool (editcurve_paint.cc). The
  /// result has ordinary pen anchors and handles that the user can move. A scribble that ends where it began becomes
  /// a closed, filled path. Otherwise it becomes an open stroke in the current ink.
  void fit(StageViewport v, List<Offset> way) {
    final ws = WsScope.read(context), m = ws.inside!;
    // The fitted path is complete, so the next pen click starts a new one.
    penning = false;
    final points = [for (final p in way) v.toComp(p)], error = (v.toComp(way.first + const Offset(8, 0)) - points.first).distance;
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

  /// Turns the brush stroke into a drawing layer, or erases from the selected drawing with the eraser.
  void brushDragEnd(StageViewport v) {
    final way = brush, ws = WsScope.read(context), m = ws.inside;
    setState(() => brush = null);
    if (way == null || way.length < 2 || m == null) return;
    final options = StrokeOptions(size: widget.brushSize, simulatePressure: true, isComplete: true);
    final points = getStrokePoints([for (final p in way) PointVector.fromOffset(offset: v.toComp(p))], options: options);
    if (points.length < 2) return;
    getStrokeOutlinePoints(points, options: options, rememberSimulatedPressure: true);
    final said = [
      for (final p in points) '${p.point.x} ${p.point.y} ${2 * getStrokeRadius(options.size, options.thinning, p.pressure, options.easing) / options.size}',
    ];
    if (widget.brushTool == 3) {
      // The eraser removes from the selected drawing, as Alight Motion's eraser does from the drawing layer it is in.
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
    // An outline with no fill shows nothing, so use white when no ink is chosen, as drawing apps do.
    m.later('say', layer: -1, name: 'fill', word: ws.ink.isEmpty ? 'ffffff' : ws.ink);
    ws.after(m.later('together'), (done, _) => done && made > 0 ? ws.select('$made') : null);
  }
}
