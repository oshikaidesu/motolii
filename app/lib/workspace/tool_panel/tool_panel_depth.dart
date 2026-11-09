// The tool panel's Depth tool: the camera seen from above. Layers sit as slabs at their Z in their own hue, the lens cone opens
// with the focal length, and the focus line (with its depth-of-field band) is dragged or snapped to a slab.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import 'tool_panel_widgets.dart';
import '../../widgets/controls.dart' show Chip, ChipLook;
import '../state/state.dart';
import '../workspace.dart' show LayerCards;
import '../../widgets/two_fingers.dart';

const _zMax = 3000.0;

/// The lens, kept per document so leaving the tool panel and coming back keeps it.
class _Lens {
  double focal = 50, focus = 1120, fstop = 2.8;
  String? target;

  double get fov => 2 * math.atan(36 / (2 * focal));

  /// Thin-lens depth of field, with one comp px read as 4 mm and a 0.03 mm circle of confusion.
  ({double near, double far}) get dof {
    const c = .03, k = 4.0;
    final s = focus * k, h = focal * focal / (fstop * c) + focal;
    final near = s * (h - focal) / (h + s - 2 * focal), far = s >= h ? double.infinity : s * (h - focal) / (h - s);
    return (near: near / k, far: far / k);
  }
}

final _lenses = Expando<_Lens>();

/// Joined: millimetres of focal length to the document camera's zoom 1, on Filament's own 24 mm high film
/// (Camera::setLensProjection): 12 mm over the tangent of half the stage's 30 degrees.
const _filmMm = 12 / 0.2679491924311227;

/// Joined: the document's camera that the tool panel is on (the first one listed), the lens read from it as the tool panel counts
/// (focus in points of the picture from the eye; none said, where it looks), and how far off its eye is.
({int camera, double eye})? _lensOf(Ws ws, _Lens lens) {
  final m = ws.inside, cam = ws.layers.where((l) => l.kind == WsKind.camera).firstOrNull;
  if (m == null || cam == null) return null;
  final t = int.parse(cam.id), at = m.now, p = m.point, eye = 6 * (m.value(t, 'distance', at) ?? 1) * p;
  final stop = m.value(t, 'aperture', at) ?? 0, focus = m.value(t, 'focus', at) ?? 0;
  lens
    ..focal = (m.value(t, 'zoom', at) ?? 1) * _filmMm
    ..fstop = stop > 0
        ? stop
        : 22 // (nought, all sharp: the tool panel's narrowest)
    ..focus = focus > 0 ? focus * p : eye;
  return (camera: t, eye: eye);
}

typedef _Slab = ({String id, String name, Color tone, double x, double z, double w});

/// Each thing seen from above: where it is (across, and how far from the eye).
List<_Slab> _slabsOf(Ws ws) {
  final m = ws.inside!, eye = _lensOf(ws, _Lens())?.eye;
  return [
    for (final l in ws.layers)
      if (eye != null && l.kind != WsKind.camera)
        (
          id: l.id,
          name: l.name,
          tone: wsTone(l.kind),
          x: (m.value(int.parse(l.id), 'x', 0) ?? 0) * m.point,
          z: eye - (m.value(int.parse(l.id), 'z', 0) ?? 0) * m.point,
          w: m.bounds(int.parse(l.id))?[2] ?? 200,
        ),
  ];
}

class DepthTool extends StatefulWidget {
  const DepthTool({super.key});
  @override
  State<DepthTool> createState() => _DepthToolState();
}

class _DepthToolState extends State<DepthTool> {
  @override
  Widget build(BuildContext context) {
    WsScope.pictureOf(context); // (the lens as it is in the picture shown)
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked}), lens = _lenses[ws] ??= _Lens(), joined = _lensOf(ws, lens);
    // (the one value the hand moves, carried as a hand on the stage carries it)
    void edit(void Function() f, String name, double value) {
      setState(f);
      if (joined != null) {
        ws.inside!
          ..take(joined.camera)
          ..dragUpdate(name, value);
      }
    }

    final cam = ws.layers.where((l) => l.kind == WsKind.camera).firstOrNull;
    if (joined != null) {
      // (joined: the thing the focus is on is the one nearest it of those it holds sharp, by the document's values)
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
            Chip(label: cam?.name ?? 'Camera', look: ChipLook.flat(WsT.toneCamera)),
            SizedBox(width: Shape.s(8)),
            Text('${lens.focal.round()} mm', style: T.value(Grey.g91)),
            SizedBox(width: Shape.s(8)),
            Text('f/${lens.fstop.toStringAsFixed(1)}', style: T.value(Grey.g91)),
            SizedBox(width: Shape.s(8)),
            Text('${(lens.fov * 180 / math.pi).toStringAsFixed(1)}° view', style: T.label(Grey.g56)),
          ],
          right: [Chip(label: target == null ? 'Focus free' : 'On ${target.name}', dot: target == null ? Grey.g56 : wsTone(target.kind))],
        ),
        const SizedBox(height: WsT.gutter),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: WsT.card,
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
                    onFocal: (f) => edit(
                      () => lens.focal = f.clamp(8.0, 600.0),
                      'zoom',
                      f.clamp(8.0, 600.0) / _filmMm,
                    ), // (the cone's edge pulled: a narrower view is a longer lens)
                    onDone: () {
                      if (joined != null) ws.after(ws.inside!.later('drag_end', number: 1)); // (a hand let go is one step of the document)
                    },
                  ),
                ),
              ),
              const SizedBox(width: WsT.gutter),
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
        Expanded(child: Text(a, style: T.label(Grey.g56))),
        Text(b, style: T.value(Grey.g91).copyWith(fontSize: T.px(10.5))),
      ],
    );
    return ColoredBox(
      color: WsT.card,
      child: ListView(
        padding: EdgeInsets.only(top: Shape.s(7), bottom: WsT.inset),
        children: [
          if (camera case final id?) LayerCards(layer: id, only: const ['Camera Options']),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: WsT.inset),
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
    final slabs = _slabsOf(WsScope.of(context, {WsAspect.document}));
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
            supportedDevices: wsPressing,
            behavior: HitTestBehavior.opaque,
            onTapUp: (e) {
              final id = hit(e.localPosition);
              if (id == null) return;
              widget.onFocus(slabs.firstWhere((s) => s.id == id).z, id); // (focus on that thing, where it is)
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
            // (the cone's edge, pulled across, opens or closes the view: the lens's own length, Transform's manner)
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

/// Comp space (x across, z away from the camera) to the diagram's pixels.
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
    final lab = T.value(Grey.g56).copyWith(fontSize: T.px(9.5));
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
    // (a knob on the cone's edge: pulled across, it opens or closes the view)
    final knobZ = _zMax * .45, knob = m.at(knobZ * math.tan(half), knobZ);
    c.drawCircle(knob, 6, Paint()..color = WsT.toneCamera);
    c.drawCircle(
      knob,
      6,
      Paint()
        ..color = WsT.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    c.restore();
    // The focus line and its tag.
    final y = m.at(0, focus).dy;
    final acc = Paint()
      ..color = WsT.accent
      ..strokeWidth = hot ? 2 : 1.5;
    for (var x = 30.0; x < s.width - 50; x += 7) {
      c.drawLine(Offset(x, y), Offset(math.min(x + 4, s.width - 50), y), acc);
    }
    // Slabs: sharp ones in their full hue, soft ones sink toward the card.
    for (final sl in slabs) {
      final r = m.slab(sl.x, sl.z, sl.w), sharp = sl.z >= near && sl.z <= far, on = sl.id == target;
      final col = sharp ? sl.tone : Color.lerp(sl.tone, WsT.card, .55)!;
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
    // Names over their slabs, the focused one first; a name that would cover a slab, the tag or another name is left out.
    final taken = [for (final sl in slabs) m.slab(sl.x, sl.z, sl.w).inflate(1), Rect.fromLTWH(s.width - 48, y - 8, 42, 16)];
    for (final sl in [...slabs.where((e) => e.id == target), ...slabs.where((e) => e.id != target)]) {
      final r = m.slab(sl.x, sl.z, sl.w), sharp = sl.z >= near && sl.z <= far, on = sl.id == target;
      final np = TextPainter(
        text: TextSpan(
          text: sl.name,
          style: T.label(sharp ? Grey.g91 : Grey.g56).copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = Rect.fromLTWH(r.left, r.top - 2 - np.height, np.width, np.height);
      if (!taken.any((t) => t.overlaps(at))) {
        taken.add(at);
        np.paint(c, at.topLeft);
      }
      np.dispose();
    }
    final tag = '${focus.round()}';
    final tp = TextPainter(
      text: TextSpan(
        text: tag,
        style: T.value(WsT.onAccent).copyWith(fontSize: T.px(10), fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final tr = RRect.fromRectAndRadius(Rect.fromLTWH(s.width - 48, y - 8, 42, 16), Shape.r(WsT.chipRadius));
    c.drawRRect(tr, fill..color = WsT.accent);
    tp.paint(c, tr.center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
    // The camera body at the cone's tip.
    final e = m.eye;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: e + const Offset(0, 9), width: Shape.z(18), height: Shape.z(12)), Shape.r(3)),
      fill..color = WsT.toneCamera,
    );
    c.drawPath(
      Path()
        ..moveTo(e.dx - 5, e.dy + 3)
        ..lineTo(e.dx, e.dy - 3)
        ..lineTo(e.dx + 5, e.dy + 3)
        ..close(),
      fill,
    );
    c.drawCircle(e + const Offset(0, 9), 2.5, Paint()..color = WsT.onAccent);
    toolText(c, 'CAM', e + const Offset(14, 9), T.micro(Grey.g63).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1), ay: .5);
  }

  @override
  bool shouldRepaint(_DepthPainter o) =>
      o.focal != focal || o.focus != focus || o.near != near || o.far != far || o.target != target || o.hot != hot || o.slabs.length != slabs.length;
}
