// Slim OpenType feature chip strip (`v_font_features`) for the Text card.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_meta.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Slim chip strip for OpenType features (`v_font_features`): shows quick toggles
/// for features actually present in the font, preserves arbitrary user tokens,
/// and lets users add any raw OpenType tag via `+`.
class TextFeaturesStrip extends StatefulWidget {
  const TextFeaturesStrip({
    required this.doc,
    required this.supported,
    super.key,
  });

  final InspectorValues doc;
  final Set<String> supported;

  @override
  State<TextFeaturesStrip> createState() => _TextFeaturesStripState();
}

class _TextFeaturesStripState extends State<TextFeaturesStrip> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.doc.strings['v_font_features'] ?? '';
    final activeTokens = parseFeatureTokens(raw);
    final activeByTag = {for (final t in activeTokens) featureTagOf(t): t};
    final quick = [
      for (final tag in otFeatureDescriptions.keys)
        if (widget.supported.contains(tag)) tag,
    ];
    final custom = [
      for (final t in activeTokens)
        if (!quick.contains(featureTagOf(t))) t,
    ];
    if (quick.isEmpty && custom.isEmpty && !_adding) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: InspectorSkin.tileGap),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(7),
          vertical: Shape.s(4),
        ),
        decoration: BoxDecoration(
          color: InspectorSkin.well,
          borderRadius: Shape.round(6),
        ),
        child: Wrap(
          spacing: Shape.s(4),
          runSpacing: Shape.s(4),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('OT', style: TextStyles.micro(Grey.g56)),
            for (final tag in quick)
              _FeatureChip(
                key: ValueKey('text:ot:$tag'),
                label: activeByTag[tag] ?? tag,
                tip: otFeatureDescriptions[tag] ?? tag,
                active: activeByTag.containsKey(tag),
                onTap: () => widget.doc.str(
                  'v_font_features',
                  toggleFeatureToken(raw, tag),
                ),
              ),
            for (final tok in custom)
              _FeatureChip(
                key: ValueKey('text:ot:${featureTagOf(tok)}'),
                label: tok,
                tip: 'Remove $tok',
                active: true,
                onTap: () => widget.doc.str(
                  'v_font_features',
                  toggleFeatureToken(raw, featureTagOf(tok)),
                ),
              ),
            if (_adding)
              SizedBox(
                width: Shape.z(64),
                height: Shape.z(18),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
                  decoration: BoxDecoration(
                    color: Grey.g07,
                    borderRadius: Shape.round(4),
                    border: Border.all(
                      color: Accent.fill.withValues(alpha: 0.6),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TypedField(
                    key: const ValueKey('text:ot:input'),
                    text: '',
                    standing: true,
                    style: TextStyles.micro(Grey.g95),
                    cursor: Grey.g95,
                    backgroundCursor: Grey.g20,
                    selection: Role.selected.withValues(alpha: 0.4),
                    onDone: (said) {
                      if (said != null && said.trim().isNotEmpty) {
                        widget.doc.str(
                          'v_font_features',
                          addFeatureToken(raw, said),
                        );
                      }
                      if (mounted) setState(() => _adding = false);
                    },
                  ),
                ),
              )
            else
              maybeTip(
                context,
                'Add any OpenType tag (e.g. ss05, -kern, cv01=2)',
                Pressable(
                  key: const ValueKey('text:ot:add'),
                  onTap: () => setState(() => _adding = true),
                  builder: (_, hot) => Container(
                    height: Shape.z(18),
                    padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
                    decoration: BoxDecoration(
                      color: hot ? Grey.g20 : Grey.g13,
                      borderRadius: Shape.round(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: TextStyles.micro(hot ? Grey.g95 : Grey.g63),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.tip,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final String tip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => maybeTip(
    context,
    tip,
    Pressable(
      onTap: onTap,
      builder: (_, hot) {
        final ink = active ? Accent.fill : (hot ? Grey.g95 : Grey.g76);
        final bg = active
            ? Color.alphaBlend(
                Accent.fill.withValues(alpha: hot ? 0.22 : 0.14),
                Grey.g10,
              )
            : (hot ? Grey.g20 : Grey.g13);
        final border = active
            ? Accent.fill.withValues(alpha: 0.55)
            : Grey.g26.withValues(alpha: hot ? 0.8 : 0.4);
        return Container(
          height: Shape.z(18),
          padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Shape.round(4),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(label, style: TextStyles.micro(ink))],
          ),
        );
      },
    ),
  );
}
