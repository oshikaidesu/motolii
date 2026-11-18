// The map view: items at their embedding positions, hover label, and similarity list.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/dock/map/spread.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// Tiles at their [ShelfMap] positions, fitted to the viewport at 0.92×, zoomable up to 10×.
/// Picking does not move the map (flying to the item felt disorienting).
class ShelfMapView extends StatefulWidget {
  const ShelfMapView(
    this.places,
    this.shown, {
    super.key,
    this.aspect = 1,
    this.picked,
    this.press,
    this.peek,
    this.names = const {},
  });

  final ShelfMap places;
  final List<(String, Widget)> shown;
  final double aspect;
  final String? picked;
  final void Function(String id)? press;
  final Widget Function(String id)? peek;
  final Map<String, String> names;
  @override
  State<ShelfMapView> createState() => _ShelfMapViewState();
}

class _ShelfMapViewState extends State<ShelfMapView> {
  final _keys = FocusNode(debugLabel: 'ws-map');

  String? _from;

  final _seen = <String>[];
  int _at = -1;

  final _view = TransformationController();

  final _over = ValueNotifier<String?>(null);
  Map<String, Offset>? _atWas;
  Size _roomWas = Size.zero;

  bool _forces = false;

  @override
  void initState() {
    super.initState();
    _saw(widget.picked);
  }

  @override
  void didUpdateWidget(ShelfMapView old) {
    super.didUpdateWidget(old);
    if (widget.picked != old.picked) _saw(widget.picked);
  }

  void _saw(String? id) {
    if (id == null || (_at >= 0 && _seen[_at] == id)) return;
    _seen
      ..removeRange(_at + 1, _seen.length)
      ..add(id);
    _at = _seen.length - 1;
  }

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

  void _step(List<String> list, int by) {
    final i = list.indexOf(widget.picked ?? '');
    if (i < 0 || widget.press == null) return;
    widget.press!(list[(i + by).clamp(0, list.length - 1)]);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
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
                // Keys go to the map once pressed, not to the canvas nudge.
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
    final r = mapTileRadius,
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
      // Reset view when layout or viewport changes.
      if (_atWas != null) _view.value = Matrix4.identity();
      _atWas = at;
      _roomWas = room;
    }
    Widget item(String id, Widget tile) => MouseRegion(
      onEnter: (_) => _over.value = id,
      onExit: (_) => _over.value == id ? _over.value = null : null,
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
                        key: ValueKey('ws-map-$_name-$id'),
                        rect: at,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
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

  Widget _settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      IconPress(
        dockMark(AppGlyphs.more),
        key: ValueKey('ws-map-$_name-forces'),
        tip: 'Forces',
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

  /// Hover card: the item under the pointer shown larger, with its name.
  Widget _told(
    Map<String, Widget> tiles,
    Rect? Function(String) place,
    Size room,
  ) => ListenableBuilder(
    listenable: Listenable.merge([_over, _view]),
    builder: (context, _) {
      final id = _over.value, r = id == null ? null : place(id);
      if (id == null || r == null || tiles[id] == null) return const SizedBox();
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

  /// Similarity row: arrows and nearest items, picked item first.
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
        tip: by < 0 ? 'Previous' : 'Next',
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
            tip: 'Reload',
            on: i > 0,
            onTap: () => setState(() => _from = widget.picked),
          ),
        ],
      ),
    );
  }
}
