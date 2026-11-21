// Live swatch instrument for the Fill card: previews solid/gradient/media fill
// and every stacked stroke together. When a gradient is active, dragging the
// angle handle directly edits v_gradient_angle; tapping opens the Colors shelf.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/link_line.dart' show LinkTo;
import 'package:motolii/inspector/controls/parameter_grid.dart'
    show hexControls;
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart' show drawWell;

/// One rendered stroke layer in the preview (color and width in px).
typedef FillPreviewStroke = ({Color color, double width});

/// Parses space-separated hex colors (e.g. `#59C3E8 #D64B7A` or `59C3E8 D64B7A`)
/// from a layer's `v_fill` string.
List<Color> parseFillColors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final out = <Color>[];
  for (final tok in raw.trim().split(RegExp(r'\s+'))) {
    // Strip optional CSS-style stop position (e.g. "ff0000@0.5").
    final base = tok.split('@').first;
    final norm = base.startsWith('#') ? base : '#$base';
    if (hexControls(norm) case final c?) out.add(c);
  }
  return out;
}

class FillPreview extends StatefulWidget {
  const FillPreview({
    required this.colors,
    required this.media,
    required this.hasGradient,
    required this.radial,
    required this.angle,
    required this.scale,
    required this.spread,
    required this.strokes,
    required this.angleParam,
    super.key,
  });

  final List<Color> colors;
  final String media;
  final bool hasGradient;
  final bool radial;
  final double angle;
  final double scale;
  final int spread;
  final List<FillPreviewStroke> strokes;
  final Parameter? angleParam;

  static double get height => Shape.z(56);

  @override
  State<FillPreview> createState() => _FillPreviewState();
}

class _FillPreviewState extends State<FillPreview> {
  bool _hoverHandle = false;
  bool _dragging = false;
  Offset? _down;

  bool get _canDragAngle =>
      widget.hasGradient && !widget.radial && widget.angleParam != null;

  (Offset center, Offset handle) _anglePoints(Size s) {
    final rect = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    final c = rect.center;
    final r = math.min(rect.width, rect.height) * 0.38;
    // Match engine convention (kinds.h): 0 deg = top to bottom, clockwise.
    final rad = widget.angle * math.pi / 180;
    final dir = Offset(-math.sin(rad), math.cos(rad));
    return (c, c + dir * r);
  }

  void _setAngleFrom(InspectorValues doc, Size s, Offset pos) {
    final p = widget.angleParam;
    if (p == null) return;
    final (c, _) = _anglePoints(s);
    final d = pos - c;
    if (d.distance < 3) return;
    final deg = math.atan2(-d.dx, d.dy) * 180 / math.pi;
    final snapped = (deg / 1).roundToDouble();
    doc.set('v_gradient_angle', p.typed(snapped));
  }

  void _openColors(InspectorValues doc) {
    doc.strings['route.at'] = 'v_fill';
    doc.str('route', LinkTo.colors.route);
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, FillPreview.height);
        final (_, handle) = _anglePoints(size);
        return MouseRegion(
          cursor: _dragging
              ? SystemMouseCursors.grabbing
              : (_hoverHandle
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.click),
          onHover: (e) {
            final near =
                _canDragAngle && (e.localPosition - handle).distance <= 14;
            if (near != _hoverHandle) setState(() => _hoverHandle = near);
          },
          onExit: (_) {
            if (_hoverHandle) setState(() => _hoverHandle = false);
          },
          child: Listener(
            onPointerDown: (e) {
              if (e.buttons != kPrimaryButton) return;
              _down = e.localPosition;
              if (_canDragAngle && (e.localPosition - handle).distance <= 16) {
                doc.beginGesture();
                setState(() => _dragging = true);
              }
            },
            onPointerMove: (e) {
              if (!_dragging) return;
              _setAngleFrom(doc, size, e.localPosition);
            },
            onPointerUp: (e) {
              final d = _down;
              _down = null;
              if (_dragging) {
                doc.endGesture();
                setState(() => _dragging = false);
                return;
              }
              if (d != null && (e.localPosition - d).distance < 5) {
                _openColors(doc);
              }
            },
            onPointerCancel: (_) {
              _down = null;
              if (_dragging) {
                doc.endGesture();
                setState(() => _dragging = false);
              }
            },
            child: CustomPaint(
              key: const ValueKey('fill-preview'),
              size: size,
              painter: _FillPreviewPainter(
                colors: widget.colors,
                media: widget.media,
                hasGradient: widget.hasGradient,
                radial: widget.radial,
                angle: widget.angle,
                scale: widget.scale,
                spread: widget.spread,
                strokes: widget.strokes,
                showAngle: _canDragAngle,
                lit: _hoverHandle || _dragging,
                anglePoints: _anglePoints(size),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FillPreviewPainter extends CustomPainter {
  const _FillPreviewPainter({
    required this.colors,
    required this.media,
    required this.hasGradient,
    required this.radial,
    required this.angle,
    required this.scale,
    required this.spread,
    required this.strokes,
    required this.showAngle,
    required this.lit,
    required this.anglePoints,
  });

  final List<Color> colors;
  final String media;
  final bool hasGradient;
  final bool radial;
  final double angle;
  final double scale;
  final int spread;
  final List<FillPreviewStroke> strokes;
  final bool showAngle;
  final bool lit;
  final (Offset, Offset) anglePoints;

  TileMode get _tileMode => switch (spread) {
    1 => TileMode.mirror,
    2 => TileMode.repeated,
    _ => TileMode.clamp,
  };

  @override
  void paint(Canvas c, Size s) {
    drawWell(c, s);
    final plate = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    final rrect = RRect.fromRectAndRadius(plate, const Radius.circular(6));

    // Checkerboard under transparent / empty fills.
    c.save();
    c.clipRRect(rrect);
    const cell = 6.0;
    final dark = Paint()..color = Grey.g10;
    final light = Paint()..color = Grey.g15;
    c.drawRect(plate, dark);
    for (var y = plate.top, row = 0; y < plate.bottom; y += cell, row++) {
      for (var x = plate.left, col = 0; x < plate.right; x += cell, col++) {
        if ((row + col).isEven) {
          c.drawRect(Rect.fromLTWH(x, y, cell, cell), light);
        }
      }
    }

    // Fill body: media, gradient, or solid.
    if (media.isNotEmpty) {
      c.drawRect(plate, Paint()..color = Grey.g20);
      final name = media.split('/').last;
      final tp = TextPainter(
        text: TextSpan(text: name, style: TextStyles.micro(Grey.g91)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: plate.width - 16);
      tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
    } else if (colors.length >= 2 && hasGradient) {
      final Shader shader;
      final stretch = scale.clamp(0.15, 4.0);
      if (radial) {
        final radius = math.max(plate.width, plate.height) * 0.45 * stretch;
        shader = ui.Gradient.radial(
          plate.center,
          radius,
          colors,
          null,
          _tileMode,
        );
      } else {
        // Project along the true pixel direction matching the angle handle so
        // the ramp orientation stays accurate in a wide rectangular swatch.
        final rad = angle * math.pi / 180;
        final dir = Offset(-math.sin(rad), math.cos(rad));
        final halfSpan =
            (dir.dx.abs() * plate.width + dir.dy.abs() * plate.height) *
            0.5 *
            stretch;
        shader = ui.Gradient.linear(
          plate.center - dir * halfSpan,
          plate.center + dir * halfSpan,
          colors,
          null,
          _tileMode,
        );
      }
      c.drawRect(plate, Paint()..shader = shader);
    } else if (colors.isNotEmpty) {
      c.drawRect(plate, Paint()..color = colors.first);
    }
    c.restore();

    // Stacked strokes drawn as nested outlines from outermost to innermost so
    // multiple outlines read clearly at a glance.
    final active = [
      for (final st in strokes)
        if (st.width > 0) st,
    ];
    if (active.isEmpty) {
      c.drawRRect(
        rrect,
        Paint()
          ..color = lit ? Accent.fill : Grey.g26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    } else {
      var inset = 0.0;
      for (final st in active.reversed) {
        final sw = (st.width * 0.45).clamp(1.2, 4.5);
        final rect = plate.deflate(inset + sw / 2);
        if (rect.width <= 4 || rect.height <= 4) break;
        final radius = math.max(1.5, 6.0 - inset);
        c.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          Paint()
            ..color = st.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw,
        );
        inset += sw;
      }
    }

    // Direct-manipulation angle handle for linear gradients.
    if (showAngle) {
      final (center, handle) = anglePoints;
      final ink = lit ? Accent.fill : Grey.g95;
      c.drawLine(
        center,
        handle,
        Paint()
          ..color = Grey.g07.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      c.drawLine(
        center,
        handle,
        Paint()
          ..color = ink
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(
        center,
        2.6,
        Paint()..color = Grey.g07.withValues(alpha: 0.7),
      );
      c.drawCircle(center, 1.8, Paint()..color = ink);
      c.drawCircle(
        handle,
        lit ? 5.5 : 4.5,
        Paint()..color = Grey.g07.withValues(alpha: 0.75),
      );
      c.drawCircle(handle, lit ? 4.2 : 3.2, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(_FillPreviewPainter o) =>
      o.media != media ||
      o.hasGradient != hasGradient ||
      o.radial != radial ||
      o.angle != angle ||
      o.scale != scale ||
      o.spread != spread ||
      o.showAngle != showAngle ||
      o.lit != lit ||
      o.colors.length != colors.length ||
      o.strokes.length != strokes.length ||
      !_sameColors(o.colors, colors) ||
      !_sameStrokes(o.strokes, strokes);
}

bool _sameColors(List<Color> a, List<Color> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameStrokes(List<FillPreviewStroke> a, List<FillPreviewStroke> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
