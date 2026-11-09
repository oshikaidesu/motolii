// What is picked: one thing or many, keys, a stretch between two keys; each told to the window as its own aspect.
part of 'ws.dart';

extension WsPick on Ws {
  void select(String? id) {
    if (id == _sel && many.isEmpty) return;
    _sel = id;
    many.clear();
    _aim = null;
    _keys.clear();
    _stretch = null;
    deskManual = null;
    _tell(WsAspect.picked);
  }

  void pickMany(Iterable<String> ids, {bool byHand = false}) {
    many
      ..clear()
      ..addAll(ids);
    manyByHand = byHand;
    _tell(WsAspect.picked);
  }

  void pickKey(WsKey k, {bool add = false}) {
    if (!add) _keys.clear();
    _keys.add(k);
    _stretch = null;
    _sel = k.layer;
    deskManual = null;
    _tell(WsAspect.picked);
  }

  /// Keys picked together (a box drawn round them): these and no others.
  void pickKeys(Iterable<WsKey> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    _stretch = null;
    if (_keys.isNotEmpty) _sel = _keys.first.layer;
    deskManual = null;
    _tell(WsAspect.picked);
  }

  void clearKeys() {
    if (_keys.isEmpty && _stretch == null) return;
    _keys.clear();
    _stretch = null;
    _tell(WsAspect.picked);
  }

  WsStretchPicked? _stretchOf(String layer, String name, int from) {
    final t = int.tryParse(layer), at = t == null ? const <double>[] : _inside?.keyMoments(t, name) ?? const <double>[];
    final i = at.indexWhere((s) => (s * Ws.fps).round() == from);
    return i < 0 || i + 1 >= at.length ? null : (layer: layer, name: name, at: at[i], from: from, to: (at[i + 1] * Ws.fps).round());
  }

  void pickStretch(String layer, String name, int from) {
    _keys.clear();
    _stretch = _stretchOf(layer, name, from);
    _sel = layer;
    deskManual = null;
    _tell(WsAspect.picked);
    if (_stretch != null) front('Ease');
  }
}
