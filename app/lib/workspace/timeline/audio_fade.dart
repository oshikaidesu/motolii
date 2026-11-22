// Audio fade-in / fade-out helpers backed directly by a layer's `volume` keyframes
// (single source of truth: no separate fade property is duplicated in the document).
import 'dart:math' as math;

import 'package:motolii/workspace/state/layer.dart';

/// Resolved fade lengths (in frames) and sustain volume of an audio-bearing bar.
typedef AudioFade = ({int fadeInF, int fadeOutF, double peak});

/// Whether [l] is a video or sound layer that can carry audio fades on its bar.
bool layerHasAudio(Layer l) =>
    l.kind == LayerKind.audio || (l.media != null && !l.media!.still);

/// Reads fade-in and fade-out durations from [l]'s `volume` keyframe lane.
AudioFade readAudioFade(
  Layer l, {
  required int fps,
  double fallbackPeak = 1.0,
}) {
  final defaultPeak = fallbackPeak > 0.01 ? fallbackPeak : 1.0;
  final lane = l.lanes.where((a) => a.name == 'volume').firstOrNull;
  if (lane == null ||
      lane.at.length < 2 ||
      lane.values.length != lane.at.length) {
    return (fadeInF: 0, fadeOutF: 0, peak: defaultPeak);
  }
  final pts = [
    for (var i = 0; i < lane.at.length; i++)
      ((lane.at[i] * fps).round(), lane.values[i]),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final positive = [
    for (final p in pts)
      if (p.$2 > 0.01) p.$2,
  ];
  final peak = positive.isEmpty ? defaultPeak : positive.first;

  var fadeInF = 0;
  if ((pts.first.$1 - l.inF).abs() <= 1 &&
      pts.first.$2 <= 0.01 &&
      pts[1].$1 > l.inF &&
      pts[1].$1 <= l.outF &&
      pts[1].$2 > 0.01) {
    fadeInF = pts[1].$1 - l.inF;
  }

  var fadeOutF = 0;
  final last = pts.last, prev = pts[pts.length - 2];
  if ((last.$1 - l.outF).abs() <= 1 &&
      last.$2 <= 0.01 &&
      prev.$1 < l.outF &&
      prev.$1 >= l.inF &&
      prev.$2 > 0.01) {
    fadeOutF = l.outF - prev.$1;
  }

  final span = math.max(0, l.outF - l.inF);
  fadeInF = fadeInF.clamp(0, span);
  fadeOutF = fadeOutF.clamp(0, span - fadeInF);
  return (fadeInF: fadeInF, fadeOutF: fadeOutF, peak: peak);
}

/// Computes the `volume` keyframes `(seconds, level)` representing [fadeInF] and
/// [fadeOutF] over `[inF, outF]`. Returns empty when both fades are zero.
List<(double seconds, double value)> buildAudioFadeKeys({
  required int inF,
  required int outF,
  required int fadeInF,
  required int fadeOutF,
  required double peak,
  required int fps,
}) {
  final span = math.max(1, outF - inF);
  final fi = fadeInF.clamp(0, span);
  final fo = fadeOutF.clamp(0, span - fi);
  if (fi == 0 && fo == 0) return const [];
  final level = peak > 0.01 ? peak : 1.0;
  final pts = <(int, double)>[];
  if (fi > 0) {
    pts.add((inF, 0.0));
    pts.add((inF + fi, level));
  }
  if (fo > 0) {
    final startOut = outF - fo;
    if (pts.isEmpty || pts.last.$1 != startOut) {
      pts.add((startOut, level));
    }
    pts.add((outF, 0.0));
  }
  return [for (final (f, v) in pts) (f / fps, v)];
}
