// How the window's widgets reach the Ws. A WsScope above them is an InheritedModel, so each widget rebuilds only for the
// aspects it asked for. The snapshot counter and the playhead are separate notifiers.
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/state.dart';

/// Gives the widgets below access to the window's [Ws].
///
/// A widget names the aspects it reads with [WsScope.of] and rebuilds only when one of those changes.
class WsScope extends StatefulWidget {
  const WsScope({super.key, required this.ws, required this.child});
  final Ws ws;
  final Widget child;

  /// Returns the window's state and rebuilds the caller when one of [aspects] changes.
  /// With no [aspects] the caller rebuilds on any change. The window's own widgets always name theirs.
  static Ws of(BuildContext c, [Set<WsAspect>? aspects]) {
    for (final a in aspects ?? WsAspect.values) {
      InheritedModel.inheritFrom<_WsAll>(c, aspect: a);
    }
    return read(c);
  }

  /// Returns the window's state without subscribing to changes.
  static Ws read(BuildContext c) => c.getInheritedWidgetOfExactType<_WsAll>()!.ws;

  /// Returns the playhead frame and rebuilds the caller when it moves. Nothing else in the window rebuilds on that.
  static int frameOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<WsMoment>()!.notifier!.value;

  /// Returns a counter that increases whenever the engine produces a new snapshot of the current time.
  /// Widgets that show values at the displayed time use it to rebuild.
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
  Widget build(BuildContext context) => _WsAll(
    ws: widget.ws,
    told: _told,
    child: WsMoment(
      notifier: widget.ws.moment,
      child: _WsPicture(notifier: widget.ws.seen, child: widget.child),
    ),
  );
}

class _WsPicture extends InheritedNotifier<ValueNotifier<int>> {
  const _WsPicture({required super.notifier, required super.child});
}

class _WsAll extends InheritedModel<WsAspect> {
  const _WsAll({required this.ws, required this.told, required super.child});
  final Ws ws;

  /// How many times each aspect has notified, as of this build.
  final Map<WsAspect, int> told;
  @override
  bool updateShouldNotify(_WsAll old) => !mapEquals(told, old.told) || ws != old.ws;
  @override
  bool updateShouldNotifyDependent(_WsAll old, Set<WsAspect> dependencies) => ws != old.ws || dependencies.any((a) => told[a] != old.told[a]);
}

/// The playhead's own scope below [WsScope], read through [WsScope.frameOf].
class WsMoment extends InheritedNotifier<ValueNotifier<int>> {
  const WsMoment({super.key, required super.notifier, required super.child});
}
