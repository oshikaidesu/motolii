// What the Effects shelf draws besides its tiles: a deck's cover and the map of every effect.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/dock/effects/effect_catalog.dart';
import 'package:motolii/workspace/dock/effects/effects_controller.dart';
import 'package:motolii/workspace/dock/map/image_features.dart';
import 'package:motolii/workspace/dock/map/shelf_map_view.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/tile_moving.dart';

/// A deck's cover, as Spotify makes a playlist's cover: the images of its first four effects in a 2x2 grid,
/// or the first one alone while it holds fewer than four. [pic] is an effect's image, '' when it has none.
Widget? deckCover(Iterable<String> ids, String Function(String) pic) {
  final f = [
    for (final id in ids)
      if (pic(id) case final p when p.isNotEmpty) p,
  ].take(4).toList();
  Widget one(String p) => TileMoving(p, playing: false);
  return f.isEmpty
      ? null
      : f.length < 4
      ? one(f.first)
      : Column(
          children: [
            for (final r in const [0, 2])
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: one(f[r])),
                    Expanded(child: one(f[r + 1])),
                  ],
                ),
              ),
          ],
        );
}

/// The map of the effects: each [listed] tile placed by how alike its pictures are, [every] effect being what is placed.
class EffectMapPane extends StatelessWidget {
  const EffectMapPane(
    this.effects,
    this.m, {
    required this.every,
    required this.listed,
    required this.picked,
    required this.press,
    required this.pic,
    required this.tile,
    super.key,
  });
  final EffectsController effects;
  final Motolii m;
  final List<EffectEntry> every, listed;
  final String? picked;
  final void Function(String) press;
  final String Function(String) pic;
  final Widget Function(EffectEntry) tile;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Laid out by the tiles there are, and again once all are drawn; tiles drawn in between join then.
    listenable: EffectTiles.progress,
    builder: (context, _) {
      final map = effects.map, drawing = EffectTiles.progress.value != null;
      final clip = likenessModel('clip_b32'); // Placed by how CLIP sees each tile's frames once the model is made, else by tiny colours.
      final drawn = [
        for (final e in every)
          if (pic(e.id).isNotEmpty) e,
      ];
      if (!drawing || map.places.value.isEmpty) {
        map.need(
          m,
          [for (final e in drawn) (e.id, pic(e.id))],
          (from) => effects.numbersOf(m, clip, [
            for (final e in drawn) e.label,
          ], from),
          also: '${clip ?? ''} kinds',
        );
      }
      return ShelfMapView(
        map,
        [for (final e in listed) (e.id, tile(e))],
        picked: picked,
        press: press,
        peek: (id) => TileMoving(pic(id), playing: true),
        names: {for (final e in every) e.id: e.name},
      );
    },
  );
}
