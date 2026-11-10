// A panel's header and the panel around it.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// A panel's header: the title on the left, [trailing] on the right, a hairline underneath.
///
/// [height], [color] and [padding] are for headers that need to be taller, darker or tighter.
/// [child] replaces the whole row.
class PanelHeader extends StatelessWidget {
  const PanelHeader(
    this.title, {
    super.key,
    this.trailing = const [],
    this.leading,
    this.height,
    this.color,
    this.padding,
    this.child,
  });
  final String title;
  final List<Widget> trailing;
  final Widget? leading, child;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => Container(
    height: height ?? WindowTokens.header,
    padding: padding ?? EdgeInsets.symmetric(horizontal: WindowTokens.inset),
    decoration: BoxDecoration(
      color: color ?? WindowTokens.body,
      border: Border(bottom: BorderSide(color: WindowTokens.line)),
    ),
    child:
        child ??
        Row(
          children: [
            if (leading case final l?) ...[l, SizedBox(width: Shape.s(6))],
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyles.name(Grey.g95)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            const Spacer(),
            ...trailing,
          ],
        ),
  );
}

/// A panel: a square tile of [WindowTokens.body] that clips what it holds.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRect(
    child: ColoredBox(color: WindowTokens.body, child: child),
  );
}
