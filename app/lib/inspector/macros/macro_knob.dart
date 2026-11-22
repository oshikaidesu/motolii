// Unified Signal Macro slot tile: source chip (Knob / Audio / MIDI / Layer / Wave),
// modeless draggable/clickable patch plug (`○`), 270° rotary dial or live signal meter,
// keyframe diamond (for Knob), and double-click rename.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/macros/macro_model.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// One signal channel tile in the Macros card (`macro_1` .. `macro_8`).
class MacroKnob extends StatefulWidget {
  const MacroKnob({
    required this.doc,
    required this.slot,
    required this.label,
    required this.source,
    required this.layers,
    required this.mappedCount,
    required this.configOpen,
    required this.onToggleConfig,
    required this.onRename,
    super.key,
  });

  final InspectorValues doc;
  final int slot;
  final String label;
  final MacroSource source;
  final List<MacroLayerChoice> layers;
  final int mappedCount;
  final bool configOpen;
  final VoidCallback onToggleConfig;
  final ValueChanged<String> onRename;

  @override
  State<MacroKnob> createState() => _MacroKnobState();
}

class _MacroKnobState extends State<MacroKnob> {
  bool _dragging = false;
  bool _renaming = false;
  double _startY = 0;
  double _startVal = 0;

  String get _id => 'v_macro_${widget.slot}';

  void _dragStart(DragStartDetails d) {
    _dragging = true;
    _startY = d.globalPosition.dy;
    _startVal = (widget.doc.get(_id) ?? 0.0).clamp(0.0, 100.0);
    widget.doc.beginGesture();
    setState(() {});
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final fine = HardwareKeyboard.instance.isShiftPressed ? 0.25 : 1.0;
    final delta = (_startY - d.globalPosition.dy) * 0.7 * fine;
    final next = (_startVal + delta).clamp(0.0, 100.0);
    widget.doc.setMany({_id: next});
  }

  void _dragEnd() {
    if (!_dragging) return;
    _dragging = false;
    widget.doc.endGesture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final src = widget.source;
    final isKnob = src.kind == MacroSourceKind.knob;
    final mapped = widget.mappedCount > 0;
    final tone = macroSlotColor(widget.slot);

    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.watch(_id),
        doc.watch('key:$_id'),
        doc.macroDrag,
      ]),
      builder: (context, _) {
        final value = (doc.get(_id) ?? 0.0).clamp(0.0, 100.0);
        final ks = doc.keys[_id] ?? KeyframeState.off;
        final armed = doc.macroDrag.value == widget.slot;
        final activeBorder = _dragging || armed || widget.configOpen;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(4),
            vertical: Shape.s(4),
          ),
          decoration: BoxDecoration(
            color: InspectorSkin.well,
            borderRadius: Shape.round(6),
            border: Border.all(
              color: activeBorder
                  ? tone.withValues(alpha: 0.80)
                  : (mapped || !isKnob
                        ? tone.withValues(alpha: 0.32)
                        : Grey.g20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Source badge (opens inline source tray) + draggable patch Plug (`○`).
              Row(
                children: [
                  maybeTip(
                    context,
                    'Signal source (${src.badgeLabel}) — click to switch Knob / Audio / MIDI / Layer / Wave',
                    Pressable(
                      key: ValueKey('macros:src:${widget.slot}'),
                      onTap: widget.onToggleConfig,
                      builder: (_, hot) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Shape.s(3),
                          vertical: Shape.s(1),
                        ),
                        decoration: BoxDecoration(
                          color: widget.configOpen || !isKnob
                              ? tone.withValues(alpha: hot ? 0.28 : 0.16)
                              : (hot ? Grey.g26 : Grey.g15),
                          borderRadius: Shape.round(3),
                        ),
                        child: Text(
                          src.badgeLabel,
                          style: TextStyles.micro(
                            widget.configOpen || !isKnob
                                ? tone
                                : (hot ? Grey.g91 : Grey.g56),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.mappedCount > 1) ...[
                    Text(
                      '${widget.mappedCount}',
                      style: TextStyles.micro(tone),
                    ),
                    SizedBox(width: Shape.s(2)),
                  ],
                  _PatchPlug(
                    slot: widget.slot,
                    label: widget.label,
                    tone: tone,
                    mapped: mapped,
                    armed: armed,
                    doc: doc,
                  ),
                ],
              ),
              SizedBox(height: Shape.s(2)),

              // Center: rotary dial for Knob, or live visual signal meter for Audio/MIDI/Layer/Wave.
              if (isKnob)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        key: ValueKey('macros:knob:${widget.slot}'),
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: _dragStart,
                        onVerticalDragUpdate: _dragUpdate,
                        onVerticalDragEnd: (_) => _dragEnd(),
                        onVerticalDragCancel: _dragEnd,
                        onDoubleTap: () => doc.set(_id, 0.0),
                        child: SizedBox(
                          width: Shape.z(36),
                          height: Shape.z(32),
                          child: CustomPaint(
                            painter: Draw(
                              (c, s) => _drawDial(
                                c,
                                s,
                                value / 100.0,
                                mapped ? tone : Grey.g63,
                                active: _dragging,
                                mapped: mapped,
                              ),
                              (value, mapped, _dragging),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: maybeTip(
                        context,
                        ks == KeyframeState.at
                            ? 'Remove keyframe'
                            : 'Keyframe Macro ${widget.slot}',
                        Pressable(
                          key: ValueKey('macros:key:${widget.slot}'),
                          onTap: () => doc.setKey(
                            _id,
                            ks == KeyframeState.at
                                ? KeyframeState.anim
                                : KeyframeState.at,
                          ),
                          builder: (_, hot) => SizedBox(
                            width: 11,
                            height: 11,
                            child: Center(
                              child: CustomPaint(
                                size: const Size(7, 7),
                                painter: Draw(
                                  (c, s) => _drawKeyDiamond(c, s, ks, hot),
                                  (ks, hot),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                maybeTip(
                  context,
                  '${src.badgeLabel}: ${src.shortSummary(widget.layers)} — click to configure',
                  Pressable(
                    key: ValueKey('macros:meter:${widget.slot}'),
                    onTap: widget.onToggleConfig,
                    builder: (_, hot) => SizedBox(
                      height: Shape.z(32),
                      width: double.infinity,
                      child: CustomPaint(
                        painter: Draw(
                          (c, s) => _drawSignalVisual(
                            c,
                            s,
                            src,
                            value / 100.0,
                            tone,
                            hot: hot || widget.configOpen,
                          ),
                          (src.kind, src.sub, value, hot, widget.configOpen),
                        ),
                      ),
                    ),
                  ),
                ),

              // Readout: consistent 0..100% signal level across all source kinds.
              Text(
                '${value.round()}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(
                  mapped || _dragging || !isKnob ? Grey.g91 : Grey.g56,
                ),
              ),
              SizedBox(height: Shape.s(1)),

              // Editable channel label (double-click to rename).
              if (_renaming)
                SizedBox(
                  height: Shape.z(16),
                  child: TypedField(
                    key: ValueKey('macros:rename:${widget.slot}'),
                    text: widget.label,
                    standing: true,
                    take: true,
                    escapes: true,
                    align: TextAlign.center,
                    style: TextStyles.micro(Grey.g95),
                    cursor: Grey.g95,
                    backgroundCursor: Grey.g20,
                    selection: Role.selected.withValues(alpha: 0.4),
                    onDone: (said) {
                      if (said != null) widget.onRename(said.trim());
                      if (mounted) setState(() => _renaming = false);
                    },
                  ),
                )
              else
                GestureDetector(
                  onDoubleTap: () => setState(() => _renaming = true),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyles.micro(
                      mapped || !isKnob ? Grey.g91 : Grey.g56,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Draggable (and click-to-arm) circular patch plug (`○`) for modeless parameter binding.
class _PatchPlug extends StatelessWidget {
  const _PatchPlug({
    required this.slot,
    required this.label,
    required this.tone,
    required this.mapped,
    required this.armed,
    required this.doc,
  });

  final int slot;
  final String label;
  final Color tone;
  final bool mapped;
  final bool armed;
  final InspectorValues doc;

  Widget _socket({required bool hollow, required bool hot}) => Container(
    width: Shape.z(13),
    height: Shape.z(13),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: hollow
          ? Grey.g15
          : (armed
                ? tone
                : (mapped
                      ? tone.withValues(alpha: hot ? 0.35 : 0.22)
                      : (hot ? Grey.g26 : Grey.g15))),
      shape: BoxShape.circle,
      border: Border.all(
        color: armed || mapped || hot ? tone : Grey.g44,
        width: armed ? 1.5 : 1.1,
      ),
    ),
    child: hollow
        ? null
        : Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: armed ? Grey.g10 : (mapped || hot ? tone : Grey.g56),
              shape: BoxShape.circle,
            ),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(7),
        vertical: Shape.s(3),
      ),
      decoration: BoxDecoration(
        color: Grey.g15,
        borderRadius: Shape.round(10),
        border: Border.all(color: tone, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          SizedBox(width: Shape.s(4)),
          Text(label, style: TextStyles.micro(Grey.g95)),
        ],
      ),
    );

    return maybeTip(
      context,
      armed
          ? 'Click any parameter below to connect, or click here to cancel'
          : 'Drag onto any parameter below (or click to connect)',
      Draggable<int>(
        key: ValueKey('macros:plug:$slot'),
        data: slot,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => doc.macroDrag.value = slot,
        onDragEnd: (_) {
          if (doc.macroDrag.value == slot) doc.macroDrag.value = null;
        },
        onDraggableCanceled: (_, _) {
          if (doc.macroDrag.value == slot) doc.macroDrag.value = null;
        },
        feedback: Directionality(textDirection: TextDirection.ltr, child: pill),
        childWhenDragging: _socket(hollow: true, hot: true),
        child: Pressable(
          onTap: () => doc.macroDrag.value = armed ? null : slot,
          builder: (_, hot) => _socket(hollow: false, hot: hot),
        ),
      ),
    );
  }
}

void _drawSignalVisual(
  Canvas c,
  Size s,
  MacroSource src,
  double norm,
  Color col, {
  required bool hot,
}) {
  final t = norm.clamp(0.0, 1.0);
  final padX = 4.0;
  final w = math.max(1.0, s.width - padX * 2);
  final h = s.height;

  // Subtle recessed waveform / meter trough.
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(padX, 3, w, h - 6),
      const Radius.circular(4),
    ),
    Paint()..color = hot ? Grey.g20 : Grey.g15,
  );

  final innerTop = 6.0;
  final innerH = math.max(4.0, h - 12.0);

  switch (src.kind) {
    case MacroSourceKind.wave:
      final path = Path();
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final u = i / steps;
        final y01 = switch (src.sub) {
          'tri' => 1.0 - (2.0 * u - 1.0).abs(),
          'saw' => u,
          'square' => u < 0.5 ? 1.0 : 0.0,
          'noise' => 0.5 + 0.4 * math.sin(u * 19.0) * math.cos(u * 7.3),
          _ => 0.5 + 0.5 * math.sin(u * math.pi * 2),
        };
        final px = padX + 3 + (w - 6) * u;
        final py = innerTop + innerH * (1.0 - y01);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      c.drawPath(
        path,
        Paint()
          ..color = col.withValues(alpha: 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round,
      );
      // Live signal height pip on the right edge.
      final pipY = innerTop + innerH * (1.0 - t);
      c.drawCircle(Offset(padX + w - 4, pipY), 2.3, Paint()..color = col);
    case MacroSourceKind.audio:
      // 7-bar reactive level meter.
      const bars = 7;
      final barW = ((w - 8) - (bars - 1) * 2) / bars;
      for (var i = 0; i < bars; i++) {
        final thresh = (i + 1) / bars;
        final lit = t >= thresh - 0.12;
        final bh = innerH * (0.35 + 0.65 * thresh);
        final bx = padX + 4 + i * (barW + 2);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bx, innerTop + innerH - bh, barW, bh),
            const Radius.circular(1.5),
          ),
          Paint()..color = lit ? col : Grey.g26,
        );
      }
    case MacroSourceKind.midi:
      // Stepped note-velocity pulse bar.
      final barH = math.max(2.0, innerH * t);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(padX + 5, innerTop + innerH - barH, w - 10, barH),
          const Radius.circular(2),
        ),
        Paint()..color = col.withValues(alpha: 0.75),
      );
      // Little piano-key tick baseline.
      for (var i = 0; i < 6; i++) {
        final x = padX + 5 + (w - 10) * (i / 5);
        c.drawLine(
          Offset(x, innerTop + innerH),
          Offset(x, innerTop + innerH - 3),
          Paint()
            ..color = Grey.g44
            ..strokeWidth = 1,
        );
      }
    case MacroSourceKind.layer:
    case MacroSourceKind.knob:
      // Horizontal normalized gauge bar.
      final cy = h * 0.5;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(padX + 4, cy - 3, w - 8, 6),
          const Radius.circular(3),
        ),
        Paint()..color = Grey.g26,
      );
      if (t > 0.005) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 4, cy - 3, (w - 8) * t, 6),
            const Radius.circular(3),
          ),
          Paint()..color = col,
        );
      }
  }
}

void _drawDial(
  Canvas c,
  Size s,
  double norm,
  Color col, {
  required bool active,
  required bool mapped,
}) {
  final center = Offset(s.width * 0.5, s.height * 0.54);
  final radius = math.min(s.width, s.height) * 0.42;
  const startAngle = 135.0 * math.pi / 180.0;
  const fullSweep = 270.0 * math.pi / 180.0;
  final rect = Rect.fromCircle(center: center, radius: radius);

  c.drawCircle(
    center,
    radius - 3.5,
    Paint()..color = active ? Grey.g26 : Grey.g15,
  );
  c.drawCircle(
    center,
    radius - 3.5,
    Paint()
      ..color = Grey.g38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );

  c.drawArc(
    rect,
    startAngle,
    fullSweep,
    false,
    Paint()
      ..color = Grey.g26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );

  final t = norm.clamp(0.0, 1.0);
  if (t > 0.002) {
    c.drawArc(
      rect,
      startAngle,
      fullSweep * t,
      false,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.9 : 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  final angle = startAngle + fullSweep * t;
  final inner = Offset(
    center.dx + math.cos(angle) * (radius * 0.18),
    center.dy + math.sin(angle) * (radius * 0.18),
  );
  final tip = Offset(
    center.dx + math.cos(angle) * (radius - 4.0),
    center.dy + math.sin(angle) * (radius - 4.0),
  );
  c.drawLine(
    inner,
    tip,
    Paint()
      ..color = mapped || active ? Grey.g95 : Grey.g76
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round,
  );
}

void _drawKeyDiamond(Canvas c, Size s, KeyframeState ks, bool hot) {
  final cx = s.width * 0.5, cy = s.height * 0.5;
  final r = s.width * 0.42;
  final path = Path()
    ..moveTo(cx, cy - r)
    ..lineTo(cx + r, cy)
    ..lineTo(cx, cy + r)
    ..lineTo(cx - r, cy)
    ..close();
  if (ks == KeyframeState.at) {
    c.drawPath(path, Paint()..color = Accent.fill);
  } else {
    c.drawPath(
      path,
      Paint()
        ..color = ks == KeyframeState.anim
            ? Accent.fill
            : (hot ? Grey.g91 : Grey.g44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }
}
