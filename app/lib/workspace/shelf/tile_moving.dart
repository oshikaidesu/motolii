// A tile's moving image: played forward and back while it plays, otherwise its still.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

export '../../bridge/motolii.dart' show ShelfItem;

/// A tile's image. An animated one plays forward and back at 24 frames a second while [playing], so it neither steps
/// nor jumps where it loops (effect_tiles.dart). Otherwise, or when no animation sits beside the file, the still is shown.
///
/// It is keyed by the file's modification time, so a widget given the same file keeps its image. An equal image
/// provider is not resolved again.
class TileMoving extends StatefulWidget {
  const TileMoving(this.file, {super.key, required this.playing});
  final String file;
  final bool playing;
  @override
  State<TileMoving> createState() => TileMovingState();
}

class TileMovingState extends State<TileMoving> {
  static final _way = [
    for (var k = 0; k < EffectTiles.moments.length; k++) k,
    for (var k = EffectTiles.moments.length - 2; k > 0; k--) k,
  ];
  int? _step;
  Timer? _clock;
  // False while its tab or page is hidden, via TickerMode as an AnimationController does.
  bool _awake = true;

  void _follow() {
    final go =
        widget.playing &&
        _awake &&
        // Check the last frame: a tile drawn with fewer frames stays as it is until it is drawn again.
        File(EffectTiles.frame(widget.file, EffectTiles.moments.length - 1))
            .existsSync();
    if (go == (_clock != null)) return;
    _clock?.cancel();
    _clock = go
        ? Timer.periodic(
            const Duration(microseconds: 41667),
            (_) => mounted && _inSight()
                ? setState(
                    () => _step =
                        ((_step ?? EffectTiles.still) + 1) % _way.length,
                  )
                : null,
          )
        : null;
    if (!go) _step = null;
  }

  /// Whether any part of it is visible, within both the shelf it scrolls in and the window. Tiles of a long shelf outside them stay still.
  bool _inSight() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    var r = box.localToGlobal(Offset.zero) & box.size;
    if (Scrollable.maybeOf(context)?.context.findRenderObject()
        case final RenderBox view when view.attached && view.hasSize) {
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
  void didUpdateWidget(TileMoving oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    File(
      _step == null
          ? widget.file
          : EffectTiles.frame(widget.file, _way[_step!]),
    ),
    fit: BoxFit.cover,
    cacheWidth: EffectTiles.readWide,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox(),
  );
}
