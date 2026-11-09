// What is picked: one thing, told to the window as its own aspect.
part of 'state.dart';

extension WsPick on Ws {
  void select(String? id) {
    if (id == _sel) return;
    _sel = id;
    _tell(WsAspect.picked);
  }
}
