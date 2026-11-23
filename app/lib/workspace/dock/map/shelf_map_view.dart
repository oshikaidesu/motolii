// The map view: items at their embedding positions, cluster zone labels, zoom bar, hover loupe, and similarity list.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress, Pressable;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/dock/map/spread.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// Tiles at their [ShelfMap] positions, fitted to the viewport at 0.94×, zoomable up to 10×.
/// Shows subtle dot grid, cluster island labels & halos, zoom controls, and an enlarged hover loupe.
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
    this.groups = const {},
  });

  final ShelfMap places;
  final List<(String, Widget)> shown;
  final double aspect;
  final String? picked;
  final void Function(String id)? press;
  final Widget Function(String id)? peek;
  final Map<String, String> names;

  /// Optional category / cluster label per item id (e.g. "Blur", "Glitch", "Japanese", "Serif").
  final Map<String, String> groups;

  @override
  State<ShelfMapView> createState() => _ShelfMapViewState();
}

class _ClusterZone {
  const _ClusterZone({
    required this.label,
    required this.center,
    required this.radius,
    required this.count,
    required this.color,
  });
  final String label;
  final Offset center;
  final double radius;
  final int count;
  final Color color;
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
  bool _showLabels = true;
  double _tileBoost = 1.18;

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

  double get _currentScale => _view.value.getMaxScaleOnAxis().clamp(1.0, 11.0);

  void _zoomBy(double factor, Size room) {
    final cur = _currentScale;
    final next = (cur * factor).clamp(1.0, 10.0);
    if ((next - cur).abs() < 1e-3) return;
    if (next <= 1.01) {
      _view.value = Matrix4.identity();
      return;
    }
    final cx = room.width / 2;
    final cy = room.height / 2;
    final m = _view.value.clone();
    final ratio = next / cur;
    final tx = m.storage[12];
    final ty = m.storage[13];
    m.storage[0] = next;
    m.storage[5] = next;
    m.storage[12] = (cx - (cx - tx) * ratio).clamp(room.width * (1 - next), 0);
    m.storage[13] = (cy - (cy - ty) * ratio).clamp(room.height * (1 - next), 0);
    _view.value = m;
  }

  void _resetZoom() {
    _view.value = Matrix4.identity();
  }

  /// Computes spatial cluster zones (centroid + radius) for the densest visible categories.
  List<_ClusterZone> _computeZones(
    Map<String, Offset> at,
    Set<String> visibleIds,
    Rect? Function(String) place,
    Map<String, Color> palette,
  ) {
    if (widget.groups.isEmpty || visibleIds.isEmpty) return const [];
    final byGroup = <String, List<(String, Offset)>>{};
    for (final id in visibleIds) {
      final g = widget.groups[id];
      if (g == null || g.isEmpty) continue;
      final r = place(id);
      if (r == null) continue;
      (byGroup[g] ??= []).add((id, r.center));
    }
    final zones = <_ClusterZone>[];
    for (final MapEntry(key: label, value: pts) in byGroup.entries) {
      if (pts.length < 3) continue;
      // Use coordinate median to anchor each island at its main cluster rather than outliers.
      final xs = [for (final p in pts) p.$2.dx]..sort();
      final ys = [for (final p in pts) p.$2.dy]..sort();
      final center = Offset(xs[xs.length ~/ 2], ys[ys.length ~/ 2]);
      // Radius covers the inner 65% of points around the median.
      final dists = [for (final p in pts) (p.$2 - center).distance]..sort();
      final rad = math.max(26.0, dists[(dists.length * 0.65).floor()]);
      final sampleId = pts.first.$1;
      final col = palette[sampleId] ?? WindowTokens.accent;
      zones.add(
        _ClusterZone(
          label: label,
          center: center,
          radius: rad,
          count: pts.length,
          color: col,
        ),
      );
    }
    zones.sort((a, b) => b.count.compareTo(a.count));
    // Suppress overlapping labels so the map stays crisp and legible.
    final kept = <_ClusterZone>[];
    for (final z in zones) {
      final overlaps = kept.any((k) => (k.center - z.center).distance < 68.0);
      if (!overlaps) kept.add(z);
      if (kept.length >= 14) break;
    }
    return kept;
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
          final sw = Shape.z(36) * widget.aspect, gap = Shape.s(4);
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
    final s = math.min(room.width / box.width, room.height / box.height) * .94,
        left = (room.width - box.width * s) / 2 - box.left * s,
        top = (room.height - box.height * s) / 2 - box.top * s;
    final tileW = math.max(12.0, side * a * s * _tileBoost);
    final tileH = math.max(10.0, side * s * _tileBoost);
    Rect? place(String id) => at[id] == null
        ? null
        : Rect.fromCenter(
            center: Offset(left + at[id]!.dx * s, top + at[id]!.dy * s),
            width: tileW,
            height: tileH,
          );
    if (!identical(at, _atWas) || room != _roomWas) {
      // Reset view when layout or viewport changes.
      if (_atWas != null) _view.value = Matrix4.identity();
      _atWas = at;
      _roomWas = room;
    }
    final palette = widget.places.paletteOf(at);
    final zones = _showLabels
        ? _computeZones(at, tiles.keys.toSet(), place, palette)
        : const <_ClusterZone>[];
    Widget item(String id, Widget tile) {
      final isPicked = widget.picked == id;
      return MouseRegion(
        onEnter: (_) => _over.value = id,
        onExit: (_) => _over.value == id ? _over.value = null : null,
        child: Listener(
          onPointerDown: (_) => _from = id,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: Shape.round(2),
              border: Border.all(
                color: isPicked
                    ? WindowTokens.accent
                    : Grey.g38.withValues(alpha: 0.45),
                width: isPicked ? 1.6 : 0.6,
              ),
            ),
            child: ClipRRect(borderRadius: Shape.round(2), child: tile),
          ),
        ),
      );
    }

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
          InteractiveViewer(
            key: ValueKey('ws-map-$_name'),
            transformationController: _view,
            minScale: 1,
            maxScale: 10 / .94,
            child: SizedBox.fromSize(
              size: room,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (zones.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _ClusterHaloPainter(zones)),
                      ),
                    ),
                  for (final MapEntry(key: id, value: tile) in tiles.entries)
                    if (place(id) case final rect?)
                      AnimatedPositioned.fromRect(
                        key: ValueKey('ws-map-$_name-$id'),
                        rect: rect,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: item(id, tile),
                      ),
                ],
              ),
            ),
          ),
          if (zones.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(child: _clusterLabelsOverlay(zones, room)),
            ),
          Positioned.fill(
            child: IgnorePointer(child: _told(tiles, place, room)),
          ),
          Positioned(
            top: Shape.s(6),
            right: Shape.s(6),
            child: _controls(room),
          ),
          Positioned(
            left: Shape.s(8),
            bottom: Shape.s(6),
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Shape.s(6),
                  vertical: Shape.s(2),
                ),
                decoration: BoxDecoration(
                  color: WindowTokens.card.withValues(alpha: 0.84),
                  borderRadius: Shape.round(4),
                  border: Border.all(color: WindowTokens.line),
                ),
                child: Text(
                  '${tiles.length} shown · Scroll to zoom · Drag to pan',
                  style: TextStyles.micro(Grey.g63),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders crisp, constant-size category pill labels anchored near the top edge of each island.
  Widget _clusterLabelsOverlay(
    List<_ClusterZone> zones,
    Size room,
  ) => ValueListenableBuilder<Matrix4>(
    valueListenable: _view,
    builder: (context, mat, _) {
      final zoom = mat.getMaxScaleOnAxis().clamp(1.0, 10.0);
      final fade = zoom <= 2.0
          ? 1.0
          : (1.0 - (zoom - 2.0) * 0.25).clamp(0.35, 1.0);
      return Opacity(
        opacity: fade,
        child: Stack(
          children: [
            for (final z in zones)
              () {
                final anchor = Offset(
                  z.center.dx,
                  z.center.dy - z.radius * 0.78,
                );
                final p = MatrixUtils.transformPoint(mat, anchor);
                if (p.dx < -40 ||
                    p.dx > room.width + 40 ||
                    p.dy < -20 ||
                    p.dy > room.height + 20) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  left: (p.dx - 46).clamp(4.0, math.max(4.0, room.width - 104)),
                  top: (p.dy - 10).clamp(4.0, math.max(4.0, room.height - 24)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Shape.s(6),
                      vertical: Shape.s(2),
                    ),
                    decoration: BoxDecoration(
                      color: WindowTokens.body.withValues(alpha: 0.86),
                      borderRadius: Shape.round(99),
                      border: Border.all(
                        color: z.color.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: z.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: Shape.s(4)),
                        Text(
                          z.label,
                          style: TextStyles.micro(Grey.g91)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: Shape.s(3)),
                        Text('${z.count}', style: TextStyles.micro(Grey.g56)),
                      ],
                    ),
                  ),
                );
              }(),
          ],
        ),
      );
    },
  );

  Widget _controls(Size room) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(4),
          vertical: Shape.s(2),
        ),
        decoration: BoxDecoration(
          color: WindowTokens.card.withValues(alpha: 0.92),
          borderRadius: Shape.round(5),
          border: Border.all(color: WindowTokens.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniToolButton(
              key: ValueKey('ws-map-$_name-zoom-out'),
              label: '−',
              onTap: () => _zoomBy(0.72, room),
            ),
            ValueListenableBuilder<Matrix4>(
              valueListenable: _view,
              builder: (_, _, _) => _MiniToolButton(
                key: ValueKey('ws-map-$_name-zoom-fit'),
                label: _currentScale <= 1.02
                    ? 'Fit'
                    : '${(_currentScale * 100).round()}%',
                onTap: _resetZoom,
              ),
            ),
            _MiniToolButton(
              key: ValueKey('ws-map-$_name-zoom-in'),
              label: '+',
              onTap: () => _zoomBy(1.4, room),
            ),
            if (widget.groups.isNotEmpty) ...[
              Container(
                width: 1,
                height: Shape.z(12),
                margin: EdgeInsets.symmetric(horizontal: Shape.s(3)),
                color: WindowTokens.line,
              ),
              _MiniToolButton(
                key: ValueKey('ws-map-$_name-labels'),
                label: 'Tags',
                on: _showLabels,
                onTap: () => setState(() => _showLabels = !_showLabels),
              ),
            ],
            Container(
              width: 1,
              height: Shape.z(12),
              margin: EdgeInsets.symmetric(horizontal: Shape.s(3)),
              color: WindowTokens.line,
            ),
            IconPress(
              dockMark(AppGlyphs.more),
              key: ValueKey('ws-map-$_name-forces'),
              tip: 'Map layout options',
              on: _forces,
              onTap: () => setState(() => _forces = !_forces),
            ),
          ],
        ),
      ),
      if (_forces)
        Container(
          key: ValueKey('ws-map-$_name-forces-open'),
          margin: EdgeInsets.only(top: Shape.s(4)),
          padding: EdgeInsets.all(Shape.s(8)),
          decoration: BoxDecoration(
            color: WindowTokens.card,
            borderRadius: Shape.round(6),
            border: Border.all(color: WindowTokens.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tile size', style: TextStyles.label(Grey.g76)),
              MiniSlider(
                key: ValueKey('ws-map-$_name-size'),
                values: [((_tileBoost - 0.8) / 1.0).clamp(0.0, 1.0)],
                width: Shape.z(104),
                onChanged: (v) =>
                    setState(() => _tileBoost = 0.8 + v.first * 1.0),
              ),
              SizedBox(height: Shape.s(6)),
              Text('Center force', style: TextStyles.label(Grey.g76)),
              ValueListenableBuilder(
                valueListenable: widget.places.squeeze,
                builder: (context, s, _) => MiniSlider(
                  key: ValueKey('ws-map-$_name-center'),
                  values: [s],
                  width: Shape.z(104),
                  onChanged: (v) => widget.places.squeeze.value = v.first,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  /// Enlarged hover loupe card: shows a clear preview, name, and category tag.
  Widget _told(
    Map<String, Widget> tiles,
    Rect? Function(String) place,
    Size room,
  ) => ListenableBuilder(
    listenable: Listenable.merge([_over, _view]),
    builder: (context, _) {
      final id = _over.value, r = id == null ? null : place(id);
      if (id == null || r == null || tiles[id] == null) return const SizedBox();
      final w = Shape.z(184), at = MatrixUtils.transformRect(_view.value, r);
      final left =
          (at.right + Shape.s(8) + w > room.width
                  ? at.left - Shape.s(8) - w
                  : at.right + Shape.s(8))
              .clamp(4.0, math.max(4.0, room.width - w - 4));
      final previewH = ((w - Shape.s(12)) / widget.aspect).clamp(52.0, 148.0);
      final group = widget.groups[id];
      return Stack(
        children: [
          Positioned(
            key: ValueKey('ws-map-$_name-told'),
            left: left.toDouble(),
            top: at.top
                .clamp(4.0, math.max(4.0, room.height - previewH - Shape.z(44)))
                .toDouble(),
            width: w,
            child: Container(
              padding: EdgeInsets.all(Shape.s(6)),
              decoration: BoxDecoration(
                color: WindowTokens.card,
                borderRadius: Shape.round(6),
                border: Border.all(
                  color: WindowTokens.accent.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Grey.g00.withValues(alpha: 0.55),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: Shape.round(4),
                    child: Container(
                      width: w - Shape.s(12),
                      height: previewH,
                      color: WindowTokens.well,
                      child: widget.peek?.call(id) ?? tiles[id],
                    ),
                  ),
                  SizedBox(height: Shape.s(6)),
                  Text(
                    widget.names[id] ?? id.split('/').last,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.name(Grey.g95)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (group != null && group.isNotEmpty) ...[
                    SizedBox(height: Shape.s(2)),
                    Text(
                      group,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.micro(Grey.g63),
                    ),
                  ],
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
      decoration: BoxDecoration(
        color: WindowTokens.card,
        border: Border(top: BorderSide(color: WindowTokens.line)),
      ),
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

class _MiniToolButton extends StatelessWidget {
  const _MiniToolButton({
    super.key,
    required this.label,
    required this.onTap,
    this.on = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(6),
        vertical: Shape.s(3),
      ),
      decoration: BoxDecoration(
        color: on
            ? WindowTokens.accent.withValues(alpha: 0.2)
            : (hot ? WindowTokens.raised : null),
        borderRadius: Shape.round(3),
      ),
      child: Text(
        label,
        style: TextStyles.micro(
          on ? WindowTokens.accent : (hot ? Grey.g95 : Grey.g76),
        ).copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = WindowTokens.body);
    const step = 24.0;
    final dot = Paint()..color = Grey.g26.withValues(alpha: 0.55);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}

class _ClusterHaloPainter extends CustomPainter {
  const _ClusterHaloPainter(this.zones);
  final List<_ClusterZone> zones;

  @override
  void paint(Canvas canvas, Size size) {
    for (final z in zones) {
      final rect = Rect.fromCircle(center: z.center, radius: z.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            z.color.withValues(alpha: 0.14),
            z.color.withValues(alpha: 0.04),
            z.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(rect);
      canvas.drawCircle(z.center, z.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ClusterHaloPainter oldDelegate) =>
      oldDelegate.zones.length != zones.length;
}
