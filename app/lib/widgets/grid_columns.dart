// How many cells fit across a panel, and how wide each is.
import 'package:motolii/skin/window_tokens.dart';

/// How many cells of at least [cell] px fit across [width] with [gap] between them, clamped to [min]..[max].
/// Every grid in the window uses this, so a wider panel gains columns instead of fatter tiles.
int wsCols(double width, double cell, {double gap = WindowTokens.gutter, int min = 1, int max = 8}) => ((width + gap) / (cell + gap)).floor().clamp(min, max);

/// The width of one of [cols] cells across [width].
double wsCell(double width, int cols, {double gap = WindowTokens.gutter}) => (width - gap * (cols - 1)) / cols;
