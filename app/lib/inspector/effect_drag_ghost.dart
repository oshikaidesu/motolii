import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_badges.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// The folded card head that follows the pointer while an effect is dragged.
class EffectDragGhost extends StatelessWidget {
  const EffectDragGhost(this.fx, {super.key});
  final CardDeclaration fx;
  @override
  Widget build(BuildContext context) => Container(
    width: Shape.z(220),
    height: InspectorSkin.titleH + InspectorSkin.insetY * 2,
    padding: EdgeInsets.symmetric(horizontal: InspectorSkin.inset),
    decoration: BoxDecoration(color: Grey.g20, boxShadow: WindowTokens.lift),
    child: Row(
      children: [
        layerBadge(fx.tone),
        SizedBox(width: Shape.s(6)),
        Text(
          fx.name,
          style: TextStyles.title(
            Grey.g95,
          ).copyWith(fontSize: TextStyles.px(12), fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
