// The timeline's ruler: work-area band, time ticks, beats, retimed ends and marker flags.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart'
    show markerFlagRoom;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/timeline_painters.dart'
    show fineTickSpacing, majorTickSpacing;
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

// ---------------------------------------------------------------- ruler

/// Paints the ruler: work-area band, time ticks, beats, retimed ends and marker flags.
class TimelineRulerPainter extends CustomPainter {
  const TimelineRulerPainter({
    required this.view,
    required this.fps,
    required this.workIn,
    required this.workOut,
    required this.markers,
    this.tempo,
    this.markColors = const {},
    this.beats = const [],
    this.retimed = const [],
  });
  final TimelineView view;
  final int fps, workIn, workOut;
  final List<(int, String)> markers;
  final Map<int, Color>
  markColors; // A marker's colour by its frame, if it has one.

  /// Frames where the videos' sound has a beat: a short tick each at the ruler's foot.
  final List<int> beats;

  /// The project's own beats: a tick each, taller where a bar begins.
  final Beats? tempo;

  /// Frames of the selected element's end of intro and start of outro: small yellow marks at the ruler's top, as in Alight Motion.
  final List<int> retimed;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint(), end = view.x(WorkspaceController.duration);
    c.drawRect(Offset.zero & s, p..color = Grey.g10);
    c.drawRect(
      Rect.fromLTRB(0, 0, s.width, TimelineMetrics.band),
      p..color = Grey.g07,
    );
    if (end < s.width) {
      c.drawRect(
        Rect.fromLTRB(end, TimelineMetrics.band, s.width, s.height),
        p..color = Grey.g07,
      );
    }

    final a = view.x(workIn), b = view.x(workOut);
    c.drawRRect(
      RRect.fromLTRBR(a, 2, b, TimelineMetrics.band - 1, Shape.r(3)),
      p..color = Grey.g38,
    );
    for (final x in [a, b - 4]) {
      c.drawRRect(
        RRect.fromLTRBR(x, 1, x + 4, TimelineMetrics.band, Shape.r(2)),
        p..color = Grey.g76,
      );
    }

    final mj = majorTickSpacing(view.pixelsPerFrame, fps),
        fn = fineTickSpacing(view.pixelsPerFrame, fps, mj),
        bottom = s.height - 1;
    for (final f in beats) {
      final x = view.x(f).roundToDouble();
      if (x >= 0 && x <= s.width) {
        c.drawRect(
          Rect.fromLTWH(x, bottom - 7, 2, 7),
          p..color = WindowTokens.toneAudio,
        );
      }
    }
    if (tempo case final b?) {
      for (final (f, bar) in b.between(
        view.scroll,
        view.scroll + s.width / view.pixelsPerFrame,
      )) {
        if (bar || b.every * view.pixelsPerFrame >= 8) {
          c.drawRect(
            Rect.fromLTWH(
              view.x(f).roundToDouble(),
              bottom - (bar ? 11 : 6),
              1,
              bar ? 11 : 6,
            ),
            p..color = bar ? WindowTokens.accent : Grey.g56,
          );
        }
      }
    }
    for (final f in retimed) {
      final x = view.x(f).roundToDouble();
      if (x >= -4 && x <= s.width + 4) {
        c.drawPath(
          Path()
            ..moveTo(x - 4, 0)
            ..lineTo(x + 4, 0)
            ..lineTo(x, 6)
            ..close(),
          p..color = WindowTokens.toneMark,
        );
      }
    }
    final flags = <(Rect, TextPainter, Color)>[];
    final xs = [for (final (f, _) in markers) view.x(f).roundToDouble()];
    for (final (f, name) in markers) {
      final x = view.x(f).roundToDouble();
      if (x < -60 || x > s.width) continue;
      final t = lineText(
        name,
        TextStyles.micro(Grey.g13).copyWith(fontWeight: FontWeight.w700),
      );
      flags.add((
        Rect.fromLTWH(
          x,
          TimelineMetrics.band + 2,
          markerFlagRoom(name, x, xs),
          12,
        ),
        t,
        markColors[f] ?? WindowTokens.toneText,
      ));
    }
    if (view.pixelsPerFrame >= 3) {
      final f0 = view.scroll.floor();
      for (var f = math.max(0, f0); f <= WorkspaceController.duration; f++) {
        final x = view.x(f).roundToDouble();
        if (x > s.width) break;
        if (f % fn != 0) {
          c.drawRect(Rect.fromLTWH(x, bottom - 3, 1, 3), p..color = Grey.g26);
        }
      }
    }
    final f0 = (view.scroll / fn).floor() * fn;
    for (
      var f = math.max(0.0, f0);
      f <= WorkspaceController.duration;
      f += fn
    ) {
      final x = view.x(f).roundToDouble();
      if (x > s.width) break;
      final isMajor = f % mj == 0;
      c.drawRect(
        Rect.fromLTWH(x, bottom - (isMajor ? 9 : 5), 1, isMajor ? 9 : 5),
        p..color = isMajor ? Grey.g63 : Grey.g44,
      );
      if (isMajor) {
        if (flags.any(
          (m) => m.$1
              .inflate(3)
              .overlaps(Rect.fromLTWH(x + 3, TimelineMetrics.band + 2, 24, 12)),
        )) {
          continue;
        }
        final sec = f ~/ fps, fr = (f % fps).round();
        final t = lineText(
          mj >= fps ? '${sec}s' : '$sec:${fr.toString().padLeft(2, '0')}',
          TextStyles.value(Grey.g76).copyWith(fontSize: TextStyles.px(10)),
        );
        t.paint(c, Offset(x + 3, TimelineMetrics.band + 3));
        t.dispose();
      }
    }

    for (final (r, t, ink) in flags) {
      final x = r.left;
      c.drawPath(
        Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right - 3, r.center.dy)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close(),
        p..color = ink,
      );
      c.drawRect(
        Rect.fromLTWH(x, r.bottom, 1, bottom - r.bottom),
        p..color = ink,
      );
      c.save();
      c.clipRect(
        Rect.fromLTRB(r.left, r.top, r.right - 3, r.bottom),
      ); // Cut the name at the end of its flag.
      t.paint(c, Offset(r.left + 3, r.center.dy - t.height / 2));
      c.restore();
      t.dispose();
    }
    c.drawRect(
      Rect.fromLTWH(0, bottom, s.width, 1),
      p..color = WindowTokens.line,
    );
  }

  @override
  bool shouldRepaint(TimelineRulerPainter o) =>
      o.view != view ||
      o.fps != fps ||
      o.workIn != workIn ||
      o.workOut != workOut ||
      o.markers != markers ||
      !mapEquals(o.markColors, markColors) ||
      !identical(o.beats, beats);
}
