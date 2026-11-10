// A shelf's sections laid out in as many columns as fit.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/grid_columns.dart';

/// A shelf's sections as cards in one column while the shelf is narrow.
///
/// As the shelf widens, columns of at least 300 px stand side by side, and each section goes to the shortest column so far.
/// [weights] estimate the section heights, in rows.
class ShelfMasonry extends StatelessWidget {
  const ShelfMasonry({
    super.key,
    required this.children,
    required this.weights,
  });
  final List<Widget> children;
  final List<double> weights;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = gridColumns(box.maxWidth, 300, max: 4);
      if (n == 1) return ListView(padding: EdgeInsets.zero, children: children);
      final cols = List.generate(n, (_) => <Widget>[]), h = List.filled(n, 0.0);
      for (final (i, w) in children.indexed) {
        var k = 0;
        for (var j = 1; j < n; j++) {
          if (h[j] < h[k]) k = j;
        }
        cols[k].add(w);
        h[k] += weights[i];
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, col) in cols.indexed) ...[
                if (i > 0) const SizedBox(width: WindowTokens.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: col,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}
