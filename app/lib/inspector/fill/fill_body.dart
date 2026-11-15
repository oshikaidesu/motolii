// The Fill card's inside: fill colour, gradient controls and the per-stroke list.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// The Fill card's inside (see host_cards.dart).
///
/// Gradient controls are shown inline when gradient is not the first option.
/// Absorbed Stroke cards appear as removable rows below the fill section.
class FillBody extends StatelessWidget {
  const FillBody(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {
    'fill',
    'fill_media',
    'gradient',
    'gradient_angle',
    'gradient_scale',
    'gradient_spread',
  };

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;

    final fillParams = [
      for (final p in card.params)
        if (p.id == 'fill' || p.id == 'fill_media') p,
    ];
    final gradParam = [
      for (final p in card.params)
        if (p.id == 'gradient') p,
    ];
    final gradSubParams = [
      for (final p in card.params)
        if (p.id == 'gradient_angle' ||
            p.id == 'gradient_scale' ||
            p.id == 'gradient_spread')
          p,
    ];
    final strokeCards = [
      for (final c in doc.cards)
        if (c.name == 'Stroke') c,
    ];

    return ListenableBuilder(
      listenable: doc.watch('v_gradient'),
      builder: (context, _) {
        final hasGradient = (doc.get('v_gradient') ?? 0) > 0.5;
        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fillParams.isNotEmpty) ParameterGrid(fillParams),
              if (gradParam.isNotEmpty) ParameterGrid(gradParam),
              if (hasGradient && gradSubParams.isNotEmpty)
                ParameterGrid(gradSubParams),
              for (final sc in strokeCards) _StrokeRow(sc, doc: doc),
              if (doc.actions.onAddStroke != null)
                _AddStrokeButton(onTap: doc.actions.onAddStroke!),
            ],
          ),
        );
      },
    );
  }
}

class _StrokeRow extends StatelessWidget {
  const _StrokeRow(this.card, {required this.doc});
  final CardDeclaration card;
  final InspectorValues doc;

  @override
  Widget build(BuildContext context) {
    final remove = doc.actions.onCardRemove;
    return Padding(
      padding: EdgeInsets.only(top: InspectorSkin.tileGap),
      child: Container(
        decoration: BoxDecoration(
          color: Grey.g10,
          borderRadius: BorderRadius.all(Shape.r(6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (remove != null)
              Align(
                alignment: Alignment.centerRight,
                child: Pressable(
                  onTap: () =>
                      remove(card.name, [for (final p in card.params) p.id]),
                  builder: (_, hot) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Shape.s(8),
                      vertical: Shape.s(4),
                    ),
                    child: Text(
                      '×',
                      style: TextStyles.label(hot ? Grey.g76 : Grey.g44),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Shape.s(6),
                remove == null ? Shape.s(6) : 0,
                Shape.s(6),
                Shape.s(6),
              ),
              child: ParameterGrid(card.params),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStrokeButton extends StatelessWidget {
  const _AddStrokeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: InspectorSkin.tileGap),
    child: Pressable(
      onTap: onTap,
      builder: (_, hot) => Container(
        height: Shape.z(28),
        decoration: BoxDecoration(
          color: hot ? Grey.g15 : null,
          borderRadius: BorderRadius.all(Shape.r(6)),
          border: Border.all(
            color: Grey.g20,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '+ Stroke',
          style: TextStyles.label(hot ? Grey.g76 : Grey.g44),
        ),
      ),
    ),
  );
}
