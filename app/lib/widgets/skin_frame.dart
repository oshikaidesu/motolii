import 'package:flutter/widgets.dart';

import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/widgets/media.dart' show Draw;

/// A part's frame from the skin: `frame.<name>.svg` stretched around [child].
///
/// While [hover] is true, `frame.<name>.hover.svg` is used instead when the skin has it.
/// Without either picture, [usual] is the decoration.
class SkinFrame extends StatelessWidget {
  const SkinFrame(
    this.name, {
    super.key,
    this.hover = false,
    required this.usual,
    required this.child,
  });

  /// The part name, as in `frame.<name>.svg`.
  final String name;

  /// Whether the pointer is over the part.
  final bool hover;

  /// The decoration used when the skin has no frame for this part.
  final Decoration usual;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final n = [
      if (hover) 'frame.$name.hover',
      'frame.$name',
    ].where(SkinParts.has).firstOrNull;
    return n == null
        ? DecoratedBox(decoration: usual, child: child)
        : CustomPaint(
            painter: Draw((c, s) => SkinParts.frame(c, Offset.zero & s, n), n),
            child: child,
          );
  }
}
