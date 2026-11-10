// Owns the panel's values (InspectorValues) and provides them again whenever they change. A different kind makes a new document, so give the widget a key.
// The look follows docs/app/DESIGN.md: hairlines, type carries hierarchy, grey levels, and an accent only for Role.selected.

import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_sync.dart';
import 'package:motolii/inspector/inspector_values.dart';

/// Owns the panel's values ([InspectorValues]) and provides them again whenever they change.
/// A different kind makes a new document, so give the widget a key.
class InspectorHost extends StatefulWidget {
  /// Creates the owner of the values of the layer that [layer] describes, filled from [snapshot].
  const InspectorHost({
    super.key,
    required this.layer,
    required this.snapshot,
    required this.actions,
    required this.edits,
    required this.live,
    required this.child,
  });

  /// The layer that is shown: its kind and name, and its cards.
  final InspectedLayer layer;

  /// The selected layer's values as the caller has them now.
  /// They are written in silently when they change, so edits made here last until then.
  final InspectorSnapshot snapshot;

  /// What the buttons and menus on the cards do.
  final CardActions actions;

  /// The callbacks that hear of what is edited here.
  final InspectorEdits edits;

  /// The values and key marks at a new time, applied without rebuilding the host.
  /// During playback only the time moves, so the fields that show the values follow and the rest of the inspector stays as built.
  final ValueListenable<(Map<String, double>, Map<String, KeyframeState>)> live;

  /// The Inspector's widgets. They find the values through [InspectorScope].
  final Widget child;

  @override
  State<InspectorHost> createState() => _InspectorHostState();
}

class _InspectorHostState extends State<InspectorHost> {
  late InspectorValues doc = _make();
  InspectorValues _make() {
    final d = InspectorValues(
      widget.layer.kind,
      cards: widget.layer.cards ?? const [],
    );
    _wire(d);
    _sync.start(d, widget.snapshot);
    return d..addListener(_r);
  }

  /// Gives the document what the caller says about the selected layer, as it is now.
  void _wire(InspectorValues d) => d
    ..layer = widget.layer
    ..actions = widget.actions;

  final _sync = InspectorSync();

  void _r() {
    _sync.report(doc, widget.edits);
    final r = doc.s2['route'];
    if (r != null) {
      doc.s2.remove('route');
      widget.edits.onAim(doc.s2.remove('route.at') ?? '');
      widget.edits.onRoute(r);
    }
    // During a drag the whole inspector is not rebuilt at each step: the field being dragged shows its own value
    // and the preview follows what the caller is told. Everything is rebuilt once when the drag ends.
    if (mounted && !doc.inGesture && !doc.ending) setState(() => _tick++);
  }

  /// What makes a list of cards need a new document: their names and declarations, whatever their defaults are.
  static List<String>? _shapeOf(List<CardDeclaration>? cards) => cards
      ?.map((f) => f.name + f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), ''))
      .toList();

  @override
  void didUpdateWidget(InspectorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.live != widget.live) {
      oldWidget.live.removeListener(_atMoment);
      widget.live.addListener(_atMoment);
    }
    final was = oldWidget.layer, now = widget.layer;
    if (was.kind != now.kind ||
        !listEquals(_shapeOf(was.cards), _shapeOf(now.cards))) {
      doc.dispose();
      doc = _make();
      _tick++;
    } else if (_sync.show(
      doc,
      widget.snapshot,
      widget.edits,
      previous: oldWidget.snapshot,
    )) {
      _tick++;
    }
    if (was.title != now.title ||
        was.kindWord != now.kindWord ||
        !listEquals(was.cardsOff, now.cardsOff)) {
      // The eye of an effect was shut or opened, so its card must change.
      _tick++;
    }
    _wire(doc);
  }

  void _atMoment() {
    final (values, marks) = widget.live.value;
    // A value that no field watches changed, such as a choice, so rebuild to show it.
    if (_sync.showAt(doc, values, marks) && mounted) setState(() => _tick++);
  }

  @override
  void initState() {
    super.initState();
    widget.live.addListener(_atMoment);
  }

  @override
  void dispose() {
    widget.live.removeListener(_atMoment);
    doc.dispose();
    super.dispose();
  }

  int _tick = 0;
  @override
  Widget build(BuildContext context) =>
      InspectorScope(doc: doc, tick: _tick, child: widget.child);
}
