// A card of the inspector: a heading and its rows.
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_badges.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/forms/forms.dart';

/// A card: a heading and its rows. Clicking the heading folds the card.
///
/// Alt-click folds or opens every card of the document at once, like Option-click on a disclosure triangle in Finder's list view.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.children,
    required this.trailing,
    required this.tone,
  });

  /// The heading text. It also names the card's fold flag in the document.
  final String title;

  /// The rows shown while the card is open.
  final List<Widget> children;

  /// A widget placed at the right end of the heading.
  final Widget? trailing;

  /// The colour of the card's badge.
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final open = !(doc.flags['fold.$title'] ?? false);
    void toggle() {
      if (!HardwareKeyboard.instance.isAltPressed) {
        return doc.flag('fold.$title', open);
      }
      for (final c in doc.cards) {
        doc.flag('fold.${c.name}', open);
      }
      doc.flag('fold.$title', open);
    }

    final head = Pressable(
      onTap: toggle,
      builder: (_, h) => SizedBox(
        height: InspectorSkin.titleH,
        child: Row(
          children: [
            // The mark is centred in its box and the gap after it equals the card's inset, so it has equal space on both sides.
            DisclosureTriangle(open: open, hot: h),
            SizedBox(width: InspectorSkin.inset),
            layerBadge(tone),
            SizedBox(width: Shape.s(6)),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.title(h ? Grey.g100 : Grey.g95).copyWith(
                  fontSize: TextStyles.px(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
            ?trailing,
          ],
        ),
      ),
    );
    final body = open ? children : const <Widget>[];
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InspectorSkin.inset,
        vertical: InspectorSkin.insetY,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          head,
          if (body.isNotEmpty) SizedBox(height: InspectorSkin.titleGap),
          ...body,
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: InspectorSkin.gap),
      child: Forms.worn.card(
        context,
        CardSpec(
          title: title,
          tone: tone,
          open: open,
          onToggle: toggle,
          trailing: trailing,
          body: body,
          head: head,
          own: content,
        ),
      ),
    );
  }
}
