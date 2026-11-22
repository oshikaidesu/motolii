// Timeline speed control (AbsentMotion-inspired): compact speed chip in the
// timeline header opening a popover with speed presets, reverse toggle, slider,
// and Start / Now / End hold-point anchor for `doc_time_stretch`.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, Pressable;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Standard playback-speed snaps (matching AbsentMotion's SpeedPanel).
const timelineSpeedPresets = <double>[0.25, 0.5, 0.75, 1.0, 2.0, 3.0];

/// Hold-point anchors accepted by the engine's `doc_time_stretch`.
const timelineSpeedHolds = <({String id, String label})>[
  (id: 'start', label: 'Start'),
  (id: 'now', label: 'Now'),
  (id: 'end', label: 'End'),
];

/// Formats a speed multiplier concisely (e.g. `1×`, `0.5×`, `-1.5×`).
String formatSpeed(double s) {
  final rounded = (s * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) return '${rounded.round()}×';
  final two = rounded.toStringAsFixed(2);
  return '${two.endsWith('0') ? two.substring(0, two.length - 1) : two}×';
}

/// Compact speed readout chip in the timeline header with an interactive
/// AbsentMotion-style speed & hold-anchor popover.
class TimelineSpeedControl extends StatefulWidget {
  const TimelineSpeedControl({
    required this.ws,
    required this.layer,
    super.key,
  });

  final WorkspaceController ws;
  final Layer layer;

  @override
  State<TimelineSpeedControl> createState() => _TimelineSpeedControlState();
}

class _TimelineSpeedControlState extends State<TimelineSpeedControl> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  double? _draft;

  bool get _canStretch =>
      widget.layer.kind != LayerKind.camera &&
      widget.layer.kind != LayerKind.group;

  double _currentSpeed() => timeline_service.isConnected(widget.ws)
      ? timeline_service.layerSpeed(widget.ws, widget.layer.id)
      : (widget.layer.media?.speed ?? 1.0);

  String _currentHold() => timeline_service.isConnected(widget.ws)
      ? timeline_service.layerSpeedHold(widget.ws, widget.layer.id)
      : 'start';

  void _applySpeed(double speed) {
    final ws = widget.ws;
    if (!timeline_service.isConnected(ws)) return;
    final clean = speed.abs() < 0.05 ? (speed < 0 ? -0.1 : 0.1) : speed;
    final hold = _currentHold();
    ws.after(
      timeline_service.stretchLayerSpeed(
        ws,
        widget.layer.id,
        clean,
        hold,
        ws.frame / WorkspaceController.fps,
      ),
      (_, _) => ws.reread(),
    );
  }

  void _setHold(String hold) {
    final ws = widget.ws;
    if (!timeline_service.isConnected(ws)) return;
    ws.after(timeline_service.setSpeedHold(ws, widget.layer.id, hold), (_, _) {
      ws.reread();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_canStretch || !timeline_service.isConnected(widget.ws)) {
      return const SizedBox.shrink();
    }
    final speed = _draft ?? _currentSpeed();
    final modified = (speed - 1.0).abs() > 0.01;
    final look = ChipLook.readout(
      ink: modified ? WindowTokens.accent : Grey.g91,
      size: 10.5,
      radius: WindowTokens.radius,
    );

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => _SpeedPopover(
        link: _link,
        speed: _draft ?? _currentSpeed(),
        hold: _currentHold(),
        onPreview: (v) => setState(() => _draft = v),
        onCommit: (v) {
          setState(() => _draft = null);
          _applySpeed(v);
        },
        onHold: _setHold,
        onClose: () {
          setState(() => _draft = null);
          _portal.hide();
        },
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Pressable(
          key: const ValueKey('ws-tl-speed'),
          onTap: () {
            if (_portal.isShowing) {
              _portal.hide();
            } else {
              setState(() => _draft = null);
              _portal.show();
            }
          },
          builder: (_, _) => Chip(label: formatSpeed(speed), look: look),
        ),
      ),
    );
  }
}

class _SpeedPopover extends StatelessWidget {
  const _SpeedPopover({
    required this.link,
    required this.speed,
    required this.hold,
    required this.onPreview,
    required this.onCommit,
    required this.onHold,
    required this.onClose,
  });

  final LayerLink link;
  final double speed;
  final String hold;
  final ValueChanged<double> onPreview;
  final ValueChanged<double> onCommit;
  final ValueChanged<String> onHold;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final reversed = speed < 0;
    final mag = speed.abs().clamp(0.1, 4.0);
    final sign = reversed ? -1.0 : 1.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, Shape.s(4)),
          child: Container(
            key: const ValueKey('ws-tl-speed-popover'),
            width: Shape.z(236),
            padding: EdgeInsets.all(Shape.s(10)),
            decoration: BoxDecoration(
              color: Grey.g15,
              borderRadius: Shape.round(6),
              border: Border.all(color: Grey.g26),
              boxShadow: [
                BoxShadow(
                  color: Grey.g00.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Speed', style: TextStyles.micro(Grey.g63)),
                    const Spacer(),
                    Text(
                      formatSpeed(speed),
                      style: TextStyles.value(Grey.g95).bold,
                    ),
                    SizedBox(width: Shape.s(6)),
                    Pressable(
                      key: const ValueKey('ws-tl-speed-rev'),
                      onTap: () => onCommit(-speed),
                      builder: (_, hot) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Shape.s(5),
                          vertical: Shape.s(2),
                        ),
                        decoration: BoxDecoration(
                          color: reversed
                              ? WindowTokens.accent.withValues(alpha: 0.22)
                              : (hot ? Grey.g26 : Grey.g20),
                          borderRadius: Shape.round(3),
                        ),
                        child: Text(
                          'Rev',
                          style: TextStyles.micro(
                            reversed ? WindowTokens.accent : Grey.g76,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Shape.s(6)),
                // Magnitude slider (0.1× .. 4.0×), preserving sign; commits on release.
                Listener(
                  onPointerUp: (_) => onCommit(sign * (mag * 20).round() / 20),
                  child: MiniSlider(
                    key: const ValueKey('ws-tl-speed-slider'),
                    values: [(mag - 0.1) / 3.9],
                    width: Shape.z(214),
                    step: 0.005,
                    height: 20,
                    groove: 4,
                    well: WindowTokens.well,
                    fill: WindowTokens.accent,
                    thumb: const Size.square(12),
                    thumbColor: Grey.g95,
                    onChanged: (v) {
                      final next = 0.1 + v.first * 3.9;
                      onPreview(sign * (next * 20).round() / 20);
                    },
                  ),
                ),
                SizedBox(height: Shape.s(6)),
                Row(
                  children: [
                    for (final p in timelineSpeedPresets)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(1)),
                          child: Pressable(
                            key: ValueKey('ws-tl-speed-preset-$p'),
                            onTap: () => onCommit(sign * p),
                            builder: (_, hot) {
                              final on = (mag - p).abs() < 0.02;
                              return Container(
                                height: Shape.z(20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: on
                                      ? WindowTokens.accent.withValues(
                                          alpha: 0.2,
                                        )
                                      : (hot ? Grey.g26 : Grey.g20),
                                  borderRadius: Shape.round(3),
                                ),
                                child: Text(
                                  formatSpeed(p),
                                  style: TextStyles.micro(
                                    on ? WindowTokens.accent : Grey.g76,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: Shape.s(8)),
                Row(
                  children: [
                    Text('Hold at', style: TextStyles.micro(Grey.g63)),
                    SizedBox(width: Shape.s(8)),
                    for (final h in timelineSpeedHolds)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(1)),
                          child: Pressable(
                            key: ValueKey('ws-tl-speed-hold-${h.id}'),
                            onTap: () => onHold(h.id),
                            builder: (_, hot) {
                              final on = hold == h.id;
                              return Container(
                                height: Shape.z(20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: on
                                      ? WindowTokens.accent.withValues(
                                          alpha: 0.2,
                                        )
                                      : (hot ? Grey.g26 : Grey.g20),
                                  borderRadius: Shape.round(3),
                                ),
                                child: Text(
                                  h.label,
                                  style: TextStyles.micro(
                                    on ? WindowTokens.accent : Grey.g76,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
