// What a shelf shows when it has nothing to show.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';

/// What a shelf shows when the search finds nothing, or when the shelf is empty.
/// A centered placeholder: a muted search glyph when the user is searching, and one soft line of text under it. Picks
/// up from Apple Music / Spotify's "no results" layout — more human than a plain mid-grey sentence.
class EmptyShelf extends StatelessWidget {
  const EmptyShelf(this.query, {super.key, this.said});
  final String query;

  /// Shown instead of the default message when nothing is typed: what is empty here and what to do.
  final String? said;
  @override
  Widget build(BuildContext context) {
    final searching = query.isNotEmpty;
    return Padding(
      padding: EdgeInsets.all(Shape.s(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glyph(
            searching ? AppGlyphs.search : AppGlyphs.folder,
            size: Shape.z(24),
            color: Grey.g44,
          ),
          SizedBox(height: Shape.s(10)),
          Text(
            said ?? 'Nothing matches “$query”',
            textAlign: TextAlign.center,
            style: TextStyles.label(Grey.g63),
          ),
        ],
      ),
    );
  }
}
