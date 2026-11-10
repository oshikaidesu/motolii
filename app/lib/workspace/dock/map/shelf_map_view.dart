// Draws the map, the name of the item under the pointer, and the similarity list below it.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// The map view: each shown item's tile at its position from [DockMapPlaces].
///
/// The tiles are drawn inside a circle so none covers another. The whole map is fitted to the viewport at one scale and
/// zoomed as one, tiles included, as in FontMap (useMapRenderer: calculateMappingDimensions; useMapZoom). It starts
/// framed at 0.92, never zooms out further, zooms in at most 10 times, and can only be moved within its canvas.
/// Items not in [DockMap.shown] are left off, and a message is shown while the map is being laid out.
///
/// The map has no colour of its own because the images tell items apart. Font names, drawn in one ink, are coloured by
/// position ([dockPalette]).
///
/// Picking an item leaves the map where the user put it, as picking in Figma leaves its canvas. Only Zoom to Selection
/// moves it. Flying to the picked item dragged the view away from the user, who said it felt like being grabbed by the
/// shoulders. A button in the top right corner sets how compact the layout is ([DockMapPlaces.squeeze], Obsidian's graph
/// "Center force").
class DockMap extends StatefulWidget {
  const DockMap(
    this.places,
    this.shown, {
    super.key,
    this.aspect = 1,
    this.picked,
    this.press,
    this.peek,
    this.names = const {},
  });

  /// Where each item lies.
  final DockMapPlaces places;

  /// The items to show, each an id and its tile.
  final List<(String, Widget)> shown;

  /// Width to height of a tile.
  final double aspect;

  /// The id of the picked item. Its nearest items are listed below the map.
  final String? picked;

  /// Called when the user presses an item.
  final void Function(String id)? press;

  /// Builds the moving image shown for the item under the pointer, as the shelf's footer does for the picked one.
  final Widget Function(String id)? peek;

  /// The name shown beside the item under the pointer, by id.
  final Map<String, String> names;
  @override
  State<DockMap> createState() => _DockMapState();
}

class _DockMapState extends State<DockMap> {
  final _keys = FocusNode(debugLabel: 'ws-map');

  /// The item the similarity list is built from: the one pressed on the map, as in XO's Space.
  String? _from;

  /// Items in the order they were picked, like XO's History.
  final _seen = <String>[];
  int _at = -1;

  /// The zoom state. The hover label is sized with it.
  final _view = TransformationController();

  /// The id of the item under the pointer.
  final _over = ValueNotifier<String?>(null);
  Map<String, Offset>? _atWas;
  Size _roomWas = Size.zero;

  /// Whether the force settings are open. They are opened from the corner button, like Obsidian's graph settings.
  bool _forces = false;

  @override
  void initState() {
    super.initState();
    _saw(widget.picked);
  }

  @override
  void didUpdateWidget(DockMap old) {
    super.didUpdateWidget(old);
    if (widget.picked != old.picked) _saw(widget.picked);
  }

  void _saw(String? id) {
    // Ignore a pick that came from stepping through the history itself.
    if (id == null || (_at >= 0 && _seen[_at] == id)) return;
    _seen
      ..removeRange(_at + 1, _seen.length)
      ..add(id);
    _at = _seen.length - 1;
  }

  /// Moves [by] steps through the picked items, like XO's History. The up and down keys call this.
  void _back(int by) {
    final i = _at + by;
    if (i < 0 || i >= _seen.length || widget.press == null) return;
    _at = i;
    widget.press!(_seen[i]);
  }

  @override
  void dispose() {
    _keys.dispose();
    _view.dispose();
    _over.dispose();
    super.dispose();
  }

  String get _name => widget.places.name;

  /// Moves [by] items along the similarity list, like XO's arrows. Shift moves five.
  void _step(List<String> list, int by) {
    final i = list.indexOf(widget.picked ?? '');
    if (i < 0 || widget.press == null) return;
    widget.press!(list[(i + by).clamp(0, list.length - 1)]);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Lay out on a canvas shaped like the viewport.
      widget.places.roomIs(box.maxWidth / box.maxHeight);
      return ListenableBuilder(
        listenable: Listenable.merge([
          widget.places.places,
          widget.places.laying,
        ]),
        builder: (context, _) {
          final at = widget.places.places.value;
          if (at.isEmpty) {
            return Center(
              child: Text(
                widget.places.laying.value
                    ? 'Laying out the map…'
                    : 'Nothing on the map yet',
                style: TextStyles.label(Grey.g63),
              ),
            );
          }
          final tiles = {for (final (id, tile) in widget.shown) id: tile};
          final sw = Shape.z(32) * widget.aspect, gap = Shape.s(4);
          final k = math.max(
            2,
            ((box.maxWidth - 3 * Shape.z(20) - 2 * gap) / (sw + gap)).floor(),
          );
          final picked = widget.picked;
          if (picked != null &&
              at.containsKey(picked) &&
              (_from == null ||
                  !widget.places
                      .alike(_from!, tiles.keys, k)
                      .contains(picked))) {
            // Picked elsewhere, so it gets its own list.
            _from = picked;
          }
          final list =
              picked == null || _from == null || !tiles.containsKey(_from)
              ? const <String>[]
              : widget.places.alike(_from!, tiles.keys, k);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _step(list, -1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _step(list, 1),
              const SingleActivator(
                LogicalKeyboardKey.arrowLeft,
                shift: true,
              ): () =>
                  _step(list, -5),
              const SingleActivator(
                LogicalKeyboardKey.arrowRight,
                shift: true,
              ): () =>
                  _step(list, 5),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _back(-1),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _back(1),
            },
            child: Focus(
              focusNode: _keys,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                // Once the map is pressed the keys go to it, not to the canvas nudge.
                onPointerDown: (_) => _keys.requestFocus(),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, room) => _map(
                          at,
                          tiles,
                          Size(room.maxWidth, room.maxHeight),
                        ),
                      ),
                    ),
                    if (list.length > 1) _alike(list, tiles, sw, gap),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _map(Map<String, Offset> at, Map<String, Widget> tiles, Size room) {
    // A tile's side is such that the tile fits inside its circle.
    final r = dockSpreadRadius,
        a = widget.aspect,
        side = 2 * r / math.sqrt(1 + a * a);
    var box = Rect.fromCenter(center: at.values.first, width: 0, height: 0);
    for (final p in at.values) {
      box = box.expandToInclude(
        Rect.fromCenter(center: p, width: 0, height: 0),
      );
    }
    box = box.inflate(r);
    final s = math.min(room.width / box.width, room.height / box.height) * .92,
        left = (room.width - box.width * s) / 2 - box.left * s,
        top = (room.height - box.height * s) / 2 - box.top * s;
    Rect? place(String id) => at[id] == null
        ? null
        : Rect.fromCenter(
            center: Offset(left + at[id]!.dx * s, top + at[id]!.dy * s),
            width: side * a * s,
            height: side * s,
          );
    if (!identical(at, _atWas) || room != _roomWas) {
      // The layout or the viewport changed, so the old view is meaningless. Show the whole map.
      if (_atWas != null) _view.value = Matrix4.identity();
      _atWas = at;
      _roomWas = room;
    }
    Widget item(String id, Widget tile) => MouseRegion(
      onEnter: (_) => _over.value = id,
      onExit: (_) => _over.value == id ? _over.value = null : null,
      // Pressing on the map makes the similarity list start from this item, as in XO's Space.
      child: Listener(onPointerDown: (_) => _from = id, child: tile),
    );

    return ClipRect(
      child: Stack(
        children: [
          InteractiveViewer(
            key: ValueKey('ws-map-$_name'),
            transformationController: _view,
            minScale: 1,
            maxScale: 10 / .92,
            child: SizedBox.fromSize(
              size: room,
              child: Stack(
                children: [
                  for (final MapEntry(key: id, value: tile) in tiles.entries)
                    if (place(id) case final at?)
                      AnimatedPositioned.fromRect(
                        // After a new layout each tile moves to its place with d3's default transition: 250 ms, easeCubic.
                        key: ValueKey('ws-map-$_name-$id'),
                        rect: at,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        child: item(id, tile),
                      ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: _told(tiles, place, room)),
          ),
          Positioned(top: Shape.s(4), right: Shape.s(4), child: _settings()),
        ],
      ),
    );
  }

  /// The settings opened from the map's top right corner, like Obsidian's graph settings.
  ///
  /// They hold its Center force, "how compact the graph is" ([DockMapPlaces.squeeze]), on the same slider the Create
  /// shelf uses for the size of Colours.
  Widget _settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      IconPress(
        dockMark(AppGlyphs.more),
        key: ValueKey('ws-map-$_name-forces'),
        on: _forces,
        onTap: () => setState(() => _forces = !_forces),
      ),
      if (_forces)
        Container(
          key: ValueKey('ws-map-$_name-forces-open'),
          padding: EdgeInsets.all(Shape.s(6)),
          color: WindowTokens.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Center force', style: TextStyles.label(Grey.g76)),
              ValueListenableBuilder(
                valueListenable: widget.places.squeeze,
                builder: (context, s, _) => MiniSlider(
                  key: ValueKey('ws-map-$_name-center'),
                  values: [s],
                  width: Shape.z(96),
                  onChanged: (v) => widget.places.squeeze.value = v.first,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  /// Shows the item under the pointer larger, with its name, kept inside the map.
  ///
  /// This is DataMapPlot's hover text, and the Embedding Projector's label of the hovered point.
  Widget _told(
    Map<String, Widget> tiles,
    Rect? Function(String) place,
    Size room,
  ) => ListenableBuilder(
    listenable: Listenable.merge([_over, _view]),
    builder: (context, _) {
      final id = _over.value, r = id == null ? null : place(id);
      if (id == null || r == null || tiles[id] == null) return const SizedBox();
      // The same size as the moving image in the footer.
      final w = Shape.z(140), at = MatrixUtils.transformRect(_view.value, r);
      final left =
          (at.right + Shape.s(6) + w > room.width
                  ? at.left - Shape.s(6) - w
                  : at.right + Shape.s(6))
              .clamp(0.0, math.max(0.0, room.width - w));
      return Stack(
        children: [
          Positioned(
            key: ValueKey('ws-map-$_name-told'),
            left: left.toDouble(),
            top: at.top
                .clamp(
                  0.0,
                  math.max(0.0, room.height - w / widget.aspect - Shape.z(24)),
                )
                .toDouble(),
            width: w,
            child: Container(
              padding: EdgeInsets.all(Shape.s(4)),
              color: WindowTokens.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: w,
                    height: (w - Shape.s(8)) / widget.aspect,
                    child: widget.peek?.call(id) ?? tiles[id],
                  ),
                  SizedBox(height: Shape.s(4)),
                  Text(
                    widget.names[id] ?? id.split('/').last,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.label(Grey.g91),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  /// The similarity list under the map, after XO's Similarity List.
  ///
  /// It has arrows and the similar items in a row. The picked item comes first, like Splice's Similar Sounds run again
  /// on one of its matches.
  Widget _alike(
    List<String> list,
    Map<String, Widget> tiles,
    double sw,
    double gap,
  ) {
    final i = list.indexOf(widget.picked ?? '');
    Widget arrow(String key, int by) => Transform.flip(
      flipX: by < 0,
      child: IconPress(
        dockMark(AppGlyphs.chevron),
        key: ValueKey('ws-map-$_name-$key'),
        onTap: () => _step(list, by),
      ),
    );
    return Container(
      key: ValueKey('ws-alike-$_name'),
      padding: EdgeInsets.symmetric(vertical: gap),
      color: WindowTokens.card,
      child: Row(
        children: [
          arrow('prev', -1),
          Expanded(
            child: Row(
              children: [
                for (final id in list)
                  Padding(
                    padding: EdgeInsets.only(right: gap),
                    child: SizedBox(
                      key: ValueKey('ws-alike-$_name-$id'),
                      width: sw,
                      height: sw / widget.aspect,
                      child: tiles[id],
                    ),
                  ),
              ],
            ),
          ),
          arrow('next', 1),
          IconPress(
            dockMark(AppGlyphs.reload),
            key: ValueKey('ws-map-$_name-refresh'),
            on: i > 0,
            onTap: () => setState(() => _from = widget.picked),
          ),
        ],
      ),
    );
  }
}
