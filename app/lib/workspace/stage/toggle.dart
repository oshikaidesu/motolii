// The on/off chips of the stage's header and of its options strip, with the marks drawn on them.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/glyphs.dart';

/// The marks a header toggle of the stage can carry.
enum StageIcon { safe, grid, snap, show }

/// An on/off chip: raised with an accent mark when on, a quiet well when off.
class Toggle extends StatelessWidget {
  const Toggle({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
    this.glyph,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;
  final StageIcon? icon;
  final Glyphs? glyph;
  @override
  Widget build(BuildContext context) => Forms.worn.flag(
    context,
    FlagSpec(
      label: label,
      on: on,
      onTap: onTap,
      mark: (ink) {
        if (glyph case final g?) return Glyph(g, size: Shape.z(14), color: ink);
        return CustomPaint(
          size: const Size.square(12),
          painter: _IconPainter(icon!, ink),
        );
      },
    ),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon, this.c);
  final StageIcon icon;
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    // Use the skin's own icon if it provides one.
    if (SkinParts.draw(cv, s, 'stage.${icon.name}', c)) return;
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = (Offset.zero & s).deflate(1);
    switch (icon) {
      case StageIcon.safe:
        cv.drawRect(r, p);
        cv.drawRect(r.deflate(2.5), p);
      case StageIcon.grid:
        cv.drawRect(r, p);
        for (final t in const [1 / 3, 2 / 3]) {
          cv.drawLine(
            Offset(r.left + r.width * t, r.top),
            Offset(r.left + r.width * t, r.bottom),
            p,
          );
          cv.drawLine(
            Offset(r.left, r.top + r.height * t),
            Offset(r.right, r.top + r.height * t),
            p,
          );
        }
      case StageIcon.snap: // A camera body and its lens.
        cv.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(r.left, r.top + r.height * .25, r.right, r.bottom),
            const Radius.circular(1.5),
          ),
          p,
        );
        cv.drawCircle(r.center.translate(0, r.height * .12), r.width * .2, p);
      case StageIcon.show: // The image halved: then and now.
        cv.drawRect(r, p);
        cv.drawRect(
          Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom),
          p..style = PaintingStyle.fill,
        );
    }
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.icon != icon || o.c != c;
}
