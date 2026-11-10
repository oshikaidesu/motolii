// How the window's widgets reach the WorkspaceController. A WorkspaceScope above them is an InheritedModel, so each widget rebuilds only for the
// aspects it asked for. The snapshot counter and the playhead are separate notifiers.
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Gives the widgets below access to the window's [WorkspaceController].
///
/// A widget names the aspects it reads with [WorkspaceScope.of] and rebuilds only when one of those changes.
class WorkspaceScope extends StatefulWidget {
  const WorkspaceScope({super.key, required this.ws, required this.child});
  final WorkspaceController ws;
  final Widget child;

  /// Returns the window's state and rebuilds the caller when one of [aspects] changes.
  /// With no [aspects] the caller rebuilds on any change. The window's own widgets always name theirs.
  static WorkspaceController of(BuildContext c, [Set<WorkspaceAspect>? aspects]) {
    for (final a in aspects ?? WorkspaceAspect.values) {
      InheritedModel.inheritFrom<_AspectScope>(c, aspect: a);
    }
    return read(c);
  }

  /// Returns the window's state without subscribing to changes.
  static WorkspaceController read(BuildContext c) => c.getInheritedWidgetOfExactType<_AspectScope>()!.ws;

  /// Returns the playhead frame and rebuilds the caller when it moves. Nothing else in the window rebuilds on that.
  static int frameOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<PlayheadScope>()!.notifier!.value;

  /// Returns a counter that increases whenever the engine produces a new snapshot of the current time.
  /// Widgets that show values at the displayed time use it to rebuild.
  static int pictureOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_SnapshotScope>()!.notifier!.value;
  @override
  State<WorkspaceScope> createState() => _WorkspaceScopeState();
}

class _WorkspaceScopeState extends State<WorkspaceScope> {
  late Map<WorkspaceAspect, int> _told = _now();
  Map<WorkspaceAspect, int> _now() => {for (final MapEntry(:key, :value) in widget.ws.on.entries) key: value.value};
  @override
  void initState() {
    super.initState();
    widget.ws.addListener(_changed);
  }

  @override
  void didUpdateWidget(WorkspaceScope old) {
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
  Widget build(BuildContext context) => _AspectScope(
    ws: widget.ws,
    told: _told,
    child: PlayheadScope(
      notifier: widget.ws.moment,
      child: _SnapshotScope(notifier: widget.ws.seen, child: widget.child),
    ),
  );
}

class _SnapshotScope extends InheritedNotifier<ValueNotifier<int>> {
  const _SnapshotScope({required super.notifier, required super.child});
}

class _AspectScope extends InheritedModel<WorkspaceAspect> {
  const _AspectScope({required this.ws, required this.told, required super.child});
  final WorkspaceController ws;

  /// How many times each aspect has notified, as of this build.
  final Map<WorkspaceAspect, int> told;
  @override
  bool updateShouldNotify(_AspectScope old) => !mapEquals(told, old.told) || ws != old.ws;
  @override
  bool updateShouldNotifyDependent(_AspectScope old, Set<WorkspaceAspect> dependencies) => ws != old.ws || dependencies.any((a) => told[a] != old.told[a]);
}

/// The playhead's own scope below [WorkspaceScope], read through [WorkspaceScope.frameOf].
class PlayheadScope extends InheritedNotifier<ValueNotifier<int>> {
  const PlayheadScope({super.key, required super.notifier, required super.child});
}
