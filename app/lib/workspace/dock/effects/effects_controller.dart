// What the Effects shelf keeps while the window is open.
import 'dart:typed_data';

import 'package:motolii/bridge/motolii.dart' show Motolii, ShelfItem;
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/map/image_features.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';

/// What the Effects shelf keeps while the window is open: its map, what the tiles' pictures look like to the map, and
/// which effect a dragged tile carries.
class EffectsController {
  /// [tags] is the window's tags, which a search of the shelf matches.
  EffectsController(this.tags);

  /// The tags of the effects, and the effect each search was last answered with.
  final ShelfTags tags;

  /// The shelf's map: where each effect lies when the shelf is shown as a map.
  final map = ShelfMap('Effects');

  /// What the tiles' pictures look like, as the numbers the map compares.
  final features = ImageFeatures();

  /// Maps the drag data of a tile being dragged (its double-click callback, which is what the canvas takes) to the effect id.
  /// See DockHover's Draggable. Dropped on a deck, the effect goes into it, like a track on a Spotify playlist
  /// or an effect in a Premiere bin.
  final carried = Expando<String>();

  /// Effect files sorted by name, as After Effects' Effects & Presets panel lists each kind.
  /// The engine lists them by file, so VIDVOX's capitals came before AbsentMotion's am_ files: two runs of A to Z.
  /// Computed once per list of files. Each entry is the name as shown and the engine's item.
  final byName = Expando<List<(String, ShelfItem)>>();

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
