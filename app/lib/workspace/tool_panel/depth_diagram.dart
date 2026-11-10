// The Depth tool's top view: the camera's lens, its field and depth of field, and the layers as slabs.
import 'package:motolii/workspace/tool_panel/depth_lens.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';

/// The top view. Drag the focus line up and down, or tap a slab to focus on that layer.
class DepthDiagram extends StatefulWidget {
  const DepthDiagram({
    super.key,
    required this.lens,
    required this.onFocus,
    required this.onFocal,
    required this.onDone,
  });
  final DepthLens lens;
  final void Function(double z, String? id) onFocus;
  final void Function(double focal) onFocal;
  final VoidCallback onDone;
  @override
  State<DepthDiagram> createState() => _DiagramState();
}

class _DiagramState extends State<DepthDiagram> {
  bool _drag = false, _hot = false;

  @override
  Widget build(BuildContext context) {
    final slabs = depthSlabsOf(
      WorkspaceScope.of(context, {WorkspaceAspect.document}),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final m = _Map(box.biggest);
        String? hit(Offset p) {
          for (final s in slabs.reversed) {
            final r = m.slab(s.x, s.z, s.w).inflate(5);
            if (r.contains(p)) return s.id;
          }
          return null;
        }

        bool nearFocus(Offset p) =>
            (m.at(0, widget.lens.focus).dy - p.dy).abs() < 9;
        final lens = widget.lens, d = lens.dof;
        return MouseRegion(
          cursor: _hot || _drag
              ? SystemMouseCursors.resizeUpDown
              : MouseCursor.defer,
          onHover: (e) {
            final h = nearFocus(e.localPosition);
            if (h != _hot) setState(() => _hot = h);
          },
          onExit: (_) {
            if (_hot) setState(() => _hot = false);
          },
          child: GestureDetector(
            supportedDevices: pressingDevices,
            behavior: HitTestBehavior.opaque,
            onTapUp: (e) {
              final id = hit(e.localPosition);
              if (id == null) return;
              // Focus on the clicked layer at its own distance.
              widget.onFocus(slabs.firstWhere((s) => s.id == id).z, id);
              widget.onDone();
            },
            onVerticalDragStart: (e) {
              if (nearFocus(e.localPosition)) setState(() => _drag = true);
            },
            onVerticalDragUpdate: (e) {
              if (_drag) widget.onFocus(m.z(e.localPosition.dy), null);
            },
            onVerticalDragEnd: (_) {
              if (_drag) widget.onDone();
              setState(() => _drag = false);
            },
            onHorizontalDragEnd: (_) => widget.onDone(),
            // Dragging sideways changes the focal length, as the cone edge opens or closes the view.
            onHorizontalDragUpdate: (e) {
              final d = e.localPosition - m.eye;
              if (d.dy < -8) {
                widget.onFocal(
                  18 / math.tan(math.atan2(d.dx.abs(), -d.dy).clamp(.02, 1.5)),
                );
              }
            },
            child: CustomPaint(
              size: box.biggest,
              painter: _DepthPainter(
                slabs: slabs,
                focal: lens.focal,
                focus: lens.focus,
                near: d.near,
                far: d.far,
                target: lens.target,
                hot: _hot || _drag,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Maps canvas space (x across, z away from the camera) to the diagram's pixels.
class _Map {
  _Map(Size s) : size = s {
    const top = 12.0, bottom = 30.0, left = 34.0;
    scale = math.max(
      .01,
      math.min(
        (s.height - top - bottom) / depthZMax,
        (s.width - left - 10) / 2600,
      ),
    );
    eye = Offset(left + (s.width - left - 10) / 2, s.height - bottom);
  }
  final Size size;
  late final double scale;
  late final Offset eye;
  Offset at(double x, double z) =>
      Offset(eye.dx + x * scale, eye.dy - z * scale);
  double z(double y) => (eye.dy - y) / scale;
  Rect slab(double x, double z, double w) =>
      Rect.fromCenter(center: at(x, z), width: w * scale, height: Shape.z(6));
}

/// Paints the diagram: depth rulings, lens cone, depth-of-field band, focus line, slabs and the camera.
class _DepthPainter extends CustomPainter {
  const _DepthPainter({
    required this.slabs,
    required this.focal,
    required this.focus,
    required this.near,
    required this.far,
    required this.target,
    required this.hot,
  });
  final List<DepthSlab> slabs;
  final double focal, focus, near, far;
  final String? target;
  final bool hot;

  @override
  void paint(Canvas c, Size s) {
    final m = _Map(s), fill = Paint();
    final line = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final lab = TextStyles.value(Grey.g56)
        .copyWith(fontSize: TextStyles.px(9.5));
    // Depth rulings every 500 px, labelled every 1000.
    for (var z = 0.0; z <= depthZMax; z += 500) {
      final y = m.at(0, z).dy.floorToDouble() + .5;
      final major = z % 1000 == 0;
      c.drawLine(
        Offset(30, y),
        Offset(s.width - 6, y),
        line..color = major ? Grey.g20 : Grey.g15,
      );
      if (major) {
        toolText(
          c,
          z == 0 ? '0' : '${(z / 1000).round()}k',
          Offset(26, y),
          lab,
          ax: 1,
          ay: .5,
        );
      }
    }
    // The lens cone, out to the far edge of the diagram.
    final half = math.atan(36 / (2 * focal)), reach = depthZMax * 1.1;
    final spread = reach * math.tan(half);
    final cone = Path()
      ..moveTo(m.eye.dx, m.eye.dy)
      ..lineTo(m.at(-spread, reach).dx, m.at(-spread, reach).dy)
      ..lineTo(m.at(spread, reach).dx, m.at(spread, reach).dy)
      ..close();
    c.save();
    c.clipRect(Rect.fromLTRB(30, 0, s.width, s.height));
    c.drawPath(cone, fill..color = Grey.g15);
    // Depth of field: the band that is sharp, inside the cone.
    c.save();
    c.clipPath(cone);
    final fy = m.at(0, far.isInfinite ? reach : far).dy, ny = m.at(0, near).dy;
    c.drawRect(Rect.fromLTRB(0, fy, s.width, ny), fill..color = Grey.g20);
    c.restore();
    c.drawPath(cone, line..color = Grey.g38);
    // A knob on the cone edge shows that dragging sideways changes the view.
    final knobZ = depthZMax * .45, knob = m.at(knobZ * math.tan(half), knobZ);
    c.drawCircle(knob, 6, Paint()..color = WindowTokens.toneCamera);
    c.drawCircle(
      knob,
      6,
      Paint()
        ..color = WindowTokens.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    c.restore();
    // The focus line and its tag.
    final y = m.at(0, focus).dy;
    dashed(
      c,
      Offset(30, y),
      Offset(s.width - 50, y),
      WindowTokens.accent,
      hot ? 2 : 1.5,
      4,
      3,
    );
    // Slabs: sharp ones in their full hue, soft ones sink toward the card.
    for (final sl in slabs) {
      final r = m.slab(sl.x, sl.z, sl.w),
          sharp = sl.z >= near && sl.z <= far,
          on = sl.id == target;
      final col = sharp
          ? sl.tone
          : Color.lerp(sl.tone, WindowTokens.card, .55)!;
      final rr = RRect.fromRectAndRadius(r, Shape.r(2));
      c.drawRRect(rr, fill..color = col);
      if (on) {
        c.drawRRect(
          rr.inflate(2),
          line
            ..color = Grey.g95
            ..strokeWidth = 1.2,
        );
      }
      line.strokeWidth = 1;
    }
    // Layer names above their slabs, the focused layer first.
    // A name that would cover a slab, the focus tag or another name is left out.
    final taken = [
      for (final sl in slabs) m.slab(sl.x, sl.z, sl.w).inflate(1),
      Rect.fromLTWH(s.width - 48, y - 8, 42, 16),
    ];
    for (final sl in [
      ...slabs.where((e) => e.id == target),
      ...slabs.where((e) => e.id != target),
    ]) {
      final r = m.slab(sl.x, sl.z, sl.w),
          sharp = sl.z >= near && sl.z <= far,
          on = sl.id == target;
      final np = lineText(
        sl.name,
        TextStyles.label(sharp ? Grey.g91 : Grey.g56)
            .copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w400),
      );
      final at = Rect.fromLTWH(
        r.left,
        r.top - 2 - np.height,
        np.width,
        np.height,
      );
      if (!taken.any((t) => t.overlaps(at))) {
        taken.add(at);
        np.paint(c, at.topLeft);
      }
      np.dispose();
    }
    final tag = '${focus.round()}';
    final tr = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width - 48, y - 8, 42, 16),
      Shape.r(WindowTokens.chipRadius),
    );
    c.drawRRect(tr, fill..color = WindowTokens.accent);
    toolText(
      c,
      tag,
      tr.center,
      TextStyles.value(WindowTokens.onAccent)
          .copyWith(fontSize: TextStyles.px(10), fontWeight: FontWeight.w700),
      ax: .5,
      ay: .5,
    );
    // The camera body at the cone's tip.
    final e = m.eye;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: e + const Offset(0, 9),
          width: Shape.z(18),
          height: Shape.z(12),
        ),
        Shape.r(3),
      ),
      fill..color = WindowTokens.toneCamera,
    );
    c.drawPath(
      Path()
        ..moveTo(e.dx - 5, e.dy + 3)
        ..lineTo(e.dx, e.dy - 3)
        ..lineTo(e.dx + 5, e.dy + 3)
        ..close(),
      fill,
    );
    c.drawCircle(
      e + const Offset(0, 9),
      2.5,
      Paint()..color = WindowTokens.onAccent,
    );
    toolText(
      c,
      'CAM',
      e + const Offset(14, 9),
      TextStyles.micro(Grey.g63)
          .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
      ay: .5,
    );
  }

  @override
  bool shouldRepaint(_DepthPainter o) =>
      o.focal != focal ||
      o.focus != focus ||
      o.near != near ||
      o.far != far ||
      o.target != target ||
      o.hot != hot ||
      o.slabs.length != slabs.length;
}
