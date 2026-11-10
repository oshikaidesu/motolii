// What the user has selected (Selection): a layer, several layers together, keyframes, a stretch between two keyframes,
// and the property a picked colour is written to.
import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/layer.dart';

/// What is selected in the window: one layer, the layers selected together, keyframes and one stretch between two keyframes.
class Selection {
  /// Creates an empty selection.
  ///
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

  String? _selected; // Nothing is selected when a document opens.

  /// The id of the selected layer, or null when none is.
  String? get selected => _selected;

  /// The selected layer, or null when none is.
  Layer? get layer => _layers().where((l) => l.id == _selected).firstOrNull;

  /// The layers selected together, outlined in the preview. A relation is made of them. Selecting one layer clears them.
  final many = <String>{};

  /// Whether [many] were picked one by one, so that the first leads. A box selection has no order.
  bool manyInOrder = false;
  final _keys = <SelectedKeyframe>{};

  /// The selected keyframes.
  Set<SelectedKeyframe> get keys => _keys;

  /// The stretch selected by clicking its line, like Theatre.js's connector between two keyframes
  /// (BasicKeyframeConnector.tsx, Apache-2.0). It belongs to one property, whereas a keyframe covers every property at that time.
  StretchPicked? _stretch;

  /// The selected stretch between two keyframes of one property, or null when none is.
  StretchPicked? get stretch => _stretch;

  /// Selects the layer [id], or clears the selection when null.
  void select(String? id) {
    if (id == _selected && many.isEmpty) return;
    _selected = id;
    many.clear();
    _aim = null;
    _keys.clear();
    _stretch = null;
    _onLayerSelected();
    _onChanged();
  }

  /// Selects several layers. With [inOrder] the first one leads.
  void pickMany(Iterable<String> ids, {bool inOrder = false}) {
    many
      ..clear()
      ..addAll(ids);
    manyInOrder = inOrder;
    _onChanged();
  }

  /// Selects one keyframe, or adds it to the selection when [add] is true.
  void pickKey(SelectedKeyframe k, {bool add = false}) {
    if (!add) _keys.clear();
    _keys.add(k);
    _stretch = null;
    _selected = k.layer;
    _onLayerSelected();
    _onChanged();
  }

  /// Selects exactly these keyframes, for example after a box selection.
  void pickKeys(Iterable<SelectedKeyframe> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    _stretch = null;
    if (_keys.isNotEmpty) _selected = _keys.first.layer;
    _onLayerSelected();
    _onChanged();
  }

  /// Deselects all keyframes and the selected stretch.
  void clearKeys() {
    if (_keys.isEmpty && _stretch == null) return;
    _keys.clear();
    _stretch = null;
    _onChanged();
  }

  StretchPicked? _stretchOf(String layer, String name, int from) {
    final t = int.tryParse(layer),
        at = t == null
            ? const <double>[]
            : _engine()?.keyTimes(t, name) ?? const <double>[];
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

  /// Selects the stretch of property [name] on [layer] that starts at frame [from], and shows the Ease panel.
  void pickStretch(String layer, String name, int from) {
    _keys.clear();
    _stretch = _stretchOf(layer, name, from);
    _selected = layer;
    _onLayerSelected();
    _onChanged();
    if (_stretch != null) _onStretchSelected();
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
    if (_stretch case final s?) _stretch = _stretchOf(s.layer, s.name, s.from);
  }
}
