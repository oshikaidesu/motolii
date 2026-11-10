// A shelf's map: items laid out so that similar ones lie near each other, like XLN Audio XO's Space.
// Positions come from the engine's t-SNE (motolii_map), then items are pushed apart until none covers another
// ([dockSpread], after FontMap) and optionally drawn together (Obsidian's graph "Center force"). The shelf's chips and
// search words narrow which items are shown, as XO's filters do. Flutter's InteractiveViewer pans and zooms. Below the
// map, a similarity list shows the items nearest the picked one (XO's Similarity List, Splice's Similar Sounds). The user
// steps through it with its arrows or the left and right keys. The map is laid out again when the shelf's contents
// change, and positions are cached in ~/Library/Caches/Motolii.
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
import 'package:force_graph/force_graph.dart'
    show CollideForce, Force, ForceNode, ForceSimulation;
import 'package:material_color_utilities/material_color_utilities.dart'
    show Cam16;

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/storage/json_file.dart' show fileKeep;

/// Where one shelf's items lie on its map, by id, on a canvas shaped like the viewport ([dockSpread]). [laying] is true
/// while the layout is being computed.
class DockMapPlaces {
  DockMapPlaces(this.name) {
    squeeze.addListener(() => _laid.isNotEmpty ? _spread() : null);
  }
  final String name;
  final places = ValueNotifier<Map<String, Offset>>(const {});
  final laying = ValueNotifier<bool>(false);

  /// How tightly the islands are drawn together, from 0 to 1 (the `squeeze` of [dockSpread], Obsidian's graph "Center
  /// force"). It starts at 0, which gives the map as FontMap lays it out.
  final squeeze = ValueNotifier<double>(0);
  String? _for;

  /// Positions from t-SNE, before overlap removal. Similarity is judged from these.
  Map<String, Offset> _laid = const {};

  /// Width to height of the viewport.
  double _aspect = 1920 / 1080;
  Future<void>? _spreading;

  /// Sets the viewport's width to height ratio and pushes the items apart again on a canvas of that shape.
  void roomIs(double aspect) {
    if (!aspect.isFinite || aspect <= 0 || aspect == _aspect) return;
    _aspect = aspect;
    if (_laid.isNotEmpty) _spread();
  }

  /// Pushes [_laid] apart for the current viewport and draws it together by [squeeze] ([dockSpread]).
  ///
  /// One run is active at a time. It repeats until its result matches the latest layout, aspect and squeeze.
  Future<void> _spread() =>
      _spreading ??
      (_spreading = Zone.root.run<Future<void>>(
        () => Future<void>(() async {
          try {
            for (
              var laid = const <String, Offset>{}, a = 0.0, q = -1.0;
              !identical(laid, _laid) || a != _aspect || q != squeeze.value;
            ) {
              laid = _laid;
              a = _aspect;
              q = squeeze.value;
              final s = laid.isEmpty
                  ? const <Offset>[]
                  : await _spreadAway(laid.values.toList(), a, q);
              if (identical(laid, _laid)) {
                places.value = {
                  for (final (i, id) in laid.keys.indexed) id: s[i],
                };
              }
            }
          } finally {
            _spreading = null;
          }
        }),
      ));

  File get _kept => File('${_mapsAt.path}/map_$name.json');

  /// Lays out [items], each an id and the source it is read from.
  ///
  /// [read] turns the sources into feature vectors, or null for an item to leave off the map. [also] is any other input
  /// the layout depends on; all items are laid out again when it changes.
  ///
  /// Items laid out before stay where they were. A new or changed item goes to the median of its 25 nearest placed items,
  /// as openTSNE adds points to an existing map (prepare_partial, initialization "median", k 25; BSD-3). Everything goes
  /// through t-SNE only when nothing was laid out before.
  void need(
    Motolii m,
    List<(String, String)> items,
    Future<List<Float32List?>> Function(List<String> from) read, {
    String also = '',
  }) {
    final key = jsonEncode([
      also,
      for (final (id, from) in items) '$id\t$from',
    ]);
    if (key == _for) return;
    _for = key;
    Zone.root.run(() async {
      Future<void> show(Map<String, Offset> laid) async {
        if (key != _for) return;
        _laid = laid;
        await _spread();
      }

      var known = <String, Offset>{};
      try {
        final kept =
                jsonDecode(await _kept.readAsString()) as Map<String, dynamic>,
            was = (jsonDecode(kept['for'] as String) as List).cast<String>();
        final same = was.skip(1).toSet(),
            from = {for (final (id, f) in items) id: f};
        if (was.first.trim() == also.trim()) {
          known = {
            for (final MapEntry(key: id, value: at)
                in (kept['places'] as Map<String, dynamic>).entries)
              if (same.contains('$id\t${from[id]}'))
                id: Offset(
                  ((at as List)[0] as num).toDouble(),
                  (at[1] as num).toDouble(),
                ),
          };
        }
      } catch (
        _
      ) {} // Nothing cached, or the cache is for other items: lay out now.
      if (known.length == items.length) return show(known);
      if (known.isNotEmpty) await show(known);
      laying.value = known.isEmpty;
      final numbers = await read([for (final (_, from) in items) from]);
      if (key != _for) return;
      var at = <String, Offset>{};
      if (known.isEmpty) {
        final ids = [
          for (final (i, (id, _)) in items.indexed)
            if (numbers[i] != null) id,
        ];
        final laid = await m.map([for (final v in numbers) ?v]);
        if (laid != null) {
          at = {
            for (final (i, id) in ids.indexed)
              id: Offset(laid[i].$1, laid[i].$2),
          };
        }
      } else {
        final seen = {
          for (final (i, (id, _)) in items.indexed) id: ?numbers[i],
        };
        at = {
          for (final (id, _) in items) id: ?known[id],
          ...await _joinedAway(known, seen),
        };
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
              for (final MapEntry(key: id, value: p) in at.entries)
                id: [p.dx, p.dy],
            },
          }),
        );
      } catch (_) {} // Not cached: laid out again next time.
    });
  }

  /// Places each item of [seen] that is not in [known] at the per-axis median of its 25 nearest known items
  /// (openTSNE's initialization.median).
  static Map<String, Offset> _joined(
    Map<String, Offset> known,
    Map<String, Float32List> seen,
  ) {
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
      out[id] = Offset(
        mid([for (final p in near) p.dx]),
        mid([for (final p in near) p.dy]),
      );
    }
    return out;
  }

  /// Returns [id] followed by the [k] - 1 items of [among] nearest to it, nearest first (XO's Similarity List).
  /// Distances use the t-SNE positions before overlap removal, as FontMap does for its similar fonts.
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

/// Where the maps are cached between sessions. A test points it elsewhere so the user's own cache is left alone.
Directory _mapsAt = Directory(
  '${Platform.environment['HOME']}/Library/Caches/Motolii',
);
void dockMapsAt(Directory d) => _mapsAt = d;

/// Runs [dockSpread] and [DockMapPlaces._joined] on their own isolate. Only their arguments are sent, because a closure
/// made inside [DockMapPlaces.need] would capture its library too.
Future<List<Offset>> _spreadAway(
  List<Offset> at,
  double aspect,
  double squeeze,
) => Isolate.run(() => dockSpread(at, aspect, squeeze));
Future<Map<String, Offset>> _joinedAway(
  Map<String, Offset> known,
  Map<String, Float32List> seen,
) => Isolate.run(() => DockMapPlaces._joined(known, seen));

/// A tile's collision radius on the map, in canvas pixels (FontMap uses 13).
const dockSpreadRadius = 13.0;

/// Pushes [at] apart until no two are within two [dockSpreadRadius] of each other, keeping each near where it was.
///
/// [at] holds positions from 0 to 1 on each axis. [aspect] is the viewport's width to height. The canvas has the area of
/// FontMap's 1920 x 1080, in the shape of the viewport. Returns the positions on that canvas.
///
/// This follows FontMap's scripts/apply-overlap-removal.mjs (MIT) with its numbers: 40 px padding, radius 13, 140 ticks
/// and a pull back to the start position of 0.03. It uses force_graph (MIT), a Dart port of d3-force, with d3's cooling.
///
/// [squeeze], from 0 to 1, also pulls every item toward the middle, at most at d3's default forceX strength of 0.1.
/// This is Obsidian's graph "Center force". Afterwards the pulls are removed and 40 more collision ticks clear any
/// overlap they caused, as FontMap's cartogram.js (src/experiments/engine/cartogram.js, relax) does.
List<Offset> dockSpread(List<Offset> at, double aspect, double squeeze) {
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
                // d3's value. force_graph keeps the one from its Apeirron graph.
                .toDouble()
        ..alphaTarget = 0
        ..addForce(collide)
        ..addForce(_Toward([for (final n in nodes) Offset(n.x, n.y)], pull));
  if (squeeze > 0) {
    sim.addForce(
      _Toward(List.filled(nodes.length, Offset(w / 2, h / 2)), squeeze * .1),
    );
  }
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

/// d3-force's forceX and forceY (x.js, y.js; ISC) in one force, which force_graph leaves out.
/// Each node is pulled toward its own point in [to], scaled by [strength] and the current alpha.
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

/// Feature vector for images, from their colours reduced to 16 x 16 pixels (Torralba, Fergus and Freeman, "80 million
/// tiny images", 2008). Several images are concatenated.
///
/// Returns null when one of them cannot be read yet, so it is asked for again next time. Cached while the window is open.
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
      final codec = await ui.instantiateImageCodec(
        await File(f).readAsBytes(),
        targetWidth: side,
        targetHeight: side,
      );
      final image = (await codec.getNextFrame()).image,
          px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
              .buffer
              .asUint8List();
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

/// Path of the CLIP image encoder [name] (clip_b32 is OpenAI's ViT-B/32, fontclip_b32 is FontCLIP's) if it has been
/// built (engine/deps/likeness_models.py), otherwise null. Without a model the maps use tiny colours ([dockTiny]).
String? dockModel(String name) {
  final f =
      '${Platform.environment['HOME']}/Library/Caches/Motolii/models/$name.onnx';
  return File(f).existsSync() ? f : null;
}

/// Feature vector of several images from the CLIP image encoder [model].
///
/// Each image is resized to 224 x 224, as CLIP's own Resize does, and gives 512 numbers. The images are concatenated so
/// that two effects are compared frame by frame at the same times, as in ViSiL's frame-to-frame similarity
/// (Kordopatis-Zilos et al., ICCV 2019). Every effect's tile is drawn at the same times. Returns null if an image cannot
/// be read or the model fails. Results are cached ([dockLookKept]), so only a new or redrawn image is encoded again.
final _clip = <String, Float32List>{};
Future<Float32List?> dockSeen(
  Motolii m,
  String model,
  List<String> files,
) async {
  final key = '$model\n${files.join('\n')}';
  if (_clip[key] case final v?) return v;
  final v = Float32List(512 * files.length),
      keys = <String>[],
      missing = <int>[];
  for (final (k, f) in files.indexed) {
    try {
      keys.add(
        '$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}',
      );
    } catch (_) {
      return null;
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
        final codec = await ui.instantiateImageCodec(
          await File(files[k]).readAsBytes(),
          targetWidth: 224,
          targetHeight: 224,
        );
        final image = (await codec.getNextFrame()).image;
        pictures.add(
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
              .asUint8List(),
        );
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

/// The cache file for an image's feature vector, in ~/Library/Caches/Motolii/looks.
/// [key] combines the model, the image and when it was drawn. [dockLookKept] returns null when nothing is cached.
File _look(String key) => File(
  '${Platform.environment['HOME']}/Library/Caches/Motolii/looks/${sha1.convert(utf8.encode(key))}.f32',
);
Float32List? dockLookKept(String key) {
  try {
    final had = _look(key).readAsBytesSync();
    return had.isEmpty || had.length % 4 != 0
        ? null
        : had.buffer.asFloat32List();
  } catch (_) {
    return null;
  }
}

void dockLookKeep(String key, Float32List v) {
  fileKeep(_look(key), Float32List.fromList(v).buffer.asUint8List());
}

/// Joins several feature vectors per item side by side, as FontMap does for fonts (FontCLIP's numbers beside the tags'
/// and shapes', weighted 1, 0.5 and 0.2).
///
/// Each part is scaled to a total spread of 1, then multiplied by its entry in [weights]. Parts listed in [even] are
/// first standardised per dimension (z-score). An item the first part has no vector for is left out (null). An item
/// missing from another part gets that part's mean, so the part says nothing about it.
List<Float32List?> dockTogether(
  List<List<Float32List?>> parts,
  List<double> weights, {
  Set<int> even = const {},
}) {
  final n = parts.first.length, made = <List<Float32List>>[];
  for (final (k, rows) in parts.indexed) {
    final dims = rows.nonNulls.firstOrNull?.length ?? 0,
        had = [
          for (final r in rows)
            if (r != null && r.length == dims) r,
        ];
    final mean = Float64List(dims),
        sd = Float64List(dims)..fillRange(0, dims, 1);
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
      if (parts.first[i] == null)
        null
      else
        Float32List.fromList([for (final k in made) ...k[i]]),
  ];
}

/// A colour for each item, by where it lies on the map, following DataMapPlot
/// (TutteInstitute/datamapplot 45a0123, datamapplot/palette_handling.py; MIT).
///
/// This is palette_from_datamap with every item as its own label, as its interactive plot does (create_plots.py):
/// - The hue goes round the map's middle by angle, spaced by distance from the middle (radius_weight_power 1).
/// - Chroma runs from 20 to 90 and lightness from 80 down to palette_min_lightness, outward from the middle among the
///   items in the same sector (theta_range π/16).
/// - The result goes through pastel_palette (degree 2), as DataMapPlot's dark mode does.
///
/// palette_min_lightness is 30, not DataMapPlot's 10: at 10 the outermost 45 of 328 fonts fell below the 3:1 contrast
/// that WCAG 2.1 (1.4.11) requires for graphics against the map's background. JCh comes from CAM16
/// (material_color_utilities), where colorspacious uses its predecessor CIECAM02.
final _palettes = Expando<Map<String, Color>>();
Map<String, Color> dockPalette(Map<String, Offset> at) =>
    _palettes[at] ??= _palette(at);
Map<String, Color> _palette(Map<String, Offset> at) {
  final ids = at.keys.toList(), n = ids.length;
  if (n == 0) return const {};
  final xs = [for (final id in ids) at[id]!.dx],
      ys = [
        for (final id in ids) -at[id]!.dy,
      ]; // y points up, as in DataMapPlot.
  final cx = (xs.reduce(math.min) + xs.reduce(math.max)) / 2,
      cy = (ys.reduce(math.min) + ys.reduce(math.max)) / 2;
  final r = [
    for (var i = 0; i < n; i++)
      math.sqrt((xs[i] - cx) * (xs[i] - cx) + (ys[i] - cy) * (ys[i] - cy)),
  ];
  final t = [for (var i = 0; i < n; i++) math.atan2(ys[i] - cy, xs[i] - cx)];
  double interp(double x, List<double> xp, List<double> fp) {
    // Same as numpy's interp: the ends are held.
    if (x <= xp.first) return fp.first;
    if (x >= xp.last) return fp.last;
    var k = 1;
    while (xp[k] < x) {
      k++;
    }
    return xp[k] == xp[k - 1]
        ? fp[k]
        : fp[k - 1] +
              (fp[k] - fp[k - 1]) * (x - xp[k - 1]) / (xp[k] - xp[k - 1]);
  }

  final order = List.generate(n, (i) => i)
    ..sort((a, b) => t[a].compareTo(t[b]));
  var sum = 0.0;
  final base = [for (final i in order) sum += r[i]],
      byT = [for (final i in order) t[i]];
  final weights = [for (final b in base) sum > 0 ? b / sum : 0.0];
  final hue = [
    for (var i = 0; i < n; i++) interp(t[i], byT, weights) * 360 % 360,
  ];
  final sectors = n < 256
      ? t
      : [for (var k = 0; k < 256; k++) -math.pi + 2 * math.pi * k / 256];
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
              if (wraps ? (t[i] > lo || t[i] < hi) : (t[i] > lo && t[i] < hi))
                r[i],
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
    final chroma = interp(r[i], ref, [
      for (var k = 0; k < m; k++) 20 + 70 * k / m,
    ]);
    final lightness = interp(r[i], ref, [
      for (var k = 0; k < m; k++) 80 - (80 - 30) * k / m,
    ]);
    raw.add(Cam16.fromJch(lightness, chroma, hue[i]).toInt());
  }
  final jch = [for (final c in raw) Cam16.fromInt(c)];
  final leastJ = jch.map((c) => c.j).reduce(math.min),
      leastC = jch.map((c) => c.chroma).reduce(math.min);
  return {
    for (final (i, c) in jch.indexed)
      ids[i]: Color(
        Cam16.fromJch(
          (c.j * math.sqrt2).clamp(leastJ, 100),
          (c.chroma / 2).clamp(math.min(10 / 2, leastC), 50),
          c.hue,
        ).toInt(),
      ),
  };
}

/// Each shelf's map, kept while the window is open.
final _maps = <String, DockMapPlaces>{};
DockMapPlaces dockMap(String shelf) => _maps[shelf] ??= DockMapPlaces(shelf);
