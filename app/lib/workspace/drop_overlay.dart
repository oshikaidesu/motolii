// The full-window accent tint and border shown while the user holds a Finder / Explorer drag over the window.
// Wire it into the workspace's Stack using a ValueNotifier<bool>, updated from the native drag-enter / drag-leave callbacks.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart'
    show BoldStyle, Motion, Shape, TextStyles;
import 'package:motolii/skin/window_tokens.dart';

/// Drawn over the window while files are dragged in, faded out at all other times.
class DropOverlay extends StatelessWidget {
  const DropOverlay({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      duration: Motion.dur,
      opacity: active ? 1 : 0,
      child: Container(
        decoration: BoxDecoration(
          color: WindowTokens.accent.withValues(alpha: .06),
          border: Border.all(color: WindowTokens.accent, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(16),
            vertical: Shape.s(10),
          ),
          decoration: BoxDecoration(
            color: WindowTokens.accent,
            borderRadius: Shape.round(10),
          ),
          child: Text(
            'Drop files to add layers',
            style: TextStyles.name(WindowTokens.onAccent).bold,
          ),
        ),
      ),
    ),
  );
}
