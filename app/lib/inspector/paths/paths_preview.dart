// The shape preview on the Paths card: renders the engine's bent SVG outline
// (with a fallback polygon when absent) and hosts the discrete Fill rule
// (Nonzero / Even-odd) toggle directly inside the well.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

import 'package:motolii/inspector/controls/well_pill.dart'
    show WellPill, maybeTip;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/paint_helpers.dart' show drawWell;

class PathsPreview extends StatelessWidget {
  const PathsPreview({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
    this.height,
    this.compact = false,
    this.evenOdd,
    this.onToggleFillRule,
    super.key,
  });

  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;
  final double? height;
  final bool compact;
  final bool? evenOdd;
  final VoidCallback? onToggleFillRule;

  @override
  Widget build(BuildContext context) {
    final h = height ?? Shape.z(52);
    final isEvenOdd = evenOdd ?? false;
    final tipText = isEvenOdd ? 'Fill rule: Even-odd' : 'Fill rule: Nonzero';
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: CustomPaint(
              key: const ValueKey('paths-preview'),
              size: Size.fromHeight(h),
              painter: _PreviewPaint(
                round: round,
                points: points,
                inner: inner,
                shape: shape,
                svgPath: svgPath,
                evenOdd: isEvenOdd,
              ),
            ),
          ),
          if (evenOdd != null && onToggleFillRule != null)
            Positioned(
              right: compact ? 5 : 10,
              bottom: compact ? 5 : 8,
              child: maybeTip(
                context,
                tipText,
                compact
                    ? _CompactFillRuleBadge(
                        key: const ValueKey('paths-fill-rule'),
                        evenOdd: isEvenOdd,
                        onTap: onToggleFillRule!,
                      )
                    : WellPill(
                        key: const ValueKey('paths-fill-rule'),
                        label: isEvenOdd ? 'Even-odd' : 'Nonzero',
                        active: isEvenOdd,
                        icon: (c, s, col) =>
                            _drawFillRuleGlyph(c, s, col, evenOdd: isEvenOdd),
                        onTap: onToggleFillRule!,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactFillRuleBadge extends StatelessWidget {
  const _CompactFillRuleBadge({
    required this.evenOdd,
    required this.onTap,
    super.key,
  });

  final bool evenOdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) {
      final ink = evenOdd ? Accent.fill : (hot ? Grey.g95 : Grey.g76);
      final border = evenOdd
          ? Accent.fill.withValues(alpha: hot ? 0.75 : 0.55)
          : (hot ? Grey.g95 : Grey.g91).withValues(alpha: hot ? 0.36 : 0.18);
      return Container(
        width: Shape.z(18),
        height: Shape.z(18),
        decoration: BoxDecoration(
          color: Grey.g07.withValues(alpha: hot ? 0.90 : 0.74),
          borderRadius: Shape.round(4),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(10, 10),
          painter: Draw(
            (c, s) => _drawFillRuleGlyph(c, s, ink, evenOdd: evenOdd),
            (hot, evenOdd),
          ),
        ),
      );
    },
  );
}

void _drawFillRuleGlyph(Canvas c, Size s, Color col, {required bool evenOdd}) {
  final a = Rect.fromLTWH(0.8, 1.8, 6.0, 6.0);
  final b = Rect.fromLTWH(3.2, 2.8, 6.0, 6.0);
  final path = Path()
    ..fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero
    ..addRect(a)
    ..addRect(b);
  c
    ..drawPath(path, Paint()..color = col.withValues(alpha: 0.78))
    ..drawRect(
      a,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    )
    ..drawRect(
      b,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
}

class _PreviewPaint extends CustomPainter {
  const _PreviewPaint({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
    required this.evenOdd,
  });
  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;
  final bool evenOdd;

  Path? _parseSvg(double cx, double cy, double r) {
    final unit = Path();
    try {
      writeSvgPathDataToPath(svgPath, _IntoPath(unit));
    } catch (_) {
      return null;
    }
    final b = unit.getBounds();
    if (b.isEmpty) return null;
    final k = r * 2 / math.max(b.width, b.height);
    return unit.transform(
      Float64List.fromList([
        k,
        0,
        0,
        0,
        0,
        k,
        0,
        0,
        0,
        0,
        1,
        0,
        cx - b.center.dx * k,
        cy - b.center.dy * k,
        0,
        1,
      ]),
    );
  }

  Path _fallbackPath(double cx, double cy, double r) {
    final path = Path();
    final isRect = shape == 'rect' && points == 4 && inner <= 0;
    if (points == 0 || points >= 50) {
      path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    } else if (isRect || points < 3) {
      final rr = math.min(round * r * 2, r * 0.49);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          Radius.circular(rr),
        ),
      );
    } else {
      final rr = round.clamp(0.0, 0.49) * r;
      final step = 2 * math.pi / points;
      final start = -math.pi / 2;
      for (var i = 0; i < points; i++) {
        final a = start + step * i;
        final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else if (rr > 0) {
          final prev = start + step * (i - 1);
          final mx = cx + r * math.cos(prev + step / 2) * 0.95;
          final my = cy + r * math.sin(prev + step / 2) * 0.95;
          path.quadraticBezierTo(mx, my, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas c, Size s) {
    drawWell(c, s);
    final cx = s.width / 2, cy = s.height / 2;
    final r = math.min(s.width, s.height) * 0.36;
    final path =
        (svgPath.isNotEmpty ? _parseSvg(cx, cy, r) : null) ??
        _fallbackPath(cx, cy, r);
    path.fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
    c.drawPath(
      path,
      Paint()
        ..color = Grey.g15
        ..style = PaintingStyle.fill,
    );
    c.drawPath(
      path,
      Paint()
        ..color = Accent.fill.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_PreviewPaint o) =>
      o.round != round ||
      o.points != points ||
      o.inner != inner ||
      o.shape != shape ||
      o.svgPath != svgPath ||
      o.evenOdd != evenOdd;
}

class _IntoPath extends PathProxy {
  _IntoPath(this.path);
  final Path path;
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}
