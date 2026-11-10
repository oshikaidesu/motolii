// What the Relations map draws, read from the engine: the layers, the camera and the relations.
import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';

typedef MapPoint3 = ({double x, double y, double z});

/// What the map draws, read from the engine: the layers, the camera and the relations.
class MapWorld {
  MapWorld(this.things, this.camera, this.relations, this.half);

  /// Layers by id: position, colour and name.
  final Map<String, (MapPoint3, Color, String)> things;
  final MapPoint3? camera;
  final List<MapRelation> relations;

  /// Half the camera's frame, in the canvas's units.
  final Size half;

  static MapWorld of(WorkspaceController ws) {
    final m = ws.inside;
    if (m == null) return MapWorld(const {}, null, const [], Size.zero);
    // The time of the frame the preview shows.
    final now = m.now, things = <String, (MapPoint3, Color, String)>{};
    MapPoint3? camera;
    // Prefer the position where the layer is shown, since a relation moves depth too.
    double v(int t, String n) =>
        (n == 'x' || n == 'y' || n == 'z' ? m.shows(t, n, now)?.$1 : null) ??
        m.value(t, n, now) ??
        0;
    final rels = <MapRelation>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id);
      if (t == null) continue;
      final kind = m.word(t, 'kind');
      if (kind == 'behaviour') {
        if (relationKinds.contains(m.word(t, 'file'))) {
          rels.add(
            MapRelation(l.id, relationLeader(m, t), [
              for (final s in m.word(t, 'members').split(' '))
                if (s != '_' && s.isNotEmpty) s,
            ]),
          );
        }
        continue;
      }
      final at = (x: v(t, 'x'), y: v(t, 'y'), z: v(t, 'z'));
      if (kind == 'camera') {
        camera = at;
        continue;
      }
      things[l.id] = (
        at,
        l.tone,
        l.name,
      ); // The label colour, the same as its row's.
    }
    return MapWorld(
      things,
      camera,
      rels,
      Size(
        ArtGeometry.comp.width / 2 / m.point,
        ArtGeometry.comp.height / 2 / m.point,
      ),
    );
  }
}

/// A relation in the world: its leader (0 for none) and its layers.
class MapRelation {
  MapRelation(this.id, int leader, this.members) : leader = '$leader';
  final String id, leader;
  final List<String> members;
}
