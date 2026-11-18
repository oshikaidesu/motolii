// What the user has selected (Selection): a layer, several layers together, keyframes, stretches between keyframes,
// and the property a picked colour is written to.
import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/layer.dart';

/// What is selected in the window: one layer, the layers selected together, keyframes and stretches between keyframes.
class Selection {
  /// Creates an empty selection.
  /// [onChanged] is called after every change. [onLayerSelected] is called when a call selects a layer (alone, or
  /// through its keyframe or its stretch), before [onChanged]. [onStretchSelected] is called after [onChanged] when a
  /// stretch was found and selected.
  Selection({
    required this._engine,
    required this._layers,
    required this._composition,
    required this._onChanged,
    required this._onLayerSelected,
    required this._onStretchSelected,
  });

  final Motolii? Function() _engine;
  final List<Layer> Function() _layers;
  final CompositionSettings _composition;
  final VoidCallback _onChanged, _onLayerSelected, _onStretchSelected;

  int? _selected; // Nothing is selected when a document opens.

  /// The id of the selected layer, or null when none is.
  int? get selected => _selected;

  /// The selected layer, or null when none is.
  Layer? get layer => _layers().where((l) => l.id == _selected).firstOrNull;

  /// The layers selected together, outlined in the preview. A relation is made of them. Selecting one layer clears them.
  final many = <int>{};

  /// The layer the last click picked, which a Shift-click's range starts from (see pickOnClick). Null after a plain selection.
  int? lead;

  /// Whether [many] were picked one by one, so that the first leads. A box selection has no order.
  bool manyInOrder = false;
  final _keys = <SelectedKeyframe>{};

  /// The selected keyframes.
  Set<SelectedKeyframe> get keys => _keys;

  final _stretches = <StretchPicked>{};

  /// The selected stretches between keyframes.
  Set<StretchPicked> get stretches => _stretches;

  /// The first selected stretch, for single-stretch consumers.
  StretchPicked? get stretch => _stretches.firstOrNull;

  /// Selects the layer [id], or clears the selection when null.
  void select(int? id) {
    if (id == _selected && many.isEmpty) return;
    _selected = id;
    many.clear();
    lead = null;
    _aim = null;
    _keys.clear();
    _stretches.clear();
    _onLayerSelected();
    _onChanged();
  }

  /// Selects several layers. With [inOrder] the first one leads.
  void pickMany(Iterable<int> ids, {bool inOrder = false, int? lead}) {
    many
      ..clear()
      ..addAll(ids);
    manyInOrder = inOrder;
    this.lead = lead;
    _onChanged();
  }

  /// Selects one keyframe, or adds it to the selection when [add] is true.
  void pickKey(SelectedKeyframe k, {bool add = false}) {
    if (!add) _keys.clear();
    _keys.add(k);
    _stretches.clear();
    _selected = k.layer;
    _onLayerSelected();
    _onChanged();
  }

  /// Selects exactly these keyframes, for example after a box selection.
  void pickKeys(Iterable<SelectedKeyframe> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    _stretches.clear();
    if (_keys.isNotEmpty) _selected = _keys.first.layer;
    _onLayerSelected();
    _onChanged();
  }

  /// Deselects all keyframes and stretches.
  void clearKeys() {
    if (_keys.isEmpty && _stretches.isEmpty) return;
    _keys.clear();
    _stretches.clear();
    _onChanged();
  }

  StretchPicked? _stretchOf(int layer, String name, int from) {
    final at = _engine()?.keyTimes(layer, name) ?? const <double>[];
    final i = at.indexWhere(
      (s) => (s * _composition.frameRate).round() == from,
    );
    return i < 0 || i + 1 >= at.length
        ? null
        : (
            layer: layer,
            name: name,
            at: at[i],
            from: from,
            to: (at[i + 1] * _composition.frameRate).round(),
          );
  }

  /// Selects a stretch, or adds it to the selection when [add] is true. Shows the Ease panel.
  void pickStretch(int layer, String name, int from, {bool add = false}) {
    if (!add) {
      _keys.clear();
      _stretches.clear();
    }
    final s = _stretchOf(layer, name, from);
    if (s != null) {
      _stretches.add(s);
      _selected = layer;
      _onLayerSelected();
    }
    _onChanged();
    if (s != null) _onStretchSelected();
  }

  String? _aim;

  /// The property that a colour picked on the Colors shelf is written to, on the selected layer or the canvas.
  /// A card's colour link or the tool strip's ink or edge sets it; null means the fill. It notifies as a selection.
  String? get aim => _aim;
  set aim(String? to) {
    if (to == _aim) return;
    _aim = to;
    _onChanged();
  }

  /// Brings the selection in line with the layers after they were read again. It tells no one: the reader does.
  void syncWithLayers() {
    final layers = _layers();
    if (_selected != null && layers.every((l) => l.id != _selected)) {
      // The selected layer is gone: select the first. With nothing selected, the selection stays empty.
      _selected = layers.firstOrNull?.id;
    }
    // A selected keyframe stays selected while it exists; a selected stretch moves to that property's next keyframe.
    _keys.removeWhere(
      (k) => !layers.any((l) => l.id == k.layer && l.keys.contains(k.frame)),
    );
    final updated = <StretchPicked>{};
    for (final s in _stretches) {
      final rebuilt = _stretchOf(s.layer, s.name, s.from);
      if (rebuilt != null) updated.add(rebuilt);
    }
    _stretches
      ..clear()
      ..addAll(updated);
  }
}
