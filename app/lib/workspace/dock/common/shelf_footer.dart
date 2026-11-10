// The footer at the bottom of a shelf, for the picked item.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The footer of a shelf: the selected item (preview, name, facts), where it would go (the selected layer), and its one action.
class ShelfFooter extends StatelessWidget {
  const ShelfFooter({
    super.key,
    this.preview,
    required this.title,
    required this.meta,
    required this.action,
    this.onAction,
    this.done = false,
    this.doneLabel = 'Added',
    this.fresh = false,
    this.lasts,
    this.more,
  });

  /// Whether the action creates a new layer instead of changing the selected one. The target then reads 'to new layer'.
  final bool fresh;

  /// A widget beside the action button, such as a three-dot menu as in Spotify.
  final Widget? more;

  /// A widget beside the target saying how long the new layer lasts. The user chooses it before the layer is placed.
  final Widget? lasts;

  /// A small preview of the selected item.
  final Widget? preview;

  /// The item's name, a line of facts about it, the action button's label, and the label shown once [done].
  final String title, meta, action, doneLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  /// Whether the action has been done. The button then shows [doneLabel] and does nothing.
  final bool done;
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
          WorkspaceAspect.document,
          WorkspaceAspect.picked,
        }),
        l = fresh ? null : ws.layer;
    return Container(
      // At least 52 high and as tall as its content. A fixed 52 overflowed by a point (RenderFlex overflow) with two lines of text.
      constraints: BoxConstraints(minHeight: Shape.z(52)),
      padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
      decoration: BoxDecoration(
        color: WindowTokens.card,
        border: Border(
          top: BorderSide(
            color: WindowTokens.ground,
            width: WindowTokens.gutter,
          ),
        ),
      ),
      child: Row(
        children: [
          if (preview case final p?) ...[
            SizedBox.square(dimension: Shape.z(34), child: p),
            SizedBox(width: Shape.s(8)),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(Grey.g95)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: Shape.s(4)),
                // Up to two lines of whole words before anything is cut off.
                Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.label(Grey.g63),
                ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('to ', style: TextStyles.label(Grey.g56)),
                    if (l != null) ...[
                      Container(
                        width: Shape.z(6),
                        height: Shape.z(6),
                        decoration: BoxDecoration(
                          color: layerKindColor(l.kind),
                          borderRadius: BorderRadius.all(Shape.r(1)),
                        ),
                      ),
                      SizedBox(width: Shape.s(4)),
                      Flexible(
                        child: Text(
                          l.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.label(Grey.g91),
                        ),
                      ),
                    ] else
                      Flexible(
                        child: Text(
                          'new layer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.label(Grey.g91),
                        ),
                      ),
                    // Scaled down rather than clipped when the shelf is narrow.
                    if (lasts case final w?) ...[
                      SizedBox(width: Shape.s(8)),
                      Flexible(
                        flex: 3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: w,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: Shape.s(6)),
          ?more,
          DockHover(
            onTap: done ? null : onAction,
            builder: (context, h) => AnimatedContainer(
              duration: Motion.dur,
              curve: Motion.ease,
              height: Shape.z(24),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? WindowTokens.raised : WindowTokens.accent,
                borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius)),
                border: Border.all(
                  color: h && !done ? Grey.g95 : const Color(0x00000000),
                ),
              ),
              child: Text(
                done ? doneLabel : action,
                style: TextStyles.name(done ? Grey.g76 : WindowTokens.onAccent)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
