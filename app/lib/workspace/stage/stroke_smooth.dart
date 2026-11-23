// Freehand stroke stabilization and corner-preserving smoothing for Brush & Pen tools.
import 'dart:ui' show Offset;

import 'package:perfect_freehand/perfect_freehand.dart' show StrokeOptions;

/// Smoothing level labels shown in the Stage options strip.
const strokeSmoothLabels = ['Off', 'Low', 'Med', 'High'];

/// Stabilizes freehand pointer strokes while preserving endpoints and intentional sharp corners.
abstract final class StrokeStabilizer {
  /// Live exponential-moving-average stabilization applied while dragging so the preview
  /// feels calm and matches the committed curve.
  static List<Offset> liveSmooth(List<Offset> raw, int level) {
    final lv = level.clamp(0, 3);
    if (lv == 0 || raw.length < 3) return raw;
    // Lower alpha = stronger lag / stabilization during live draw.
    final alpha = const [1.0, 0.58, 0.36, 0.20][lv];
    final out = <Offset>[raw.first];
    var cur = raw.first;
    for (var i = 1; i < raw.length - 1; i++) {
      final p = raw[i];
      cur = Offset(
        cur.dx + (p.dx - cur.dx) * alpha,
        cur.dy + (p.dy - cur.dy) * alpha,
      );
      out.add(cur);
    }
    // Keep the final pointer position attached to the cursor tip.
    out.add(raw.last);
    return out;
  }

  /// Corner-preserving bidirectional Gaussian smoothing applied on stroke release.
  /// Endpoints are pinned and sharp direction changes (> ~70 deg) resist flattening.
  static List<Offset> finishSmooth(List<Offset> raw, int level) {
    final lv = level.clamp(0, 3);
    if (lv == 0 || raw.length < 3) return raw;
    // First remove microscopic duplicate jitters, then run multi-pass corner-aware smoothing.
    final minStep = const [0.0, 1.2, 2.2, 3.6][lv];
    var pts = _dedupe(raw, minStep);
    if (pts.length < 3) return raw;

    final passes = const [0, 2, 5, 10][lv];
    final weight = const [0.0, 0.38, 0.52, 0.65][lv];
    for (var pass = 0; pass < passes; pass++) {
      final next = <Offset>[pts.first];
      for (var i = 1; i < pts.length - 1; i++) {
        final a = pts[i - 1], b = pts[i], c = pts[i + 1];
        // Measure turn over a ±3-sample window so micro hand-tremor zigzags get
        // smoothed away while true intentional corners remain sharp.
        final prevMacro = pts[(i - 3).clamp(0, i - 1)];
        final nextMacro = pts[(i + 3).clamp(i + 1, pts.length - 1)];
        final cornerKeep = _cornerResistance(prevMacro, b, nextMacro);
        final w = weight * (1.0 - cornerKeep);
        final avgX = 0.25 * a.dx + 0.5 * b.dx + 0.25 * c.dx;
        final avgY = 0.25 * a.dy + 0.5 * b.dy + 0.25 * c.dy;
        next.add(Offset(b.dx + (avgX - b.dx) * w, b.dy + (avgY - b.dy) * w));
      }
      next.add(pts.last);
      pts = next;
    }
    return pts;
  }

  /// `perfect_freehand` options matched to [level] so brush ribbons smooth consistently.
  static StrokeOptions brushOptions(double size, int level) {
    final lv = level.clamp(0, 3);
    return StrokeOptions(
      size: size,
      smoothing: const [0.0, 0.45, 0.72, 0.92][lv],
      streamline: const [0.0, 0.35, 0.58, 0.80][lv],
      simulatePressure: true,
      isComplete: true,
    );
  }

  /// Screen-pixel fitting tolerance handed to `curve-fit-nd` for Pen freehand scribbles.
  static double curveErrorPx(int level) =>
      const [2.5, 5.5, 10.0, 16.0][level.clamp(0, 3)];

  static List<Offset> _dedupe(List<Offset> raw, double minStep) {
    if (minStep <= 0) return raw;
    final out = <Offset>[raw.first];
    for (var i = 1; i < raw.length - 1; i++) {
      if ((raw[i] - out.last).distance >= minStep) out.add(raw[i]);
    }
    out.add(raw.last);
    return out;
  }

  /// Returns 0 for gentle curves and approaches 1 for intentional sharp corners (>= ~60° turn).
  static double _cornerResistance(Offset a, Offset b, Offset c) {
    final v1 = b - a, v2 = c - b;
    final l1 = v1.distance, l2 = v2.distance;
    if (l1 < 1e-3 || l2 < 1e-3) return 0.0;
    final cosAngle = ((v1.dx * v2.dx + v1.dy * v2.dy) / (l1 * l2)).clamp(
      -1.0,
      1.0,
    );
    // Preserve intentional corners (>= ~60 deg turn, cosAngle <= 0.5) strongly;
    // gentle bends (cosAngle > 0.5) get full smoothing.
    if (cosAngle >= 0.5) return 0.0;
    return ((0.5 - cosAngle) / 0.5).clamp(0.0, 0.96);
  }
}
