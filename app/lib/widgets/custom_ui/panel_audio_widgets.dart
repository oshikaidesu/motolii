// Audio-reactive and studio-console VST widgets:
// `ui.waveform`, `ui.sequencer`, `ui.fader`, and `ui.vu`.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_style.dart';
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/number_format.dart';

/// Audio waveform display (`ui.waveform`) with playhead, beat strike markers,
/// and optional draggable threshold line.
class PanelWaveform extends StatefulWidget {
  const PanelWaveform({
    required this.samples,
    required this.height,
    this.surfaceKey,
    this.label = '',
    this.playhead = 0.5,
    this.threshold,
    this.strikes = const [],
    this.look = 'bars',
    this.color = '',
    this.peakColor = '',
    this.framed = true,
    this.style,
    this.onInteract,
    super.key,
  });

  final Key? surfaceKey;
  final List<double> samples;
  final double height;
  final String label;
  final double playhead;
  final double? threshold;
  final List<double> strikes;
  final String look;
  final String color;
  final String peakColor;
  final bool framed;
  final PanelStyle? style;
  final void Function(
    double x,
    double y,
    double threshold,
    String phase, {
    bool live,
  })?
  onInteract;

  @override
  State<PanelWaveform> createState() => _PanelWaveformState();
}

class _PanelWaveformState extends State<PanelWaveform> {
  double? _dragThresh;
  double _lastX = 0.5;
  double _lastY = 0.5;

  (double, double, double) _resolve(Offset local, Size s) {
    final nx = (local.dx / math.max(1.0, s.width)).clamp(0.0, 1.0);
    final ny = (local.dy / math.max(1.0, s.height)).clamp(0.0, 1.0);
    // Threshold is distance from center axis (0..1).
    final thr = ((0.5 - ny).abs() * 2.0).clamp(0.05, 0.98);
    _lastX = nx;
    _lastY = ny;
    return (nx, ny, thr);
  }

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
    final peakCol =
        resolvePanelColor(widget.peakColor) ?? InspectorSkin.tonePlace;
    final bgCol =
        resolvePanelColor(st?.bg ?? '') ??
        theme.controlBg ??
        InspectorSkin.well;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? theme.radius ?? 6.0;
    final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;
    final thr = _dragThresh ?? widget.threshold;

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
                (c, s) => _paintWaveform(
                  c,
                  s,
                  samples: widget.samples,
                  playhead: widget.playhead,
                  threshold: thr,
                  strikes: widget.strikes,
                  look: widget.look,
                  accent: accentCol,
                  peak: peakCol,
                  grid: borderCol,
                ),
                (
                  widget.samples,
                  widget.playhead,
                  thr,
                  widget.strikes,
                  widget.look,
                  accentCol,
                  peakCol,
                ),
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
            if (widget.onInteract == null) return surface;
            return GestureDetector(
              key: widget.surfaceKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (x, y, t) = _resolve(d.localPosition, size);
                widget.onInteract!(x, y, t, 'down');
              },
              onPanStart: (d) {
                final (x, y, t) = _resolve(d.localPosition, size);
                if (widget.threshold != null) setState(() => _dragThresh = t);
                widget.onInteract!(x, y, t, 'down', live: true);
              },
              onPanUpdate: (d) {
                final (x, y, t) = _resolve(d.localPosition, size);
                if (widget.threshold != null) setState(() => _dragThresh = t);
                widget.onInteract!(x, y, t, 'drag', live: true);
              },
              onPanEnd: (_) {
                final t = _dragThresh ?? widget.threshold ?? 0.5;
                setState(() => _dragThresh = null);
                widget.onInteract!(_lastX, _lastY, t, 'up');
              },
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _paintWaveform(
  Canvas c,
  Size s, {
  required List<double> samples,
  required double playhead,
  required double? threshold,
  required List<double> strikes,
  required String look,
  required Color accent,
  required Color peak,
  required Color grid,
}) {
  final w = s.width;
  final h = s.height;
  final mid = h * 0.5;

  // Center line
  c.drawLine(
    Offset(0, mid),
    Offset(w, mid),
    Paint()
      ..color = grid.withValues(alpha: 0.45)
      ..strokeWidth = 0.8,
  );

  // Beat strike vertical markers (normalized 0..1 positions)
  for (final u in strikes) {
    if (u < 0 || u > 1) continue;
    final x = u * w;
    c.drawLine(
      Offset(x, 0),
      Offset(x, h),
      Paint()
        ..color = peak.withValues(alpha: 0.42)
        ..strokeWidth = 1.2,
    );
    c.drawCircle(Offset(x, 5), 2.2, Paint()..color = peak);
  }

  final n = samples.length;
  if (n > 0) {
    if (look == 'line') {
      final top = Path();
      final fill = Path()..moveTo(0, mid);
      for (var i = 0; i < n; i++) {
        final x = (i / math.max(1, n - 1)) * w;
        final amp = samples[i].clamp(0.0, 1.0);
        final y = mid - amp * (h * 0.44);
        if (i == 0) {
          top.moveTo(x, y);
        } else {
          top.lineTo(x, y);
        }
        fill.lineTo(x, y);
      }
      for (var i = n - 1; i >= 0; i--) {
        final x = (i / math.max(1, n - 1)) * w;
        final amp = samples[i].clamp(0.0, 1.0);
        fill.lineTo(x, mid + amp * (h * 0.44));
      }
      fill.close();
      c.drawPath(fill, Paint()..color = accent.withValues(alpha: 0.24));
      c.drawPath(
        top,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    } else {
      final pitch = w / n;
      final bw = math.max(1.5, pitch - 1.5);
      for (var i = 0; i < n; i++) {
        final amp = samples[i].clamp(0.03, 1.0);
        final bh = amp * (h * 0.84);
        final x = i * pitch + (pitch - bw) * 0.5;
        final over = threshold != null && amp >= threshold;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, mid - bh * 0.5, bw, bh),
            const Radius.circular(1.5),
          ),
          Paint()..color = over ? peak : accent.withValues(alpha: 0.85),
        );
      }
    }
  }

  // Draggable threshold gate lines (symmetric around center)
  if (threshold != null) {
    final dy = threshold.clamp(0.0, 1.0) * (h * 0.44);
    final tp = Paint()
      ..color = peak.withValues(alpha: 0.85)
      ..strokeWidth = 1.2;
    c.drawLine(Offset(0, mid - dy), Offset(w, mid - dy), tp);
    c.drawLine(Offset(0, mid + dy), Offset(w, mid + dy), tp);
  }

  // Live playhead cursor
  if (playhead >= 0 && playhead <= 1) {
    final px = playhead * w;
    c.drawLine(
      Offset(px, 0),
      Offset(px, h),
      Paint()
        ..color = DarkGrey.g100.withValues(alpha: 0.90)
        ..strokeWidth = 1.6,
    );
  }
}

/// 16-step beat sequencer grid (`ui.sequencer`) with click & paint-drag editing.
class PanelSequencer extends StatefulWidget {
  const PanelSequencer({
    required this.steps,
    required this.onChange,
    this.seqKey,
    this.label = '',
    this.activeStep = -1,
    this.cols = 8,
    this.color = '',
    this.style,
    super.key,
  });

  final Key? seqKey;
  final List<double> steps;
  final String label;
  final int activeStep;
  final int cols;
  final String color;
  final PanelStyle? style;
  final void Function(
    int index,
    double value,
    List<double> nextSteps, {
    bool live,
  })
  onChange;

  @override
  State<PanelSequencer> createState() => _PanelSequencerState();
}

class _PanelSequencerState extends State<PanelSequencer> {
  double _paintValue = 1.0;
  int _lastHit = -1;

  void _emit(int idx, double val, {bool live = false}) {
    final next = List<double>.of(widget.steps);
    if (idx >= 0 && idx < next.length) {
      next[idx] = val;
      widget.onChange(idx, val, next, live: live);
    }
  }

  int _hitIndex(Offset local, Size s, int cols, int rows) {
    final c = (local.dx / math.max(1.0, s.width) * cols).floor().clamp(
      0,
      cols - 1,
    );
    final r = (local.dy / math.max(1.0, s.height) * rows).floor().clamp(
      0,
      rows - 1,
    );
    return r * cols + c;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final n = math.max(1, widget.steps.length);
    final cols = widget.cols.clamp(1, 16);
    final rows = (n / cols).ceil();
    final cellH = (st?.height ?? 24.0).clamp(16.0, 44.0);
    final gap = st?.gap ?? 3.0;
    final totalH = rows * cellH + (rows - 1) * gap;
    final accentCol =
        resolvePanelColor(widget.color) ??
        resolvePanelColor(st?.accent ?? '') ??
        theme.accent ??
        Accent.fill;
    final offBg =
        resolvePanelColor(st?.bg ?? '') ??
        theme.controlBg ??
        InspectorSkin.well;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? 4.0;
    final bw = st?.borderWidth ?? 1.0;

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
            final size = Size(box.maxWidth, totalH);
            return GestureDetector(
              key: widget.seqKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final idx = _hitIndex(d.localPosition, size, cols, rows);
                if (idx >= n) return;
                final nextVal = widget.steps[idx] > 0.05 ? 0.0 : 1.0;
                _emit(idx, nextVal);
              },
              onPanStart: (d) {
                final idx = _hitIndex(d.localPosition, size, cols, rows);
                if (idx >= n) return;
                _paintValue = widget.steps[idx] > 0.05 ? 0.0 : 1.0;
                _lastHit = idx;
                _emit(idx, _paintValue, live: true);
              },
              onPanUpdate: (d) {
                final idx = _hitIndex(d.localPosition, size, cols, rows);
                if (idx >= n || idx == _lastHit) return;
                _lastHit = idx;
                _emit(idx, _paintValue, live: true);
              },
              onPanEnd: (_) {
                if (_lastHit >= 0 && _lastHit < n) {
                  _emit(_lastHit, _paintValue);
                }
                _lastHit = -1;
              },
              child: SizedBox(
                height: totalH,
                child: Column(
                  children: [
                    for (var r = 0; r < rows; r++) ...[
                      if (r > 0) SizedBox(height: gap),
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < cols; c++) ...[
                              if (c > 0) SizedBox(width: gap),
                              Expanded(
                                child: (r * cols + c) < n
                                    ? _buildPad(
                                        idx: r * cols + c,
                                        vel: widget.steps[r * cols + c],
                                        isPlayhead:
                                            (r * cols + c) == widget.activeStep,
                                        accent: accentCol,
                                        offBg: offBg,
                                        border: borderCol,
                                        rad: rad,
                                        bw: bw,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPad({
    required int idx,
    required double vel,
    required bool isPlayhead,
    required Color accent,
    required Color offBg,
    required Color border,
    required double rad,
    required double bw,
  }) {
    final on = vel > 0.05;
    final beatGroup = (idx ~/ 4).isEven;
    final baseOff = beatGroup ? offBg : Color.lerp(offBg, border, 0.18)!;
    return Container(
      decoration: BoxDecoration(
        color: on
            ? accent.withValues(alpha: 0.22 + 0.78 * vel.clamp(0.0, 1.0))
            : baseOff,
        borderRadius: BorderRadius.circular(rad),
        border: Border.all(
          color: isPlayhead ? DarkGrey.g100 : (on ? accent : border),
          width: isPlayhead ? math.max(1.8, bw) : bw,
        ),
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        width: 5,
        height: 2.5,
        decoration: BoxDecoration(
          color: isPlayhead
              ? DarkGrey.g100
              : (on
                    ? readableInkOn(accent).withValues(alpha: 0.85)
                    : border.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Studio mixing-console vertical fader (`ui.fader`) with scale ticks and machined cap.
class PanelFader extends StatefulWidget {
  const PanelFader({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.faderKey,
    this.def,
    this.step,
    this.dec,
    this.unit = '',
    this.height = 96,
    this.color = '',
    this.look = 'studio',
    this.style,
    super.key,
  });

  final Key? faderKey;
  final String label;
  final double value;
  final double min;
  final double max;
  final double? def;
  final double? step;
  final int? dec;
  final String unit;
  final double height;
  final String color;
  final String look;
  final PanelStyle? style;
  final void Function(double value, {bool live}) onChanged;

  @override
  State<PanelFader> createState() => _PanelFaderState();
}

class _PanelFaderState extends State<PanelFader> {
  double? _dragVal;

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
    final h = widget.height.clamp(56.0, 200.0);
    final span = math.max(1e-6, widget.max - widget.min);
    final shown = _dragVal ?? widget.value;
    final t = ((shown - widget.min) / span).clamp(0.0, 1.0);
    final dec =
        widget.dec ??
        ((widget.step ?? 0.01) < 1 ? ((widget.step ?? 0.01) < 0.1 ? 2 : 1) : 0);
    final accentCol =
        resolvePanelColor(widget.color) ??
        resolvePanelColor(st?.accent ?? '') ??
        theme.accent ??
        Accent.fill;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g38;
    final useMono = (st?.mono ?? false) || theme.mono;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: widget.faderKey,
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            final next = _quantize(
              widget.min +
                  (1.0 - (d.localPosition.dy / h).clamp(0.0, 1.0)) * span,
            );
            setState(() => _dragVal = next);
            widget.onChanged(next, live: true);
          },
          onVerticalDragUpdate: (d) {
            final fine = HardwareKeyboard.instance.isShiftPressed ? 0.25 : 1.0;
            final cur = _dragVal ?? widget.value;
            final next = _quantize(cur - (d.delta.dy / h) * span * fine);
            setState(() => _dragVal = next);
            widget.onChanged(next, live: true);
          },
          onVerticalDragEnd: (_) {
            final v = _dragVal ?? widget.value;
            setState(() => _dragVal = null);
            widget.onChanged(v);
          },
          onDoubleTap: widget.def == null
              ? null
              : () => widget.onChanged(_quantize(widget.def!)),
          child: SizedBox(
            width: 34,
            height: h,
            child: CustomPaint(
              painter: Draw(
                (c, s) => _paintFader(
                  c,
                  s,
                  t: t,
                  accent: accentCol,
                  border: borderCol,
                  pop: widget.look == 'pop',
                ),
                (t, accentCol, borderCol, widget.look),
              ),
            ),
          ),
        ),
        SizedBox(height: Shape.s(3)),
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.micro(
              theme.muted ?? Grey.g63,
            ).copyWith(fontSize: TextStyles.px(9), fontWeight: FontWeight.w700),
          ),
        Text(
          '${formatNumber(shown, dec)}${widget.unit}',
          maxLines: 1,
          style: TextStyles.micro(theme.fg ?? Grey.g95).copyWith(
            fontSize: TextStyles.px(9),
            fontFamily: useMono ? 'Menlo' : null,
          ),
        ),
      ],
    );
  }
}

void _paintFader(
  Canvas c,
  Size s, {
  required double t,
  required Color accent,
  required Color border,
  required bool pop,
}) {
  final cx = s.width * 0.5;
  const padY = 10.0;
  final trackH = math.max(10.0, s.height - padY * 2);

  // Precision dB scale ticks
  const ticks = 8;
  for (var i = 0; i <= ticks; i++) {
    final y = padY + trackH * (i / ticks);
    final major = i == 0 || i == ticks || i == ticks ~/ 2;
    final len = major ? 5.0 : 3.0;
    final p = Paint()
      ..color = border.withValues(alpha: major ? 0.75 : 0.4)
      ..strokeWidth = 1.0;
    c.drawLine(Offset(cx - 8 - len, y), Offset(cx - 8, y), p);
    c.drawLine(Offset(cx + 8, y), Offset(cx + 8 + len, y), p);
  }

  // Recessed track slot
  final slot = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(cx, padY + trackH * 0.5),
      width: 4.5,
      height: trackH,
    ),
    const Radius.circular(2.5),
  );
  c.drawRRect(slot, Paint()..color = DarkGrey.g00.withValues(alpha: 0.65));
  c.drawRRect(
    slot,
    Paint()
      ..color = border.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );

  // Active fill bar from bottom up
  final knobY = padY + trackH * (1.0 - t);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - 1.8, knobY, cx + 1.8, padY + trackH),
      const Radius.circular(2),
    ),
    Paint()..color = accent,
  );

  // Fader cap
  final capRect = Rect.fromCenter(
    center: Offset(cx, knobY),
    width: 22,
    height: 12,
  );
  if (pop) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        capRect.shift(const Offset(2, 2)),
        const Radius.circular(3),
      ),
      Paint()..color = border,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..color = DarkGrey.g100,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  } else {
    c.drawRRect(
      RRect.fromRectAndRadius(
        capRect.shift(const Offset(0, 1.5)),
        const Radius.circular(3),
      ),
      Paint()..color = DarkGrey.g00.withValues(alpha: 0.45),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Grey.g76, Grey.g38, Grey.g63],
        ).createShader(capRect),
    );
  }
  c.drawLine(
    Offset(capRect.left + 3, knobY),
    Offset(capRect.right - 3, knobY),
    Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round,
  );
}

/// Segmented LED audio VU meter (`ui.vu`): green -> amber -> red clip LEDs, mono or stereo.
class PanelVuMeter extends StatelessWidget {
  const PanelVuMeter({
    required this.value,
    this.rightValue,
    this.peak,
    this.label = '',
    this.segments = 16,
    this.horizontal = true,
    this.height = 14,
    this.style,
    super.key,
  });

  final double value;
  final double? rightValue;
  final double? peak;
  final String label;
  final int segments;
  final bool horizontal;
  final double height;
  final PanelStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = style;
    final segs = segments.clamp(6, 32);
    final stereo = rightValue != null;
    final h = horizontal
        ? (stereo ? height * 1.7 : height)
        : height.clamp(48.0, 180.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        Container(
          height: h,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: resolvePanelColor(st?.bg ?? '') ?? DarkGrey.g07,
            borderRadius: BorderRadius.circular(st?.radius ?? 4.0),
            border: Border.all(
              color:
                  resolvePanelColor(st?.border ?? '') ??
                  theme.border ??
                  Grey.g26,
              width: st?.borderWidth ?? 1.0,
            ),
          ),
          child: CustomPaint(
            painter: Draw(
              (c, s) => _paintVu(
                c,
                s,
                left: value.clamp(0.0, 1.0),
                right: rightValue?.clamp(0.0, 1.0),
                peak: peak?.clamp(0.0, 1.0),
                segments: segs,
                horizontal: horizontal,
              ),
              (value, rightValue, peak, segs, horizontal),
            ),
          ),
        ),
      ],
    );
  }
}

void _paintVu(
  Canvas c,
  Size s, {
  required double left,
  required double? right,
  required double? peak,
  required int segments,
  required bool horizontal,
}) {
  final channels = right == null ? [left] : [left, right];
  Color ledColor(double frac) {
    if (frac >= 0.85) return InspectorSkin.alert;
    if (frac >= 0.65) return Accent.key;
    return InspectorSkin.toneBlend;
  }

  for (var ci = 0; ci < channels.length; ci++) {
    final lvl = channels[ci];
    if (horizontal) {
      final rowH = (s.height - (channels.length - 1) * 2.0) / channels.length;
      final y = ci * (rowH + 2.0);
      final pitch = s.width / segments;
      final w = math.max(2.0, pitch - 1.8);
      for (var i = 0; i < segments; i++) {
        final frac = (i + 0.5) / segments;
        final lit = frac <= lvl;
        final isPeak = peak != null && (frac - peak).abs() < (0.7 / segments);
        final col = ledColor(frac);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(i * pitch, y, w, rowH),
            const Radius.circular(1.2),
          ),
          Paint()..color = (lit || isPeak) ? col : col.withValues(alpha: 0.16),
        );
      }
    } else {
      final colW = (s.width - (channels.length - 1) * 2.0) / channels.length;
      final x = ci * (colW + 2.0);
      final pitch = s.height / segments;
      final h = math.max(2.0, pitch - 1.8);
      for (var i = 0; i < segments; i++) {
        final frac = (i + 0.5) / segments;
        final lit = frac <= lvl;
        final isPeak = peak != null && (frac - peak).abs() < (0.7 / segments);
        final col = ledColor(frac);
        final y = s.height - (i + 1) * pitch;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, colW, h),
            const Radius.circular(1.2),
          ),
          Paint()..color = (lit || isPeak) ? col : col.withValues(alpha: 0.16),
        );
      }
    }
  }
}
