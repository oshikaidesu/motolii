// How the window's widgets reach the Ws: WsScope above them (Flutter's InheritedWidget).
part of 'state.dart';

/// The window's state to the parts below.
class WsScope extends StatefulWidget {
  const WsScope({super.key, required this.ws, required this.child});
  final Ws ws;
  final Widget child;

  static Ws read(BuildContext c) => c.getInheritedWidgetOfExactType<_WsAll>()!.ws;

  @override
  State<WsScope> createState() => _WsScopeState();
}

class _WsScopeState extends State<WsScope> {
  @override
  void initState() {
    super.initState();
    widget.ws.addListener(_changed);
  }

  @override
  void didUpdateWidget(WsScope old) {
    super.didUpdateWidget(old);
    if (old.ws != widget.ws) {
      old.ws.removeListener(_changed);
      widget.ws.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.ws.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) => _WsAll(ws: widget.ws, child: widget.child);
}

class _WsAll extends InheritedWidget {
  const _WsAll({required this.ws, required super.child});
  final Ws ws;
  @override
  bool updateShouldNotify(_WsAll old) => ws != old.ws;
}
