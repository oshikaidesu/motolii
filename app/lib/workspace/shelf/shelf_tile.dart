// The shelves' shared tile and grid layout.
// ShelfTile draws one shelf item (ShelfItem, as the engine's shelf line describes it) in the form that the shelf's entry
// in shelfLooks names. ShelfGrid lays tiles out as a grid, or as the same grid one column wide, which is the list.
// Presses are handled by the dock's DockHover.
import 'package:motolii/workspace/shelf/tile_moving.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/grid_columns.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

// Re-exported so that whoever builds a tile gets the type it takes.
export '../../bridge/motolii.dart' show ShelfItem;

/// One item of a shelf, drawn as its shelf's [look] says, or as a row when [list] is true.
///
/// It draws whatever it is given, as ValuesCard draws whatever Params it is given. What goes where depends on the form.
///
/// [ShelfForm.under] in the grid, from the bottom of the stack up:
/// - the image: [art], else the item's animated image, else the plain card;
/// - [over], laid on the image as Positioned children of its Stack;
/// - a border over everything while [lit], [picked] or hovered;
/// - the name bar, with [naming] in its place while a name is being edited. [ink] and [bold] style the name unless it is picked.
/// With [small] only the image is drawn.
///
/// [ShelfForm.over] in the grid: [art] is added to the tile's Stack as it is (Positioned.fill or Align), then [over],
/// then the name at the bottom left, with [naming] in its place.
///
/// [ShelfForm.under] and [ShelfForm.over] as a row: the image at the look's rowArt size, the name, [says] under it
/// when given, then [after] at the end of the row. [ink] also colours the name in a row; if null, it is g91 rather than
/// the bar's g76. [indent] is added on the left.
///
/// [ShelfForm.words] as a card: [after] at the top right, [art] (the sample, set by the caller in its typeface), then
/// [says] with [marks] after it on the same line. As a row: [art] over [says] and [marks], then [after] at the end.
class ShelfTile extends StatelessWidget {
  const ShelfTile(
    this.item,
    this.look, {
    super.key,
    this.list = false,
    this.small = false,
    this.art,
    this.says,
    this.picked = false,
    this.lit = false,
    this.over,
    this.after,
    this.marks = const [],
    this.naming,
    this.ink,
    this.bold = false,
    this.indent = 0,
    this.picks = true,
    this.onTap,
    this.onApply,
    this.onMenu,
    this.onHover,
    this.onMove,
  });

  /// The name bar's height under a picture.
  static const bar = 18.0;
  final ShelfItem item;
  final ShelfLook look;
  final bool list, small, picked, lit, bold, picks;
  final Widget Function(bool hover)? art;
  final String? says;
  final List<Widget> Function(bool hover)? over, after;
  final List<Widget> marks;

  /// Shown in place of the name while the name is being edited.
  final Widget? naming;
  final Color? ink;
  final double indent;
  final VoidCallback? onTap;

  /// Called on a double-click, or when the tile is dragged to the preview and dropped.
  final VoidCallback? onApply;

  /// [onMenu] is called on a right-click with the position on the screen.
  /// [onMove] is called as the pointer moves with the position inside the tile.
  final ValueChanged<Offset>? onMenu, onMove;
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    onDoubleTap: onApply,
    picks: picks,
    onHover: onHover,
    onMenu: onMenu,
    onMove: onMove,
    builder: (context, h) => switch (look.form) {
      ShelfForm.words => list ? _wordsRow(h) : _wordsCard(h),
      _ when list => _row(h),
      ShelfForm.under => _under(h),
      ShelfForm.over => _over(h),
    },
  );

  // In the grid the image always plays while in sight (TileMoving decides that). When [small] it plays only under the
  // pointer, because decoding 1,255 animated images at 16 frames each takes about 3 GB.
  Widget? _image(bool h) => item.picture.isEmpty
      ? null
      : TileMoving(item.picture, playing: h || !small);

  Widget _box({
    double? height,
    required EdgeInsetsGeometry padding,
    AlignmentGeometry? alignment,
    required Color color,
    required Widget child,
  }) => look.eased
      ? AnimatedContainer(
          duration: Motion.dur,
          curve: Motion.ease,
          height: height,
          padding: padding,
          alignment: alignment,
          color: color,
          child: child,
        )
      : Container(
          height: height,
          padding: padding,
          alignment: alignment,
          color: color,
          child: child,
        );

  Widget _under(bool h) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: look.aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: WindowTokens.card),
            ?(art?.call(h) ?? _image(h)),
            ...?over?.call(h),
            // The border is drawn over everything but ignores presses, so the star under it can still be pressed.
            if (lit || picked || h)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: lit || picked ? WindowTokens.accentInk : Grey.g76,
                      width: lit || picked ? 2 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (!small)
        _box(
          height: Shape.z(bar),
          padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
          alignment: Alignment.centerLeft,
          color: dockFill(picked, h, WindowTokens.card),
          // A name wider than its tile is drawn smaller, never cut.
          child:
              naming ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.name,
                  maxLines: 1,
                  style: TextStyles.micro(dockInk(picked, ink ?? Grey.g76))
                      .copyWith(fontWeight: bold ? FontWeight.w700 : null),
                ),
              ),
        ),
    ],
  );

  Widget _over(bool h) => _box(
    padding: EdgeInsets.all(Shape.s(7)),
    color: picked
        ? WindowTokens.accent
        : (h ? WindowTokens.raised : WindowTokens.card),
    child: Stack(
      children: [
        if (art case final a?)
          a(h)
        else if (_image(h) case final p?)
          Positioned.fill(child: p),
        ...?over?.call(h),
        Align(
          alignment: Alignment.bottomLeft,
          child:
              naming ??
              AutoSizeText(
                // A long name wraps onto two lines at word boundaries, as Finder's icons do. It shrinks rather than break a word.
                item.name,
                maxLines: 2,
                wrapWords: false,
                minFontSize: 6,
                stepGranularity: .5,
                style: TextStyles.name(dockInk(picked, ink ?? Grey.g95))
                    .copyWith(fontWeight: FontWeight.w700),
              ),
        ),
      ],
    ),
  );

  Widget _row(bool h) {
    final name =
        naming ??
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.name(dockInk(picked, ink)),
        );
    return _box(
      height: Shape.z(look.row),
      padding: EdgeInsets.only(
        left: Shape.s(4) + indent,
        right: WindowTokens.inset,
      ),
      color: dockFill(picked, h),
      child: Row(
        children: [
          SizedBox(
            width: Shape.z(look.rowArt.width),
            height: Shape.z(look.rowArt.height),
            child: Stack(
              fit: StackFit.expand,
              children: [
                art?.call(h) ??
                    _image(h) ??
                    ColoredBox(color: WindowTokens.card),
              ],
            ),
          ),
          SizedBox(width: Shape.s(look.rowGap)),
          Expanded(
            child: switch (says) {
              null => name,
              final said => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  SizedBox(height: Shape.s(4)),
                  Text(
                    said,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.label(dockInk(picked, Grey.g63)),
                  ),
                ],
              ),
            },
          ),
          ...?after?.call(h),
        ],
      ),
    );
  }

  Widget _sample(bool h) =>
      art?.call(h) ??
      Text(
        item.name,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: TextStyles.name(dockInk(picked, Grey.g95)),
      );

  Widget _caption() => Row(
    children: [
      Flexible(
        child: Text(
          says ?? item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.label(dockInk(picked, Grey.g76)),
        ),
      ),
      ...marks,
    ],
  );

  Widget _wordsRow(bool h) => _box(
    height: Shape.z(look.row),
    padding: EdgeInsets.only(left: WindowTokens.inset, right: Shape.s(4)),
    color: dockFill(picked, h, WindowTokens.card),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sample(h),
              SizedBox(height: Shape.s(5)),
              _caption(),
            ],
          ),
        ),
        ...?after?.call(h),
      ],
    ),
  );

  /// The wide form: a card with the sample large enough to judge the face, what it is under it.
  Widget _wordsCard(bool h) => _box(
    height: switch (look.height) {
      final x? => Shape.z(x),
      null => null,
    },
    padding: EdgeInsets.fromLTRB(
      WindowTokens.inset,
      Shape.s(8),
      Shape.s(4),
      Shape.s(8),
    ),
    color: dockFill(picked, h, WindowTokens.card),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Spacer(), ...?after?.call(h)]),
        const Spacer(),
        _sample(h),
        const Spacer(),
        _caption(),
      ],
    ),
  );
}

/// The shelves' shared layout: [count] tiles, as many across as fit (gridColumns, gridCellWidth) or [cols], then [footer].
///
/// Only the tiles in view are built, using Flutter's lazy grid. A Wrap built all 1,293 effects each time the shelf opened.
/// - [list]: the same grid one column wide, each row as high as the look's row.
/// - [small]: the tiles are their images alone.
/// - [shrinkWrap]: only as high as its content, for use inside another list that does the scrolling.
/// - [pad]: the space around the tiles. If null, only the look's top space is used.
class ShelfGrid extends StatelessWidget {
  const ShelfGrid(
    this.look, {
    super.key,
    required this.count,
    required this.tile,
    this.list = false,
    this.small = false,
    this.cols,
    this.shrinkWrap = false,
    this.pad,
    this.footer,
  });
  final ShelfLook look;
  final int count;
  final Widget Function(int i) tile;
  final bool list, small, shrinkWrap;
  final int? cols;
  final EdgeInsets? pad;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final round = pad ?? EdgeInsets.only(top: look.top),
          wide = box.maxWidth - round.horizontal;
      final across = list
          ? 1
          : cols ??
                gridColumns(
                  wide,
                  look.sized ? Shape.z(look.cell) : look.cell,
                  min: look.min,
                );
      return CustomScrollView(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        slivers: [
          SliverPadding(
            padding: round,
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: across,
                crossAxisSpacing: WindowTokens.gutter,
                mainAxisSpacing: WindowTokens.gutter,
                mainAxisExtent: list
                    ? Shape.z(look.row)
                    : switch (look.height) {
                        final x? => Shape.z(x),
                        // A tile is its image plus its name bar.
                        null =>
                          gridCellWidth(wide, across) / look.aspect +
                              (small ? 0 : Shape.z(ShelfTile.bar)),
                      },
              ),
              itemCount: count,
              itemBuilder: (context, i) => tile(i),
            ),
          ),
          if (footer case final f?) SliverToBoxAdapter(child: f),
        ],
      );
    },
  );
}
