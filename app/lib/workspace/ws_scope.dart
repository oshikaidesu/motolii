// How the window's widgets reach the Ws: WsScope above them, each widget rebuilt only for the aspects it asked for
// (Flutter's InheritedModel), the picture and the playhead's moment as notifiers of their own.
part of 'ws.dart';

/// The window's state to the parts below (Flutter's InheritedModel): a part says which aspects it reads
/// ([WsScope.of]) and is built again only when one of those changed.
class WsScope extends StatefulWidget {
  const WsScope({super.key, required this.ws, required this.child});
  final Ws ws;
  final Widget child;
  /// The window's state, the part built again when one of [aspects] changes (none said: any, as a pane of your own
  /// may: the window's own parts each say theirs).
  static Ws of(BuildContext c, [Set<WsAspect>? aspects]) {
    for (final a in aspects ?? WsAspect.values) {
      InheritedModel.inheritFrom<_WsAll>(c, aspect: a);
    }
    return read(c);
  }
  static Ws read(BuildContext c) => c.getInheritedWidgetOfExactType<_WsAll>()!.ws;
  /// The playhead, and built again when it moves (nothing else of the window does that).
  static int frameOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<WsMoment>()!.notifier!.value;
  /// The inside's moment's picture: built again when a new one comes (what shows values at the moment shown).
  static int pictureOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_WsPicture>()!.notifier!.value;
  @override
  State<WsScope> createState() => _WsScopeState();
}

class _WsScopeState extends State<WsScope> {
  late Map<WsAspect, int> _told = _now();
  Map<WsAspect, int> _now() => {for (final MapEntry(:key, :value) in widget.ws.on.entries) key: value.value};
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
      _told = _now();
    }
  }
  @override
  void dispose() {
    widget.ws.removeListener(_changed);
    super.dispose();
  }
  void _changed() => setState(() => _told = _now());
  @override
  Widget build(BuildContext context) => _WsAll(ws: widget.ws, told: _told, child: WsMoment(notifier: widget.ws.moment, child: _WsPicture(notifier: widget.ws.seen, child: widget.child)));
}

class _WsPicture extends InheritedNotifier<ValueNotifier<int>> {
  const _WsPicture({required super.notifier, required super.child});
}

class _WsAll extends InheritedModel<WsAspect> {
  const _WsAll({required this.ws, required this.told, required super.child});
  final Ws ws;
  final Map<WsAspect, int> told;   // (how many times each aspect was told, as of this build)
  @override
  bool updateShouldNotify(_WsAll old) => !mapEquals(told, old.told) || ws != old.ws;
  @override
  bool updateShouldNotifyDependent(_WsAll old, Set<WsAspect> dependencies) => ws != old.ws || dependencies.any((a) => told[a] != old.told[a]);
}

/// The playhead: told when it moves, and again when what was read at it was put off (the inside busy).
class WsMomentNow extends ValueNotifier<int> {
  WsMomentNow(super.value);
  void again() => notifyListeners();
}

/// The playhead's own scope, under [WsScope]: [WsScope.frameOf].
class WsMoment extends InheritedNotifier<ValueNotifier<int>> {
  const WsMoment({super.key, required super.notifier, required super.child});
}
