// A colour for each item of a shelf's map, by where it lies.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:material_color_utilities/material_color_utilities.dart'
    show Cam16;

/// A colour for each item, by where it lies on the map, following DataMapPlot
/// (TutteInstitute/datamapplot 45a0123, datamapplot/palette_handling.py; MIT).
///
/// This is palette_from_datamap with every item as its own label, as its interactive plot does (create_plots.py):
/// - The hue goes round the map's middle by angle, spaced by distance from the middle (radius_weight_power 1).
/// - Chroma runs from 20 to 90 and lightness from 80 down to palette_min_lightness, outward from the middle among the
///   items in the same sector (theta_range π/16).
/// - The result goes through pastel_palette (degree 2), as DataMapPlot's dark mode does.
///
/// palette_min_lightness is 30, not DataMapPlot's 10: at 10 the outermost 45 of 328 fonts fell below the 3:1 contrast
/// that WCAG 2.1 (1.4.11) requires for graphics against the map's background. JCh comes from CAM16
/// (material_color_utilities), where colorspacious uses its predecessor CIECAM02.
Map<String, Color> mapPalette(Map<String, Offset> at) {
  final ids = at.keys.toList(), n = ids.length;
  if (n == 0) return const {};
  final xs = [for (final id in ids) at[id]!.dx],
      ys = [
        for (final id in ids) -at[id]!.dy,
      ]; // y points up, as in DataMapPlot.
  final cx = (xs.reduce(math.min) + xs.reduce(math.max)) / 2,
      cy = (ys.reduce(math.min) + ys.reduce(math.max)) / 2;
  final r = [
    for (var i = 0; i < n; i++)
      math.sqrt((xs[i] - cx) * (xs[i] - cx) + (ys[i] - cy) * (ys[i] - cy)),
  ];
  final t = [for (var i = 0; i < n; i++) math.atan2(ys[i] - cy, xs[i] - cx)];
  double interp(double x, List<double> xp, List<double> fp) {
    // Same as numpy's interp: the ends are held.
    if (x <= xp.first) return fp.first;
    if (x >= xp.last) return fp.last;
    var k = 1;
    while (xp[k] < x) {
      k++;
    }
    return xp[k] == xp[k - 1]
        ? fp[k]
        : fp[k - 1] +
              (fp[k] - fp[k - 1]) * (x - xp[k - 1]) / (xp[k] - xp[k - 1]);
  }

  final order = List.generate(n, (i) => i)
    ..sort((a, b) => t[a].compareTo(t[b]));
  var sum = 0.0;
  final base = [for (final i in order) sum += r[i]],
      byT = [for (final i in order) t[i]];
  final weights = [for (final b in base) sum > 0 ? b / sum : 0.0];
  final hue = [
    for (var i = 0; i < n; i++) interp(t[i], byT, weights) * 360 % 360,
  ];
  final sectors = n < 256
      ? t
      : [for (var k = 0; k < 256; k++) -math.pi + 2 * math.pi * k / 256];
  const range = math.pi / 16;
  final radii = [
    for (final theta in sectors)
      () {
        for (var s = 0; s < 16; s++) {
          final spread = 2 * range + (math.pi - 2 * range) * s / 15;
          var hi = theta + spread / 2, lo = theta - spread / 2;
          if (hi > math.pi) hi -= 2 * math.pi;
          if (lo < -math.pi) lo += 2 * math.pi;
          final wraps = lo > 0 && hi < 0;
          final some = [
            for (var i = 0; i < n; i++)
              if (wraps ? (t[i] > lo || t[i] < hi) : (t[i] > lo && t[i] < hi))
                r[i],
          ]..sort();
          if (some.isNotEmpty) return some;
        }
        return [...r]..sort();
      }(),
  ];
  final raw = <int>[];
  for (var i = 0; i < n; i++) {
    var j = 0;
    for (var k = 1; k < sectors.length; k++) {
      if ((sectors[k] - t[i]).abs() < (sectors[j] - t[i]).abs()) j = k;
    }
    final ref = radii[j], m = ref.length;
    final chroma = interp(r[i], ref, [
      for (var k = 0; k < m; k++) 20 + 70 * k / m,
    ]);
    final lightness = interp(r[i], ref, [
      for (var k = 0; k < m; k++) 80 - (80 - 30) * k / m,
    ]);
    raw.add(Cam16.fromJch(lightness, chroma, hue[i]).toInt());
  }
  final jch = [for (final c in raw) Cam16.fromInt(c)];
  final leastJ = jch.map((c) => c.j).reduce(math.min),
      leastC = jch.map((c) => c.chroma).reduce(math.min);
  return {
    for (final (i, c) in jch.indexed)
      ids[i]: Color(
        Cam16.fromJch(
          (c.j * math.sqrt2).clamp(leastJ, 100),
          (c.chroma / 2).clamp(math.min(10 / 2, leastC), 50),
          c.hue,
        ).toInt(),
      ),
  };
}
