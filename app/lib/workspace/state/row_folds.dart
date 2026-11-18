// Which rows of the timeline are open (RowFolds): the keyframe lanes under a layer, and the members of a group.
import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:motolii/workspace/state/layer.dart';

/// Which rows the user has opened in the timeline: the lanes of keyframed properties under a layer, and the members of a group.
/// Only the rows fold. The document does not know of it and the file does not save it.
class RowFolds {
  /// Creates it with every row closed. [animating] says whether Animate is on, which opens every layer's lanes.
  /// [onChanged] is called after every change.
  RowFolds({
    required this._animating,
    required this._layers,
    required this._onChanged,
  });

  final bool Function() _animating;
  final List<Layer> Function() _layers;
  final VoidCallback _onChanged;

  // Which layers show their keyframed properties in lanes under their rows. The user opens them (After Effects' twirl,
  // Ableton's unfolded track). With Animate on, every layer is open and only the ones the user shut are tracked.
  final _lanesOpen = <int>{}, _lanesShut = <int>{};

  /// Whether layer [id] shows its keyframed properties in lanes under its row.
  bool lanesOpen(int id) =>
      _animating() ? !_lanesShut.contains(id) : _lanesOpen.contains(id);

  /// Whether the user opened the lanes of what a relation aims at. Animate opens keyframe lanes only.
  bool aimsOpen(int id) => _lanesOpen.contains(id) && !_lanesShut.contains(id);

  /// Opens the lanes of the layers [ids] when none of them is open, else shuts them all.
  void twirl(Iterable<int> ids) {
    final open = ids.any(lanesOpen), s = _animating() ? _lanesShut : _lanesOpen;
    open == _animating() ? s.addAll(ids) : s.removeAll(ids);
    _onChanged();
  }

  /// Forgets which lanes the user shut while Animate held every layer open. It tells no one: the caller does.
  void forgetShut() => _lanesShut.clear();

  // The open groups. A closed group is one row, like a precomposed layer or Alight Motion's group (the triangle is
  // Apple Motion's and Cavalry's). Only the rows fold; the document does not know and the file does not save it.
  final _groupsOpen = <int>{};

  /// Whether the group [id] shows its members as rows.
  bool groupOpen(int id) => _groupsOpen.contains(id);

  /// Opens the group [id], or closes it when it is open.
  void turnGroup(int id) {
    if (!_groupsOpen.remove(id)) _groupsOpen.add(id);
    // The group's own keyframe lanes follow it: one triangle per row
    _groupsOpen.contains(id) ? _lanesOpen.add(id) : _lanesOpen.remove(id);
    _onChanged();
  }

  /// Each layer hidden by a closed group, mapped to the row standing for it: the outermost closed group above it.
  Map<int, int> get foldedAway {
    final layers = _layers();
    final of = <int, Layer>{for (final l in layers) l.id: l};
    final away = <int, int>{};
    for (final l in layers) {
      for (final p in l.ancestors(of)) {
        if (p.kind == LayerKind.group && !groupOpen(p.id)) away[l.id] = p.id;
      }
    }
    return away;
  }
}
