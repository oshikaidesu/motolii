// Tactile VST rotary knob control for declarative custom panels and cards.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_style.dart';
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/number_format.dart';

/// Rotary dial widget supporting 4 VST skins: `arc`, `pop`, `hardware`, `minimal`.
/// Drag vertically to turn (Shift = 4x fine precision); double-tap resets to [def].
class PanelKnob extends StatefulWidget {
  const PanelKnob({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.knobKey,
    this.def,
    this.step,
    this.dec,
    this.unit = '',
    this.size = 44,
    this.look = 'arc',
    this.color = '',
    this.trackColor = '',
    this.capColor = '',
    this.borderColor = '',
    this.style,
    super.key,
  });

  final Key? knobKey;
  final String label;
  final double value;
  final double min;
  final double max;
  final double? def;
  final double? step;
  final int? dec;
  final String unit;
  final double size;
  final String look;
  final String color;
  final String trackColor;
  final String capColor;
  final String borderColor;
  final PanelStyle? style;
  final void Function(double value, {bool live}) onChanged;

  @override
  State<PanelKnob> createState() => _PanelKnobState();
}

class _PanelKnobState extends State<PanelKnob> {
  double _startValue = 0;
  double _dragDy = 0;
  double _liveValue = 0;
  bool _dragging = false;

  double _quantize(double v) {
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    final step = widget.step;
    if (step == null || step <= 0) return clamped;
    return (((clamped - widget.min) / step).round() * step + widget.min)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final span = math.max(1e-6, widget.max - widget.min);
    final shown = _dragging ? _liveValue : widget.value;
    final t = ((shown - widget.min) / span).clamp(0.0, 1.0);
    final dec =
        widget.dec ??
        ((widget.step ?? 0.01) < 1 ? ((widget.step ?? 0.01) < 0.1 ? 2 : 1) : 0);
    final dialSize = widget.size.clamp(28.0, 96.0);

    final accentCol =
        resolvePanelColor(widget.color) ??
        resolvePanelColor(st?.accent ?? '') ??
        theme.accent ??
        Accent.fill;
    final trackCol =
        resolvePanelColor(widget.trackColor) ??
        resolvePanelColor(st?.controlBg ?? '') ??
        theme.controlBg ??
        Grey.g26;
    final capCol =
        resolvePanelColor(widget.capColor) ??
        resolvePanelColor(st?.bg ?? '') ??
        (widget.look == 'pop'
            ? DarkGrey.g100
            : (widget.look == 'hardware' ? Grey.g91 : InspectorSkin.well));
    final borderCol =
        resolvePanelColor(widget.borderColor) ??
        resolvePanelColor(st?.border ?? '') ??
        theme.border ??
        (widget.look == 'pop' ? DarkGrey.g00 : Grey.g38);
    final labelCol =
        resolvePanelColor(st?.muted ?? '') ?? theme.muted ?? Grey.g63;
    final valueCol = resolvePanelColor(st?.fg ?? '') ?? theme.fg ?? Grey.g95;
    final useMono = (st?.mono ?? false) || theme.mono;

    final labelStyle = TextStyles.micro(labelCol).copyWith(
      fontSize: TextStyles.px(st?.fontSize ?? 9.5),
      letterSpacing: st?.letterSpacing ?? (widget.look == 'hardware' ? 0.8 : 0),
      fontWeight: widget.look == 'pop' ? FontWeight.w800 : FontWeight.w600,
    );
    final valueStyle = TextStyles.micro(valueCol).copyWith(
      fontSize: TextStyles.px(9.5),
      fontWeight: FontWeight.w700,
      fontFamily: useMono ? 'Menlo' : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: widget.knobKey,
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {
            _dragging = true;
            _startValue = widget.value;
            _liveValue = widget.value;
            _dragDy = 0;
          },
          onVerticalDragUpdate: (d) {
            final fine = HardwareKeyboard.instance.isShiftPressed ? 0.25 : 1.0;
            _dragDy -= d.delta.dy * fine;
            final next = _quantize(_startValue + (_dragDy / 120.0) * span);
            setState(() => _liveValue = next);
            widget.onChanged(next, live: true);
          },
          onVerticalDragEnd: (_) {
            final finalVal = _liveValue;
            setState(() => _dragging = false);
            widget.onChanged(finalVal);
          },
          onDoubleTap: widget.def == null
              ? null
              : () => widget.onChanged(_quantize(widget.def!)),
          child: SizedBox(
            width: dialSize + 6,
            height: dialSize + 6,
            child: CustomPaint(
              painter: Draw(
                (c, s) => _paintKnob(
                  c,
                  s,
                  t: t,
                  look: widget.look,
                  accent: accentCol,
                  track: trackCol,
                  cap: capCol,
                  border: borderCol,
                  hot: _dragging,
                ),
                (
                  t,
                  widget.look,
                  accentCol,
                  trackCol,
                  capCol,
                  borderCol,
                  _dragging,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: Shape.s(2)),
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        Text(
          '${formatNumber(shown, dec)}${widget.unit}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
      ],
    );
  }
}

void _paintKnob(
  Canvas c,
  Size s, {
  required double t,
  required String look,
  required Color accent,
  required Color track,
  required Color cap,
  required Color border,
  required bool hot,
}) {
  final center = Offset(s.width * 0.5, s.height * 0.5);
  final outerR = math.min(s.width, s.height) * 0.5 - 3.0;
  // Standard VST 270-degree sweep from 7:30 to 4:30.
  const startAngle = math.pi * 0.75;
  const fullSweep = math.pi * 1.5;
  final angle = startAngle + fullSweep * t;

  if (look == 'pop') {
    // Flat-Pop / Neubrutalism: hard offset black shadow + thick ink outline + bold color wedge.
    final capR = outerR * 0.76;
    c.drawCircle(
      center + const Offset(2.5, 2.5),
      capR,
      Paint()..color = border,
    );
    // Chunky background track ticks
    c.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle,
      fullSweep,
      false,
      Paint()
        ..color = border.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    if (t > 0.005) {
      c.drawArc(
        Rect.fromCircle(center: center, radius: outerR),
        startAngle,
        fullSweep * t,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round,
      );
    }
    c.drawCircle(center, capR, Paint()..color = cap);
    c.drawCircle(
      center,
      capR,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // Bold pointer dot + bar (auto-contrast on dark or light pop caps).
    final pointerCol = readableInkOn(cap);
    final p1 =
        center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.28);
    final p2 =
        center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.76);
    c.drawLine(
      p1,
      p2,
      Paint()
        ..color = pointerCol
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(center, capR * 0.22, Paint()..color = accent);
    c.drawCircle(
      center,
      capR * 0.22,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    return;
  }

  if (look == 'hardware') {
    // Teenage Engineering / Braun encoder: precision tick ring + solid colored aluminum cap + crisp white notch.
    final tickR1 = outerR - 1.5;
    final tickR2 = outerR + 1.0;
    const ticks = 11;
    for (var i = 0; i <= ticks; i++) {
      final frac = i / ticks;
      final a = startAngle + fullSweep * frac;
      final lit = frac <= t + 0.001;
      c.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * tickR1,
        center + Offset(math.cos(a), math.sin(a)) * tickR2,
        Paint()
          ..color = lit ? accent : border.withValues(alpha: 0.45)
          ..strokeWidth = i == 0 || i == ticks || i == 5 ? 1.6 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
    final capR = outerR * 0.74;
    // Soft machined shadow
    c.drawCircle(
      center + const Offset(0, 2.0),
      capR,
      Paint()..color = DarkGrey.g00.withValues(alpha: 0.22),
    );
    c.drawCircle(center, capR, Paint()..color = accent);
    c.drawCircle(
      center,
      capR,
      Paint()
        ..color = DarkGrey.g00.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Top specular rim
    c.drawArc(
      Rect.fromCircle(center: center, radius: capR - 1.2),
      -math.pi * 0.85,
      math.pi * 0.7,
      false,
      Paint()
        ..color = DarkGrey.g100.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    // Crisp high-contrast encoder notch
    final notchInk = readableInkOn(accent);
    final p1 =
        center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.22);
    final p2 =
        center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.84);
    c.drawLine(
      p1,
      p2,
      Paint()
        ..color = notchInk
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    return;
  }

  if (look == 'minimal') {
    final ringR = outerR * 0.88;
    c.drawArc(
      Rect.fromCircle(center: center, radius: ringR),
      startAngle,
      fullSweep,
      false,
      Paint()
        ..color = track.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    if (t > 0.005) {
      c.drawArc(
        Rect.fromCircle(center: center, radius: ringR),
        startAngle,
        fullSweep * t,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
    final dot = center + Offset(math.cos(angle), math.sin(angle)) * ringR;
    c.drawCircle(dot, 3.2, Paint()..color = accent);
    return;
  }

  // Default `arc` (Serum / FabFilter VST glowing arc + dark machined dial)
  final arcR = outerR;
  final capR = outerR * 0.72;
  c.drawArc(
    Rect.fromCircle(center: center, radius: arcR),
    startAngle,
    fullSweep,
    false,
    Paint()
      ..color = track.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round,
  );
  if (t > 0.005) {
    // Subtle outer glow
    c.drawArc(
      Rect.fromCircle(center: center, radius: arcR),
      startAngle,
      fullSweep * t,
      false,
      Paint()
        ..color = accent.withValues(alpha: hot ? 0.36 : 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );
    c.drawArc(
      Rect.fromCircle(center: center, radius: arcR),
      startAngle,
      fullSweep * t,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }
  c.drawCircle(
    center,
    capR,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: [
          Color.lerp(cap, DarkGrey.g100, 0.14)!,
          Color.lerp(cap, DarkGrey.g00, 0.25)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: capR)),
  );
  c.drawCircle(
    center,
    capR,
    Paint()
      ..color = border.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );
  final p1 = center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.24);
  final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (capR * 0.80);
  c.drawLine(
    p1,
    p2,
    Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round,
  );
}
