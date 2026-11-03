// A shelf's map, as XLN Audio's XO's Space: each item where what is alike lies near (laid out by the inside's t-SNE,
// motolii_map, as XO's are), then each given a cell of a grid so none hides another (Kyle McDonald's CloudToGrid, the
// inside's motolii_grid); the shelf's chips and words narrowing which are shown, as XO's filters narrow its Space;
// moved and zoomed by Flutter's own InteractiveViewer. Under it XO's Similarity List (Splice's Similar Sounds beside
// its list): the nearest to the one picked, stepped along by its arrows or the left and right keys. Laid out again
// when what the shelf holds changes (XO's Scan & Refresh, done by itself), kept between openings beside the tiles
// (~/Library/Caches/Motolii).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../motolii.dart' show Motolii, MotoliiQuestions;
import '../tokens.dart';
import 'dock_glyphs.dart';
import 'dock_parts.dart' show DockIconButton;
import 'ws.dart' show WsT;

/// Where one shelf's items lie on its map, by id, 0 to 1 each way; [laying] while that is being worked out.
class DockMapPlaces {
  DockMapPlaces(this.name) {
    places.addListener(_grids.clear);
  }
  final String name;
  final places = ValueNotifier<Map<String, Offset>>(const {});
  final laying = ValueNotifier<bool>(false);
  /// Told when a grid is laid ([grid]).
  final gridded = ValueNotifier<int>(0);
  String? _for;
  Motolii? _m;
  final _grids = <String, Map<String, int>?>{};

  File get _kept => File('${Platform.environment['HOME']}/Library/Caches/Motolii/map_$name.json');

  /// Laid out for these items (each its id and what it is read from), each read as numbers by [read] (null: left off the
  /// map); only when they are not the ones laid out last, nor the ones kept from before ([also]: what else they were
  /// laid out by, the same items read again when it changes).
  void need(Motolii m, List<(String, String)> items, Future<List<Float32List?>> Function(List<String> from) read, {String also = ''}) {
    _m = m;
    final key = jsonEncode([also, for (final (id, from) in items) '$id\t$from']);
    if (key == _for) return;
    _for = key;
    Zone.root.run(() async {   // (on the program's own clock, as fontsRead: a test may wait for it)
      try {
        final kept = jsonDecode(await _kept.readAsString()) as Map<String, dynamic>;
        if (kept['for'] == key) {
          places.value = {for (final MapEntry(key: id, value: at) in (kept['places'] as Map<String, dynamic>).entries) id: Offset(((at as List)[0] as num).toDouble(), (at[1] as num).toDouble())};
          return;
        }
      } catch (_) {}   // (none kept, or for others: laid out now)
      laying.value = true;
      final numbers = await read([for (final (_, from) in items) from]);
      final ids = [for (final (i, (id, _)) in items.indexed) if (numbers[i] != null) id];
      final laid = await m.map([for (final v in numbers) ?v]);
      if (key != _for) return;   // (asked for others meanwhile: theirs comes)
      laying.value = false;
      places.value = laid == null ? const {} : {for (final (i, id) in ids.indexed) id: Offset(laid[i].$1, laid[i].$2)};
      try {
        _kept.parent.createSync(recursive: true);
        await _kept.writeAsString(jsonEncode({'for': key, 'places': {for (final MapEntry(key: id, value: at) in places.value.entries) id: [at.dx, at.dy]}}));
      } catch (_) {}   // (not kept: laid out again next time)
    });
  }

  /// Each item's cell of a [cols] x [rows] grid (row * cols + column), the nearest for them all; null while it is
  /// being worked out (asked now, [gridded] told when done) or where it cannot be (too many: left where they lie).
  Map<String, int>? grid(int cols, int rows) {
    final key = '$cols x $rows', laid = places.value, m = _m;
    if (_grids.containsKey(key) || m == null || laid.isEmpty) return _grids[key];
    _grids[key] = null;
    Zone.root.run(() async {
      final cells = await m.grid([for (final p in laid.values) (p.dx, p.dy)], cols, rows);
      if (!identical(laid, places.value)) return;   // (laid out again meanwhile: its own grid is asked)
      _grids[key] = cells == null ? const {} : {for (final (i, id) in laid.keys.indexed) id: cells[i]};
      gridded.value++;
    });
    return null;
  }

  /// [id] and the [k] - 1 nearest it on the map of [among], nearest first: XO's Similarity List ("the most similar
  /// sounding in the XO Space").
  List<String> alike(String id, Iterable<String> among, int k) {
    final at = places.value, p = at[id];
    if (p == null) return const [];
    final near = [for (final o in among) if (o != id) if (at[o] case final q?) (o, (q - p).distanceSquared)]..sort((a, b) => a.$2.compareTo(b.$2));
    return [id, for (final (o, _) in near.take(k - 1)) o];
  }
}

/// A picture's numbers: its colours made 16 points square, as Torralba, Fergus and Freeman's tiny images ("80 million
/// tiny images", 2008) tell pictures apart by their colours made small; several pictures one after another. null:
/// one of them cannot be read (yet: asked again next time). Read once while the window is open.
final _tiny = <String, Float32List>{};
Future<Float32List?> dockTiny(List<String> files) async {
  final key = files.join('\n');
  if (_tiny[key] case final v?) return v;
  final v = await _read(files);
  if (v != null) _tiny[key] = v;
  return v;
}
Future<Float32List?> _read(List<String> files) async {
  const side = 16;
  final out = Float32List(files.length * side * side * 3);
  for (final (k, f) in files.indexed) {
    try {
      final codec = await ui.instantiateImageCodec(await File(f).readAsBytes(), targetWidth: side, targetHeight: side);
      final image = (await codec.getNextFrame()).image, px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      image.dispose();
      codec.dispose();
      for (var i = 0; i < side * side; i++) {
        for (var ch = 0; ch < 3; ch++) {
          out[(k * side * side + i) * 3 + ch] = px[i * 4 + ch] / 255;
        }
      }
    } catch (_) {
      return null;
    }
  }
  return out;
}

/// The CLIP image encoder [name] (clip_b32: OpenAI's ViT-B/32; fontclip_b32: FontCLIP's) once it has been made
/// (engine/look_models.py); null: not made, the maps tell pictures apart by their tiny colours ([dockTiny]).
String? dockModel(String name) {
  final f = '${Platform.environment['HOME']}/Library/Caches/Motolii/models/$name.onnx';
  return File(f).existsSync() ? f : null;
}

/// Pictures' numbers by a CLIP image encoder ([model]): each picture made 224 square (as CLIP's own Resize takes it),
/// its 512 numbers, several pictures one after another, so two effects are told apart frame by frame at the same
/// moments: ViSiL's frame-to-frame likeness (Kordopatis-Zilos et al., ICCV 2019) taken only where the frames are of
/// one moment, the effects' tiles all drawn at the same ones. null: one of them cannot be read, or not told. Read once
/// while the window is open.
final _clip = <String, Float32List>{};
Future<Float32List?> dockSeen(Motolii m, String model, List<String> files) async {
  final key = '$model\n${files.join('\n')}';
  if (_clip[key] case final v?) return v;
  final pictures = <Uint8List>[];
  for (final f in files) {
    try {
      final codec = await ui.instantiateImageCodec(await File(f).readAsBytes(), targetWidth: 224, targetHeight: 224);
      final image = (await codec.getNextFrame()).image;
      pictures.add((await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List());
      image.dispose();
      codec.dispose();
    } catch (_) {
      return null;
    }
  }
  final told = await m.likeness(model, pictures);
  if (told == null) return null;
  final v = Float32List(512 * told.length);
  for (final (k, t) in told.indexed) {
    v.setRange(512 * k, 512 * (k + 1), t);
  }
  return _clip[key] = v;
}

/// Items' numbers of several parts side by side, as FontMap lays fonts by FontCLIP's numbers beside their tags' and
/// their shapes' (weighted 1, 0.5, 0.2): each part's numbers made of one spread in all, times its [weights]' share, those
/// of the [even] parts first each made of one spread itself (a z-score, each number its own scale). Left off (null): an
/// item the first part has none for; one another part has none for takes that part's mean (nothing told by it).
List<Float32List?> dockTogether(List<List<Float32List?>> parts, List<double> weights, {Set<int> even = const {}}) {
  final n = parts.first.length, made = <List<Float32List>>[];
  for (final (k, rows) in parts.indexed) {
    final dims = rows.nonNulls.firstOrNull?.length ?? 0, had = [for (final r in rows) if (r != null && r.length == dims) r];
    final mean = Float64List(dims), sd = Float64List(dims)..fillRange(0, dims, 1);
    for (final r in had) {
      for (var i = 0; i < dims; i++) {
        mean[i] += r[i] / had.length;
      }
    }
    if (even.contains(k)) {
      sd.fillRange(0, dims, 0);
      for (final r in had) {
        for (var i = 0; i < dims; i++) {
          sd[i] += (r[i] - mean[i]) * (r[i] - mean[i]) / had.length;
        }
      }
      for (var i = 0; i < dims; i++) {
        sd[i] = math.sqrt(sd[i]) + 1e-6;
      }
    }
    final out = [for (final _ in rows) Float32List(dims)];
    var spread = 0.0;
    for (final (j, r) in rows.indexed) {
      if (r == null || r.length != dims) continue;
      for (var i = 0; i < dims; i++) {
        out[j][i] = (r[i] - mean[i]) / sd[i];
        spread += out[j][i] * out[j][i] / had.length;
      }
    }
    final by = spread > 0 ? weights[k] / math.sqrt(spread) : 0.0;
    for (final r in out) {
      for (var i = 0; i < dims; i++) {
        r[i] *= by;
      }
    }
    made.add(out);
  }
  return [
    for (var i = 0; i < n; i++)
      if (parts.first[i] == null) null else Float32List.fromList([for (final k in made) ...k[i]]),
  ];
}

/// The map: each shown item's tile in its cell, the cells as many as the items and as large as the room allows ([aspect]
/// a tile's width to its height; [cell] wide where they lie before the grid comes), the rest left off; what is said
/// while it is being laid out. [picked]: the one picked, its nearest under the map; [press]: one press on one of them.
/// [kinds]: what each is (the shelf's own word for it), each tile edged in its kind's [hue], as XO's Space colours each
/// sound by its drum type and the Embedding Projector colours points by a column ("Color by"), and each coloured kind's
/// name over where its tiles are, as DataMapPlot names each cluster at its middle.
class DockMap extends StatefulWidget {
  const DockMap(this.places, this.shown, {super.key, this.cell = 26, this.aspect = 1, this.picked, this.press, this.kinds = const {}, this.hue});
  final DockMapPlaces places;
  final List<(String, Widget)> shown;
  final double cell, aspect;
  final String? picked;
  final void Function(String id)? press;
  final Map<String, String> kinds;
  final Color? Function(String kind)? hue;
  @override
  State<DockMap> createState() => _DockMapState();
}

class _DockMapState extends State<DockMap> {
  final _keys = FocusNode(debugLabel: 'ws-map');
  String? _from;   // (where the list of the alike was made from: the one pressed on the map, as XO's from its Space)
  final _seen = <String>[];   // (what was picked, in turn: XO's History)
  int _at = -1;

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
    if (id == null || (_at >= 0 && _seen[_at] == id)) return;   // (gone to by the history itself: kept as it is)
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.places.places, widget.places.laying, widget.places.gridded]),
    builder: (context, _) {
      final at = widget.places.places.value;
      if (at.isEmpty) {
        return Center(child: Text(widget.places.laying.value ? 'Laying out the map…' : 'Nothing on the map yet', style: T.label(Grey.g63)));
      }
      final tiles = {for (final (id, tile) in widget.shown) id: tile};
      final sw = Shape.z(32) * widget.aspect, gap = Shape.s(4);
      return LayoutBuilder(
        builder: (context, box) {
          final k = math.max(2, ((box.maxWidth - 3 * Shape.z(20) - 2 * gap) / (sw + gap)).floor());
          final picked = widget.picked;
          if (picked != null && at.containsKey(picked) && (_from == null || !widget.places.alike(_from!, tiles.keys, k).contains(picked))) _from = picked;   // (picked elsewhere: its own list)
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
                onPointerDown: (_) => _keys.requestFocus(),   // (the keys go to the map once it is pressed, not to the stage's nudge)
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
    final n = at.length, a = widget.aspect;
    final cols = math.max(1, math.sqrt(n * room.width / (math.max(1.0, room.height) * a)).ceil()), rows = (n / cols).ceil();
    final cw = math.min(room.width / cols, room.height * a / rows), ch = cw / a, left = (room.width - cols * cw) / 2;
    final cells = widget.places.grid(cols, rows), w = Shape.z(widget.cell), h = w / a;
    Rect? place(String id) => switch ((cells, at[id])) {
      (final g?, _) when g.isNotEmpty => g[id] == null ? null : Rect.fromLTWH(left + g[id]! % cols * cw + 1, g[id]! ~/ cols * ch + 1, cw - 2, ch - 2),
      (_, final p?) => Rect.fromLTWH(p.dx * (room.width - w), p.dy * (room.height - h), w, h),   // (before the grid comes, or too many for one: where they lie)
      _ => null,
    };
    final where = <String, List<Offset>>{};
    for (final id in tiles.keys) {
      if ((widget.kinds[id], place(id)) case (final k?, final r?) when k.isNotEmpty) (where[k] ??= []).add(r.center);
    }
    Color? hue(String id) => widget.kinds[id] == null ? null : widget.hue?.call(widget.kinds[id]!);
    return ClipRect(
      child: InteractiveViewer(
        key: ValueKey('ws-map-$_name'),
        maxScale: 12,
        boundaryMargin: EdgeInsets.all(cw),
        child: SizedBox.fromSize(
          size: room,
          child: Stack(
            children: [
              for (final MapEntry(key: id, value: tile) in tiles.entries)
                if (place(id) case final r?)
                  Positioned.fromRect(
                    key: ValueKey('ws-map-$_name-$id'),
                    rect: r,
                    child: Listener(   // (pressed on the map: the list made from it, as XO's Space)
                      onPointerDown: (_) => _from = id,
                      child: hue(id) == null ? tile : DecoratedBox(position: DecorationPosition.foreground, decoration: BoxDecoration(border: Border.all(color: hue(id)!, width: Shape.s(2))), child: tile),
                    ),
                  ),
              for (final MapEntry(key: k, value: at) in where.entries)
                if (widget.hue?.call(k) case final c?)   // (the names the colours' key: a kind with none goes unnamed)
                  Positioned(
                    key: ValueKey('ws-map-$_name-kind-$k'),
                    left: at.map((p) => p.dx).reduce((a, b) => a + b) / at.length,
                    top: at.map((p) => p.dy).reduce((a, b) => a + b) / at.length,
                    child: IgnorePointer(
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(6), vertical: Shape.s(3)),
                          color: WsT.card.withValues(alpha: 0.9),
                          child: Text(k, style: T.title(c)),   // (read at a glance over the tiles, as a map's place names)
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// XO's Similarity List under the map: its arrows, the alike in a row, and its Refresh (the picked one first:
  /// Splice's Similar Sounds run again on one of its matches).
  Widget _alike(List<String> list, Map<String, Widget> tiles, double sw, double gap) {
    final i = list.indexOf(widget.picked ?? '');
    Widget arrow(String key, int by) => Transform.flip(flipX: by < 0, child: DockIconButton(DockG.chevron, key: ValueKey('ws-map-$_name-$key'), onTap: () => _step(list, by)));
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
          DockIconButton(DockG.reload, key: ValueKey('ws-map-$_name-refresh'), on: i > 0, onTap: () => setState(() => _from = widget.picked)),
        ],
      ),
    );
  }
}

/// Each shelf's map, while the window is open (not the document's).
final _maps = <String, DockMapPlaces>{};
DockMapPlaces dockMap(String shelf) => _maps[shelf] ??= DockMapPlaces(shelf);
