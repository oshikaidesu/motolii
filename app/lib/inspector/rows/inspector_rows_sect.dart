// A group: a heading and its rows, with a rule above the group after the first.
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge;

/// A group: a heading and its rows, with a rule above the group after the first.
class Sect extends StatelessWidget {
  const Sect({super.key, this.title, this.children = const [], this.trailing, this.tone});
  final String? title;
  final List<Widget> children;
  final Widget? trailing;

  /// Pop only: the card's colour stripe.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final ed = const Ed();
    final head = (title == null && trailing == null)
        ? null
        : Hov(
            cursor: SystemMouseCursors.basic,
            builder: (_, _) => SizedBox(
              height: Shape.z(24),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(ed.head(title!), maxLines: 1, overflow: TextOverflow.ellipsis, style: ed.headStyle()),
                    )
                  else
                    const Spacer(),
                  ?trailing,
                ],
              ),
            ),
          );
    if (Pop.on(context)) return _PopCard(this);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: ed.gap),
          child: const Rule(),
        ),
        const SizedBox(height: 4),
        ?head,
        ...children,
      ],
    );
  }
}

class _PopCard extends StatelessWidget {
  const _PopCard(this.s);
  final Sect s;
  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc, title = s.title, tone = s.tone;
    final open = title == null || !(doc.b['fold.$title'] ?? false);
    final toggle = (title == null
        ? null
        : () {
            if (!HardwareKeyboard.instance.isAltPressed) return doc.flag('fold.$title', open);
            for (final c in doc.cards) {
              doc.flag('fold.${c.name}', open); // (the Mac's Option on a disclosure triangle: all of them, Finder's list; this one as they go)
            }
            doc.flag('fold.$title', open);
          });
    List<Widget> lead(bool h) => [
      // the mark sits centred in its box, and the gap after it equals the card's inset, so it has the same air on both sides
      if (toggle != null) ...[FoldMark(open: open, hot: h), SizedBox(width: Pop.inset)],
      if (tone != null) ...[Badge(tone, size: 16, radius: const Radius.circular(16 * .32), mark: MarkPaint(Pop.onAccent)), SizedBox(width: Shape.s(6))],
      if (title != null)
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.title(h && toggle != null ? Grey.g100 : Grey.g95).copyWith(fontSize: T.px(12), fontWeight: FontWeight.w700),
          ),
        ),
    ];
    final head = title == null && s.trailing == null
        ? null
        : Hov(
            onTap: toggle,
            builder: (_, h) => SizedBox(
              height: Pop.titleH,
              child: Row(
                children: [
                  ...lead(h),
                  const Expanded(child: SizedBox()),
                  ?s.trailing,
                ],
              ),
            ),
          );
    final body = open ? s.children : const <Widget>[];
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: Pop.inset, vertical: Pop.insetY),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?head,
          if (head != null && body.isNotEmpty) SizedBox(height: Pop.titleGap),
          ...body,
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: Pop.gap),
      child: Forms.worn.card(
        // (as the skin's forms draw a card)
        context,
        CardSpec(title: title, tone: tone, open: open, onToggle: toggle, trailing: s.trailing, body: body, head: head, own: content),
      ),
    );
  }
}
