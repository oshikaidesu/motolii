// The star button, and the file that stores which effects are starred.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/media.dart' show drawStar, glyph;
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// The star button that adds an item to Starred. It is shown on hover, on the selected row, or when set.
class DockStar extends StatelessWidget {
  const DockStar({super.key, required this.on, required this.onTap, this.ink});
  final bool on;
  final VoidCallback onTap;
  final Color? ink;
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    builder: (context, h) {
      final col = ink ?? (on ? Pop.keyDot : (h ? Grey.g91 : Grey.g56));
      return SizedBox(
        width: Shape.z(20),
        height: Shape.z(20),
        child: Center(child: glyph(11, (cv, s) => drawStar(cv, s, col, on), [col, on])),
      );
    },
  );
}
