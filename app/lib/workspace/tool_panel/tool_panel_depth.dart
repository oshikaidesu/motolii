// The Tool Panel's Depth tool: a top view of the camera and the layers.
// Each layer is a slab at its Z position, drawn in the color of its kind.
// The lens cone widens as the focal length shortens.
// The user drags the focus line, together with its depth-of-field band, or clicks a slab to focus on that layer.
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/inspector_feed/panel.dart' show LayerCards;
import 'package:motolii/widgets/two_fingers.dart';

const _zMax = 3000.0;

/// The lens settings shown in the diagram. One is kept per document, so the values survive leaving the tool panel and coming back.
class _Lens {
  double focal = 50, focus = 1120, fstop = 2.8;
  String? target;

  double get fov => 2 * math.atan(36 / (2 * focal));

  /// The thin-lens depth of field, taking one canvas pixel as 4 mm and a circle of confusion of 0.03 mm.
  ({double near, double far}) get dof {
    const c = .03, k = 4.0;
    final s = focus * k, h = focal * focal / (fstop * c) + focal;
    final near = s * (h - focal) / (h + s - 2 * focal), far = s >= h ? double.infinity : s * (h - focal) / (h - s);
    return (near: near / k, far: far / k);
  }
}

final _lenses = Expando<_Lens>();

/// The focal length in millimetres that corresponds to a document camera zoom of 1.
///
/// It assumes Filament's 24 mm high film (Camera::setLensProjection): 12 mm divided by the tangent of half the stage's 30 degree field of view.
const _filmMm = 12 / 0.2679491924311227;

/// Reads the first camera layer of the document into [lens] and returns its layer id and its distance from the eye.
///
/// The focus is stored in canvas points measured from the eye. When the camera has no focus value, the focus is the eye distance.
/// Returns null when the document has no camera.
({int camera, double eye})? _lensOf(WorkspaceController ws, _Lens lens) {
  final m = ws.inside, cam = ws.layers.where((l) => l.kind == LayerKind.camera).firstOrNull;
  if (m == null || cam == null) return null;
  final t = int.parse(cam.id), at = m.now, p = m.point, eye = 6 * (m.value(t, 'distance', at) ?? 1) * p;
  final stop = m.value(t, 'aperture', at) ?? 0, focus = m.value(t, 'focus', at) ?? 0;
  lens
    ..focal = (m.value(t, 'zoom', at) ?? 1) * _filmMm
    ..fstop = stop > 0
        ? stop
        // An aperture of 0 means everything is sharp, which is shown as the narrowest f-stop of the tool panel.
        : 22
    ..focus = focus > 0 ? focus * p : eye;
  return (camera: t, eye: eye);
}

typedef _Slab = ({String id, String name, Color tone, double x, double z, double w});

/// Returns one slab per layer, except cameras: its horizontal position and its distance from the eye.
List<_Slab> _slabsOf(WorkspaceController ws) {
  final m = ws.inside!, eye = _lensOf(ws, _Lens())?.eye;
  return [
    for (final l in ws.layers)
      if (eye != null && l.kind != LayerKind.camera)
        (
          id: l.id,
          name: l.name,
          tone: layerKindColor(l.kind),
          x: (m.value(int.parse(l.id), 'x', 0) ?? 0) * m.point,
          z: eye - (m.value(int.parse(l.id), 'z', 0) ?? 0) * m.point,
          w: m.bounds(int.parse(l.id))?[2] ?? 200,
        ),
  ];
}

/// The Depth tool: a top view of the camera lens with the layers as slabs.
class DepthTool extends StatefulWidget {
  const DepthTool({super.key});
  @override
  State<DepthTool> createState() => _DepthToolState();
}

class _DepthToolState extends State<DepthTool> {
  @override
  Widget build(BuildContext context) {
    // Rebuild when the displayed snapshot changes, so the lens matches it.
    WorkspaceScope.pictureOf(context);
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked}), lens = _lenses[ws] ??= _Lens(), joined = _lensOf(ws, lens);
    // Sets one camera value and sends it to the engine as a drag, the same way a drag on the stage does.
    void edit(void Function() f, String name, double value) {
      setState(f);
      if (joined != null) {
        ws.inside!
          ..take(joined.camera)
          ..dragUpdate(name, value);
      }
    }

    final cam = ws.layers.where((l) => l.kind == LayerKind.camera).firstOrNull;
    if (joined != null) {
      // With a document camera, the focused layer is the sharp layer nearest to the focus.
      final d = lens.dof,
          sharp = _slabsOf(ws).where((s) => s.z >= d.near && s.z <= d.far).toList()
            ..sort((a, b) => (a.z - lens.focus).abs().compareTo((b.z - lens.focus).abs()));
      lens.target = sharp.firstOrNull?.id;
    }
    final target = ws.layers.where((l) => l.id == lens.target).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolStrip(
          left: [
            Chip(label: cam?.name ?? 'Camera', look: ChipLook.flat(WindowTokens.toneCamera)),
            SizedBox(width: Shape.s(8)),
            Text('${lens.focal.round()} mm', style: TextStyles.value(Grey.g91)),
            SizedBox(width: Shape.s(8)),
            Text('f/${lens.fstop.toStringAsFixed(1)}', style: TextStyles.value(Grey.g91)),
            SizedBox(width: Shape.s(8)),
            Text('${(lens.fov * 180 / math.pi).toStringAsFixed(1)}° view', style: TextStyles.label(Grey.g56)),
          ],
          right: [Chip(label: target == null ? 'Focus free' : 'On ${target.name}', dot: target == null ? Grey.g56 : layerKindColor(target.kind))],
        ),
        const SizedBox(height: WindowTokens.gutter),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: WindowTokens.card,
                  child: _Diagram(
                    lens: lens,
                    onFocus: (z, id) => edit(
                      () {
                        lens.focus = z.clamp(100.0, _zMax);
                        lens.target = id;
                      },
                      'focus',
                      z.clamp(100.0, _zMax) / (ws.inside?.point ?? 1),
                    ),
                    // A narrower view is a longer lens.
                    onFocal: (f) => edit(() => lens.focal = f.clamp(8.0, 600.0), 'zoom', f.clamp(8.0, 600.0) / _filmMm),
                    onDone: () {
                      // Ending the drag makes the change one undo step.
                      if (joined != null) ws.after(ws.inside!.later('drag_end', number: 1));
                    },
                  ),
                ),
              ),
              const SizedBox(width: WindowTokens.gutter),
              SizedBox(
                width: Shape.z(128),
                child: _LensNumbers(lens: lens, camera: joined == null ? null : cam?.id),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The side column with the depth of field and its near and far limits. With a camera it also shows the Camera Options card.
class _LensNumbers extends StatelessWidget {
  const _LensNumbers({required this.lens, required this.camera});
  final _Lens lens;
  final String? camera;
  @override
  Widget build(BuildContext context) {
    final d = lens.dof;
    String far(double v) => v.isInfinite ? '∞' : v.round().toString();
    Widget pair(String a, String b) => Row(
      children: [
        Expanded(child: Text(a, style: TextStyles.label(Grey.g56))),
        Text(b, style: TextStyles.value(Grey.g91).copyWith(fontSize: TextStyles.px(10.5))),
      ],
    );
    return ColoredBox(
      color: WindowTokens.card,
      child: ListView(
        padding: EdgeInsets.only(top: Shape.s(7), bottom: WindowTokens.inset),
        children: [
          if (camera case final id?) LayerCards(layer: id, only: const ['Camera Options']),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: Shape.s(6)),
                ToolReadout(value: far(d.far - d.near), unit: 'px', sub: 'depth of field'),
                SizedBox(height: Shape.s(7)),
                pair('Near', far(d.near)),
                SizedBox(height: Shape.s(4)),
                pair('Far', far(d.far)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The top view. Drag the focus line up and down, or tap a slab to focus on that layer.
class _Diagram extends StatefulWidget {
  const _Diagram({required this.lens, required this.onFocus, required this.onFocal, required this.onDone});
  final _Lens lens;
  final void Function(double z, String? id) onFocus;
  final void Function(double focal) onFocal;
  final VoidCallback onDone;
  @override
  State<_Diagram> createState() => _DiagramState();
}

class _DiagramState extends State<_Diagram> {
  bool _drag = false, _hot = false;

  @override
  Widget build(BuildContext context) {
    final slabs = _slabsOf(WorkspaceScope.of(context, {WorkspaceAspect.document}));
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

        bool nearFocus(Offset p) => (m.at(0, widget.lens.focus).dy - p.dy).abs() < 9;
        final lens = widget.lens, d = lens.dof;
        return MouseRegion(
          cursor: _hot || _drag ? SystemMouseCursors.resizeUpDown : MouseCursor.defer,
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
              if (d.dy < -8) widget.onFocal(18 / math.tan(math.atan2(d.dx.abs(), -d.dy).clamp(.02, 1.5)));
            },
            child: CustomPaint(
              size: box.biggest,
              painter: _DepthPainter(slabs: slabs, focal: lens.focal, focus: lens.focus, near: d.near, far: d.far, target: lens.target, hot: _hot || _drag),
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
    scale = math.max(.01, math.min((s.height - top - bottom) / _zMax, (s.width - left - 10) / 2600));
    eye = Offset(left + (s.width - left - 10) / 2, s.height - bottom);
  }
  final Size size;
  late final double scale;
  late final Offset eye;
  Offset at(double x, double z) => Offset(eye.dx + x * scale, eye.dy - z * scale);
  double z(double y) => (eye.dy - y) / scale;
  Rect slab(double x, double z, double w) => Rect.fromCenter(center: at(x, z), width: w * scale, height: Shape.z(6));
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
  final List<_Slab> slabs;
  final double focal, focus, near, far;
  final String? target;
  final bool hot;

  @override
  void paint(Canvas c, Size s) {
    final m = _Map(s), fill = Paint();
    final line = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final lab = TextStyles.value(Grey.g56).copyWith(fontSize: TextStyles.px(9.5));
    // Depth rulings every 500 px, labelled every 1000.
    for (var z = 0.0; z <= _zMax; z += 500) {
      final y = m.at(0, z).dy.floorToDouble() + .5;
      final major = z % 1000 == 0;
      c.drawLine(Offset(30, y), Offset(s.width - 6, y), line..color = major ? Grey.g20 : Grey.g15);
      if (major) toolText(c, z == 0 ? '0' : '${(z / 1000).round()}k', Offset(26, y), lab, ax: 1, ay: .5);
    }
    // The lens cone, out to the far edge of the diagram.
    final half = math.atan(36 / (2 * focal)), reach = _zMax * 1.1;
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
    final knobZ = _zMax * .45, knob = m.at(knobZ * math.tan(half), knobZ);
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
    dashed(c, Offset(30, y), Offset(s.width - 50, y), WindowTokens.accent, hot ? 2 : 1.5, 4, 3);
    // Slabs: sharp ones in their full hue, soft ones sink toward the card.
    for (final sl in slabs) {
      final r = m.slab(sl.x, sl.z, sl.w), sharp = sl.z >= near && sl.z <= far, on = sl.id == target;
      final col = sharp ? sl.tone : Color.lerp(sl.tone, WindowTokens.card, .55)!;
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
    final taken = [for (final sl in slabs) m.slab(sl.x, sl.z, sl.w).inflate(1), Rect.fromLTWH(s.width - 48, y - 8, 42, 16)];
    for (final sl in [...slabs.where((e) => e.id == target), ...slabs.where((e) => e.id != target)]) {
      final r = m.slab(sl.x, sl.z, sl.w), sharp = sl.z >= near && sl.z <= far, on = sl.id == target;
      final np = lineText(sl.name, TextStyles.label(sharp ? Grey.g91 : Grey.g56).copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w400));
      final at = Rect.fromLTWH(r.left, r.top - 2 - np.height, np.width, np.height);
      if (!taken.any((t) => t.overlaps(at))) {
        taken.add(at);
        np.paint(c, at.topLeft);
      }
      np.dispose();
    }
    final tag = '${focus.round()}';
    final tr = RRect.fromRectAndRadius(Rect.fromLTWH(s.width - 48, y - 8, 42, 16), Shape.r(WindowTokens.chipRadius));
    c.drawRRect(tr, fill..color = WindowTokens.accent);
    toolText(c, tag, tr.center, TextStyles.value(WindowTokens.onAccent).copyWith(fontSize: TextStyles.px(10), fontWeight: FontWeight.w700), ax: .5, ay: .5);
    // The camera body at the cone's tip.
    final e = m.eye;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: e + const Offset(0, 9), width: Shape.z(18), height: Shape.z(12)), Shape.r(3)),
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
    c.drawCircle(e + const Offset(0, 9), 2.5, Paint()..color = WindowTokens.onAccent);
    toolText(c, 'CAM', e + const Offset(14, 9), TextStyles.micro(Grey.g63).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1), ay: .5);
  }

  @override
  bool shouldRepaint(_DepthPainter o) =>
      o.focal != focal || o.focus != focus || o.near != near || o.far != far || o.target != target || o.hot != hot || o.slabs.length != slabs.length;
}
