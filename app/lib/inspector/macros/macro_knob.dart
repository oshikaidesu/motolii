// Ableton Live-style rotary macro knob: 270° arc dial with vertical drag,
// live value readout, keyframe mark, double-click rename, and Map-mode button.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/macros/macro_model.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// One Ableton-style rotary knob in the Macros card (`macro_1` .. `macro_8`).
class MacroKnob extends StatefulWidget {
  const MacroKnob({
    required this.doc,
    required this.slot,
    required this.label,
    required this.mappedCount,
    required this.mapMode,
    required this.pickedProp,
    required this.onRename,
    required this.onBindPicked,
    super.key,
  });

  final InspectorValues doc;
  final int slot;
  final String label;
  final int mappedCount;
  final bool mapMode;
  final String? pickedProp;
  final ValueChanged<String> onRename;
  final VoidCallback onBindPicked;

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
    final mapped = widget.mappedCount > 0;
    final tone = macroSlotColor(widget.slot);

    return ListenableBuilder(
      listenable: Listenable.merge([doc.watch(_id), doc.watch('key:$_id')]),
      builder: (context, _) {
        final value = (doc.get(_id) ?? 0.0).clamp(0.0, 100.0);
        final ks = doc.keys[_id] ?? KeyframeState.off;
        final canBind = widget.mapMode && widget.pickedProp != null;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(4),
            vertical: Shape.s(5),
          ),
          decoration: BoxDecoration(
            color: InspectorSkin.well,
            borderRadius: Shape.round(6),
            border: Border.all(
              color: _dragging
                  ? tone.withValues(alpha: 0.75)
                  : (mapped ? tone.withValues(alpha: 0.32) : Grey.g20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: tiny mapped-count dot + keyframe diamond.
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: mapped ? tone : Grey.g38,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (widget.mappedCount > 1) ...[
                    SizedBox(width: Shape.s(2)),
                    Text(
                      '${widget.mappedCount}',
                      style: TextStyles.micro(tone),
                    ),
                  ],
                  const Spacer(),
                  maybeTip(
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
                ],
              ),
              SizedBox(height: Shape.s(1)),
              // Rotary dial (Ableton Live 270° arc + indicator needle).
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
                    height: Shape.z(34),
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
              // Numeric percentage readout.
              Text(
                '${value.round()}%',
                style: TextStyles.micro(
                  mapped || _dragging ? Grey.g91 : Grey.g56,
                ),
              ),
              SizedBox(height: Shape.s(2)),
              // Editable knob label (double-click to rename like Ableton Cmd+R).
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
                    style: TextStyles.micro(mapped ? Grey.g91 : Grey.g56),
                  ),
                ),
              // In Map mode, show Ableton's per-knob `Map` button below the label.
              if (widget.mapMode) ...[
                SizedBox(height: Shape.s(4)),
                Pressable(
                  key: ValueKey('macros:bind:${widget.slot}'),
                  onTap: canBind ? widget.onBindPicked : null,
                  builder: (_, hot) => Container(
                    height: Shape.z(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: canBind
                          ? (hot
                                ? tone.withValues(alpha: 0.32)
                                : tone.withValues(alpha: 0.20))
                          : Grey.g20,
                      borderRadius: Shape.round(3),
                      border: Border.all(
                        color: canBind
                            ? tone.withValues(alpha: 0.65)
                            : Grey.g26,
                      ),
                    ),
                    child: Text(
                      'Map',
                      style: TextStyles.micro(canBind ? tone : Grey.g44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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
  final radius = math.min(s.width, s.height) * 0.41;
  // 270° sweep starting at bottom-left (135°).
  const startAngle = 135.0 * math.pi / 180.0;
  const fullSweep = 270.0 * math.pi / 180.0;
  final rect = Rect.fromCircle(center: center, radius: radius);

  // Inner knob cap.
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

  // Track background arc.
  c.drawArc(
    rect,
    startAngle,
    fullSweep,
    false,
    Paint()
      ..color = Grey.g26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round,
  );

  // Active value arc.
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
        ..strokeWidth = active ? 3.0 : 2.6
        ..strokeCap = StrokeCap.round,
    );
  }

  // Pointer needle from center to current angle.
  final angle = startAngle + fullSweep * t;
  final inner = Offset(
    center.dx + math.cos(angle) * (radius * 0.18),
    center.dy + math.sin(angle) * (radius * 0.18),
  );
  final tip = Offset(
    center.dx + math.cos(angle) * (radius - 4.2),
    center.dy + math.sin(angle) * (radius - 4.2),
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
