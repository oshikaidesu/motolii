// The stage's painters: the view (guides, grid, boxes, handles and captions), the rulers, and a path's points.
import 'dart:math' as math;
import 'dart:ui' show PathOperation, PointMode;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/camera_gestures.dart'
    show cameraFrameRollKnob;
import 'package:motolii/workspace/stage/selection_handles.dart';
import 'package:motolii/workspace/stage/stage_drag.dart' show SnapGap;
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// A stroke of [w] pixels in the colour [c].
Paint linePaint(Color c, [double w = 1]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c;

/// Draws a line that reads on any artwork: a dark under-stroke, then the colour.
void _legible(Canvas c, Path p, Color col, [double w = 1.5]) {
  c.drawPath(p, linePaint(Grey.g00, w + 2));
  c.drawPath(p, linePaint(col, w));
}

/// What one painter draws: everything (including the stand-in art), or one side of the engine's preview.
/// With the preview in the composition, [under] is what lies beneath it (surround, captions), [over] what lies above (grid, guides, selection).
enum ViewPart { all, under, over }

/// Paints what the stage shows around and over the preview: the surround and captions under it; the grid, safe
/// areas, guides, motion path, snap lines, camera gizmos and the selection with its handles over it.
class ViewPainter extends CustomPainter {
  ViewPainter(
    this.scene,
    this.v,
    this.sel,
    this.hover, {
    required this.grid,
    required this.safe,
    this.alpha = false,
    this.part = ViewPart.all,
    this.pivots = false,
    this.met = (null, null),
    this.gaps = const [],
    this.hideGizmos = false,
    this.marked = false,
    this.trail,
    this.parent,
    this.grip,
    this.form = ('', 0),
    this.crop = const [],
    this.cameraTarget,
    this.cameraMode = false,
    this.cameraOrbiting = false,
    this.cameraHover,
    this.falloffRing,
  });

  /// The layer ID the active camera is currently Z-targeting, drawn with lock-on brackets.
  final int? cameraTarget;

  /// True while Camera Mode is active: paints subtle viewfinder chrome and Z-target hover reticles.
  final bool cameraMode;

  /// True while actively orbiting in Camera Mode: paints a subtle virtual trackball circle.
  final bool cameraOrbiting;

  /// Hovered layer ID in Camera Mode (invited for 1-click Z-target lock-on).
  final int? cameraHover;

  /// Active proportional editing falloff circle during a path-point drag.
  final ({Offset center, double radius})? falloffRing;

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

  /// Equal-spacing smart guides active during a magnetic drag.
  final List<SnapGap> gaps;

  /// True while scrubbing an inspector parameter so overlays/gizmos stay out of the way.
  final bool hideGizmos;

  /// The selected layer's path over time in canvas coordinates, or null if it does not move or is not read yet.
  final List<Offset>? trail;

  /// The id of the selected layer's parent. Its frame is drawn grey
  final int? parent;
  final ArtScene scene;
  final StageViewport v;
  final int? sel, hover;
  final bool grid, safe, alpha;

  Path _boxPath(ArtBox b) =>
      Path()..addPolygon([for (final p in b.corners) v.toScreen(p)], true);

  @override
  void paint(Canvas c, Size size) {
    final comp = v.compositionRect;
    if (part != ViewPart.over) {
      c.drawRect(Offset.zero & size, Paint()..color = StageTokens.surround);
    }
    c.save();
    c.clipRect(v.area);
    if (part != ViewPart.over) {
      if (alpha) _checkerboard(c, comp);
      _captions(c, comp);
    }
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
      // Hairline path + time-sampled velocity dots (dense = slow, spaced = fast), hollow start -> solid end.
      final pts = [for (final q in w) v.toScreen(q)];
      final accent = WindowTokens.accent;
      c.drawPoints(
        PointMode.polygon,
        pts,
        linePaint(accent.withValues(alpha: .28), 1.0),
      );
      final dot = Paint()..color = accent.withValues(alpha: .72);
      Offset? prev;
      for (var i = 1; i + 1 < pts.length; i += 2) {
        final p = pts[i];
        if (prev != null && (p - prev).distance < 5.0) continue;
        c.drawCircle(p, 1.5, dot);
        prev = p;
      }
      final start = pts.first, end = pts.last;
      c.drawCircle(start, 3.0, Paint()..color = Grey.g00);
      c.drawCircle(start, 3.0, linePaint(accent.withValues(alpha: .85), 1.2));
      c.drawCircle(end, 3.4, Paint()..color = Grey.g00);
      c.drawCircle(end, 2.3, Paint()..color = accent.withValues(alpha: .9));
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
    if (gaps.isNotEmpty) _drawGaps(c);
    if (hideGizmos) return c.restore();
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
    if (cameraMode && scene.gizmos.isEmpty) {
      _viewfinder(c, comp);
    }
    if (ArtGeometry.boxOf(scene, cameraTarget) case final b?) {
      _lockBrackets(c, b);
    }
    if (cameraMode &&
        cameraHover != null &&
        cameraHover != cameraTarget &&
        ArtGeometry.boxOf(scene, cameraHover) != null) {
      _hoverReticle(c, ArtGeometry.boxOf(scene, cameraHover)!);
    }
    if (falloffRing case final ring? when ring.radius > 2) {
      c.drawCircle(
        ring.center,
        ring.radius,
        linePaint(Grey.g00.withValues(alpha: .45), 2.4),
      );
      c.drawCircle(
        ring.center,
        ring.radius,
        linePaint(WindowTokens.accent.withValues(alpha: .65), 1.1),
      );
    }
    if (cameraMode && scene.gizmos.isEmpty) {
      return c.restore();
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
            knob: l.kind != LayerKind.camera,
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
    final l = lineText(scene.title, TextStyles.micro(Grey.g76).bold),
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

  /// Draws equal-spacing smart guides (end ticks, connector line, and px badge)
  /// like Google Slides / Illustrator / Figma.
  void _drawGaps(Canvas c) {
    final accent = WindowTokens.accent;
    final stroke = linePaint(accent, 1.2);
    final shadow = linePaint(Grey.g00, 3.0);
    const cap = 4.5;
    for (final g in gaps) {
      final p0 = g.horizontal
          ? v.toScreen(Offset(g.from, g.at))
          : v.toScreen(Offset(g.at, g.from));
      final p1 = g.horizontal
          ? v.toScreen(Offset(g.to, g.at))
          : v.toScreen(Offset(g.at, g.to));
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy);
      if (g.horizontal) {
        path
          ..moveTo(p0.dx, p0.dy - cap)
          ..lineTo(p0.dx, p0.dy + cap)
          ..moveTo(p1.dx, p1.dy - cap)
          ..lineTo(p1.dx, p1.dy + cap);
      } else {
        path
          ..moveTo(p0.dx - cap, p0.dy)
          ..lineTo(p0.dx + cap, p0.dy)
          ..moveTo(p1.dx - cap, p1.dy)
          ..lineTo(p1.dx + cap, p1.dy);
      }
      c.drawPath(path, shadow);
      c.drawPath(path, stroke);
      final mid = (p0 + p1) / 2;
      final label = '${g.size.round()}';
      final tp = lineText(label, TextStyles.micro(WindowTokens.onAccent).bold);
      final bw = tp.width + 8, bh = tp.height + 3;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: mid, width: bw, height: bh),
        Shape.r(3),
      );
      c.drawRRect(rect, Paint()..color = accent);
      tp.paint(c, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
      tp.dispose();
    }
  }

  /// Draws a camera in 3D View as a pure Boxcam frame: rectangular outline,
  /// subtle rule-of-thirds guides, centre dot, and (when selected) corner resize
  /// handles plus top roll knob. No frustum pyramid lines or rear eye handle.
  void _gizmo(Canvas c, int id) {
    final g = [
          for (final p in scene.gizmo(id)) p == null ? null : v.toScreen(p),
        ],
        picked = id == sel;
    if (g.length < 5) return;
    final ink = picked ? WindowTokens.accent : Grey.g76,
        frame = [g[0], g[1], g[2], g[3]].nonNulls.toList();
    if (frame.length == 4) {
      _legible(c, Path()..addPolygon(frame, true), ink, picked ? 2 : 1.2);
      final guide = linePaint(ink.withValues(alpha: .24), 1);
      for (final t in const [1 / 3, 2 / 3]) {
        c.drawLine(
          Offset.lerp(frame[0], frame[1], t)!,
          Offset.lerp(frame[3], frame[2], t)!,
          guide,
        );
        c.drawLine(
          Offset.lerp(frame[0], frame[3], t)!,
          Offset.lerp(frame[1], frame[2], t)!,
          guide,
        );
      }
      if (picked) {
        for (final p in frame) {
          c.drawRect(
            Rect.fromCenter(center: p, width: 9, height: 9),
            Paint()..color = Grey.g00,
          );
          c.drawRect(
            Rect.fromCenter(center: p, width: 7, height: 7),
            Paint()..color = ink,
          );
        }
        if (cameraFrameRollKnob(frame) case final knob?) {
          final topMid = (frame[0] + frame[1]) * .5;
          _legible(
            c,
            Path()
              ..moveTo(topMid.dx, topMid.dy)
              ..lineTo(knob.dx, knob.dy),
            ink,
            1.2,
          );
          c.drawCircle(knob, 4.5, Paint()..color = Grey.g00);
          c.drawCircle(knob, 3.5, Paint()..color = ink);
        }
      }
    }
    if (g[4] case final look?) {
      c.drawCircle(look, 3.5, linePaint(Grey.g00, 2.8));
      c.drawCircle(look, 3.5, linePaint(ink, 1.4));
    }
  }

  /// Subtle Z-target lock-on corner brackets around the layer the camera currently tracks.
  void _lockBrackets(Canvas c, ArtBox b) {
    final pts = [for (final p in b.corners) v.toScreen(p)];
    if (pts.length != 4) return;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final p = pts[i];
      final prev = pts[(i + 3) % 4] - p;
      final next = pts[(i + 1) % 4] - p;
      final lp = math.min(12.0, prev.distance * .25);
      final ln = math.min(12.0, next.distance * .25);
      if (prev.distance < 1 || next.distance < 1) continue;
      final a = p + prev / prev.distance * lp;
      final d = p + next / next.distance * ln;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(p.dx, p.dy)
        ..lineTo(d.dx, d.dy);
    }
    _legible(c, path, WindowTokens.toneCamera, 1.8);
  }

  /// Subtle viewfinder frame chrome while Camera Mode is active in Camera View.
  void _viewfinder(Canvas c, Rect comp) {
    final cam = WindowTokens.toneCamera;
    final inset = comp.deflate(6);
    if (inset.width < 24 || inset.height < 24) return;
    final k = math.min(18.0, math.min(inset.width, inset.height) * .08);
    final corners = Path();
    for (final (o, dx, dy) in [
      (inset.topLeft, 1.0, 1.0),
      (inset.topRight, -1.0, 1.0),
      (inset.bottomRight, -1.0, -1.0),
      (inset.bottomLeft, 1.0, -1.0),
    ]) {
      corners
        ..moveTo(o.dx + dx * k, o.dy)
        ..lineTo(o.dx, o.dy)
        ..lineTo(o.dx, o.dy + dy * k);
    }
    _legible(c, corners, cam.withValues(alpha: .85), 1.6);
    final m = comp.center;
    final cross = Path()
      ..moveTo(m.dx - 7, m.dy)
      ..lineTo(m.dx - 2.5, m.dy)
      ..moveTo(m.dx + 2.5, m.dy)
      ..lineTo(m.dx + 7, m.dy)
      ..moveTo(m.dx, m.dy - 7)
      ..lineTo(m.dx, m.dy - 2.5)
      ..moveTo(m.dx, m.dy + 2.5)
      ..lineTo(m.dx, m.dy + 7);
    _legible(c, cross, cam.withValues(alpha: .55), 1.0);
    if (cameraOrbiting) {
      final r = math.min(comp.width, comp.height) * .28;
      c.drawCircle(m, r, linePaint(Grey.g00.withValues(alpha: .35), 2.5));
      c.drawCircle(m, r, linePaint(cam.withValues(alpha: .42), 1.1));
    }
  }

  /// Visual invitation reticle on a hovered layer in Camera Mode (click to Z-target).
  void _hoverReticle(Canvas c, ArtBox b) {
    final pts = [for (final p in b.corners) v.toScreen(p)];
    if (pts.length != 4) return;
    final cam = WindowTokens.toneCamera.withValues(alpha: .72);
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final p = pts[i];
      final prev = pts[(i + 3) % 4] - p;
      final next = pts[(i + 1) % 4] - p;
      final lp = math.min(8.0, prev.distance * .18);
      final ln = math.min(8.0, next.distance * .18);
      if (prev.distance < 1 || next.distance < 1) continue;
      final a = p + prev / prev.distance * lp;
      final d = p + next / next.distance * ln;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(p.dx, p.dy)
        ..lineTo(d.dx, d.dy);
    }
    _legible(c, path, cam, 1.2);
    final ctr = v.toScreen(b.c);
    c.drawCircle(ctr, 3.2, linePaint(Grey.g00.withValues(alpha: .6), 2.2));
    c.drawCircle(ctr, 3.2, linePaint(cam, 1.2));
  }

  void _selection(Canvas c, ArtBox b, ArtLayer l) {
    final h = selectionHandles(
          v.toScreen,
          b,
          knob: l.kind != LayerKind.camera,
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
    if (h['crop c0'] != null) {
      // Crop: the cut-away margin dimmed around the kept rectangle, as Google Slides shades a crop.
      final inner = Path()
        ..addPolygon([
          h['crop c0']!,
          h['crop c1']!,
          h['crop c2']!,
          h['crop c3']!,
        ], true);
      if (h['corner 0'] != null) {
        final outer = Path()
          ..addPolygon([
            h['corner 0']!,
            h['corner 1']!,
            h['corner 2']!,
            h['corner 3']!,
          ], true);
        c.drawPath(
          Path.combine(PathOperation.difference, outer, inner),
          Paint()..color = Grey.g00.withValues(alpha: 0.4),
        );
      }
      c.drawPath(inner, linePaint(lit, 1.5));
      for (var i = 0; i < 4; i++) {
        // A grip at each corner of the kept rectangle.
        if (h['crop c$i'] case final p? when seen('crop c$i')) {
          final big = grip == 'crop c$i' ? 1.6 : 1.0;
          c.drawCircle(p, 4.5 * big, Paint()..color = Grey.g00);
          c.drawCircle(p, 3 * big, Paint()..color = lit);
        }
      }
    }
    for (var i = 0; i < 4; i++) {
      // Crop: a bar on each side where the layer is cut.
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
    final tp = lineText(text, TextStyles.micro(ink).bold);
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

  /// Draws an 8 px transparency checkerboard inside the composition rect.
  void _checkerboard(Canvas c, Rect comp) {
    final visible = comp.intersect(v.area);
    if (visible.isEmpty) return;
    c.save();
    c.clipRect(visible);
    c.drawRect(visible, Paint()..color = StageTokens.checkerA);
    const tile = 8.0;
    final light = Paint()..color = StageTokens.checkerB;
    final col0 = ((visible.left - comp.left) / tile).floor();
    final col1 = ((visible.right - comp.left) / tile).ceil();
    final row0 = ((visible.top - comp.top) / tile).floor();
    final row1 = ((visible.bottom - comp.top) / tile).ceil();
    for (var row = row0; row < row1; row++) {
      final y = comp.top + row * tile;
      for (var col = col0; col < col1; col++) {
        if (((row + col) & 1) == 0) continue;
        c.drawRect(Rect.fromLTWH(comp.left + col * tile, y, tile, tile), light);
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ViewPainter o) =>
      o.scene != scene ||
      o.v != v ||
      o.sel != sel ||
      o.hover != hover ||
      o.grid != grid ||
      o.safe != safe ||
      o.alpha != alpha ||
      o.part != part ||
      o.pivots != pivots ||
      o.met != met ||
      !listEquals(o.gaps, gaps) ||
      o.hideGizmos != hideGizmos ||
      o.marked != marked ||
      !identical(o.trail, trail) ||
      o.parent != parent ||
      o.grip != grip ||
      o.cameraTarget != cameraTarget ||
      o.cameraMode != cameraMode ||
      o.cameraOrbiting != cameraOrbiting ||
      o.cameraHover != cameraHover ||
      o.falloffRing != falloffRing ||
      o.form != form ||
      !listEquals(o.crop, crop);
}
