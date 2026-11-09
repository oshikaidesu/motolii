// dock_map_view.dart: the map drawn, its names over it and what the pointer is on; under it the list of the alike.
part of 'dock_map.dart';

/// The map: each shown item's tile where it lies ([DockMapPlaces]), inside its circle so none covers another ([aspect] a
/// tile's width to its height), the whole fitted to the room at one scale and zoomed as one, the tiles with it, as
/// FontMap's map (useMapRenderer: calculateMappingDimensions; useMapZoom: framed at 0.92 to start, never further out,
/// at most 10 times, moved only within its canvas); the rest left off; what is
/// said while it is being laid out. No colour of its own: the pictures tell them apart; the fonts' words, in one ink,
/// are inked by where they lie ([dockPalette]). [picked]: the one picked, its nearest under the map; [press]: one press on one
/// of them. What the pointer is on is told by it: its [peek] (its pictures moving, as the shelf's foot shows the
/// picked one) and its name of [names]. A pick leaves the map where the hand left it, as a pick in Figma leaves its
/// canvas (it moves by Zoom to Selection alone): flown to, the one picked dragged the view away (11/4, the user: "like
/// being grabbed by the shoulders"). From its corner how compact it is laid ([DockMapPlaces.squeeze], Obsidian's graph's
/// Center force).
class DockMap extends StatefulWidget {
  const DockMap(this.places, this.shown, {super.key, this.aspect = 1, this.picked, this.press, this.peek, this.names = const {}});
  final DockMapPlaces places;
  final List<(String, Widget)> shown;
  final double aspect;
  final String? picked;
  final void Function(String id)? press;
  final Widget Function(String id)? peek;
  final Map<String, String> names;
  @override
  State<DockMap> createState() => _DockMapState();
}

class _DockMapState extends State<DockMap> {
  final _keys = FocusNode(debugLabel: 'ws-map');
  String? _from; // (where the list of the alike was made from: the one pressed on the map, as XO's from its Space)
  final _seen = <String>[]; // (what was picked, in turn: XO's History)
  int _at = -1;
  final _view = TransformationController(); // (how near it is zoomed: what the pointer is on told at its size)
  final _over = ValueNotifier<String?>(null); // (the one the pointer is on)
  Map<String, Offset>? _atWas;
  Size _roomWas = Size.zero;
  bool _forces = false; // (Obsidian's graph settings opened from its corner: its Forces)

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
    if (id == null || (_at >= 0 && _seen[_at] == id)) return; // (gone to by the history itself: kept as it is)
    _seen
      ..removeRange(_at + 1, _seen.length)
      ..add(id);
    _at = _seen.length - 1;
  }

  /// XO's History: the up and down keys back and forth through what was picked.
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

  /// XO's arrows: [by] along the list of the alike (Shift: five).
  void _step(List<String> list, int by) {
    final i = list.indexOf(widget.picked ?? '');
    if (i < 0 || widget.press == null) return;
    widget.press!(list[(i + by).clamp(0, list.length - 1)]);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      widget.places.roomIs(box.maxWidth / box.maxHeight); // (laid out on a canvas the shape of the room it is seen in)
      return ListenableBuilder(
        listenable: Listenable.merge([widget.places.places, widget.places.laying]),
        builder: (context, _) {
          final at = widget.places.places.value;
          if (at.isEmpty) {
            return Center(child: Text(widget.places.laying.value ? 'Laying out the map…' : 'Nothing on the map yet', style: T.label(Grey.g63)));
          }
          final tiles = {for (final (id, tile) in widget.shown) id: tile};
          final sw = Shape.z(32) * widget.aspect, gap = Shape.s(4);
          final k = math.max(2, ((box.maxWidth - 3 * Shape.z(20) - 2 * gap) / (sw + gap)).floor());
          final picked = widget.picked;
          if (picked != null && at.containsKey(picked) && (_from == null || !widget.places.alike(_from!, tiles.keys, k).contains(picked))) {
            _from = picked; // (picked elsewhere: its own list)
          }
          final list = picked == null || _from == null || !tiles.containsKey(_from) ? const <String>[] : widget.places.alike(_from!, tiles.keys, k);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(list, -1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(list, 1),
              const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () => _step(list, -5),
              const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () => _step(list, 5),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () => _back(-1),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () => _back(1),
            },
            child: Focus(
              focusNode: _keys,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _keys.requestFocus(), // (the keys go to the map once it is pressed, not to the stage's nudge)
                child: Column(
                  children: [
                    Expanded(child: LayoutBuilder(builder: (context, room) => _map(at, tiles, Size(room.maxWidth, room.maxHeight)))),
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
    final r = dockSpreadRadius, a = widget.aspect, side = 2 * r / math.sqrt(1 + a * a); // (a tile inside its circle)
    var box = Rect.fromCenter(center: at.values.first, width: 0, height: 0);
    for (final p in at.values) {
      box = box.expandToInclude(Rect.fromCenter(center: p, width: 0, height: 0));
    }
    box = box.inflate(r);
    final s = math.min(room.width / box.width, room.height / box.height) * .92,
        left = (room.width - box.width * s) / 2 - box.left * s,
        top = (room.height - box.height * s) / 2 - box.top * s;
    Rect? place(String id) =>
        at[id] == null ? null : Rect.fromCenter(center: Offset(left + at[id]!.dx * s, top + at[id]!.dy * s), width: side * a * s, height: side * s);
    if (!identical(at, _atWas) || room != _roomWas) {
      // (laid out anew, or the room another size: where it was looking is gone, so the whole)
      if (_atWas != null) _view.value = Matrix4.identity();
      _atWas = at;
      _roomWas = room;
    }
    Widget item(String id, Widget tile) => MouseRegion(
      onEnter: (_) => _over.value = id,
      onExit: (_) => _over.value == id ? _over.value = null : null,
      child: Listener(onPointerDown: (_) => _from = id, child: tile), // (pressed on the map: the list made from it, as XO's Space)
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
                        // (laid out anew, each moves there: d3's transition, 250 ms, easeCubic, its defaults)
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
          Positioned.fill(child: IgnorePointer(child: _told(tiles, place, room))),
          Positioned(top: Shape.s(4), right: Shape.s(4), child: _settings()),
        ],
      ),
    );
  }

  /// Obsidian's graph settings, opened from the map's top right corner: its Forces' Center force, "how compact the graph
  /// is" ([DockMapPlaces.squeeze]), on the slider the Create shelf's Colours size is set by.
  Widget _settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      IconPress(dockMark(DockG.more), key: ValueKey('ws-map-$_name-forces'), on: _forces, onTap: () => setState(() => _forces = !_forces)),
      if (_forces)
        Container(
          key: ValueKey('ws-map-$_name-forces-open'),
          padding: EdgeInsets.all(Shape.s(6)),
          color: WsT.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Center force', style: T.label(Grey.g76)),
              ValueListenableBuilder(
                valueListenable: widget.places.squeeze,
                builder: (context, s, _) =>
                    MiniSlider(key: ValueKey('ws-map-$_name-center'), value: s, width: Shape.z(96), onChanged: (v) => widget.places.squeeze.value = v),
              ),
            ],
          ),
        ),
    ],
  );

  /// What the pointer is on, by it: its tile larger and its name (DataMapPlot's hover text, the Projector's label of
  /// the one hovered), kept inside the map.
  Widget _told(Map<String, Widget> tiles, Rect? Function(String) place, Size room) => ListenableBuilder(
    listenable: Listenable.merge([_over, _view]),
    builder: (context, _) {
      final id = _over.value, r = id == null ? null : place(id);
      if (id == null || r == null || tiles[id] == null) return const SizedBox();
      final w = Shape.z(140), at = MatrixUtils.transformRect(_view.value, r); // (as large as the foot's moving picture)
      final left = (at.right + Shape.s(6) + w > room.width ? at.left - Shape.s(6) - w : at.right + Shape.s(6)).clamp(0.0, math.max(0.0, room.width - w));
      return Stack(
        children: [
          Positioned(
            key: ValueKey('ws-map-$_name-told'),
            left: left.toDouble(),
            top: at.top.clamp(0.0, math.max(0.0, room.height - w / widget.aspect - Shape.z(24))).toDouble(),
            width: w,
            child: Container(
              padding: EdgeInsets.all(Shape.s(4)),
              color: WsT.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: w, height: (w - Shape.s(8)) / widget.aspect, child: widget.peek?.call(id) ?? tiles[id]),
                  SizedBox(height: Shape.s(4)),
                  Text(widget.names[id] ?? id.split('/').last, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  /// XO's Similarity List under the map: its arrows, the alike in a row, and its Refresh (the picked one first:
  /// Splice's Similar Sounds run again on one of its matches).
  Widget _alike(List<String> list, Map<String, Widget> tiles, double sw, double gap) {
    final i = list.indexOf(widget.picked ?? '');
    Widget arrow(String key, int by) => Transform.flip(
      flipX: by < 0,
      child: IconPress(dockMark(DockG.chevron), key: ValueKey('ws-map-$_name-$key'), onTap: () => _step(list, by)),
    );
    return Container(
      key: ValueKey('ws-alike-$_name'),
      padding: EdgeInsets.symmetric(vertical: gap),
      color: WsT.card,
      child: Row(
        children: [
          arrow('prev', -1),
          Expanded(
            child: Row(
              children: [
                for (final id in list)
                  Padding(
                    padding: EdgeInsets.only(right: gap),
                    child: SizedBox(key: ValueKey('ws-alike-$_name-$id'), width: sw, height: sw / widget.aspect, child: tiles[id]),
                  ),
              ],
            ),
          ),
          arrow('next', 1),
          IconPress(dockMark(DockG.reload), key: ValueKey('ws-map-$_name-refresh'), on: i > 0, onTap: () => setState(() => _from = widget.picked)),
        ],
      ),
    );
  }
}
