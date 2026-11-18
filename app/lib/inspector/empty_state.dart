import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// What the Inspector shows when nothing is selected.
/// A centered hint tells the user why the inspector is empty (After Effects' Effect Controls belongs to a layer, and
/// Alight Motion shows none). Below it, a soft "Stage settings" toggle reveals the stage's own cards (Apple Motion's
/// Project pane does the same).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context),
        ed = const InspectorHairline(),
        open = x.doc.flags['stage.open'] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A quiet placeholder: inspector glyph on top, two short lines of muted text underneath. Light enough that it
        // never competes with real cards when they come in.
        Padding(
          padding: EdgeInsets.fromLTRB(
            Shape.s(12),
            Shape.s(28),
            Shape.s(12),
            Shape.s(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Glyph(AppGlyphs.inspector, size: Shape.z(28), color: Grey.g44),
              SizedBox(height: Shape.s(10)),
              Text(
                'Nothing selected',
                style: TextStyles.name(Grey.g76).bold,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Shape.s(4)),
              Text(
                'Pick a layer to see its values.',
                style: TextStyles.label(Grey.g56),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Pressable(
          key: const ValueKey('stage-settings'),
          onTap: () => x.doc.flag('stage.open', !open),
          builder: (_, h) => Container(
            height: InspectorSkin.cell,
            margin: EdgeInsets.only(bottom: InspectorSkin.gap),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
            decoration: BoxDecoration(
              color: h ? Grey.g20 : InspectorSkin.well,
              borderRadius: Shape.round(6),
            ),
            child: Row(
              children: [
                Text(
                  'Stage settings',
                  style: TextStyles.label(h ? Grey.g95 : Grey.g76),
                ),
                const Spacer(),
                // The chevron rotates a quarter turn down when the panel is open, so the control reads as "expandable" at a glance.
                RotatedBox(
                  quarterTurns: open ? 1 : 0,
                  child: Glyph(
                    AppGlyphs.chevron,
                    size: Shape.z(10),
                    color: h ? Grey.g91 : Grey.g56,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open)
          // The stage's own cards, holding the values for the whole image.
          for (final c in x.doc.cards) ValuesCard(c),
        SizedBox(height: Shape.s(1)),
        Container(height: 1, color: ed.rule),
      ],
    );
  }
}
