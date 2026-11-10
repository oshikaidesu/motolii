// What the Effects shelf keeps while the window is open.
import 'dart:typed_data';

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/workspace/dock/map/image_features.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

/// What the Effects shelf keeps while the window is open: its map, what the tiles' pictures look like to the map, and
/// which effect a dragged tile carries.
class EffectsController {
  /// The shelf's map: where each effect lies when the shelf is shown as a map.
  final map = ShelfMap('Effects');

  /// What the tiles' pictures look like, as the numbers the map compares.
  final features = ImageFeatures();

  /// Maps the drag data of a tile being dragged (its double-click callback, which is what the canvas takes) to the effect id.
  /// See DockHover's Draggable. Dropped on a deck, the effect goes into it, like a track on a Spotify playlist
  /// or an effect in a Premiere bin.
  final carried = Expando<String>();

  /// The Effects map's coordinates for the effects whose tile frames are read from [homes].
  /// An effect is placed by how it looks, from CLIP at three of its sixteen frames so motion counts (or tiny colours), and what it is for ([kinds], the engine's label, such as an ISF's CATEGORIES or its startImage, endImage and progress, see isf.cpp).
  /// The kind is weighted twice as much as the look: each kind becomes an island with similar effects near each other,
  /// as XO's Space keeps each drum type's colour together.
  Future<List<Float32List?>> numbersOf(
    Motolii m,
    String? clip,
    List<String> kinds,
    List<String> homes,
  ) async {
    final look = [
      for (final f in homes)
        await (clip == null
            ? features.tiny
            : (List<String> at) => features.seen(m, clip, at))([
          for (final k in const [0, 7, 15]) EffectTiles.frame(f, k),
        ]),
    ];
    final all = kinds.toSet().toList();
    return joinFeatures(
      [
        look,
        [for (final k in kinds) Float32List(all.length)..[all.indexOf(k)] = 1],
      ],
      const [1, 2],
      even: const {0},
    );
  }
}
