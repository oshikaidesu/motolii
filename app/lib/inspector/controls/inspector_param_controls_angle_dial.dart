import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

/// A dial for an angle. The user turns it by dragging around its centre, or drags the number beside it.
///
/// One turn of the pointer is one turn of the value, so the dial always follows the pointer's direction. A drag is one undo step.
class AngleDial extends StatefulWidget {
  const AngleDial({super.key, required this.id, required this.p});
  final String id;
  final Param p;
  @override
  State<AngleDial> createState() => _AngleDialState();
}

class _AngleDialState extends State<AngleDial> {
  double? _last;
  bool _hot = false;
  double _angle(Offset local) {
    // The dial is drawn around this centre. Its slot may be smaller than the size it asks for (InspectorSkin.glyph).
    final o = (context.size ?? const Size(22, 22)).center(Offset.zero);
    return math.atan2(local.dy - o.dy, local.dx - o.dx);
  }

  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context), doc = x.doc;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: Listener(
        onPointerDown: (e) {
          _last = _angle(e.localPosition);
          doc.beginGesture();
        },
        onPointerMove: (e) {
          final last = _last;
          if (last == null) return;
          final a = _angle(e.localPosition);
          var d = a - last;
          if (d > math.pi) d -= 2 * math.pi;
          if (d < -math.pi) d += 2 * math.pi;
          _last = a;
          // The limits are those of a typed number, not the slider's ends. An angle in After Effects turns without end and counts
          // its revolutions. A closed range of at least one turn wraps around inside the range, as Godot's wrapf does.
          final p = widget.p,
              lo = p.open && (p.min ?? 0) < 0 ? double.negativeInfinity : p.validMin ?? p.min ?? double.negativeInfinity,
              hi = p.open ? double.infinity : p.validMax ?? p.max ?? double.infinity;
          var v = (doc.get(widget.id) ?? 0) + d * 180 / math.pi;
          if (hi - lo >= 360) v = v > hi ? v - 360 * ((v - hi) / 360).ceil() : (v < lo ? v + 360 * ((lo - v) / 360).ceil() : v);
          doc.set(widget.id, v.clamp(lo, hi).roundToDouble());
        },
        onPointerUp: (_) {
          if (_last != null) doc.endGesture();
          _last = null;
        },
        onPointerCancel: (_) {
          if (_last != null) doc.endGesture();
          _last = null;
        },
        // Repaints when its value changes, as a number field does (Doc.watch), without rebuilding the Inspector.
        child: ListenableBuilder(
          listenable: doc.watch(widget.id),
          builder: (context, _) => CustomPaint(size: const Size(22, 22), painter: _DialPaint(doc.get(widget.id) ?? 0, _hot || _last != null)),
        ),
      ),
    );
  }
}

class _DialPaint extends CustomPainter {
  const _DialPaint(this.deg, this.hot);
  final double deg;
  final bool hot;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero), r = 9.0;
    c.drawCircle(o, r, Paint()..color = hot ? Grey.g38 : Grey.g26);
    final a = deg * math.pi / 180;
    c.drawArc(
      Rect.fromCircle(center: o, radius: r - 1.5),
      -math.pi / 2,
      a.clamp(-2 * math.pi, 2 * math.pi),
      false,
      Paint()
        ..color = Grey.g63
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tip = o + Offset(math.sin(a), -math.cos(a)) * (r - 1);
    c.drawLine(
      o,
      tip,
      Paint()
        ..color = Grey.g95
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(o, 1.8, Paint()..color = Grey.g95);
  }

  @override
  bool shouldRepaint(_DialPaint o) => o.deg != deg || o.hot != hot;
}
