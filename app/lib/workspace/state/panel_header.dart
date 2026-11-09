// Part of state.dart: a panel's header and the panel round it.
part of 'state.dart';

/// A panel: a square tile of [WsT.body] that clips what it holds.
class WsPanel extends StatelessWidget {
  const WsPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRect(
    child: ColoredBox(color: WsT.body, child: child),
  );
}

/// How many cells of at least [cell] px fit across [width] with [gap] between them, kept within [min]..[max].
/// Every grid in the window reads this, so a pane made wider gains columns instead of fatter tiles.
int wsCols(double width, double cell, {double gap = WsT.gutter, int min = 1, int max = 8}) => ((width + gap) / (cell + gap)).floor().clamp(min, max);

/// The width of one of [cols] cells across [width].
double wsCell(double width, int cols, {double gap = WsT.gutter}) => (width - gap * (cols - 1)) / cols;
