// The dock's shared pieces: per-shelf memory, hover, section heads, and the footer at the bottom of a shelf.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/grid_columns.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

// Re-exported so shelves get the shared small widgets together with the dock's own.
export '../../widgets/controls.dart' show Badge, Chip, IconPress;

/// A section header inside a shelf body: a hue swatch, the title in capitals, an optional count, and an optional fold chevron.
class DockSection extends StatelessWidget {
  const DockSection(this.title, {super.key, this.count, this.hue, this.folded, this.onTap, this.trailing});
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
              duration: Mo.dur,
              curve: Mo.ease,
              child: Glyph(DockG.chevron, size: Shape.z(8), color: Grey.g63),
            ),
            SizedBox(width: Shape.s(6)),
          ],
          Container(
            width: Shape.z(8),
            height: Shape.z(8),
            decoration: BoxDecoration(color: hue ?? Grey.g56, borderRadius: BorderRadius.all(Shape.r(2))),
          ),
          SizedBox(width: Shape.s(6)),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.micro(Grey.g91).copyWith(fontWeight: FontWeight.w700, letterSpacing: .9),
            ),
          ),
          // The trailing widget is scaled down in a narrow shelf, never clipped.
          if (trailing case final w?)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: w),
              ),
            ),
          if (count != null) Text('$count', style: T.value(Grey.g56).copyWith(fontSize: T.px(10))),
        ],
      ),
    ),
  );
}

/// The footer of a shelf: the selected item (preview, name, facts), where it would go (the selected layer), and its one action.
class DockFooter extends StatelessWidget {
  const DockFooter({
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
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked}), l = fresh ? null : ws.layer;
    return Container(
      // At least 52 high and as tall as its content. A fixed 52 overflowed by a point (RenderFlex overflow) with two lines of text.
      constraints: BoxConstraints(minHeight: Shape.z(52)),
      padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
      decoration: BoxDecoration(
        color: WindowTokens.card,
        border: Border(
          top: BorderSide(color: WindowTokens.ground, width: WindowTokens.gutter),
        ),
      ),
      child: Row(
        children: [
          if (preview case final p?) ...[SizedBox.square(dimension: Shape.z(34), child: p), SizedBox(width: Shape.s(8))],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.name(Grey.g95).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: Shape.s(4)),
                // Up to two lines of whole words before anything is cut off.
                Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(Grey.g63)),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('to ', style: T.label(Grey.g56)),
                    if (l != null) ...[
                      Container(
                        width: Shape.z(6),
                        height: Shape.z(6),
                        decoration: BoxDecoration(color: wsTone(l.kind), borderRadius: BorderRadius.all(Shape.r(1))),
                      ),
                      SizedBox(width: Shape.s(4)),
                      Flexible(
                        child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                      ),
                    ] else
                      Flexible(
                        child: Text('new layer', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                      ),
                    // Scaled down rather than clipped when the shelf is narrow.
                    if (lasts case final w?) ...[
                      SizedBox(width: Shape.s(8)),
                      Flexible(
                        flex: 3,
                        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w),
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
              duration: Mo.dur,
              curve: Mo.ease,
              height: Shape.z(24),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? WindowTokens.raised : WindowTokens.accent,
                borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius)),
                border: Border.all(color: h && !done ? Grey.g95 : const Color(0x00000000)),
              ),
              child: Text(done ? doneLabel : action, style: T.name(done ? Grey.g76 : WindowTokens.onAccent).copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a shelf shows when the search finds nothing, or when the shelf is empty.
class DockEmpty extends StatelessWidget {
  const DockEmpty(this.query, {super.key, this.said});
  final String query;

  /// Shown instead of the default message when nothing is typed: what is empty here and what to do.
  final String? said;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(24)),
    child: Text(said ?? 'Nothing matches “$query”', textAlign: TextAlign.center, style: T.label(Grey.g63)),
  );
}

/// A shelf's sections as cards in one column while the shelf is narrow.
///
/// As the shelf widens, columns of at least 300 px stand side by side, and each section goes to the shortest column so far.
/// [weights] estimate the section heights, in rows.
class DockMasonry extends StatelessWidget {
  const DockMasonry({super.key, required this.children, required this.weights});
  final List<Widget> children;
  final List<double> weights;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = wsCols(box.maxWidth, 300, max: 4);
      if (n == 1) return ListView(padding: EdgeInsets.zero, children: children);
      final cols = List.generate(n, (_) => <Widget>[]), h = List.filled(n, 0.0);
      for (final (i, w) in children.indexed) {
        var k = 0;
        for (var j = 1; j < n; j++) {
          if (h[j] < h[k]) k = j;
        }
        cols[k].add(w);
        h[k] += weights[i];
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, col) in cols.indexed) ...[
                if (i > 0) const SizedBox(width: WindowTokens.gutter),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: col),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}
