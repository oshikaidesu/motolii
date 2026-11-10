// A group: a heading and its rows.
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Hov;
import 'package:motolii/widgets/media.dart' show Draw;

/// A card: a heading and its rows, folded by its title.
class Sect extends StatelessWidget {
  const Sect({super.key, required this.title, required this.children, required this.trailing, required this.tone});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  /// The card's colour stripe.
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    final open = !(doc.b['fold.$title'] ?? false);
    void toggle() {
      if (!HardwareKeyboard.instance.isAltPressed) return doc.flag('fold.$title', open);
      for (final c in doc.cards) {
        doc.flag('fold.${c.name}', open); // (the Mac's Option on a disclosure triangle: all of them, Finder's list; this one as they go)
      }
      doc.flag('fold.$title', open);
    }

    final head = Hov(
      onTap: toggle,
      builder: (_, h) => SizedBox(
        height: Pop.titleH,
        child: Row(
          children: [
            // the mark sits centred in its box, and the gap after it equals the card's inset, so it has the same air on both sides
            FoldMark(open: open, hot: h),
            SizedBox(width: Pop.inset),
            Badge(tone, size: 16, radius: const Radius.circular(16 * .32), mark: Draw((c, s) => drawLayerMark(c, s, Pop.onAccent), Pop.onAccent)),
            SizedBox(width: Shape.s(6)),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.title(h ? Grey.g100 : Grey.g95).copyWith(fontSize: T.px(12), fontWeight: FontWeight.w700),
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
      padding: EdgeInsets.symmetric(horizontal: Pop.inset, vertical: Pop.insetY),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          head,
          if (body.isNotEmpty) SizedBox(height: Pop.titleGap),
          ...body,
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: Pop.gap),
      child: Forms.worn.card(
        // (as the skin's forms draw a card)
        context,
        CardSpec(title: title, tone: tone, open: open, onToggle: toggle, trailing: trailing, body: body, head: head, own: content),
      ),
    );
  }
}
