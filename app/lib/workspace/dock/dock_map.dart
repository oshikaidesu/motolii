// A shelf's map, as XLN Audio's XO's Space: each item where what is alike lies near (laid out by the inside's t-SNE,
// motolii_map, as XO's are), then pushed apart till none covers another, each kept near where it lay, as FontMap lays
// its fonts, on d3-force itself (force_graph; dockSpread), drawn together as far as asked by Obsidian's graph's Center
// force; the shelf's chips and words narrowing which are shown, as XO's filters narrow its Space;
// moved and zoomed by Flutter's own InteractiveViewer. Under it XO's Similarity List (Splice's Similar Sounds beside
// its list): the nearest to the one picked, stepped along by its arrows or the left and right keys. Laid out again
// when what the shelf holds changes (XO's Scan & Refresh, done by itself), kept between openings beside the tiles
// (~/Library/Caches/Motolii).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:force_graph/force_graph.dart' show CollideForce, Force, ForceNode, ForceSimulation;
import 'package:material_color_utilities/material_color_utilities.dart' show Cam16;

import '../../bridge/motolii.dart' show Motolii, MotoliiQuestions;
import '../../widgets/media.dart' show MiniSlider;
import '../../skin/tokens.dart';
import 'dock_glyphs.dart';
import 'dock_widgets.dart' show dockMark, IconPress;
import '../state/state.dart' show WsT;
part 'dock_map_view.dart';

/// Where one shelf's items lie on its map, by id, on a canvas the room's shape ([dockSpread]); [laying] while that is
/// being worked out.
class DockMapPlaces {
  DockMapPlaces(this.name) {
    squeeze.addListener(() => _laid.isNotEmpty ? _spread() : null);
  }
  final String name;
  final places = ValueNotifier<Map<String, Offset>>(const {});
  final laying = ValueNotifier<bool>(false);

  /// How tightly the islands are drawn together, 0 to 1 ([dockSpread]'s squeeze: Obsidian's graph's Center force);
  /// none at first, the map as FontMap lays it.
  final squeeze = ValueNotifier<double>(0);
  String? _for;
  Map<String, Offset> _laid = const {}; // (where t-SNE lays them, before they are pushed apart: what is alike is told by it)
  double _aspect = 1920 / 1080; // (the room's width to its height: FontMap's canvas is the page it is shown on)
  Future<void>? _spreading;

  /// The room the map is shown in, its width to its height: pushed apart again on a canvas of that shape.
  void roomIs(double aspect) {
    if (!aspect.isFinite || aspect <= 0 || aspect == _aspect) return;
    _aspect = aspect;
    if (_laid.isNotEmpty) _spread();
  }

  /// [_laid] pushed apart for the room and drawn together by [squeeze] ([dockSpread]), one at a time, again till what it
  /// was for is the last asked.
  Future<void> _spread() =>
      _spreading ??
      (_spreading = Zone.root.run<Future<void>>(
        () => Future<void>(() async {
          try {
            for (var laid = const <String, Offset>{}, a = 0.0, q = -1.0; !identical(laid, _laid) || a != _aspect || q != squeeze.value;) {
              laid = _laid;
              a = _aspect;
              q = squeeze.value;
              final s = laid.isEmpty ? const <Offset>[] : await _spreadAway(laid.values.toList(), a, q);
              if (identical(laid, _laid)) places.value = {for (final (i, id) in laid.keys.indexed) id: s[i]};
            }
          } finally {
            _spreading = null;
          }
        }),
      ));

  File get _kept => File('${_mapsAt.path}/map_$name.json');

  /// Laid out for these items (each its id and what it is read from), each read as numbers by [read] (null: left off the
  /// map; [also]: what else they were laid out by, all laid out again when it changes). Those laid out before stay where
  /// they lay (kept between openings); one new, or its picture changed, goes where its 25 nearest of those lie, the
  /// middle of theirs each way: openTSNE's way of adding points to a map made (prepare_partial, initialization "median",
  /// k 25; BSD-3), the others not moved. All laid out by t-SNE only when none lay before.
  void need(Motolii m, List<(String, String)> items, Future<List<Float32List?>> Function(List<String> from) read, {String also = ''}) {
    final key = jsonEncode([also, for (final (id, from) in items) '$id\t$from']);
    if (key == _for) return;
    _for = key;
    Zone.root.run(() async {
      // (on the program's own clock, as fontsRead: a test may wait for it)
      Future<void> show(Map<String, Offset> laid) async {
        // (kept as t-SNE lays them; pushed apart each time shown, a moment's work)
        if (key != _for) return;
        _laid = laid;
        await _spread();
      }

      var known = <String, Offset>{};
      try {
        final kept = jsonDecode(await _kept.readAsString()) as Map<String, dynamic>, was = (jsonDecode(kept['for'] as String) as List).cast<String>();
        final same = was.skip(1).toSet(), from = {for (final (id, f) in items) id: f};
        if (was.first.trim() == also.trim()) {
          known = {
            for (final MapEntry(key: id, value: at) in (kept['places'] as Map<String, dynamic>).entries)
              if (same.contains('$id\t${from[id]}')) id: Offset(((at as List)[0] as num).toDouble(), (at[1] as num).toDouble()),
          };
        }
      } catch (_) {} // (none kept, or for others: laid out now)
      if (known.length == items.length) return show(known);
      if (known.isNotEmpty) await show(known); // (those laid before at once; the new join them when read)
      laying.value = known.isEmpty;
      final numbers = await read([for (final (_, from) in items) from]);
      if (key != _for) return; // (asked for others meanwhile: theirs comes)
      var at = <String, Offset>{};
      if (known.isEmpty) {
        final ids = [
          for (final (i, (id, _)) in items.indexed)
            if (numbers[i] != null) id,
        ];
        final laid = await m.map([for (final v in numbers) ?v]);
        if (laid != null) at = {for (final (i, id) in ids.indexed) id: Offset(laid[i].$1, laid[i].$2)};
      } else {
        final seen = {for (final (i, (id, _)) in items.indexed) id: ?numbers[i]};
        at = {for (final (id, _) in items) id: ?known[id], ...await _joinedAway(known, seen)};
      }
      if (key != _for) return;
      await show(at);
      laying.value = false;
      try {
        _kept.parent.createSync(recursive: true);
        await _kept.writeAsString(
          jsonEncode({
            'for': key,
            'places': {
              for (final MapEntry(key: id, value: p) in at.entries) id: [p.dx, p.dy],
            },
          }),
        );
      } catch (_) {} // (not kept: laid out again next time)
    });
  }

  /// Where each of [seen] not [known] goes: the middle each way of where its 25 nearest of the known lie (openTSNE's
  /// initialization.median).
  static Map<String, Offset> _joined(Map<String, Offset> known, Map<String, Float32List> seen) {
    final base = [
          for (final id in known.keys)
            if (seen.containsKey(id)) id,
        ],
        out = <String, Offset>{};
    double mid(List<double> v) => (v..sort())[v.length ~/ 2];
    for (final MapEntry(key: id, value: v) in seen.entries) {
      if (known.containsKey(id) || base.isEmpty) continue;
      final far = <(String, double)>[];
      for (final o in base) {
        final w = seen[o]!;
        var d = 0.0;
        for (var i = 0; i < v.length && i < w.length; i++) {
          d += (v[i] - w[i]) * (v[i] - w[i]);
        }
        far.add((o, d));
      }
      far.sort((a, b) => a.$2.compareTo(b.$2));
      final near = [for (final (o, _) in far.take(25)) known[o]!];
      out[id] = Offset(mid([for (final p in near) p.dx]), mid([for (final p in near) p.dy]));
    }
    return out;
  }

  /// [id] and the [k] - 1 nearest it on the map of [among], nearest first: XO's Similarity List ("the most similar
  /// sounding in the XO Space"), where t-SNE laid them (FontMap's similar fonts: the nearest before its overlap removal).
  List<String> alike(String id, Iterable<String> among, int k) {
    final at = _laid.isEmpty ? places.value : _laid, p = at[id];
    if (p == null) return const [];
    final near = [
      for (final o in among)
        if (o != id)
          if (at[o] case final q?) (o, (q - p).distanceSquared),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [id, for (final (o, _) in near.take(k - 1)) o];
  }
}

/// Where the maps are kept between openings (a test points it elsewhere, as the decks and the recent: the maker's own left
/// alone).
Directory _mapsAt = Directory('${Platform.environment['HOME']}/Library/Caches/Motolii');
void dockMapsAt(Directory d) => _mapsAt = d;

/// [dockSpread] and [DockMapPlaces._joined] on an isolate of their own (Isolate.run), sent only what they are given here
/// (a closure made inside [DockMapPlaces.need] would carry the inside's library with it).
Future<List<Offset>> _spreadAway(List<Offset> at, double aspect, double squeeze) => Isolate.run(() => dockSpread(at, aspect, squeeze));
Future<Map<String, Offset>> _joinedAway(Map<String, Offset> known, Map<String, Float32List> seen) => Isolate.run(() => DockMapPlaces._joined(known, seen));

/// A tile's reach on the map: FontMap's collision radius, 13 of its canvas's pixels.
const dockSpreadRadius = 13.0;

/// Places (0 to 1 each way) pushed apart till none is within two [dockSpreadRadius] of another, each kept near where it
/// lay: FontMap's scripts/apply-overlap-removal.mjs (MIT) with its numbers (a 1920 x 1080 canvas 40 in from its edges,
/// radius 13, 140 ticks, pulled back at 0.03) on d3-force itself, in Dart (force_graph, MIT: its ForceSimulation and
/// CollideForce, strength 1, 3 iterations, with d3's own cooling); its canvas, the page it is shown on, here as many
/// pixels in the shape of the room ([aspect] its width to its height). [squeeze] (0 to 1): each pulled to the middle as
/// well, at most at d3's own strength for that pull (forceX's 0.1), the islands drawn together while none covers
/// another: Obsidian's graph's Center force ("controls how compact the graph is"), as d3's disjoint force-directed graph
/// keeps its pieces together with forceX and forceY to the middle; then the pulls let go and only the pushing apart
/// run 40 ticks more, removing what the pull leaves, as FontMap's own drawn-together map does (src/experiments/engine/
/// cartogram.js, relax). Where each lies on that canvas.
List<Offset> dockSpread(List<Offset> at, [double aspect = 1920 / 1080, double squeeze = 0]) {
  const pad = 40.0, r = dockSpreadRadius, pull = 0.03;
  final w = math.sqrt(1920 * 1080 * aspect), h = 1920 * 1080 / w;
  final nodes = [
    for (final (i, p) in at.indexed)
      ForceNode(id: '$i')
        ..x = p.dx * (w - 2 * pad) + pad
        ..y = p.dy * (h - 2 * pad) + pad,
  ];
  final collide = CollideForce(radius: (_) => r),
      sim = ForceSimulation(nodes)
        ..alphaDecay =
            1 -
            math
                .pow(0.001, 1 / 300)
                .toDouble() // (d3's, where force_graph keeps its Apeirron graph's)
        ..alphaTarget = 0
        ..addForce(collide)
        ..addForce(_Toward([for (final n in nodes) Offset(n.x, n.y)], pull));
  if (squeeze > 0) sim.addForce(_Toward(List.filled(nodes.length, Offset(w / 2, h / 2)), squeeze * .1));
  for (var tick = 0; tick < 140; tick++) {
    sim.tick();
  }
  if (squeeze > 0) {
    sim
      ..clearForces()
      ..addForce(collide);
    for (var tick = 0; tick < 40; tick++) {
      sim.tick();
    }
  }
  return [for (final n in nodes) Offset(n.x, n.y)];
}

/// d3-force's forceX and forceY (x.js, y.js; ISC) at once, which force_graph leaves out: each pulled toward its own
/// point, [strength] of the way left, times the heat.
class _Toward implements Force {
  _Toward(this.to, this.strength);
  final List<Offset> to;
  final double strength;
  var _nodes = const <ForceNode>[];
  @override
  void initialize(List<ForceNode> nodes, _) => _nodes = nodes;
  @override
  void apply(double alpha) {
    for (final (i, n) in _nodes.indexed) {
      n
        ..vx += (to[i].dx - n.x) * strength * alpha
        ..vy += (to[i].dy - n.y) * strength * alpha;
    }
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
/// (engine/deps/likeness_models.py); null: not made, the maps tell pictures apart by their tiny colours ([dockTiny]).
String? dockModel(String name) {
  final f = '${Platform.environment['HOME']}/Library/Caches/Motolii/models/$name.onnx';
  return File(f).existsSync() ? f : null;
}

/// Pictures' numbers by a CLIP image encoder ([model]): each picture made 224 square (as CLIP's own Resize takes it),
/// its 512 numbers, several pictures one after another, so two effects are told apart frame by frame at the same
/// moments: ViSiL's frame-to-frame likeness (Kordopatis-Zilos et al., ICCV 2019) taken only where the frames are of
/// one moment, the effects' tiles all drawn at the same ones. null: one of them cannot be read, or not told. Each
/// picture's kept once read ([dockLookKept]): only a new or redrawn one is read again.
final _clip = <String, Float32List>{};
Future<Float32List?> dockSeen(Motolii m, String model, List<String> files) async {
  final key = '$model\n${files.join('\n')}';
  if (_clip[key] case final v?) return v;
  final v = Float32List(512 * files.length), keys = <String>[], missing = <int>[];
  for (final (k, f) in files.indexed) {
    try {
      keys.add('$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}');
    } catch (_) {
      return null; // (the picture not there)
    }
    if (dockLookKept(keys[k]) case final had?) {
      v.setRange(512 * k, 512 * (k + 1), had);
    } else {
      missing.add(k);
    }
  }
  if (missing.isNotEmpty) {
    final pictures = <Uint8List>[];
    for (final k in missing) {
      try {
        final codec = await ui.instantiateImageCodec(await File(files[k]).readAsBytes(), targetWidth: 224, targetHeight: 224);
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
    for (final (j, k) in missing.indexed) {
      v.setRange(512 * k, 512 * (k + 1), told[j]);
      dockLookKeep(keys[k], told[j]);
    }
  }
  return _clip[key] = v;
}

/// A picture's numbers kept once told (~/Library/Caches/Motolii/looks, by [key]: the model, what was drawn and when),
/// so a shelf reads again only what is new; null: none kept.
File _look(String key) => File('${Platform.environment['HOME']}/Library/Caches/Motolii/looks/${sha1.convert(utf8.encode(key))}.f32');
Float32List? dockLookKept(String key) {
  try {
    final had = _look(key).readAsBytesSync();
    return had.isEmpty || had.length % 4 != 0 ? null : had.buffer.asFloat32List();
  } catch (_) {
    return null;
  }
}

void dockLookKeep(String key, Float32List v) {
  try {
    _look(key).parent.createSync(recursive: true);
    _look(key).writeAsBytesSync(Float32List.fromList(v).buffer.asUint8List());
  } catch (_) {} // (not kept: read again next time)
}

/// Items' numbers of several parts side by side, as FontMap lays fonts by FontCLIP's numbers beside their tags' and
/// their shapes' (weighted 1, 0.5, 0.2): each part's numbers made of one spread in all, times its [weights]' share, those
/// of the [even] parts first each made of one spread itself (a z-score, each number its own scale). Left off (null): an
/// item the first part has none for; one another part has none for takes that part's mean (nothing told by it).
List<Float32List?> dockTogether(List<List<Float32List?>> parts, List<double> weights, {Set<int> even = const {}}) {
  final n = parts.first.length, made = <List<Float32List>>[];
  for (final (k, rows) in parts.indexed) {
    final dims = rows.nonNulls.firstOrNull?.length ?? 0,
        had = [
          for (final r in rows)
            if (r != null && r.length == dims) r,
        ];
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

/// Each one's colour by where it lies on the map, as DataMapPlot colours its map (TutteInstitute/datamapplot 45a0123,
/// datamapplot/palette_handling.py, MIT): palette_from_datamap with each one its own label, as its interactive plot
/// gives each point its finest layer's label's colour (create_plots.py, label_layers reversed) — the hue round the
/// map's middle by angle, spaced by how far each lies from it (radius_weight_power 1), chroma 20 to 90 and lightness 80
/// to its palette_min_lightness out from the middle as the others lie in its sector (theta_range π/16); then its
/// pastel_palette (degree 2), as its darkmode colours text on its dark ground. Alike ones lie together, so each island is
/// a run of hues. palette_min_lightness 30, not its 10: at 10 the outermost 45 of 328 fonts fell under WCAG 2.1's 3:1
/// (1.4.11, a picture needed to tell what it is) on the map's ground. JCh by CAM16 (material_color_utilities,
/// CIECAM02's successor; colorspacious's JCh is CIECAM02's).
final _palettes = Expando<Map<String, Color>>();
Map<String, Color> dockPalette(Map<String, Offset> at) => _palettes[at] ??= _palette(at);
Map<String, Color> _palette(Map<String, Offset> at) {
  final ids = at.keys.toList(), n = ids.length;
  if (n == 0) return const {};
  final xs = [for (final id in ids) at[id]!.dx], ys = [for (final id in ids) -at[id]!.dy]; // (y up, as DataMapPlot's)
  final cx = (xs.reduce(math.min) + xs.reduce(math.max)) / 2, cy = (ys.reduce(math.min) + ys.reduce(math.max)) / 2;
  final r = [for (var i = 0; i < n; i++) math.sqrt((xs[i] - cx) * (xs[i] - cx) + (ys[i] - cy) * (ys[i] - cy))];
  final t = [for (var i = 0; i < n; i++) math.atan2(ys[i] - cy, xs[i] - cx)];
  double interp(double x, List<double> xp, List<double> fp) {
    // (numpy's interp: the ends held)
    if (x <= xp.first) return fp.first;
    if (x >= xp.last) return fp.last;
    var k = 1;
    while (xp[k] < x) {
      k++;
    }
    return xp[k] == xp[k - 1] ? fp[k] : fp[k - 1] + (fp[k] - fp[k - 1]) * (x - xp[k - 1]) / (xp[k] - xp[k - 1]);
  }

  final order = List.generate(n, (i) => i)..sort((a, b) => t[a].compareTo(t[b]));
  var sum = 0.0;
  final base = [for (final i in order) sum += r[i]], byT = [for (final i in order) t[i]];
  final weights = [for (final b in base) sum > 0 ? b / sum : 0.0];
  final hue = [for (var i = 0; i < n; i++) interp(t[i], byT, weights) * 360 % 360];
  final sectors = n < 256 ? t : [for (var k = 0; k < 256; k++) -math.pi + 2 * math.pi * k / 256];
  const range = math.pi / 16;
  final radii = [
    for (final theta in sectors)
      () {
        for (var s = 0; s < 16; s++) {
          final spread = 2 * range + (math.pi - 2 * range) * s / 15;
          var hi = theta + spread / 2, lo = theta - spread / 2;
          if (hi > math.pi) hi -= 2 * math.pi;
          if (lo < -math.pi) lo += 2 * math.pi;
          final wraps = lo > 0 && hi < 0;
          final some = [
            for (var i = 0; i < n; i++)
              if (wraps ? (t[i] > lo || t[i] < hi) : (t[i] > lo && t[i] < hi)) r[i],
          ]..sort();
          if (some.isNotEmpty) return some;
        }
        return [...r]..sort();
      }(),
  ];
  final raw = <int>[];
  for (var i = 0; i < n; i++) {
    var j = 0;
    for (var k = 1; k < sectors.length; k++) {
      if ((sectors[k] - t[i]).abs() < (sectors[j] - t[i]).abs()) j = k;
    }
    final ref = radii[j], m = ref.length;
    final chroma = interp(r[i], ref, [for (var k = 0; k < m; k++) 20 + 70 * k / m]);
    final lightness = interp(r[i], ref, [for (var k = 0; k < m; k++) 80 - (80 - 30) * k / m]);
    raw.add(Cam16.fromJch(lightness, chroma, hue[i]).toInt());
  }
  final jch = [for (final c in raw) Cam16.fromInt(c)];
  final leastJ = jch.map((c) => c.j).reduce(math.min), leastC = jch.map((c) => c.chroma).reduce(math.min);
  return {
    for (final (i, c) in jch.indexed)
      ids[i]: Color(Cam16.fromJch((c.j * math.sqrt2).clamp(leastJ, 100), (c.chroma / 2).clamp(math.min(10 / 2, leastC), 50), c.hue).toInt()),
  };
}

/// Each shelf's map, while the window is open (not the document's).
final _maps = <String, DockMapPlaces>{};
DockMapPlaces dockMap(String shelf) => _maps[shelf] ??= DockMapPlaces(shelf);
