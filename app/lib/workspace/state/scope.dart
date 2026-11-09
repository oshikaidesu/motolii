// How the window's widgets reach the Ws: WsScope above them (Flutter's InheritedWidget).
part of 'state.dart';

/// The window's state to the parts below. A part that wants news listens to that aspect itself.
class WsScope extends InheritedWidget {
  const WsScope({super.key, required this.ws, required super.child});
  final Ws ws;

  static Ws read(BuildContext c) => c.getInheritedWidgetOfExactType<WsScope>()!.ws;

  @override
  bool updateShouldNotify(WsScope old) => ws != old.ws;
}
