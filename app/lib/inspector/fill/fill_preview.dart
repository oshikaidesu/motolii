// Live swatch instrument for the Fill card: previews solid/gradient/media fill
// and every stacked stroke together. Discrete gradient modes (Linear/Radial and
// Pad/Reflect/Repeat) live inside the well as compact glass pills, while the
// handle edits angle (linear) or stretch (radial) directly.
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
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/paint_helpers.dart' show drawWell;
import 'package:motolii/widgets/tip.dart' show Tip;

/// One rendered stroke layer in the preview.
/// `align`: -1 inside, 0 center (both), 1 outside.
typedef FillPreviewStroke = ({List<Color> colors, double width, int align});

/// Parses space-separated hex colors (e.g. `#59C3E8 #D64B7A` or `59C3E8 D64B7A`)
/// from a layer's `v_fill` string.
List<Color> parseFillColors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final out = <Color>[];
  for (final tok in raw.trim().split(RegExp(r'\s+'))) {
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
    required this.gradIndex,
    required this.gradOptions,
    required this.radial,
    required this.angle,
    required this.scale,
    required this.spreadIndex,
    required this.spreadOptions,
    required this.strokes,
    required this.angleParam,
    required this.scaleParam,
    super.key,
  });

  final List<Color> colors;
  final String media;
  final bool hasGradient;
  final int gradIndex;
  final List<String> gradOptions;
  final bool radial;
  final double angle;
  final double scale;
  final int spreadIndex;
  final List<String> spreadOptions;
  final List<FillPreviewStroke> strokes;
  final Parameter? angleParam;
  final Parameter? scaleParam;

  static double get height => Shape.z(64);

  @override
  State<FillPreview> createState() => _FillPreviewState();
}

class _FillPreviewState extends State<FillPreview> {
  bool _hoverHandle = false;
  bool _dragging = false;
  Offset? _down;

  bool get _canDragAngle =>
      widget.hasGradient && !widget.radial && widget.angleParam != null;
  bool get _canDragRadius =>
      widget.hasGradient && widget.radial && widget.scaleParam != null;
  bool get _canDragHandle => _canDragAngle || _canDragRadius;

  (Offset center, Offset handle) _handlePoints(Size s) {
    final rect = Rect.fromLTWH(11, 11, s.width - 22, s.height - 22);
    final c = rect.center;
    if (widget.radial) {
      final maxR = rect.width * 0.34;
      final r = (widget.scale.clamp(0.1, 4.0) / 4.0) * maxR;
      return (c, c + Offset(math.max(10.0, r), 0));
    }
    final r = math.min(rect.width, rect.height) * 0.36;
    // Match engine convention (kinds.h): 0 deg = top to bottom, clockwise.
    final rad = widget.angle * math.pi / 180;
    final dir = Offset(-math.sin(rad), math.cos(rad));
    return (c, c + dir * r);
  }

  void _dragTo(InspectorValues doc, Size s, Offset pos) {
    final (c, _) = _handlePoints(s);
    final d = pos - c;
    if (_canDragAngle) {
      if (d.distance < 3) return;
      final deg = (math.atan2(-d.dx, d.dy) * 180 / math.pi).roundToDouble();
      doc.set('v_gradient_angle', widget.angleParam!.typed(deg));
    } else if (_canDragRadius) {
      final rect = Rect.fromLTWH(11, 11, s.width - 22, s.height - 22);
      final maxR = rect.width * 0.34;
      final next = (d.distance / maxR * 4.0).clamp(0.1, 4.0);
      doc.set('v_gradient_scale', widget.scaleParam!.typed(next));
    }
  }

  void _cycleGradientMode(InspectorValues doc) {
    final opts = widget.gradOptions;
    if (opts.length < 2) return;
    // Skip any "none" entry when toggling between gradient types while active.
    final activeIndices = [
      for (var i = 0; i < opts.length; i++)
        if (opts[i].toLowerCase() != 'none') i,
    ];
    final pool = activeIndices.length >= 2
        ? activeIndices
        : [for (var i = 0; i < opts.length; i++) i];
    final pos = pool.indexOf(widget.gradIndex);
    final next = pool[(pos + 1) % pool.length];
    doc
      ..beginGesture()
      ..set('v_gradient', next.toDouble())
      ..endGesture();
  }

  void _cycleSpread(InspectorValues doc) {
    final opts = widget.spreadOptions;
    if (opts.length < 2) return;
    final next = (widget.spreadIndex + 1) % opts.length;
    doc
      ..beginGesture()
      ..set('v_gradient_spread', next.toDouble())
      ..endGesture();
  }

  void _openColors(InspectorValues doc) {
    doc.strings['route.at'] = 'v_fill';
    doc.str('route', LinkTo.colors.route);
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final modeLabel = _cap(
      widget.gradOptions.elementAtOrNull(widget.gradIndex) ??
          (widget.radial ? 'radial' : 'linear'),
    );
    final spreadLabel = _cap(
      widget.spreadOptions.elementAtOrNull(widget.spreadIndex) ?? 'pad',
    );

    return SizedBox(
      height: FillPreview.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, FillPreview.height);
          final (_, handle) = _handlePoints(size);
          return Stack(
            children: [
              MouseRegion(
                cursor: _dragging
                    ? SystemMouseCursors.grabbing
                    : (_hoverHandle
                          ? SystemMouseCursors.grab
                          : SystemMouseCursors.click),
                onHover: (e) {
                  final near =
                      _canDragHandle &&
                      (e.localPosition - handle).distance <= 14;
                  if (near != _hoverHandle) setState(() => _hoverHandle = near);
                },
                onExit: (_) {
                  if (_hoverHandle) setState(() => _hoverHandle = false);
                },
                child: Listener(
                  onPointerDown: (e) {
                    if (e.buttons != kPrimaryButton) return;
                    _down = e.localPosition;
                    if (_canDragHandle &&
                        (e.localPosition - handle).distance <= 16) {
                      doc.beginGesture();
                      setState(() => _dragging = true);
                    }
                  },
                  onPointerMove: (e) {
                    if (!_dragging) return;
                    _dragTo(doc, size, e.localPosition);
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
                      spread: widget.spreadIndex,
                      strokes: widget.strokes,
                      showHandle: _canDragHandle,
                      lit: _hoverHandle || _dragging,
                      handlePoints: _handlePoints(size),
                    ),
                  ),
                ),
              ),
              if (widget.hasGradient && widget.gradOptions.length >= 2)
                Positioned(
                  left: 16,
                  bottom: 15,
                  child: _maybeTip(
                    context,
                    'Gradient type ($modeLabel)',
                    _WellPill(
                      key: const ValueKey('fill-mode-pill'),
                      label: modeLabel,
                      icon: (c, s, col) =>
                          _drawModeGlyph(c, s, col, radial: widget.radial),
                      onTap: () => _cycleGradientMode(doc),
                    ),
                  ),
                ),
              if (widget.hasGradient && widget.spreadOptions.length >= 2)
                Positioned(
                  right: 16,
                  bottom: 15,
                  child: _maybeTip(
                    context,
                    'Past end ($spreadLabel)',
                    _WellPill(
                      key: const ValueKey('fill-spread-pill'),
                      label: spreadLabel,
                      icon: (c, s, col) => _drawSpreadGlyph(
                        c,
                        s,
                        col,
                        spread: widget.spreadIndex,
                      ),
                      onTap: () => _cycleSpread(doc),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Widget _maybeTip(BuildContext context, String text, Widget child) =>
    Overlay.maybeOf(context) != null ? Tip(text, child: child) : child;

/// Compact frosted dark pill anchored inside the preview well for discrete
/// non-keyframed modes.
class _WellPill extends StatelessWidget {
  const _WellPill({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final void Function(Canvas, Size, Color) icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) => Container(
      height: Shape.z(20),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
      decoration: BoxDecoration(
        color: Grey.g07.withValues(alpha: hot ? 0.90 : 0.72),
        borderRadius: Shape.round(4),
        border: Border.all(
          color: (hot ? Grey.g95 : Grey.g91).withValues(
            alpha: hot ? 0.36 : 0.16,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(10, 10),
            painter: Draw((c, s) => icon(c, s, hot ? Grey.g95 : Grey.g76), (
              hot,
              label,
            )),
          ),
          SizedBox(width: Shape.s(4)),
          Text(label, style: TextStyles.micro(hot ? Grey.g95 : Grey.g91)),
        ],
      ),
    ),
  );
}

void _drawModeGlyph(Canvas c, Size s, Color col, {required bool radial}) {
  final p = Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  if (radial) {
    final center = s.center(Offset.zero);
    c
      ..drawCircle(center, s.width * 0.4, p)
      ..drawCircle(center, 1.5, Paint()..color = col);
  } else {
    c
      ..drawLine(Offset(1.5, s.height - 1.5), Offset(s.width - 1.5, 1.5), p)
      ..drawCircle(Offset(1.5, s.height - 1.5), 1.3, Paint()..color = col)
      ..drawCircle(Offset(s.width - 1.5, 1.5), 1.3, Paint()..color = col);
  }
}

void _drawSpreadGlyph(Canvas c, Size s, Color col, {required int spread}) {
  final p = Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final yMid = s.height * 0.5;
  switch (spread) {
    case 1: // Reflect: mirrored chevron
      c.drawPath(
        Path()
          ..moveTo(1, s.height - 2)
          ..lineTo(s.width * 0.5, 2)
          ..lineTo(s.width - 1, s.height - 2),
        p,
      );
    case 2: // Repeat: tiled parallel strokes
      c
        ..drawLine(Offset(2, s.height - 2), Offset(4.5, 2), p)
        ..drawLine(Offset(5.5, s.height - 2), Offset(8, 2), p);
    default: // Pad: clamped ends
      c
        ..drawLine(Offset(1.5, 2), Offset(1.5, s.height - 2), p)
        ..drawLine(Offset(1.5, yMid), Offset(s.width - 1.5, yMid), p)
        ..drawLine(
          Offset(s.width - 1.5, 2),
          Offset(s.width - 1.5, s.height - 2),
          p,
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
    required this.showHandle,
    required this.lit,
    required this.handlePoints,
  });

  final List<Color> colors;
  final String media;
  final bool hasGradient;
  final bool radial;
  final double angle;
  final double scale;
  final int spread;
  final List<FillPreviewStroke> strokes;
  final bool showHandle;
  final bool lit;
  final (Offset, Offset) handlePoints;

  TileMode get _tileMode => switch (spread) {
    1 => TileMode.mirror,
    2 => TileMode.repeated,
    _ => TileMode.clamp,
  };

  Shader _buildShader(Rect bounds, List<Color> cols) {
    final stretch = scale.clamp(0.15, 4.0);
    if (radial) {
      final radius = math.max(bounds.width, bounds.height) * 0.45 * stretch;
      return ui.Gradient.radial(bounds.center, radius, cols, null, _tileMode);
    }
    // True pixel-space direction matching the angle handle.
    final rad = angle * math.pi / 180;
    final dir = Offset(-math.sin(rad), math.cos(rad));
    final halfSpan =
        (dir.dx.abs() * bounds.width + dir.dy.abs() * bounds.height) *
        0.5 *
        stretch;
    return ui.Gradient.linear(
      bounds.center - dir * halfSpan,
      bounds.center + dir * halfSpan,
      cols,
      null,
      _tileMode,
    );
  }

  Paint _strokePaint(Rect rect, double sw, List<Color> cols) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    if (cols.length >= 2) {
      p.shader = _buildShader(rect.inflate(sw / 2), cols);
    } else {
      p.color = cols.firstOrNull ?? Grey.g91;
    }
    return p;
  }

  @override
  void paint(Canvas c, Size s) {
    drawWell(c, s);
    final plate = Rect.fromLTWH(11, 11, s.width - 22, s.height - 22);
    const baseRadius = 5.0;
    final rrect = RRect.fromRectAndRadius(
      plate,
      const Radius.circular(baseRadius),
    );

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
      c.drawRect(plate, Paint()..shader = _buildShader(plate, colors));
    } else if (colors.isNotEmpty) {
      c.drawRect(plate, Paint()..color = colors.first);
    }
    c.restore();

    // Stacked strokes drawn at their true alignment (outside / center / inside)
    // with solid or gradient stroke paint.
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
      var outOffset = 0.0;
      var inOffset = 0.0;
      for (final st in active) {
        final sw = (st.width * 0.45).clamp(1.4, 4.5);
        final Rect rect;
        final double radius;
        if (st.align > 0) {
          final reach = outOffset + sw / 2;
          if (reach > 8.5) continue;
          rect = plate.inflate(reach);
          radius = baseRadius + reach;
          outOffset += sw;
        } else if (st.align < 0) {
          final inset = inOffset + sw / 2;
          rect = plate.deflate(inset);
          if (rect.width <= 4 || rect.height <= 4) continue;
          radius = math.max(1.5, baseRadius - inset);
          inOffset += sw;
        } else {
          rect = plate;
          radius = baseRadius;
        }
        c.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          _strokePaint(rect, sw, st.colors),
        );
      }
    }

    // Direct-manipulation angle (linear) or radius (radial) handle.
    if (showHandle) {
      final (center, handle) = handlePoints;
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
      o.showHandle != showHandle ||
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
    if (a[i].width != b[i].width ||
        a[i].align != b[i].align ||
        a[i].colors.length != b[i].colors.length ||
        !_sameColors(a[i].colors, b[i].colors)) {
      return false;
    }
  }
  return true;
}
