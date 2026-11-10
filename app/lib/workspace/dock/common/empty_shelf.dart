// What a shelf shows when it has nothing to show.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// What a shelf shows when the search finds nothing, or when the shelf is empty.
class EmptyShelf extends StatelessWidget {
  const EmptyShelf(this.query, {super.key, this.said});
  final String query;

  /// Shown instead of the default message when nothing is typed: what is empty here and what to do.
  final String? said;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(24)),
    child: Text(
      said ?? 'Nothing matches “$query”',
      textAlign: TextAlign.center,
      style: TextStyles.label(Grey.g63),
    ),
  );
}
