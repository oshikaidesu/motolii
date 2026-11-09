// What is picked: one thing, and keys; each told to the window as its own aspect.
part of 'state.dart';

extension WsPick on Ws {
  void select(String? id) {
    if (id == _sel) return;
    _sel = id;
    _keys.clear();
    _tell(WsAspect.picked);
  }

  /// Keys picked together (a box drawn round them): these and no others.
  void pickKeys(Iterable<WsKey> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    if (_keys.isNotEmpty) _sel = _keys.first.layer;
    _tell(WsAspect.picked);
  }

  void clearKeys() {
    if (_keys.isEmpty) return;
    _keys.clear();
    _tell(WsAspect.picked);
  }
}
