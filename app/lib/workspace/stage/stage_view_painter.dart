// The stage's painter: guides, grid, boxes, handles and captions.
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/stage/stage_view_relations.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Draws a line that reads on any artwork: a dark under-stroke, then the colour.
void _legible(Canvas c, Path p, Color col, [double w = 1.5]) {
  c.drawPath(p, linePaint(Grey.g00, w + 2));
  c.drawPath(p, linePaint(col, w));
}

class ViewPainter extends CustomPainter {
  ViewPainter(
    this.scene,
    this.v,
    this.sel,
    this.hover, {
    required this.grid,
    required this.safe,
    this.part = ViewPart.all,
    this.pivots = false,
    this.met = (null, null),
    this.marked = false,
    this.trail,
    this.parent,
    this.grip,
    this.form = ('', 0),
    this.crop = const [],
  });

  /// The handle being dragged. Only it is drawn, highlighted, until the drag ends.
  final String? grip;

  /// The selected shape's form and corner roundness, which decide its own handles.
  final (String, double) form;

  /// The selected image's crop, drawn as a bar on each side.
  final List<double> crop;

  /// Whether the engine already marks the selected and hovered layers, so they are not drawn here.
  final bool marked;

  /// Which part to paint: below the preview, above it, or all.
  final ViewPart part;

  /// Whether to show every layer's anchor point (Pivots).
  final bool pivots;

  /// The snap lines (x, y) the dragged layer sits on, or null on an axis with none.
  final (double?, double?) met;

  /// The selected layer's path over time in canvas coordinates, or null if it does not move or is not read yet.
  final List<Offset>? trail;

  /// The id of the selected layer's parent. Its frame is drawn grey, like Alight Motion's parent outline.
  final String? parent;
  final ArtScene scene;
  final StageViewport v;
  final String? sel, hover;
  final bool grid, safe;

  Path _boxPath(ArtBox b) =>
      Path()..addPolygon([for (final p in b.corners) v.toScreen(p)], true);

  @override
  void paint(Canvas c, Size size) {
    final comp = v.comp;
    if (part != ViewPart.over) {
      c.drawRect(Offset.zero & size, Paint()..color = StageTokens.surround);
    }
    c.save();
    c.clipRect(v.area);
    if (part != ViewPart.over) _captions(c, comp);
    if (part == ViewPart.under) {
      c.restore();
      return;
    }
    c.save();
    c.clipRect(comp);
    if (grid) _grid(c, comp);
    if (safe && scene.gizmos.isEmpty) _safe(c, comp);
    c.restore();
    _guides(c);
    if (trail case final w? when w.length > 1) {
      // A thin line with an arrowhead at intervals along the direction of motion.
      final line = linePaint(WindowTokens.accent.withValues(alpha: .75), 1.2),
          pts = [for (final q in w) v.toScreen(q)];
      c.drawPoints(PointMode.polygon, pts, line);
      for (var i = 6; i + 1 < pts.length; i += 12) {
        final d = pts[i + 1] - pts[i];
        if (d.distance < .5) continue;
        final u = d / d.distance, n = Offset(-u.dy, u.dx), tip = pts[i];
        c.drawPath(
          Path()
            ..moveTo((tip - u * 6 + n * 4).dx, (tip - u * 6 + n * 4).dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo((tip - u * 6 - n * 4).dx, (tip - u * 6 - n * 4).dy),
          line,
        );
      }
    }
    if (met.$1 case final x?) {
      c.drawLine(
        Offset(v.toScreen(Offset(x, 0)).dx, v.area.top),
        Offset(v.toScreen(Offset(x, 0)).dx, v.area.bottom),
        linePaint(WindowTokens.accent),
      );
    }
    if (met.$2 case final y?) {
      c.drawLine(
        Offset(v.area.left, v.toScreen(Offset(0, y)).dy),
        Offset(v.area.right, v.toScreen(Offset(0, y)).dy),
        linePaint(WindowTokens.accent),
      );
    }
    if (pivots) {
      for (final MapEntry(:key, :value) in scene.boxes.entries) {
        if (key == sel) continue;
        final a = v.toScreen(value.anchor);
        c.drawCircle(a, 3.5, linePaint(Grey.g00, 3));
        c.drawCircle(a, 3.5, linePaint(Grey.g91, 1.2));
      }
    }
    // The selected layer's parent frame, in grey.
    if (ArtGeometry.boxOf(scene, parent) case final b?) {
      c.drawPath(_boxPath(b), linePaint(Grey.g63, 1));
    }
    for (final id in scene.gizmos.keys) {
      _gizmo(c, id);
    }
    if (marked) {
      // The engine marks the frame, corners, sides, rotate knob and anchor. Only the layer's own handles are drawn here.
      if ((ArtGeometry.boxOf(scene, sel), scene.layer(sel)) case (
        final b?,
        final l?,
      )) {
        _own(
          c,
          selectionHandles(
            v.toScreen,
            b,
            knob: l.kind != LayerKind.camera && l.id != 'bg',
            form: form.$1,
            round: form.$2,
            crop: crop,
          ),
        );
      }
      return c.restore();
    }
    // The hovered layer's outline uses its label colour, like its row in the layer list.
    if (ArtGeometry.boxOf(scene, hover) case final b?) {
      _legible(c, _boxPath(b), layerLabelColor(hover!), 1);
    }
    if (ArtGeometry.boxOf(scene, sel) case final b?) {
      _selection(c, b, scene.layer(sel)!);
    }
    c.restore();
  }

  void _captions(Canvas c, Rect comp) {
    if (comp.top - v.area.top < 18) return;
    final l = lineText(
          scene.title,
          TextStyles.micro(Grey.g76).copyWith(fontWeight: FontWeight.w700),
        ),
        d = lineText(
          '${ArtGeometry.comp.width.round()} × ${ArtGeometry.comp.height.round()}  ·  ${WorkspaceController.fps} fps',
          TextStyles.micro(Grey.g56),
        );
    final y = comp.top - 6 - l.height;
    l.paint(c, Offset(comp.left, y));
    d.paint(c, Offset(comp.left + l.width + 8, y));
    final f = scene.frame,
        tc = lineText(
          'F ${f.toString().padLeft(3, '0')}',
          TextStyles.value(Grey.g76),
        );
    tc.paint(c, Offset(comp.right - tc.width, comp.top - 6 - tc.height));
  }

  void _grid(Canvas c, Rect comp) {
    final p = linePaint(StageTokens.overlay);
    for (var i = 1; i < 12; i++) {
      final x = comp.left + comp.width * i / 12;
      c.drawLine(Offset(x, comp.top), Offset(x, comp.bottom), p);
    }
    for (var j = 1; j < 7; j++) {
      final y = comp.top + comp.height * j / 7;
      c.drawLine(Offset(comp.left, y), Offset(comp.right, y), p);
    }
  }

  void _safe(Canvas c, Rect comp) {
    final p = linePaint(StageTokens.safe);
    c.drawRect(
      Rect.fromCenter(
        center: comp.center,
        width: comp.width * .9,
        height: comp.height * .9,
      ),
      linePaint(StageTokens.overlay),
    );
    final t = Rect.fromCenter(
          center: comp.center,
          width: comp.width * .8,
          height: comp.height * .8,
        ),
        k = comp.width * .03;
    for (final (o, dx, dy) in [
      (t.topLeft, 1.0, 1.0),
      (t.topRight, -1.0, 1.0),
      (t.bottomRight, -1.0, -1.0),
      (t.bottomLeft, 1.0, -1.0),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(o.dx + dx * k, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + dy * k),
        p,
      );
    }
    final m = comp.center;
    c.drawLine(m - const Offset(8, 0), m + const Offset(8, 0), p);
    c.drawLine(m - const Offset(0, 8), m + const Offset(0, 8), p);
  }

  void _guides(Canvas c) {
    final p = linePaint(StageTokens.guide);
    for (final gx in scene.guidesX) {
      final x = v.toScreen(Offset(gx, 0)).dx.roundToDouble() + .5;
      c.drawLine(Offset(x, v.area.top), Offset(x, v.area.bottom), p);
    }
    for (final gy in scene.guidesY) {
      final y = v.toScreen(Offset(0, gy)).dy.roundToDouble() + .5;
      c.drawLine(Offset(v.area.left, y), Offset(v.area.right, y), p);
    }
  }

  /// Draws a camera in the custom view: its crossed frame as in AbsentMotion's DrawCameraFrames, lines from its
  /// position to the frame corners, and its point of interest as in After Effects. The selected camera also gets
  /// corner handles, because the frame size sets the lens.
  void _gizmo(Canvas c, String id) {
    final g = [
          for (final p in scene.gizmo(id)) p == null ? null : v.toScreen(p),
        ],
        picked = id == sel;
    if (g.length < 6) return;
    final ink = picked ? WindowTokens.accent : Grey.g76,
        frame = [g[0], g[1], g[2], g[3]].nonNulls.toList(),
        eye = g[5];
    if (frame.length == 4) {
      _legible(c, Path()..addPolygon(frame, true), ink, picked ? 2 : 1);
      c.drawLine(frame[0], frame[2], linePaint(ink.withValues(alpha: .35), 1));
      c.drawLine(frame[1], frame[3], linePaint(ink.withValues(alpha: .35), 1));
      if (eye != null)
        for (final p in frame) {
          c.drawLine(eye, p, linePaint(ink.withValues(alpha: .35), 1));
        }
      if (picked)
        for (final p in frame) {
          c.drawRect(
            Rect.fromCenter(center: p, width: 7, height: 7),
            Paint()..color = ink,
          );
        }
    }
    if (g[4] case final look?) {
      c.drawCircle(look, 5, linePaint(Grey.g00, 3));
      c.drawCircle(look, 5, linePaint(ink, 1.4));
    }
    if (eye != null) {
      c.drawCircle(eye, 6, Paint()..color = Grey.g00);
      c.drawCircle(
        eye,
        6,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _selection(Canvas c, ArtBox b, ArtLayer l) {
    final h = selectionHandles(
          v.toScreen,
          b,
          knob: l.kind != LayerKind.camera && l.id != 'bg',
          form: form.$1,
          round: form.$2,
          crop: crop,
        ),
        pts = [for (var i = 0; i < 4; i++) h['corner $i']!];
    _legible(c, Path()..addPolygon(pts, true), WindowTokens.accent);
    final top = v.toScreen(b.top);
    final lit = WindowTokens.accent.withValues(alpha: 1);
    bool seen(String k) => grip == null || grip == k;
    if (h['turn'] case final knob? when seen('turn')) {
      _legible(
        c,
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(knob.dx, knob.dy),
        WindowTokens.accent,
        1,
      );
      final big = grip == 'turn' ? 2.0 : 1.0;
      c.drawCircle(knob, 4.5 * big, Paint()..color = Grey.g00);
      c.drawCircle(knob, 3.5 * big, Paint()..color = lit);
    }
    for (final (key, p) in [
      for (final (i, p) in pts.indexed) ('corner $i', p),
      for (var i = 0; i < 4; i++)
        if (h['side $i'] case final s?) ('side $i', s),
    ]) {
      if (!seen(key)) continue;
      final r = Rect.fromCenter(
        center: p,
        width: StageTokens.handle,
        height: StageTokens.handle,
      ).inflate(grip == key ? StageTokens.handle / 2 : 0);
      c.drawRect(r.inflate(1), Paint()..color = Grey.g00);
      c.drawRect(r, Paint()..color = lit);
    }
    _own(c, h);
    final a = h['anchor']!;
    if (seen('anchor')) {
      final big = grip == 'anchor' ? 1.6 : 1.0;
      c.drawCircle(a, 6 * big, linePaint(Grey.g00, 3.5));
      c.drawCircle(a, 6 * big, linePaint(lit, 1.5));
      for (final d in const [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
      ]) {
        c.drawLine(a + d * 3, a + d * 10 * big, linePaint(Grey.g00, 3));
        c.drawLine(a + d * 3, a + d * 10 * big, linePaint(lit, 1.2));
      }
    }
    final bounds = pts
        .skip(1)
        .fold(
          Rect.fromPoints(pts[0], pts[0]),
          (r, p) => r.expandToInclude(Rect.fromPoints(p, p)),
        );
    _tag(
      c,
      bounds.topLeft,
      l.name,
      WindowTokens.accent,
      WindowTokens.onAccent,
      layerKindColor(l.kind),
    );
  }

  /// Draws the selected layer's own handles (roundness, points, crop), besides the frame handles that the engine marks
  /// too (see desk_marks in live.h).
  void _own(Canvas c, Map<String, Offset> h) {
    final lit = WindowTokens.accent.withValues(alpha: 1);
    bool seen(String k) => grip == null || grip == k;
    if (h['round'] case final r? when seen('round')) {
      // Corner roundness: a ring inside the first corner.
      final big = grip == 'round' ? 1.6 : 1.0;
      c.drawCircle(r, 4.5 * big, Paint()..color = Grey.g00);
      c.drawCircle(r, 3.5 * big, linePaint(lit, 1.5));
    }
    if (h['points'] case final p? when seen('points')) {
      // Point count: a diamond outside one side.
      final big = grip == 'points' ? 1.6 : 1.0,
          d = Path()
            ..addPolygon([
              p + Offset(0, -5 * big),
              p + Offset(5 * big, 0),
              p + Offset(0, 5 * big),
              p + Offset(-5 * big, 0),
            ], true);
      c.drawPath(d, linePaint(Grey.g00, 3));
      c.drawPath(d, Paint()..color = lit);
    }
    for (var i = 0; i < 4; i++) {
      // Image crop: a bar on each side where the image is cut.
      if (h['crop $i'] case final p? when seen('crop $i')) {
        final big = grip == 'crop $i' ? 1.6 : 1.0,
            along = i.isEven ? Offset(0, 7 * big) : Offset(7 * big, 0);
        c.drawLine(p - along, p + along, linePaint(Grey.g00, 6));
        c.drawLine(p - along, p + along, linePaint(lit, 3));
      }
    }
  }

  /// Draws a small rounded name tag above [at], kept inside the viewport.
  void _tag(
    Canvas c,
    Offset at,
    String text,
    Color fill,
    Color ink,
    Color? pip,
  ) {
    final tp = lineText(
      text,
      TextStyles.micro(ink).copyWith(fontWeight: FontWeight.w700),
    );
    final w = tp.width + 12 + (pip == null ? 0 : 10);
    var o = Offset(at.dx, at.dy - StageTokens.tagH - 4);
    o = Offset(
      o.dx.clamp(
        v.area.left + 4,
        math.max(v.area.left + 4, v.area.right - w - 4),
      ),
      o.dy.clamp(
        v.area.top + 4,
        math.max(v.area.top + 4, v.area.bottom - StageTokens.tagH - 4),
      ),
    );
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx, o.dy, w, StageTokens.tagH),
      Shape.r(WindowTokens.chipRadius),
    );
    c.drawRRect(r.inflate(1), Paint()..color = Grey.g00);
    c.drawRRect(r, Paint()..color = fill);
    var x = o.dx + 6;
    if (pip != null) {
      c.drawRect(Rect.fromLTWH(x, o.dy + 5, 6, 6), Paint()..color = Grey.g00);
      c.drawRect(Rect.fromLTWH(x + 1, o.dy + 6, 4, 4), Paint()..color = pip);
      x += 10;
    }
    tp.paint(c, Offset(x, o.dy + (StageTokens.tagH - tp.height) / 2));
  }

  @override
  bool shouldRepaint(ViewPainter o) =>
      o.scene != scene ||
      o.v != v ||
      o.sel != sel ||
      o.hover != hover ||
      o.grid != grid ||
      o.safe != safe ||
      o.part != part ||
      o.pivots != pivots ||
      o.met != met ||
      o.marked != marked ||
      !identical(o.trail, trail) ||
      o.parent != parent ||
      o.grip != grip ||
      o.form != form ||
      !listEquals(o.crop, crop);
}

// ---- rulers -----------------------------------------------------------------------------------------------------------

class RulerPainter extends CustomPainter {
  RulerPainter(this.v, this.cursor, this.scene) : super(repaint: cursor);
  final StageViewport v;
  final ArtScene scene;
  final ValueNotifier<Offset?> cursor;

  static double _step(double s) {
    for (final st in [25.0, 50.0, 100.0, 200.0, 250.0, 500.0, 1000.0]) {
      if (st * s >= 56) return st;
    }
    return 2000;
  }

  @override
  void paint(Canvas c, Size size) {
    final r = StageTokens.ruler;
    final comp = v.comp,
        bg = Paint()..color = StageTokens.rulerGround,
        span = Paint()..color = StageTokens.rulerSpan;
    c.drawRect(Rect.fromLTWH(0, 0, size.width, r), bg);
    c.drawRect(Rect.fromLTWH(0, 0, r, size.height), bg);
    c.drawRect(
      Rect.fromLTRB(
        math.max(comp.left, r),
        0,
        math.min(comp.right, size.width),
        r,
      ),
      span,
    );
    c.drawRect(
      Rect.fromLTRB(
        0,
        math.max(comp.top, r),
        r,
        math.min(comp.bottom, size.height),
      ),
      span,
    );
    final edge = linePaint(WindowTokens.line);
    c.drawLine(Offset(0, r - .5), Offset(size.width, r - .5), edge);
    c.drawLine(Offset(r - .5, 0), Offset(r - .5, size.height), edge);
    final step = _step(v.s),
        minor = step / 5,
        tick = Paint()..color = StageTokens.tick;
    final label = TextStyles.micro(Grey.g56);

    c.save();
    c.clipRect(Rect.fromLTWH(r, 0, size.width - r, r));
    final x0 = (v.toComp(Offset(r, 0)).dx / minor).floor() * minor,
        x1 = v.toComp(Offset(size.width, 0)).dx;
    for (var x = x0; x <= x1; x += minor) {
      final sx = v.toScreen(Offset(x, 0)).dx.roundToDouble() + .5,
          major = (x / step).round() * step == x;
      c.drawLine(Offset(sx, major ? 2 : r - 4), Offset(sx, r), tick);
      if (major) lineText('${x.round()}', label).paint(c, Offset(sx + 3, 2));
    }
    c.restore();

    c.save();
    c.clipRect(Rect.fromLTWH(0, r, r, size.height - r));
    final y0 = (v.toComp(Offset(0, r)).dy / minor).floor() * minor,
        y1 = v.toComp(Offset(0, size.height)).dy;
    for (var y = y0; y <= y1; y += minor) {
      final sy = v.toScreen(Offset(0, y)).dy.roundToDouble() + .5,
          major = (y / step).round() * step == y;
      c.drawLine(Offset(major ? 2 : r - 4, sy), Offset(r, sy), tick);
      if (major) {
        c.save();
        c.translate(2, sy - 3);
        c.rotate(-math.pi / 2);
        lineText('${y.round()}', label).paint(c, Offset.zero);
        c.restore();
      }
    }
    c.restore();

    final g = Paint()..color = StageTokens.guide;
    for (final gx in scene.guidesX) {
      final x = v.toScreen(Offset(gx, 0)).dx;
      if (x > r) {
        c.drawPath(
          Path()..addPolygon([
            Offset(x - 4, r - 5),
            Offset(x + 4, r - 5),
            Offset(x, r),
          ], true),
          g,
        );
      }
    }
    for (final gy in scene.guidesY) {
      final y = v.toScreen(Offset(0, gy)).dy;
      if (y > r) {
        c.drawPath(
          Path()..addPolygon([
            Offset(r - 5, y - 4),
            Offset(r - 5, y + 4),
            Offset(r, y),
          ], true),
          g,
        );
      }
    }

    if (cursor.value case final p?) {
      final s = v.toScreen(p),
          hot = Paint()
            ..color = WindowTokens.accent
            ..strokeWidth = 1;
      if (s.dx > r) c.drawLine(Offset(s.dx, 0), Offset(s.dx, r), hot);
      if (s.dy > r) c.drawLine(Offset(0, s.dy), Offset(r, s.dy), hot);
    }
    c.drawRect(Rect.fromLTWH(0, 0, r, r), bg);
  }

  @override
  bool shouldRepaint(RulerPainter o) =>
      o.v != v || o.cursor != cursor || o.scene != scene;
}
