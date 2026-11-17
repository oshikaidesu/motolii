// How many cells fit across a panel, and how wide each is.
// Also the bento packing algorithm, shared between the Colors shelf and the home screen.
import 'dart:math' as math;

import 'package:motolii/skin/window_tokens.dart';

/// How many cells of at least [cell] px fit across [width] with [gap] between them, clamped to [min]..[max].
/// Every grid in the window uses this, so a wider panel gains columns instead of fatter tiles.
int gridColumns(
  double width,
  double cell, {
  double gap = WindowTokens.gutter,
  int min = 1,
  int max = 8,
}) => ((width + gap) / (cell + gap)).floor().clamp(min, max);

/// The width of one of [cols] cells across [width].
double gridCellWidth(
  double width,
  int cols, {
  double gap = WindowTokens.gutter,
}) => (width - gap * (cols - 1)) / cols;

/// A box to pack into a bento grid. [weight] decides the shape: heavier boxes are bigger.
/// [wide] hints that the box prefers a horizontal shape (like a gradient or a banner).
class BentoItem {
  const BentoItem(this.group, this.i, this.weight, {this.wide = false});
  final String group;
  final int i;
  final double weight;
  final bool wide;
}

/// Packs [items] into a grid of [cols] columns, returning (x, y, w, h) in grid cells.
/// Each item's shape is seeded from [seed] and its identity so the layout is stable.
/// Dense auto-placement: each box goes where it first fits from the top left.
List<(int, int, int, int)> bentoPack(
  List<BentoItem> items,
  int cols, [
  int seed = 0,
]) {
  final taken = <int, Set<int>>{}, out = <(int, int, int, int)>[];
  bool free(int x, int y, int w, int h) {
    if (x + w > cols) return false;
    for (var j = y; j < y + h; j++) {
      for (var i = x; i < x + w; i++) {
        if (taken[j]?.contains(i) ?? false) return false;
      }
    }
    return true;
  }

  for (final b in items) {
    var thrown = 0;
    for (var d = 1; d <= seed; d++) {
      if (math.Random(Object.hash(d, b.group, b.i, 7)).nextDouble() < .35) {
        thrown = d;
      }
    }
    final r = math.Random(Object.hash(thrown, b.group, b.i));
    final shapes = b.wide
        ? const [(2, 1), (3, 1), (2, 2)]
        : b.weight >= 1.6
        ? const [(2, 2), (3, 2), (2, 3), (3, 3)]
        : b.weight >= .9
        ? const [(2, 1), (1, 2), (2, 2), (1, 1)]
        : const [(1, 1), (1, 1), (1, 2), (2, 1)];
    final (w0, h) = shapes[r.nextInt(shapes.length)];
    final w = math.min(w0, cols);
    for (var y = 0; ; y++) {
      final x = [
        for (var x = 0; x < cols; x++)
          if (free(x, y, w, h)) x,
      ].firstOrNull;
      if (x == null) continue;
      for (var j = y; j < y + h; j++) {
        taken.putIfAbsent(j, () => {}).addAll([
          for (var i = x; i < x + w; i++) i,
        ]);
      }
      out.add((x, y, w, h));
      break;
    }
  }
  return out;
}
