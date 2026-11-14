// The tooltip: the name of what the pointer rests on, and the key that does it, as in macOS and Windows.
// naked_ui's NakedTooltip (on Flutter's RawTooltip) owns the delay, the placing at the window's edge and the hiding; this is its look.
// A button takes its name as `tip:` (Pressable, IconPress); anything else wraps itself in [Tip].
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart'
    show NakedTooltip, OverlayAlignment, OverlayPositionConfig, OverlaySide;

import 'package:motolii/skin/tokens.dart';

class Tip extends StatelessWidget {
  const Tip(this.name, {super.key, this.keys = '', required this.child});

  /// What the thing is or does. Empty shows no tooltip.
  final String name;

  /// The key bound to it, as the menus write it. Empty when none.
  final String keys;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return child;
    return NakedTooltip(
      // A little wait, so it does not flash up while the pointer crosses a row of buttons.
      hoverDelay: const Duration(milliseconds: 500),
      positioning: OverlayPositionConfig(
        side: OverlaySide.bottom,
        alignment: OverlayAlignment.center,
        sideOffset: Shape.s(6),
      ),
      semanticLabel: name,
      overlayBuilder: (_, _) => Container(
        key: const ValueKey('tip'),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(8),
          vertical: Shape.s(4),
        ),
        decoration: BoxDecoration(
          color: Grey.g13,
          borderRadius: BorderRadius.all(Shape.r(4)),
          border: Border.all(color: Grey.g26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: TextStyles.name(Grey.g91)),
            if (keys.isNotEmpty) ...[
              SizedBox(width: Shape.s(8)),
              Text(keys, style: TextStyles.label(Grey.g56)),
            ],
          ],
        ),
      ),
      child: child,
    );
  }
}
