// The header of a section inside a shelf.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// A section header inside a shelf body: a hue swatch, the title in capitals, an optional count, and an optional fold chevron.
class ShelfSection extends StatelessWidget {
  const ShelfSection(
    this.title, {
    super.key,
    this.count,
    this.hue,
    this.folded,
    this.onTap,
    this.trailing,
  });
  final String title;
  final int? count;
  final Color? hue;
  final bool? folded;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    builder: (context, h) => Container(
      height: Shape.z(24),
      color: h && onTap != null ? WindowTokens.raised : WindowTokens.card,
      padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
      child: Row(
        children: [
          if (folded != null) ...[
            AnimatedRotation(
              turns: folded! ? 0 : .25,
              duration: Motion.dur,
              curve: Motion.ease,
              child: Glyph(
                AppGlyphs.chevron,
                size: Shape.z(8),
                color: Grey.g63,
              ),
            ),
            SizedBox(width: Shape.s(6)),
          ],
          Container(
            width: Shape.z(8),
            height: Shape.z(8),
            decoration: BoxDecoration(
              color: hue ?? Grey.g56,
              borderRadius: BorderRadius.all(Shape.r(2)),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.micro(Grey.g91)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: .9),
            ),
          ),
          // The trailing widget is scaled down in a narrow shelf, never clipped.
          if (trailing case final w?)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: w,
                ),
              ),
            ),
          if (count != null)
            Text(
              '$count',
              style: TextStyles.value(Grey.g56)
                  .copyWith(fontSize: TextStyles.px(10)),
            ),
        ],
      ),
    ),
  );
}
