import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// What the Inspector shows when nothing is selected.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), ed = const InspectorHairline();
    // One plain muted line, with no controls and no stale values.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Shape.s(4), bottom: Shape.s(8)),
          child: Text(
            'Nothing selected',
            style: TextStyles.label(Grey.g56).copyWith(height: 1.4),
          ),
        ),
        // With nothing selected, nothing is shown. After Effects' Effect Controls belongs to a layer and Alight Motion shows none.
        // The stage's own settings appear only when asked for, as in Apple Motion's Project pane.
        Pressable(
          key: const ValueKey('stage-settings'),
          onTap: () =>
              x.doc.flag('stage.open', !(x.doc.flags['stage.open'] ?? false)),
          builder: (_, h) => Container(
            height: InspectorSkin.cell,
            margin: EdgeInsets.only(bottom: InspectorSkin.gap),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: h ? Grey.g20 : InspectorSkin.well,
              borderRadius: BorderRadius.all(Shape.r(6)),
            ),
            child: Text(
              'Stage settings',
              style: TextStyles.label(h ? Grey.g95 : Grey.g76),
            ),
          ),
        ),
        if (x.doc.flags['stage.open'] ?? false)
          // The stage's own cards, holding the values for the whole image.
          for (final c in x.doc.cards) ValuesCard(c),
        SizedBox(height: Shape.s(1)),
        Container(height: 1, color: ed.rule),
      ],
    );
  }
}
