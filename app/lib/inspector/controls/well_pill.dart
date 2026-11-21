// Compact frosted pill anchored inside a live preview well for discrete
// non-keyframed modes (used by FillPreview, BlendPreview, etc.).
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/tip.dart' show Tip;

/// Wraps [child] in a [Tip] only when an [Overlay] ancestor exists, so
/// lightweight widget tests without an overlay mount cleanly.
Widget maybeTip(BuildContext context, String text, Widget child) =>
    Overlay.maybeOf(context) != null ? Tip(text, child: child) : child;

/// Frosted dark pill seated inside a preview well. Set [active] for binary
/// toggles (e.g. Invert) so the enabled state reads at a glance.
class WellPill extends StatelessWidget {
  const WellPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
    super.key,
  });

  final String label;
  final void Function(Canvas, Size, Color) icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) {
      final ink = active ? Accent.fill : (hot ? Grey.g95 : Grey.g91);
      final glyph = active ? Accent.fill : (hot ? Grey.g95 : Grey.g76);
      final bg = active
          ? Color.alphaBlend(
              Accent.fill.withValues(alpha: hot ? 0.24 : 0.16),
              Grey.g07.withValues(alpha: 0.86),
            )
          : Grey.g07.withValues(alpha: hot ? 0.90 : 0.72);
      final border = active
          ? Accent.fill.withValues(alpha: hot ? 0.75 : 0.55)
          : (hot ? Grey.g95 : Grey.g91).withValues(alpha: hot ? 0.36 : 0.16);
      return Container(
        height: Shape.z(20),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(label.isEmpty ? 5 : 6),
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: Shape.round(4),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(10, 10),
              painter: Draw((c, s) => icon(c, s, glyph), (hot, active, label)),
            ),
            if (label.isNotEmpty) ...[
              SizedBox(width: Shape.s(4)),
              Text(label, style: TextStyles.micro(ink)),
            ],
          ],
        ),
      );
    },
  );
}
