// The shelves' one tile and one layout. A shelf's item (ShelfItem, as the engine's shelf line says it) is drawn by
// ShelfTile in the form its shelf's row of shelfLooks names, and laid out by ShelfGrid: a grid, or the same grid one
// column wide, which is the list. The press is the dock's DockHover.
import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';

import '../../bridge/motolii.dart' show ShelfItem;
import '../../skin/tokens.dart';
import '../dock/dock_widgets.dart';
import '../state/state.dart';
import 'effect_tiles.dart';

export '../../bridge/motolii.dart' show ShelfItem; // (what a tile is given comes with the tile)

/// The three forms a tile has: its name in a bar under its picture (Effects, Program, Media), its name laid over its
/// picture (Create), or its art being words set in a face (Fonts).
enum ShelfForm { under, over, words }

/// How one shelf's tiles look: a row of [shelfLooks]. Every size is today's px, and grows with the skin's Size
/// (Shape.z) where it is drawn; [cell] only when [sized].
class ShelfLook {
  const ShelfLook(
    this.form, {
    required this.cell,
    this.sized = false,
    this.min = 1,
    this.aspect = 1,
    this.height,
    this.row = 34,
    this.rowArt = const Size(40, 28),
    this.rowGap = 8,
    this.top = 0,
    this.eased = true,
  });
  final ShelfForm form;

  /// The least width of a cell, of which there are at least [min] across (wsCols).
  final double cell;
  final bool sized;
  final int min;

  /// The picture's width over its height ([ShelfForm.under]), or the whole tile's [height] where that is fixed.
  final double aspect;
  final double? height;

  /// As a row: its height, its picture's size, and the gap between the picture and the name.
  final double row;
  final Size rowArt;
  final double rowGap;

  /// The room over the first tiles.
  final double top;

  /// Its fill goes to the next over [Mo.dur], not at once.
  final bool eased;
}

const _square = ShelfLook(ShelfForm.under, cell: 84, sized: true, row: 22, rowArt: Size(18, 18), rowGap: 6, eased: false);

/// Every shelf's look, by the shelf's name (DockCtx.shelf).
const shelfLooks = <String, ShelfLook>{
  'Effects': _square,
  'Program': _square,
  'Media': ShelfLook(ShelfForm.under, cell: 76, min: 2, aspect: 16 / 9, top: WsT.gutter),
  'Create': ShelfLook(ShelfForm.over, cell: 74, min: 2, height: 70),
  'Fonts': ShelfLook(ShelfForm.words, cell: 200, height: 96, row: 46),
};

/// One item of a shelf, drawn as its shelf's [look] says; [list]: as a row. It draws whatever it is given, as
/// ValuesCard draws whatever Params it is given. Where each part goes, by form:
///
/// under, in the grid: the picture ([art], else the item's picture moving, else the plain card), [over] laid on it
/// (Positioned children of its Stack), a border over all while [lit], [picked] or under the pointer, then the name
/// bar ([naming] in its place; [ink] and [bold] are the name's, while it is not picked). [small]: the picture alone.
///
/// over, in the grid: [art] is a child of the tile's Stack as it is (Positioned.fill or Align), then [over], then the
/// name at the bottom left ([naming] in its place).
///
/// under and over, as a row: the picture at the look's rowArt, the name ([ink] is its ink in a row too: none given,
/// it is g91, not the bar's g76), [says] under it when given, then [after] at the row's end. [indent] is added at its left.
///
/// words, as a card: [after] at the top right, [art] (the sample, set by the caller in its face), then [says] with
/// [marks] after it on its line. As a row: [art] over [says] and [marks], then [after] at the row's end.
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
  final Widget? naming; // (where its name is being written, in its place)
  final Color? ink;
  final double indent;
  final VoidCallback? onTap;
  final VoidCallback? onApply; // (two presses, or carried to the stage and let go)
  final ValueChanged<Offset>? onMenu, onMove; // (a right click, where on the screen; the pointer moving, where in the tile)
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

  // (in the grid always: played while in sight, TileMoving's own; small, on the map, under the pointer alone: 1,255 of 16 pictures are about 3 GB)
  Widget? _image(bool h) => item.picture.isEmpty ? null : TileMoving(item.picture, playing: h || !small);

  Widget _box({double? height, required EdgeInsetsGeometry padding, AlignmentGeometry? alignment, required Color color, required Widget child}) => look.eased
      ? AnimatedContainer(duration: Mo.dur, curve: Mo.ease, height: height, padding: padding, alignment: alignment, color: color, child: child)
      : Container(height: height, padding: padding, alignment: alignment, color: color, child: child);

  Widget _under(bool h) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: look.aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: WsT.card),
            ?(art?.call(h) ?? _image(h)),
            ...?over?.call(h),
            if (lit || picked || h)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: lit || picked ? WsT.accentInk : Grey.g76, width: lit || picked ? 2 : 1),
                  ),
                ),
              ), // (drawn over all, taking no press: the star under it is pressed)
          ],
        ),
      ),
      if (!small)
        _box(
          height: Shape.z(bar),
          padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
          alignment: Alignment.centerLeft,
          color: dockFill(picked, h, WsT.card),
          child:
              naming ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(item.name, maxLines: 1, style: T.micro(dockInk(picked, ink ?? Grey.g76)).copyWith(fontWeight: bold ? FontWeight.w700 : null)),
              ), // (a name wider than its tile is drawn smaller, never cut)
        ),
    ],
  );

  Widget _over(bool h) => _box(
    padding: EdgeInsets.all(Shape.s(7)),
    color: picked ? WsT.accent : (h ? WsT.raised : WsT.card),
    child: Stack(
      children: [
        if (art case final a?) a(h) else if (_image(h) case final p?) Positioned.fill(child: p),
        ...?over?.call(h),
        Align(
          alignment: Alignment.bottomLeft,
          child:
              naming ??
              AutoSizeText(
                // (a long name on two lines of whole words, as Finder's icons have it; smaller rather than a word broken)
                item.name,
                maxLines: 2,
                wrapWords: false,
                minFontSize: 6,
                stepGranularity: .5,
                style: T.name(dockInk(picked, ink ?? Grey.g95)).copyWith(fontWeight: FontWeight.w700),
              ),
        ),
      ],
    ),
  );

  Widget _row(bool h) {
    final name = naming ?? Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.name(dockInk(picked, ink)));
    return _box(
      height: Shape.z(look.row),
      padding: EdgeInsets.only(left: Shape.s(4) + indent, right: WsT.inset),
      color: dockFill(picked, h),
      child: Row(
        children: [
          SizedBox(
            width: Shape.z(look.rowArt.width),
            height: Shape.z(look.rowArt.height),
            child: Stack(
              fit: StackFit.expand,
              children: [art?.call(h) ?? _image(h) ?? ColoredBox(color: WsT.card)],
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
                  Text(said, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(dockInk(picked, Grey.g63))),
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
      art?.call(h) ?? Text(item.name, maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: T.name(dockInk(picked, Grey.g95)));

  Widget _caption() => Row(
    children: [
      Flexible(
        child: Text(says ?? item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(dockInk(picked, Grey.g76))),
      ),
      ...marks,
    ],
  );

  Widget _wordsRow(bool h) => _box(
    height: Shape.z(look.row),
    padding: EdgeInsets.only(left: WsT.inset, right: Shape.s(4)),
    color: dockFill(picked, h, WsT.card),
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
    padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(8), Shape.s(4), Shape.s(8)),
    color: dockFill(picked, h, WsT.card),
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

/// The shelves' one layout: [count] tiles, as many across as the room holds (wsCols, wsCell; or [cols]), only those
/// in sight made (Flutter's own lazy grid: a Wrap made all 1,293 effects at each opening), then [footer]. [list]: the
/// same grid one column wide, each row as high as the look's row. [small]: the tiles are their pictures alone.
/// [shrinkWrap]: as high as what it holds, inside another list, which scrolls it. [pad]: the room round the tiles,
/// where it is not the look's top alone.
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
      final round = pad ?? EdgeInsets.only(top: look.top), wide = box.maxWidth - round.horizontal;
      final across = list ? 1 : cols ?? wsCols(wide, look.sized ? Shape.z(look.cell) : look.cell, min: look.min);
      return CustomScrollView(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        slivers: [
          SliverPadding(
            padding: round,
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: across,
                crossAxisSpacing: WsT.gutter,
                mainAxisSpacing: WsT.gutter,
                mainAxisExtent: list
                    ? Shape.z(look.row)
                    : switch (look.height) {
                        final x? => Shape.z(x),
                        null => wsCell(wide, across) / look.aspect + (small ? 0 : Shape.z(ShelfTile.bar)), // (a tile: its picture and its name)
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

/// A tile's picture, its moving ones played there and back at 24 a second while [playing], so it neither steps nor jumps
/// where it starts again (effect_tiles.dart); its still otherwise, and for a picture with none beside it. Keyed by when
/// the file was written: a widget told the same file keeps the picture it had (an equal provider is not resolved again).
class TileMoving extends StatefulWidget {
  const TileMoving(this.file, {super.key, required this.playing});
  final String file;
  final bool playing;
  @override
  State<TileMoving> createState() => TileMovingState();
}

class TileMovingState extends State<TileMoving> {
  static final _way = [for (var k = 0; k < EffectTiles.moments.length; k++) k, for (var k = EffectTiles.moments.length - 2; k > 0; k--) k];
  int? _step;
  Timer? _clock;
  bool _awake = true; // (its tab, its page shown: TickerMode, as an AnimationController's)

  void _follow() {
    final go =
        widget.playing &&
        _awake &&
        File(EffectTiles.frame(widget.file, EffectTiles.moments.length - 1)).existsSync(); // (the last: one drawn with fewer stands until it is drawn again)
    if (go == (_clock != null)) return;
    _clock?.cancel();
    _clock = go
        ? Timer.periodic(
            const Duration(microseconds: 41667),
            (_) => mounted && _inSight() ? setState(() => _step = ((_step ?? EffectTiles.still) + 1) % _way.length) : null,
          )
        : null;
    if (!go) _step = null;
  }

  /// Whether some of it is in sight: within the shelf it scrolls in, and the window (a long shelf's tiles out of it stand still).
  bool _inSight() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    var r = box.localToGlobal(Offset.zero) & box.size;
    if (Scrollable.maybeOf(context)?.context.findRenderObject() case final RenderBox view when view.attached && view.hasSize) {
      r = r.intersect(view.localToGlobal(Offset.zero) & view.size);
    }
    r = r.intersect(Offset.zero & MediaQuery.sizeOf(context));
    return r.width > 0 && r.height > 0;
  }

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _awake = TickerMode.valuesOf(context).enabled;
    _follow();
  }

  @override
  void didUpdateWidget(TileMoving old) {
    super.didUpdateWidget(old);
    _follow();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image.file(
    key: ValueKey(FileStat.statSync(widget.file).modified),
    File(_step == null ? widget.file : EffectTiles.frame(widget.file, _way[_step!])),
    fit: BoxFit.cover,
    cacheWidth: EffectTiles.readWide,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox(),
  );
}
