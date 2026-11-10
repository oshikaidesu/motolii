// The selection: one layer or many, keyframes, and the stretch between two keyframes. Each change notifies [WsAspect.picked].
part of 'workspace_state.dart';

extension WsPick on Ws {
  /// Selects the layer [id], or clears the selection when null.
  void select(String? id) {
    if (id == _sel && many.isEmpty) return;
    _sel = id;
    many.clear();
    _aim = null;
    _keys.clear();
    _stretch = null;
    toolPanelManual = null;
    _tell(WsAspect.picked);
  }

  /// Selects several layers. With [inOrder] the first one leads.
  void pickMany(Iterable<String> ids, {bool inOrder = false}) {
    many
      ..clear()
      ..addAll(ids);
    manyInOrder = inOrder;
    _tell(WsAspect.picked);
  }

  /// Selects one keyframe, or adds it to the selection when [add] is true.
  void pickKey(WsKey k, {bool add = false}) {
    if (!add) _keys.clear();
    _keys.add(k);
    _stretch = null;
    _sel = k.layer;
    toolPanelManual = null;
    _tell(WsAspect.picked);
  }

  /// Selects exactly these keyframes, for example after a box selection.
  void pickKeys(Iterable<WsKey> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    _stretch = null;
    if (_keys.isNotEmpty) _sel = _keys.first.layer;
    toolPanelManual = null;
    _tell(WsAspect.picked);
  }

  /// Deselects all keyframes and the selected stretch.
  void clearKeys() {
    if (_keys.isEmpty && _stretch == null) return;
    _keys.clear();
    _stretch = null;
    _tell(WsAspect.picked);
  }

  WsStretchPicked? _stretchOf(String layer, String name, int from) {
    final t = int.tryParse(layer), at = t == null ? const <double>[] : _inside?.keyTimes(t, name) ?? const <double>[];
    final i = at.indexWhere((s) => (s * Ws.fps).round() == from);
    return i < 0 || i + 1 >= at.length ? null : (layer: layer, name: name, at: at[i], from: from, to: (at[i + 1] * Ws.fps).round());
  }

  /// Selects the stretch of property [name] on [layer] that starts at frame [from], and shows the Ease panel.
  void pickStretch(String layer, String name, int from) {
    _keys.clear();
    _stretch = _stretchOf(layer, name, from);
    _sel = layer;
    toolPanelManual = null;
    _tell(WsAspect.picked);
    if (_stretch != null) front('Ease');
  }
}
