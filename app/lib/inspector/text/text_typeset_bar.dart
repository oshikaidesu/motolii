// Collapsible OpenType feature section (`v_font_features`) for the Text card:
// closed by default as a quiet 1-line fold row matching ValuesCard's Advanced
// fold (showing any enabled tags inline); when expanded, renders real OFF vs ON
// glyph comparisons using the layer's actual font + Flutter FontFeature.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_meta.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Collapsible `OpenType` section showing live before/after glyph comparisons
/// for every user-facing feature in the active font, plus arbitrary tag entry.
class TextFeaturesFold extends StatefulWidget {
  const TextFeaturesFold({
    required this.doc,
    required this.supported,
    required this.featureNames,
    required this.fontFamily,
    super.key,
  });

  final InspectorValues doc;
  final Set<String> supported;
  final Map<String, String> featureNames;
  final String? fontFamily;

  @override
  State<TextFeaturesFold> createState() => _TextFeaturesFoldState();
}

class _TextFeaturesFoldState extends State<TextFeaturesFold> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final raw = doc.strings['v_font_features'] ?? '';
    final activeTokens = parseFeatureTokens(raw);
    final activeByTag = {for (final t in activeTokens) featureTagOf(t): t};
    final exposed = exposedOpenTypeTags(widget.supported);
    final custom = [
      for (final t in activeTokens)
        if (!exposed.contains(featureTagOf(t))) t,
    ];
    if (exposed.isEmpty && custom.isEmpty && !_adding) {
      return const SizedBox.shrink();
    }
    final open = doc.flags['text.ot'] ?? false;

    return Padding(
      padding: EdgeInsets.only(top: Shape.s(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Standard fold header matching ValuesCard._FoldRow.
          Pressable(
            key: const ValueKey('text:ot:toggle'),
            onTap: () => doc.flag('text.ot', !open),
            builder: (_, h) => Container(
              height: Shape.z(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const InspectorHairline().rule),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'OpenType',
                    style: TextStyles.label(h || open ? Grey.g95 : Grey.g63),
                  ),
                  if (!open && activeTokens.isNotEmpty) ...[
                    SizedBox(width: Shape.s(8)),
                    Expanded(
                      child: Text(
                        activeTokens.join('  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.micro(Accent.fill),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  DisclosureTriangle(open: open, hot: h || open),
                ],
              ),
            ),
          ),
          if (open) ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Shape.z(240)),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final tag in exposed)
                      _FeatureCompareRow(
                        key: ValueKey('text:ot:$tag'),
                        tag: tag,
                        token: activeByTag[tag],
                        spec: resolveOtFeatureSpec(tag, widget.featureNames),
                        fontFamily: widget.fontFamily,
                        onTap: () => doc.str(
                          'v_font_features',
                          toggleFeatureToken(raw, tag),
                        ),
                      ),
                    for (final tok in custom)
                      _FeatureCompareRow(
                        key: ValueKey('text:ot:${featureTagOf(tok)}'),
                        tag: featureTagOf(tok),
                        token: tok,
                        spec: resolveOtFeatureSpec(
                          featureTagOf(tok),
                          widget.featureNames,
                        ),
                        fontFamily: widget.fontFamily,
                        onTap: () => doc.str(
                          'v_font_features',
                          toggleFeatureToken(raw, featureTagOf(tok)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Shape.s(3)),
            if (_adding)
              Container(
                height: Shape.z(22),
                padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
                decoration: BoxDecoration(
                  color: InspectorSkin.well,
                  borderRadius: Shape.round(4),
                  border: Border.all(color: Accent.fill.withValues(alpha: 0.6)),
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
                      doc.str('v_font_features', addFeatureToken(raw, said));
                    }
                    if (mounted) setState(() => _adding = false);
                  },
                ),
              )
            else
              maybeTip(
                context,
                'Add any OpenType tag (e.g. ss05, -kern, cv01=2)',
                Pressable(
                  key: const ValueKey('text:ot:add'),
                  onTap: () => setState(() => _adding = true),
                  builder: (_, h) => Padding(
                    padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
                    child: Text(
                      '+ Add tag',
                      style: TextStyles.micro(h ? Grey.g95 : Grey.g56),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One OpenType feature row showing a live `OFF → ON` specimen rendered in the
/// active font so the glyph change is visible by direct comparison.
class _FeatureCompareRow extends StatelessWidget {
  const _FeatureCompareRow({
    required this.tag,
    required this.token,
    required this.spec,
    required this.fontFamily,
    required this.onTap,
    super.key,
  });

  final String tag;
  final String? token;
  final OtFeatureSpec spec;
  final String? fontFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = token != null;
    final offFeatures = [
      FontFeature.disable(tag),
      if (spec.contrastOff case final c?) FontFeature.enable(c),
    ];
    final onFeatures = [
      FontFeature.enable(tag),
      if (spec.contrastOff case final c?) FontFeature.disable(c),
    ];
    final base = TextStyles.name(Grey.g95).copyWith(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.1,
    );

    return Pressable(
      onTap: onTap,
      builder: (_, hot) => Container(
        height: Shape.z(22),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
        margin: EdgeInsets.only(top: Shape.s(2)),
        decoration: BoxDecoration(
          color: active
              ? Color.alphaBlend(
                  Accent.fill.withValues(alpha: hot ? 0.16 : 0.10),
                  InspectorSkin.well,
                )
              : (hot ? Grey.g20 : InspectorSkin.well),
          borderRadius: Shape.round(4),
          border: Border.all(
            color: active
                ? Accent.fill.withValues(alpha: 0.45)
                : Grey.g20.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // Direct before -> after specimen in the real font.
            SizedBox(
              width: Shape.z(64),
              child: Row(
                children: [
                  Text(
                    spec.sample,
                    style: base.copyWith(
                      color: Grey.g56,
                      fontFeatures: offFeatures,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
                    child: Text('→', style: TextStyles.micro(Grey.g44)),
                  ),
                  Text(
                    spec.sample,
                    style: base.copyWith(
                      color: active ? Accent.fill : Grey.g95,
                      fontFeatures: onFeatures,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Shape.s(6)),
            Expanded(
              child: Text(
                spec.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(
                  active ? Grey.g95 : (hot ? Grey.g91 : Grey.g63),
                ),
              ),
            ),
            Text(
              token ?? tag,
              style: TextStyles.micro(active ? Accent.fill : Grey.g44),
            ),
          ],
        ),
      ),
    );
  }
}
