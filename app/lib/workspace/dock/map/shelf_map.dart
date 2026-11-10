// A shelf's map: items laid out so that similar ones lie near each other, like XLN Audio XO's Space.
// Positions come from the engine's t-SNE (motolii_map), then items are pushed apart until none covers another
// ([spreadApart], after FontMap) and optionally drawn together (Obsidian's graph "Center force"). The shelf's chips and
// search words narrow which items are shown, as XO's filters do. Flutter's InteractiveViewer pans and zooms. Below the
// map, a similarity list shows the items nearest the picked one (XO's Similarity List, Splice's Similar Sounds). The user
// steps through it with its arrows or the left and right keys. The map is laid out again when the shelf's contents
// change, and positions are cached in ~/Library/Caches/Motolii.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/workspace/dock/map/map_palette.dart';
import 'package:motolii/workspace/dock/map/spread.dart';

/// Where one shelf's items lie on its map, by id, on a canvas shaped like the viewport ([spreadApart]). [laying] is true
/// while the layout is being computed. A shelf keeps its map while the window is open.
class ShelfMap {
  /// The map of the shelf called [name]; its positions are cached under that name.
  ShelfMap(this.name) {
    squeeze.addListener(() => _laid.isNotEmpty ? _spread() : null);
  }
  final String name;
  final places = ValueNotifier<Map<String, Offset>>(const {});
  final laying = ValueNotifier<bool>(false);

  /// How tightly the islands are drawn together, from 0 to 1 (the `squeeze` of [spreadApart], Obsidian's graph "Center
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

  /// Pushes [_laid] apart for the current viewport and draws it together by [squeeze] ([spreadApart]).
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

  /// Where the maps are cached between sessions. A test points it elsewhere with [shelfMapsAt], so the user's own
  /// cache is left alone.
  static Directory _cacheFolder = Directory(
    '${Platform.environment['HOME']}/Library/Caches/Motolii',
  );

  File get _kept => File('${_cacheFolder.path}/map_$name.json');

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

  final _palettes = Expando<Map<String, Color>>();

  /// A colour for each item of [at], by where it lies on the map ([mapPalette]). Worked out once for each layout.
  Map<String, Color> paletteOf(Map<String, Offset> at) =>
      _palettes[at] ??= mapPalette(at);
}

/// Sets where the maps are cached between sessions. A test points it at a folder of its own.
void shelfMapsAt(Directory d) => ShelfMap._cacheFolder = d;

/// Runs [spreadApart] and [ShelfMap._joined] on their own isolate. Only their arguments are sent, because a closure
/// made inside [ShelfMap.need] would capture its library too.
Future<List<Offset>> _spreadAway(
  List<Offset> at,
  double aspect,
  double squeeze,
) => Isolate.run(() => spreadApart(at, aspect, squeeze));
Future<Map<String, Offset>> _joinedAway(
  Map<String, Offset> known,
  Map<String, Float32List> seen,
) => Isolate.run(() => ShelfMap._joined(known, seen));
