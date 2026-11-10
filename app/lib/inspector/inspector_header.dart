import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/glyphs.dart';

/// The Inspector's header: the layer's kind icon, name and kind, and the Animate all switch.
class InspectorHeader extends StatelessWidget {
  const InspectorHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    // The name the app gives the layer kind, for kinds that have no word of their own.
    final w = doc.layer.kindWord;
    final (word, glyph) = switch (doc.kind) {
      Kind.shape when w != null => (
        w,
        w == 'Film' || w == 'Picture'
            ? Glyphs.image
            : w == 'Sound'
            ? Glyphs.media
            : Glyphs.shape,
      ),
      Kind.shape => ('Shape', Glyphs.shape),
      Kind.text => ('Text', Glyphs.text),
      Kind.camera => ('Camera', Glyphs.camera),
      Kind.group => ('Group', Glyphs.grid),
      Kind.none => ('', null),
    };
    return Container(
      height: Shape.z(34),
      padding: EdgeInsets.symmetric(horizontal: InspectorSkin.inset),
      color: InspectorSkin.card,
      child: Row(
        children: [
          Container(
            width: Shape.z(22),
            height: Shape.z(22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: InspectorSkin.accent,
              borderRadius: BorderRadius.all(Shape.r(6)),
            ),
            child: glyph == null
                ? null
                : Glyph(
                    glyph,
                    size: Shape.z(13),
                    color: InspectorSkin.onAccent,
                  ),
          ),
          SizedBox(width: Shape.s(8)),
          Flexible(
            child: FittedBox(
              // Scale the name down rather than cut it off.
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                doc.name,
                maxLines: 1,
                style: TextStyles.title(Grey.g100).copyWith(
                  fontSize: TextStyles.px(13),
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          Text(word, maxLines: 1, style: TextStyles.label(Grey.g56)),
          const Spacer(),
          Text('Animate all', style: TextStyles.label(Grey.g63)),
          SizedBox(width: Shape.s(6)),
          Forms.worn.onOff(
            context,
            SwitchSpec(
              on: doc.animateAll,
              onChanged: (v) {
                doc.animateAll = v;
                doc.poke();
              },
            ),
          ),
        ],
      ),
    );
  }
}
