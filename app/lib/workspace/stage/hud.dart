// The stage's readout pill: the zoom and the pointer's position.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';

/// The pill at the bottom-left of the viewport: the zoom and the pointer position in composition pixels.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.scale, required this.cursor});
  final double scale;
  final ValueNotifier<Offset?> cursor;
  @override
  Widget build(BuildContext context) => Container(
    height: StageTokens.hud,
    padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
    decoration: BoxDecoration(
      color: WindowTokens.card,
      borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${(scale * 100).round()}%', style: TextStyles.value(Grey.g95)),
        Container(
          width: 1,
          height: Shape.z(10),
          margin: EdgeInsets.symmetric(horizontal: Shape.s(8)),
          color: WindowTokens.line,
        ),
        ValueListenableBuilder<Offset?>(
          valueListenable: cursor,
          builder: (_, p, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (l, n) in [('X ', p?.dx), ('Y ', p?.dy)]) ...[
                Text(l, style: TextStyles.micro(Grey.g56)),
                SizedBox(
                  width: Shape.z(34),
                  child: Text(
                    n == null ? '—' : '${n.round()}',
                    style: TextStyles.value(n == null ? Grey.g56 : Grey.g91),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
