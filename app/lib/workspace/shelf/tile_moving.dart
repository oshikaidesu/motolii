// A tile's moving image: played forward and back while it plays, otherwise its still.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:motolii/storage/disk.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

export '../../bridge/motolii.dart' show ShelfItem;

/// One clock for every moving tile, so the frames of all of them change on the same beat, in one frame, not each on its own timer.
class _Beat {
  static final beat = ValueNotifier<int>(0);
  static int _users = 0;
  static Timer? _timer;

  static void join() {
    if (_users++ == 0) {
      _timer = Timer.periodic(
        const Duration(microseconds: 41667),
        (_) => beat.value++,
      );
    }
  }

  static void leave() {
    if (--_users == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

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
  DateTime? _stamp;
  bool _clocked = false;
  // False while its tab or page is hidden, via TickerMode as an AnimationController does.
  bool _awake = true;

  void _follow() {
    _stamp = modifiedOf(widget.file);
    final go =
        widget.playing &&
        _awake &&
        // Check the last frame: a tile drawn with fewer frames stays as it is until it is drawn again.
        existsFile(
          EffectTiles.frame(widget.file, EffectTiles.moments.length - 1),
        );
    if (go == _clocked) return;
    _clocked = go;
    if (go) {
      _Beat.join();
      _Beat.beat.addListener(_next);
    } else {
      _Beat.beat.removeListener(_next);
      _Beat.leave();
      _step = null;
    }
  }

  void _next() {
    if (mounted && _inSight()) {
      setState(() => _step = ((_step ?? EffectTiles.still) + 1) % _way.length);
    }
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
    if (_clocked) {
      _Beat.beat.removeListener(_next);
      _Beat.leave();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image(
    key: ValueKey(_stamp),
    image: imageFile(
      _step == null
          ? widget.file
          : EffectTiles.frame(widget.file, _way[_step!]),
      cacheWidth: EffectTiles.readWide,
    ),
    fit: BoxFit.cover,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox(),
  );
}
