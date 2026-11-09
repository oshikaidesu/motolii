// motolii_questions.dart: questions of the inside (docs/app/BRIDGE.md Q): asked on another isolate or a channel, the answer a Future; the window never waits on them.
part of 'motolii.dart';

extension MotoliiQuestions on Motolii {
  /// The stage's picture as a Flutter texture (the inside draws it by its own clock; nothing is copied). -1: none.
  Future<int> texture() async {
    final (a, _) = await answered(later('live')); // (opened by the hand: the window never stands still for it)
    if (a == 0) return -1;
    return await Motolii._channel.invokeMethod<int>('start', {'lib': libPath, 'handle': _m.address}) ?? -1;
  }

  /// A ticket's answer when it comes, and why not if refused: Thermion's VoidCallbackRegistry, as it is (a Completer under
  /// each request's number, completed when the inside says an answer is there: motolii_add_listener 8). Nothing looks again and again.
  Future<(int, String)> answered(int ticket) {
    final a = answer(ticket);
    if (a >= 0) return Future.value((a, a >= 1 ? '' : answerWhy));
    return (_waiting[ticket] ??= Completer<(int, String)>()).future;
  }

  /// A ticket's answer: -1 not done yet, 0 refused ([answerWhy] says why), 1 done; said once.
  int answer(int ticket) {
    final a = _answer(_m, ticket);
    if (a >= 0) _take(3); // (done: the pictures as the inside made them before it answered)
    return a;
  }

  String get answerWhy => _answerWhy(_m).toDartString();
}
