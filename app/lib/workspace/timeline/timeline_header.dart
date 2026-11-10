// The row above the tracks: project name, transport buttons, playhead time, tempo and zoom controls.
import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, IconPress;
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/widgets/timeline_painters.dart' show TimelineGlyphs;
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

/// The timeline header. Narrow widths drop the total time, then the project name and layer summary, then the zoom slider.
class TimelineHeader extends StatelessWidget {
  const TimelineHeader({
    super.key,
    required this.ws,
    required this.loop,
    required this.zoom,
    required this.onToggle,
    required this.onStep,
    required this.onLoop,
    required this.onZoom,
    required this.onMark,
  });
  final WorkspaceController ws;
  final bool loop;
  final double zoom;
  final VoidCallback onToggle, onLoop, onMark;
  final ValueChanged<int> onStep;
  final void Function(double z, {int? anchor}) onZoom;

  @override
  Widget build(BuildContext context) {
    final big = TextStyles.value(Grey.g76)
        .copyWith(fontSize: TextStyles.px(14), fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()]);
    final picked = ws.keys.length, layer = ws.layer;
    return PanelHeader(
      '',
      height: TimelineMetrics.header,
      child: LayoutBuilder(
        builder: (context, box) {
          final roomy = box.maxWidth >= 1000, mid = box.maxWidth >= 820, slide = box.maxWidth >= 600; // Narrower than this, only the zoom buttons remain.
          return Row(
            children: [
              if (mid) ...[
                Chip(label: ws.document?.replaceFirst(RegExp(r'\.motolii$'), '') ?? 'Main', look: _readout(mono: false)),
                SizedBox(width: Shape.s(12)),
              ], // End of the project name chip.
              _RoundButton(TimelineGlyphs.toStart, key: const ValueKey('ws-tl-start'), onTap: () => onStep(-ws.frame)),
              SizedBox(width: Shape.s(2)),
              _RoundButton(TimelineGlyphs.stepBack, key: const ValueKey('ws-tl-back'), onTap: () => onStep(-1)),
              SizedBox(width: Shape.s(2)),
              ValueListenableBuilder<int>(
                // Only the play button listens to playback, so the rest of the row is not rebuilt.
                valueListenable: ws.on[WorkspaceAspect.playing]!,
                builder: (_, _, _) => _RoundButton(
                  ws.playing ? TimelineGlyphs.pause : TimelineGlyphs.play,
                  key: const ValueKey('ws-tl-play'),
                  width: Shape.z(34),
                  on: ws.playing,
                  rest: WindowTokens.accent,
                  onTap: onToggle,
                ),
              ),
              SizedBox(width: Shape.s(2)),
              _RoundButton(TimelineGlyphs.stepFwd, key: const ValueKey('ws-tl-fwd'), onTap: () => onStep(1)),
              SizedBox(width: Shape.s(2)),
              _RoundButton(TimelineGlyphs.loop, key: const ValueKey('ws-tl-loop'), on: loop, onTap: onLoop),
              SizedBox(width: Shape.s(2)),
              ValueListenableBuilder<int>(
                // Like the Set button in Ableton Live: adds a marker at the playhead, or removes the one already there.
                valueListenable: ws.moment,
                builder: (_, _, _) => _RoundButton(
                  ws.marks.any((k) => (k.$1 * WorkspaceController.fps).round() == ws.frame) ? TimelineGlyphs.minus : TimelineGlyphs.plus,
                  key: const ValueKey('ws-tl-mark'),
                  width: Shape.z(66),
                  label: 'Marker',
                  onTap: onMark,
                ),
              ),
              SizedBox(width: Shape.s(12)),
              // The playhead time. Clicking it lets the user type a time, as in the current time display of Premiere Pro and After Effects.
              // Return moves the playhead there; Esc or a click elsewhere leaves it where it was.
              ValueListenableBuilder<int>(
                valueListenable: ws.moment,
                builder: (_, _, _) => NumberField(
                  key: const ValueKey('ws-tl-time'),
                  editorKey: const ValueKey('ws-tl-time-words'),
                  value: () => ws.frame.toDouble(),
                  text: (_, _) => ws.timecode(), // The whole text starts selected, so typing replaces it.
                  style: big.copyWith(color: Grey.g100),
                  accent: WindowTokens.accent,
                  allow: null,
                  parse: (said) => parseTimecode(said, ws.frame, WorkspaceController.fps)?.toDouble(),
                  sayOnLeave: false,
                  onType: (to) => onStep(to.round().clamp(0, WorkspaceController.duration) - ws.frame),
                  paint: (_, shown, typing) =>
                      typing ? SizedBox(width: Shape.z(72), child: shown) : Text(ws.timecode(), style: big), // One colour and one weight for the whole time.
                ),
              ),
              SizedBox(width: Shape.s(8)),
              if (roomy) ...[Text('/ ${ws.timecode(WorkspaceController.duration)}', style: TextStyles.value(Grey.g56)), SizedBox(width: Shape.s(10))],
              Chip(label: '${WorkspaceController.fps} fps', look: _readout()),
              SizedBox(width: Shape.s(4)),
              _Tempo(ws: ws),
              SizedBox(width: Shape.s(12)),
              if (mid && layer != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      layerKindChip(layer.kind, tone: layer.tone),
                      SizedBox(width: Shape.s(6)),
                      Flexible(
                        child: FittedBox(
                          // Scale the text down to fit instead of cutting it off.
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            picked > 0 ? '${layer.name}  ·  $picked key${picked == 1 ? '' : 's'}' : '${layer.name}  ·  ${layer.keys.length} keys',
                            style: TextStyles.label(Grey.g76),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              _RoundButton(TimelineGlyphs.minus, key: const ValueKey('ws-tl-zoom-out'), size: Shape.z(22), onTap: () => onZoom(zoom / 1.5)),
              SizedBox(width: Shape.s(4)),
              if (slide) ...[
                MiniSlider(
                  key: const ValueKey('ws-tl-zoom'),
                  values: [math.log(zoom) / math.log(TimelineMetrics.maxZoom)],
                  width: Shape.z(96),
                  step: .001,
                  height: 22,
                  groove: 6,
                  well: WindowTokens.well,
                  fill: Grey.g44,
                  thumb: const Size.square(12),
                  thumbColor: Grey.g91,
                  onChanged: (v) => onZoom(math.pow(TimelineMetrics.maxZoom, v.first).toDouble()),
                ),
                SizedBox(width: Shape.s(4)),
              ],
              _RoundButton(TimelineGlyphs.plus, key: const ValueKey('ws-tl-zoom-in'), size: Shape.z(22), onTap: () => onZoom(zoom * 1.5)),
              SizedBox(width: Shape.s(4)),
              _RoundButton(
                TimelineGlyphs.fit,
                key: const ValueKey('ws-tl-fit'),
                size: Shape.z(22),
                width: Shape.z(46),
                label: 'Fit',
                lit: zoom <= 1.001,
                onTap: () => onZoom(1),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Parses a typed time the way Premiere Pro's timecode field reads it.
///
/// Digits are read from the right as frames, seconds and minutes, so 852, 8:52 and 8.52 all mean 8 seconds 52 frames.
/// A leading + or - makes the time relative to [now] (+30 is 30 frames later). Returns null if [said] is not a time.
int? parseTimecode(String said, int now, int fps) {
  final m = RegExp(r'^\s*([+-]?)([\d:.;]+)\s*$').firstMatch(halfWidth(said));
  if (m == null) return null;
  final parts = m[2]!.split(RegExp(r'[:.;]'));
  final fields = parts.length > 1
      ? [for (final p in parts.reversed) int.tryParse(p) ?? 0]
      : [
          for (var s = parts.single; s.isNotEmpty; s = s.length > 2 ? s.substring(0, s.length - 2) : '')
            int.parse(s.length > 2 ? s.substring(s.length - 2) : s),
        ];
  final f = fields[0] + (fields.length > 1 ? fields[1] * fps : 0) + (fields.length > 2 ? fields[2] * 60 * fps : 0);
  return switch (m[1]) {
    '+' => now + f,
    '-' => now - f,
    _ => f,
  };
}

/// A round icon button that lights up on hover. [on] fills it with the accent colour, [lit] raises it in grey.
class _RoundButton extends StatelessWidget {
  const _RoundButton(this.g, {super.key, this.onTap, this.on = false, this.lit = false, this.size = 24, this.width, this.rest, this.label});
  final TimelineGlyphs g;
  final VoidCallback? onTap;
  final bool on, lit;
  final double size;
  final double? width;
  final Color? rest;
  final String? label;
  @override
  Widget build(BuildContext context) => IconPress(
    (ink) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Glyph(g, size: 11, color: ink),
        if (label case final l?) ...[SizedBox(width: Shape.s(4)), Text(l, style: TextStyles.micro(ink).copyWith(fontWeight: FontWeight.w700))],
      ],
    ),
    onTap: onTap,
    on: on,
    lit: lit,
    size: size,
    width: width,
    rest: const Color(0x00000000), // Flat at rest; the button shows itself on hover.
    ink: rest ?? Grey.g56,
  );
}

/// The project's tempo, shown beside the frame rate as in Ableton Live's Control Bar.
///
/// Clicking it lets the user type a value. Tap sets it from presses made in time with the beat; more presses give a more
/// accurate value (see "Tapping the Tempo" in the Live manual). With no tempo set, no beats are shown.
class _Tempo extends StatefulWidget {
  const _Tempo({required this.ws});
  final WorkspaceController ws;
  @override
  State<_Tempo> createState() => _TempoState();
}

class _TempoState extends State<_Tempo> {
  final _taps = <DateTime>[];
  final _field = GlobalKey<TypedFieldState>();
  bool _typing = false;
  bool _tapping = false; // True while Tap is pressed. Tap takes keyboard focus from the field, so the field stays open until the taps stop.
  Timer? _tapped;

  // Called when editing ends. [said] is the typed text, or null if the user cancelled with Esc.
  void _left(String? said) {
    setState(() => _typing = false);
    final bpm = parseNumber(said ?? '') ?? 0; // An empty field means no tempo.
    if (said != null && bpm != widget.ws.bpm) _set(bpm);
  }

  @override
  void dispose() {
    _tapped?.cancel();
    super.dispose();
  }

  static String _said(double bpm) => bpm == bpm.roundToDouble() ? '${bpm.round()}' : bpm.toStringAsFixed(1);

  void _set(double bpm) {
    final ws = widget.ws;
    ws.after(ws.inside!.later('set', layer: 0, name: 'bpm', number: bpm.clamp(0, 999)), (_, _) => ws.reread());
  }

  void _tap() {
    final now = DateTime.now();
    _tapped?.cancel();
    _tapped = Timer(const Duration(milliseconds: 2500), () {
      _tapping = false;
      if (mounted && _field.currentState?.focused != true) setState(() => _typing = false);
    });
    if (_taps.isNotEmpty && now.difference(_taps.last).inMilliseconds > 2000) _taps.clear();
    _taps.add(now);
    if (_taps.length < 2) return;
    final bpm = (60000 * (_taps.length - 1) / now.difference(_taps.first).inMilliseconds).clamp(20.0, 999.0);
    _field.currentState?.put(_said((bpm * 10).roundToDouble() / 10));
    _set((bpm * 10).roundToDouble() / 10);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws, bpm = ws.bpm;
    if (ws.inside == null) return const SizedBox.shrink();
    if (!_typing) {
      return NakedButton(
        key: const ValueKey('ws-tl-bpm'),
        mouseCursor: SystemMouseCursors.text,
        enableFeedback: false,
        onPressed: () {
          _taps.clear();
          setState(() => _typing = true);
        },
        child: Chip(label: bpm > 0 ? '${_said(bpm)} BPM' : 'BPM', look: _readout()),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const ValueKey('ws-tl-bpm-words'),
          width: Shape.z(42),
          child: TypedField(
            key: _field,
            text: bpm > 0 ? _said(bpm) : '',
            take: true,
            escapes: true,
            hold: () => _tapping,
            style: TextStyles.value(Grey.g95).copyWith(fontSize: TextStyles.px(10.5)),
            cursor: WindowTokens.accent,
            selection: WindowTokens.accent.withValues(alpha: .3),
            onDone: _left,
          ),
        ),
        SizedBox(width: Shape.s(4)),
        Listener(
          onPointerDown: (_) => _tapping = true,
          child: NakedButton(
            key: const ValueKey('ws-tl-bpm-tap'),
            enableFeedback: false,
            onPressed: _tap,
            child: Chip(label: 'Tap', look: _readout(mono: false)),
          ),
        ),
      ],
    );
  }
}

/// Chip style of the header's readouts: well background, Grey.g91 text, and the same corner radius as the buttons.
ChipLook _readout({bool mono = true}) => ChipLook.readout(ink: Grey.g91, size: 10.5, radius: WindowTokens.radius, mono: mono);
