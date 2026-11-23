// Neutral third-person world-space (XZ) radar for the Depth panel: fixed world grid, moving camera cone,
// Boxcam frame plane, DOF band, Z-target lock highlight, and spatial layer slabs.
import 'dart:math' as math;

import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/tool_panel/depth_lens.dart';

enum _DragKind { none, focus, focal }

/// World-space XZ radar view. Click a slab to focus on it, drag the focus bar along the view axis,
/// or drag the cone edge knob to adjust focal length.
class DepthDiagram extends StatefulWidget {
  const DepthDiagram({
    super.key,
    required this.lens,
    required this.onFocus,
    required this.onFocal,
    required this.onDone,
    this.onCancel,
  });
  final DepthLens lens;
  final void Function(double zPx, int? id) onFocus;
  final void Function(double focal) onFocal;
  final VoidCallback onDone;
  final VoidCallback? onCancel;
  @override
  State<DepthDiagram> createState() => _DiagramState();
}

class _DiagramState extends State<DepthDiagram> {
  _DragKind _drag = _DragKind.none;
  _DragKind _hot = _DragKind.none;
  double? _focusBefore, _focalBefore;

  bool _escapeKey(KeyEvent e) {
    if (e is! KeyDownEvent ||
        e.logicalKey != LogicalKeyboardKey.escape ||
        _drag == _DragKind.none) {
      return false;
    }
    if (_focusBefore != null) widget.lens.focus = _focusBefore!;
    if (_focalBefore != null) widget.lens.focal = _focalBefore!;
    setState(() => _drag = _DragKind.none);
    widget.onCancel?.call();
    HardwareKeyboard.instance.removeHandler(_escapeKey);
    _focusBefore = null;
    _focalBefore = null;
    return true;
  }

  void _endDrag() {
    HardwareKeyboard.instance.removeHandler(_escapeKey);
    if (_drag != _DragKind.none) widget.onDone();
    setState(() => _drag = _DragKind.none);
    _focusBefore = null;
    _focalBefore = null;
  }

  @override
  Widget build(BuildContext context) {
    WorkspaceScope.frameOf(context);
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document});
    final lens = widget.lens;
    final slabs = depthSlabsOf(ws, lens);
    return LayoutBuilder(
      builder: (context, box) {
        final map = _RadarMap(box.biggest, lens, slabs);

        int? hitSlab(Offset p) {
          for (final s in slabs.reversed) {
            final (a, b) = map.slabSegment(s);
            if (_distToSegment(p, a, b) <= 9) return s.id;
          }
          return null;
        }

        _DragKind hitControl(Offset p) {
          if ((p - map.focalKnob).distance <= 12) return _DragKind.focal;
          final (fa, fb) = map.focusSegment;
          if (_distToSegment(p, fa, fb) <= 9) return _DragKind.focus;
          return _DragKind.none;
        }

        final d = lens.dof;
        return MouseRegion(
          cursor: switch (_drag != _DragKind.none ? _drag : _hot) {
            _DragKind.focus => SystemMouseCursors.grab,
            _DragKind.focal => SystemMouseCursors.resizeLeftRight,
            _DragKind.none => MouseCursor.defer,
          },
          onHover: (e) {
            final h = hitControl(e.localPosition);
            if (h != _hot) setState(() => _hot = h);
          },
          onExit: (_) {
            if (_hot != _DragKind.none) setState(() => _hot = _DragKind.none);
          },
          child: GestureDetector(
            supportedDevices: pressingDevices,
            behavior: HitTestBehavior.opaque,
            onTapUp: (e) {
              final id = hitSlab(e.localPosition);
              if (id == null) return;
              final slab = slabs.firstWhere((s) => s.id == id);
              if (slab.depthPx > 10) {
                widget.onFocus(slab.depthPx, id);
                widget.onDone();
              }
            },
            onPanStart: (e) {
              final kind = hitControl(e.localPosition);
              if (kind == _DragKind.none) return;
              _focusBefore = lens.focus;
              _focalBefore = lens.focal;
              HardwareKeyboard.instance.addHandler(_escapeKey);
              setState(() => _drag = kind);
            },
            onPanUpdate: (e) {
              if (_drag == _DragKind.none) return;
              final (wx, wz) = map.toWorld(e.localPosition);
              final (fx, fz) = lens.forward;
              final (rx, rz) = lens.right;
              final dx = wx - lens.eyeX, dz = wz - lens.eyeZ;
              final along = dx * fx + dz * fz;
              if (_drag == _DragKind.focus) {
                final px = math.max(50.0, along * lens.point);
                widget.onFocus(px, null);
              } else if (_drag == _DragKind.focal && along > 0.3) {
                final across = (dx * rx + dz * rz).abs();
                final halfAngle = math.atan2(across, along).clamp(0.03, 1.35);
                // Matches 24 mm sensor height (half = 12 mm).
                widget.onFocal(12.0 / math.tan(halfAngle));
              }
            },
            onPanEnd: (_) => _endDrag(),
            onPanCancel: _endDrag,
            child: CustomPaint(
              size: box.biggest,
              painter: _RadarPainter(
                map: map,
                lens: lens,
                slabs: slabs,
                near: d.near,
                far: d.far,
                hot: _drag != _DragKind.none ? _drag : _hot,
              ),
            ),
          ),
        );
      },
    );
  }
}

double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 < 1e-4) return (p - a).distance;
  final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2).clamp(
    0.0,
    1.0,
  );
  return (p - (a + ab * t)).distance;
}

/// World-fixed XZ top-down projection centered on the world origin (neutral third-person radar).
/// +X is right, -Z is up (into the scene), +Z is down (toward default camera).
class _RadarMap {
  _RadarMap(this.size, this.lens, List<DepthSlab> slabs) {
    // Keep world origin fixed so camera movement reads clearly; expand smoothly only when objects move far out.
    var reach = 7.5;
    void include(double x, double z) {
      reach = math.max(reach, math.max(x.abs(), z.abs()) + 1.5);
    }

    include(lens.eyeX, lens.eyeZ);
    include(lens.lookX, lens.lookZ);
    for (final s in slabs) {
      include(s.x, s.z);
    }
    worldRadius = reach;
    const pad = 12.0;
    final usableW = math.max(40.0, size.width - pad * 2);
    final usableH = math.max(40.0, size.height - pad * 2);
    scale = math.min(usableW, usableH) / (worldRadius * 2);
    origin = Offset(size.width * .5, size.height * .46);
  }

  final Size size;
  final DepthLens lens;
  late final double worldRadius;
  late final double scale;
  late final Offset origin;

  Offset toScreen(double wx, double wz) =>
      Offset(origin.dx + wx * scale, origin.dy + wz * scale);

  (double, double) toWorld(Offset p) =>
      ((p.dx - origin.dx) / scale, (p.dy - origin.dy) / scale);

  Offset get eye => toScreen(lens.eyeX, lens.eyeZ);
  Offset get look => toScreen(lens.lookX, lens.lookZ);

  /// World-space segment of a slab rotated by its `rotate_y`.
  (Offset, Offset) slabSegment(DepthSlab s) {
    final half = s.widthUnits * .5;
    final dx = math.cos(s.yaw) * half, dz = -math.sin(s.yaw) * half;
    return (toScreen(s.x - dx, s.z - dz), toScreen(s.x + dx, s.z + dz));
  }

  /// Cross-cone segment at distance [distUnits] along the camera forward axis.
  (Offset, Offset) coneChord(double distUnits) {
    final (fx, fz) = lens.forward;
    final (rx, rz) = lens.right;
    final halfSpread = distUnits * math.tan(lens.fov * .5);
    final cx = lens.eyeX + fx * distUnits, cz = lens.eyeZ + fz * distUnits;
    return (
      toScreen(cx - rx * halfSpread, cz - rz * halfSpread),
      toScreen(cx + rx * halfSpread, cz + rz * halfSpread),
    );
  }

  /// Focus line across the camera cone.
  (Offset, Offset) get focusSegment => coneChord(lens.focusUnits);

  /// Boxcam frame plane segment across the camera cone at `look`.
  (Offset, Offset) get frameSegment => coneChord(lens.frameDepth);

  /// Cone-edge handle for dragging focal length.
  Offset get focalKnob => coneChord(lens.frameDepth * .65).$2;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.map,
    required this.lens,
    required this.slabs,
    required this.near,
    required this.far,
    required this.hot,
  });

  final _RadarMap map;
  final DepthLens lens;
  final List<DepthSlab> slabs;
  final double near, far;
  final _DragKind hot;

  @override
  void paint(Canvas c, Size s) {
    final fill = Paint();
    final line = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    c.save();
    c.clipRect(Offset.zero & s);

    // 1. Fixed world XZ grid (neutral third-person ground plane).
    final step = map.worldRadius > 16 ? 4.0 : 2.0;
    final maxGrid = (map.worldRadius * 2).ceil();
    for (var g = -maxGrid.toDouble(); g <= maxGrid; g += step) {
      final isAxis = g == 0;
      line.color = isAxis ? Grey.g26 : Grey.g15;
      final sx = map.toScreen(g, 0).dx.floorToDouble() + .5;
      if (sx >= 0 && sx <= s.width) {
        c.drawLine(Offset(sx, 0), Offset(sx, s.height), line);
      }
      final sy = map.toScreen(0, g).dy.floorToDouble() + .5;
      if (sy >= 0 && sy <= s.height) {
        c.drawLine(Offset(0, sy), Offset(s.width, sy), line);
      }
    }
    // Subtle origin crosshair and axis cues.
    final orig = map.origin;
    c.drawCircle(orig, 2.2, line..color = Grey.g38);
    final axisStyle = TextStyles.micro(Grey.g38);
    toolText(c, '+X', Offset(s.width - 14, orig.dy - 9), axisStyle, ax: .5);
    toolText(c, '-Z', Offset(orig.dx + 12, 10), axisStyle, ax: .5);

    // 2. FPS radar view cone + DOF band + Boxcam frame plane.
    final reach = map.worldRadius * 2.4;
    final (cl, cr) = map.coneChord(reach);
    final cone = Path()
      ..moveTo(map.eye.dx, map.eye.dy)
      ..lineTo(cl.dx, cl.dy)
      ..lineTo(cr.dx, cr.dy)
      ..close();
    c.drawPath(
      cone,
      fill..color = WindowTokens.toneCamera.withValues(alpha: .09),
    );

    // Depth-of-field sharp band clipped inside the view cone.
    final nearUnits = lens.point > 0 ? math.max(0.0, near / lens.point) : 0.0;
    final farUnits = far.isInfinite
        ? reach
        : (lens.point > 0 ? math.min(reach, far / lens.point) : reach);
    if (farUnits > nearUnits) {
      final (nl, nr) = map.coneChord(nearUnits);
      final (fl, fr) = map.coneChord(farUnits);
      final dofBand = Path()
        ..moveTo(nl.dx, nl.dy)
        ..lineTo(nr.dx, nr.dy)
        ..lineTo(fr.dx, fr.dy)
        ..lineTo(fl.dx, fl.dy)
        ..close();
      c.save();
      c.clipPath(cone);
      c.drawPath(
        dofBand,
        fill..color = WindowTokens.accent.withValues(alpha: .16),
      );
      c.restore();
    }
    c.drawPath(
      cone,
      line
        ..color = WindowTokens.toneCamera.withValues(alpha: .48)
        ..strokeWidth = 1.1,
    );

    // Boxcam frame line (at `look`, perpendicular to camera sight line).
    final (bl, br) = map.frameSegment;
    c.drawLine(
      bl,
      br,
      line
        ..color = WindowTokens.toneCamera.withValues(alpha: .85)
        ..strokeWidth = 1.6,
    );
    // Sight line from eye to Boxcam frame centre.
    dashed(
      c,
      map.eye,
      map.look,
      WindowTokens.toneCamera.withValues(alpha: .35),
      1,
      3,
      3,
    );

    // Focus plane dashed line (overlays Boxcam frame when Auto Focus is active).
    final (flA, flB) = map.focusSegment;
    dashed(
      c,
      flA,
      flB,
      WindowTokens.accent,
      hot == _DragKind.focus ? 2.2 : 1.5,
      4,
      3,
    );

    // Focal-length drag knob on the right cone edge.
    final knob = map.focalKnob;
    c.drawCircle(
      knob,
      hot == _DragKind.focal ? 6.5 : 5.0,
      fill..color = WindowTokens.toneCamera,
    );
    c.drawCircle(
      knob,
      hot == _DragKind.focal ? 6.5 : 5.0,
      line
        ..color = WindowTokens.card
        ..strokeWidth = 1.5,
    );

    // 3. Spatial layer slabs in world XZ.
    final taken = <Rect>[];
    for (final sl in slabs) {
      final (a, b) = map.slabSegment(sl);
      final sharp = sl.depthPx >= near && sl.depthPx <= far;
      final locked = sl.id == lens.lockTarget;
      final focused = sl.id == lens.target;
      final col = sharp ? sl.tone : Color.lerp(sl.tone, WindowTokens.card, .5)!;
      c.drawLine(
        a,
        b,
        Paint()
          ..color = Grey.g00
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      c.drawLine(
        a,
        b,
        Paint()
          ..color = col
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
      final mid = (a + b) * .5;
      if (locked) {
        // Z-target lock-on diamond ring around the locked layer.
        c.drawCircle(
          mid,
          8,
          line
            ..color = WindowTokens.toneCamera
            ..strokeWidth = 1.6,
        );
      } else if (focused) {
        c.drawCircle(
          mid,
          6,
          line
            ..color = Grey.g95
            ..strokeWidth = 1.1,
        );
      }
      final label = lineText(
        sl.name,
        TextStyles.label(sharp || locked ? Grey.g91 : Grey.g56).copyWith(
          fontWeight: (locked || focused) ? FontWeight.w700 : FontWeight.w400,
        ),
      );
      final rect = Rect.fromLTWH(
        mid.dx - label.width * .5,
        mid.dy - 10 - label.height,
        label.width,
        label.height,
      );
      if (!taken.any((r) => r.overlaps(rect))) {
        taken.add(rect.inflate(1));
        label.paint(c, rect.topLeft);
      }
      label.dispose();
    }

    // 4. Camera directional arrow / marker at `eye` pointing along `forward`.
    final (fx, fz) = lens.forward;
    final (rx, rz) = lens.right;
    final e = map.eye;
    final tip = Offset(e.dx + fx * 10, e.dy + fz * 10);
    final backL = Offset(e.dx - fx * 6 - rx * 6, e.dy - fz * 6 - rz * 6);
    final backR = Offset(e.dx - fx * 6 + rx * 6, e.dy - fz * 6 + rz * 6);
    final camTri = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(backL.dx, backL.dy)
      ..lineTo(backR.dx, backR.dy)
      ..close();
    c.drawPath(camTri, fill..color = WindowTokens.toneCamera);
    c.drawPath(
      camTri,
      line
        ..color = WindowTokens.card
        ..strokeWidth = 1.4,
    );
    c.drawCircle(e, 2.2, fill..color = WindowTokens.onAccent);

    // Focus distance pill at top-right of the radar.
    final tag = lens.autoFocus
        ? 'AUTO ${lens.focus.round()}'
        : '${lens.focus.round()}';
    final tp = lineText(
      tag,
      TextStyles.value(WindowTokens.onAccent)
          .copyWith(fontSize: TextStyles.px(9.5), fontWeight: FontWeight.w700),
    );
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width - tp.width - 16, 6, tp.width + 10, 16),
      Shape.r(WindowTokens.chipRadius),
    );
    c.drawRRect(pill, fill..color = WindowTokens.accent);
    tp.paint(c, Offset(pill.left + 5, pill.top + (16 - tp.height) * .5));
    tp.dispose();

    c.restore();
  }

  @override
  bool shouldRepaint(_RadarPainter o) => true;
}
