// The "Saved 14:30" / "Writing film.mp4 · 48%" indicator in the top bar.
// Accepts the display values directly so it can be tested and shown in a golden without WorkspaceController.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Pressable;

/// Top-bar notice: a coloured dot, a label, and an optional slim progress bar underneath.
/// When [onGo] is set the label is underlined and tappable (e.g. "Cancel" during export).
class SavedDisplay extends StatelessWidget {
  const SavedDisplay({
    super.key,
    required this.label,
    this.progress,
    this.onGo,
  });

  final String label;

  /// 0.0–1.0 when a progress bar should be shown; null otherwise.
  final double? progress;

  /// Called when the user taps the label (e.g. to cancel export); null = not tappable.
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context) {
    final active = progress != null || onGo != null;
    final said = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: onGo == null
          ? TextStyles.label(active ? Grey.g91 : Grey.g63)
          : TextStyles.label(active ? Grey.g91 : Grey.g63)
                .copyWith(decoration: TextDecoration.underline),
    );
    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Shape.z(260)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          onGo == null
              ? said
              : Pressable(onTap: onGo!, builder: (_, _) => said),
          if (progress != null) ...[
            SizedBox(height: Shape.s(3)),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: Grey.g20,
                borderRadius: Shape.round(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress!.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: WindowTokens.accent,
                    borderRadius: Shape.round(1),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(
          active ? WindowTokens.accent : Grey.g38,
          size: Shape.z(6),
          radius: Radius.circular(Shape.z(3)),
        ),
        SizedBox(width: Shape.s(6)),
        body,
      ],
    );
  }
}
