// Interactive visual editors for VST custom panels:
// `ui.curve` (multi-point FabFilter/EQ curve), `ui.gradient` (multi-stop color bar),
// and `ui.picker` (Live2D / Rigify character body picker with draggable control pins).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/script_files.dart' show readRelativeBytes;
import 'package:motolii/widgets/custom_ui/panel_style.dart';
import 'package:motolii/widgets/media.dart' show Draw;

/// One control point on `ui.curve`.
typedef CurvePoint = ({double x, double y, String label});

/// One color stop on `ui.gradient`.
typedef GradientStop = ({double pos, String color});

/// One interactive pin on `ui.picker`.
typedef PickerPin = ({
  String id,
  String label,
  double x,
  double y,
  String color,
  bool active,
});

/// Multi-point smooth spline curve editor (`ui.curve`) with draggable nodes.
class PanelCurveEditor extends StatefulWidget {
  const PanelCurveEditor({
    required this.points,
    required this.height,
    required this.onChanged,
    this.curveKey,
    this.label = '',
    this.color = '',
    this.grid = true,
    this.framed = true,
    this.style,
    super.key,
  });

  final Key? curveKey;
  final List<CurvePoint> points;
  final double height;
  final String label;
  final String color;
  final bool grid;
  final bool framed;
  final PanelStyle? style;
  final void Function(
    int index,
    double x,
    double y,
    List<Map<String, Object>> nextPoints,
    String phase, {
    bool live,
  })
  onChanged;

  @override
  State<PanelCurveEditor> createState() => _PanelCurveEditorState();
}

class _PanelCurveEditorState extends State<PanelCurveEditor> {
  int _dragIndex = -1;
  List<CurvePoint>? _livePoints;

  List<CurvePoint> get _pts => _livePoints ?? widget.points;

  int _nearest(Offset local, Size s) {
    final pts = _pts;
    var best = -1;
    var bestDist = 28.0;
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].x * s.width, (1.0 - pts[i].y) * s.height);
      final d = (p - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  List<Map<String, Object>> _asMaps(List<CurvePoint> pts) => [
    for (final p in pts) {'x': p.x, 'y': p.y, 'label': p.label},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final h = Shape.z(widget.height);
    final accentCol =
        resolvePanelColor(widget.color) ??
        resolvePanelColor(st?.accent ?? '') ??
        theme.accent ??
        Accent.fill;
    final bgCol =
        resolvePanelColor(st?.bg ?? '') ??
        theme.controlBg ??
        InspectorSkin.well;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? theme.radius ?? 6.0;
    final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, h);
            final paint = CustomPaint(
              size: size,
              painter: Draw(
                (c, s) => _paintCurve(
                  c,
                  s,
                  pts: _pts,
                  dragIndex: _dragIndex,
                  accent: accentCol,
                  gridCol: borderCol,
                  showGrid: widget.grid,
                ),
                (_pts, _dragIndex, accentCol, borderCol, widget.grid),
              ),
            );
            final surface = widget.framed
                ? Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(rad),
                      border: bw > 0
                          ? Border.all(color: borderCol, width: bw)
                          : null,
                      boxShadow: st?.shadow == null
                          ? null
                          : [st!.shadow!.toBoxShadow()],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(math.max(0, rad - 1)),
                      child: paint,
                    ),
                  )
                : SizedBox(height: h, child: paint);
            return GestureDetector(
              key: widget.curveKey,
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                final idx = _nearest(d.localPosition, size);
                if (idx < 0) return;
                _dragIndex = idx;
                _livePoints = List<CurvePoint>.of(widget.points);
                setState(() {});
                final p = _livePoints![idx];
                widget.onChanged(
                  idx,
                  p.x,
                  p.y,
                  _asMaps(_livePoints!),
                  'down',
                  live: true,
                );
              },
              onPanUpdate: (d) {
                if (_dragIndex < 0 || _livePoints == null) return;
                final nx = (d.localPosition.dx / math.max(1.0, size.width))
                    .clamp(0.0, 1.0);
                final ny =
                    (1.0 - (d.localPosition.dy / math.max(1.0, size.height)))
                        .clamp(0.0, 1.0);
                final old = _livePoints![_dragIndex];
                _livePoints![_dragIndex] = (x: nx, y: ny, label: old.label);
                setState(() {});
                widget.onChanged(
                  _dragIndex,
                  nx,
                  ny,
                  _asMaps(_livePoints!),
                  'drag',
                  live: true,
                );
              },
              onPanEnd: (_) {
                if (_dragIndex >= 0 && _livePoints != null) {
                  final p = _livePoints![_dragIndex];
                  final idx = _dragIndex;
                  final out = _asMaps(_livePoints!);
                  setState(() {
                    _dragIndex = -1;
                    _livePoints = null;
                  });
                  widget.onChanged(idx, p.x, p.y, out, 'up');
                }
              },
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _paintCurve(
  Canvas c,
  Size s, {
  required List<CurvePoint> pts,
  required int dragIndex,
  required Color accent,
  required Color gridCol,
  required bool showGrid,
}) {
  if (showGrid) {
    final gp = Paint()
      ..color = gridCol.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 4; i++) {
      final x = s.width * (i / 4);
      final y = s.height * (i / 4);
      c.drawLine(Offset(x, 0), Offset(x, s.height), gp);
      c.drawLine(Offset(0, y), Offset(s.width, y), gp);
    }
  }
  if (pts.isEmpty) return;

  final sorted = List<CurvePoint>.of(pts)..sort((a, b) => a.x.compareTo(b.x));
  final offs = [
    for (final p in sorted) Offset(p.x * s.width, (1.0 - p.y) * s.height),
  ];

  // Smooth Catmull-Rom cubic path
  final path = Path()..moveTo(offs.first.dx, offs.first.dy);
  for (var i = 0; i < offs.length - 1; i++) {
    final p0 = i > 0 ? offs[i - 1] : offs[i];
    final p1 = offs[i];
    final p2 = offs[i + 1];
    final p3 = i + 2 < offs.length ? offs[i + 2] : p2;
    final c1 = p1 + (p2 - p0) * (1 / 6);
    final c2 = p2 - (p3 - p1) * (1 / 6);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }

  final fill = Path.from(path)
    ..lineTo(offs.last.dx, s.height)
    ..lineTo(offs.first.dx, s.height)
    ..close();
  c.drawPath(
    fill,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.34),
          accent.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & s),
  );
  // Subtle glow + crisp curve line
  c.drawPath(
    path,
    Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round,
  );
  c.drawPath(
    path,
    Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round,
  );

  for (var i = 0; i < pts.length; i++) {
    final p = Offset(pts[i].x * s.width, (1.0 - pts[i].y) * s.height);
    final hot = i == dragIndex;
    c.drawCircle(
      p,
      hot ? 7.5 : 5.5,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
    c.drawCircle(p, hot ? 4.8 : 3.8, Paint()..color = accent);
    c.drawCircle(
      p,
      hot ? 4.8 : 3.8,
      Paint()
        ..color = DarkGrey.g100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}

/// Interactive multi-stop color gradient bar (`ui.gradient`) with draggable stop handles.
class PanelGradientBar extends StatefulWidget {
  const PanelGradientBar({
    required this.stops,
    required this.onChanged,
    this.gradKey,
    this.label = '',
    this.height = 28,
    this.style,
    super.key,
  });

  final Key? gradKey;
  final List<GradientStop> stops;
  final String label;
  final double height;
  final PanelStyle? style;
  final void Function(
    int index,
    double pos,
    String color,
    List<Map<String, Object>> nextStops,
    String phase, {
    bool live,
  })
  onChanged;

  @override
  State<PanelGradientBar> createState() => _PanelGradientBarState();
}

class _PanelGradientBarState extends State<PanelGradientBar> {
  int _dragIndex = -1;
  List<GradientStop>? _liveStops;

  List<GradientStop> get _stops => _liveStops ?? widget.stops;

  int _nearest(double localX, double width) {
    final st = _stops;
    var best = -1;
    var bestD = 24.0;
    for (var i = 0; i < st.length; i++) {
      final d = (st[i].pos * width - localX).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  List<Map<String, Object>> _asMaps(List<GradientStop> s) => [
    for (final e in s) {'pos': e.pos, 'color': e.color},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final barH = widget.height.clamp(16.0, 48.0);
    final totalH = barH + 12.0;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? 5.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return GestureDetector(
              key: widget.gradKey,
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                final idx = _nearest(d.localPosition.dx, w);
                if (idx < 0) return;
                _dragIndex = idx;
                _liveStops = List<GradientStop>.of(widget.stops);
                setState(() {});
                final cur = _liveStops![idx];
                widget.onChanged(
                  idx,
                  cur.pos,
                  cur.color,
                  _asMaps(_liveStops!),
                  'down',
                  live: true,
                );
              },
              onPanUpdate: (d) {
                if (_dragIndex < 0 || _liveStops == null) return;
                final pos = (d.localPosition.dx / math.max(1.0, w)).clamp(
                  0.0,
                  1.0,
                );
                final cur = _liveStops![_dragIndex];
                _liveStops![_dragIndex] = (pos: pos, color: cur.color);
                setState(() {});
                widget.onChanged(
                  _dragIndex,
                  pos,
                  cur.color,
                  _asMaps(_liveStops!),
                  'drag',
                  live: true,
                );
              },
              onPanEnd: (_) {
                if (_dragIndex >= 0 && _liveStops != null) {
                  final idx = _dragIndex;
                  final cur = _liveStops![idx];
                  final out = _asMaps(_liveStops!);
                  setState(() {
                    _dragIndex = -1;
                    _liveStops = null;
                  });
                  widget.onChanged(idx, cur.pos, cur.color, out, 'up');
                }
              },
              child: SizedBox(
                height: totalH,
                child: CustomPaint(
                  painter: Draw(
                    (c, s) => _paintGradientBar(
                      c,
                      s,
                      stops: _stops,
                      barH: barH,
                      dragIndex: _dragIndex,
                      border: borderCol,
                      rad: rad,
                    ),
                    (_stops, _dragIndex, borderCol, rad),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

void _paintGradientBar(
  Canvas c,
  Size s, {
  required List<GradientStop> stops,
  required double barH,
  required int dragIndex,
  required Color border,
  required double rad,
}) {
  final sorted = List<GradientStop>.of(stops)
    ..sort((a, b) => a.pos.compareTo(b.pos));
  final cols = [
    for (final e in sorted) resolvePanelColor(e.color) ?? Accent.fill,
  ];
  final pos = [for (final e in sorted) e.pos.clamp(0.0, 1.0)];
  final barRect = Rect.fromLTWH(0, 0, s.width, barH);
  final rr = RRect.fromRectAndRadius(barRect, Radius.circular(rad));

  if (cols.length >= 2) {
    c.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          colors: cols,
          stops: pos,
        ).createShader(barRect),
    );
  } else {
    c.drawRRect(rr, Paint()..color = cols.isEmpty ? Accent.fill : cols.first);
  }
  c.drawRRect(
    rr,
    Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );

  for (var i = 0; i < stops.length; i++) {
    final x = stops[i].pos.clamp(0.0, 1.0) * s.width;
    final col = resolvePanelColor(stops[i].color) ?? Accent.fill;
    final hot = i == dragIndex;
    final tri = Path()
      ..moveTo(x, barH + 1)
      ..lineTo(x - 5, barH + 10)
      ..lineTo(x + 5, barH + 10)
      ..close();
    c.drawPath(tri, Paint()..color = col);
    c.drawPath(
      tri,
      Paint()
        ..color = hot ? DarkGrey.g100 : border
        ..style = PaintingStyle.stroke
        ..strokeWidth = hot ? 1.8 : 1.1,
    );
  }
}

/// Character Rig / Live2D / Rigify body picker (`ui.picker`) with draggable control pins.
class PanelRigPicker extends StatefulWidget {
  const PanelRigPicker({
    required this.pins,
    required this.height,
    required this.onPin,
    this.pickerKey,
    this.label = '',
    this.svg = '',
    this.src = '',
    this.baseFile = '',
    this.framed = true,
    this.style,
    super.key,
  });

  final Key? pickerKey;
  final List<PickerPin> pins;
  final double height;
  final String label;
  final String svg;
  final String src;
  final String baseFile;
  final bool framed;
  final PanelStyle? style;
  final void Function(
    String pinId,
    double x,
    double y,
    String phase, {
    bool live,
  })
  onPin;

  @override
  State<PanelRigPicker> createState() => _PanelRigPickerState();
}

class _PanelRigPickerState extends State<PanelRigPicker> {
  int _dragIndex = -1;
  double? _dx;
  double? _dy;

  int _hitPin(Offset local, Size s) {
    var best = -1;
    var bestDist = 24.0;
    for (var i = 0; i < widget.pins.length; i++) {
      final p = Offset(widget.pins[i].x * s.width, widget.pins[i].y * s.height);
      final d = (p - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  Uint8List? _decodeBg() {
    final trimmed = widget.src.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:image/')) {
      final comma = trimmed.indexOf(',');
      if (comma < 0) return null;
      try {
        return base64Decode(trimmed.substring(comma + 1));
      } catch (_) {
        return null;
      }
    }
    return readRelativeBytes(widget.baseFile, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final h = Shape.z(widget.height);
    final bgCol =
        resolvePanelColor(st?.bg ?? '') ??
        theme.controlBg ??
        InspectorSkin.well;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? theme.radius ?? 8.0;
    final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;
    final imgBytes = _decodeBg();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, h);
            final stack = Stack(
              fit: StackFit.expand,
              children: [
                if (imgBytes != null)
                  Image.memory(
                    imgBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                else if (widget.svg.contains('<svg'))
                  SvgPicture.string(widget.svg, fit: BoxFit.contain),
                CustomPaint(
                  size: size,
                  painter: Draw(
                    (c, s) => _paintRigPins(
                      c,
                      s,
                      pins: widget.pins,
                      dragIndex: _dragIndex,
                      dx: _dx,
                      dy: _dy,
                      defaultAccent: theme.accent ?? Accent.fill,
                    ),
                    (widget.pins, _dragIndex, _dx, _dy, theme.accent),
                  ),
                ),
              ],
            );
            final surface = widget.framed
                ? Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(rad),
                      border: bw > 0
                          ? Border.all(color: borderCol, width: bw)
                          : null,
                      boxShadow: st?.shadow == null
                          ? null
                          : [st!.shadow!.toBoxShadow()],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(math.max(0, rad - 1)),
                      child: stack,
                    ),
                  )
                : SizedBox(height: h, child: stack);

            return GestureDetector(
              key: widget.pickerKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final idx = _hitPin(d.localPosition, size);
                if (idx < 0) return;
                final p = widget.pins[idx];
                widget.onPin(p.id, p.x, p.y, 'down');
              },
              onPanStart: (d) {
                final idx = _hitPin(d.localPosition, size);
                if (idx < 0) return;
                final p = widget.pins[idx];
                setState(() {
                  _dragIndex = idx;
                  _dx = p.x;
                  _dy = p.y;
                });
                widget.onPin(p.id, p.x, p.y, 'down', live: true);
              },
              onPanUpdate: (d) {
                if (_dragIndex < 0) return;
                final nx = (d.localPosition.dx / math.max(1.0, size.width))
                    .clamp(0.0, 1.0);
                final ny = (d.localPosition.dy / math.max(1.0, size.height))
                    .clamp(0.0, 1.0);
                setState(() {
                  _dx = nx;
                  _dy = ny;
                });
                widget.onPin(
                  widget.pins[_dragIndex].id,
                  nx,
                  ny,
                  'drag',
                  live: true,
                );
              },
              onPanEnd: (_) {
                if (_dragIndex >= 0) {
                  final id = widget.pins[_dragIndex].id;
                  final fx = _dx ?? widget.pins[_dragIndex].x;
                  final fy = _dy ?? widget.pins[_dragIndex].y;
                  setState(() {
                    _dragIndex = -1;
                    _dx = null;
                    _dy = null;
                  });
                  widget.onPin(id, fx, fy, 'up');
                }
              },
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _paintRigPins(
  Canvas c,
  Size s, {
  required List<PickerPin> pins,
  required int dragIndex,
  required double? dx,
  required double? dy,
  required Color defaultAccent,
}) {
  for (var i = 0; i < pins.length; i++) {
    final pin = pins[i];
    final hot = i == dragIndex;
    final px = (hot && dx != null ? dx : pin.x) * s.width;
    final py = (hot && dy != null ? dy : pin.y) * s.height;
    final center = Offset(px, py);
    final col = resolvePanelColor(pin.color) ?? defaultAccent;

    // Halo + crisp control ring
    c.drawCircle(
      center,
      (hot || pin.active) ? 10.5 : 8.0,
      Paint()..color = col.withValues(alpha: (hot || pin.active) ? 0.30 : 0.18),
    );
    c.drawCircle(center, (hot || pin.active) ? 5.8 : 4.6, Paint()..color = col);
    c.drawCircle(
      center,
      (hot || pin.active) ? 5.8 : 4.6,
      Paint()
        ..color = DarkGrey.g100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    if (pin.label.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: pin.label,
          style: TextStyles.micro(DarkGrey.g100)
              .copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          px + 8,
          py - tp.height * 0.5 - 2,
          tp.width + 8,
          tp.height + 4,
        ),
        const Radius.circular(4),
      );
      c.drawRRect(pill, Paint()..color = DarkGrey.g00.withValues(alpha: 0.72));
      tp.paint(c, Offset(px + 12, py - tp.height * 0.5));
    }
  }
}
