// Dragging the two ends of a span up and down the bars at the sides of the graph square.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/ease/ease_writes.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool_state.dart';

/// For each span whose ends the user has moved, each property's two key values as they first were, and the scale of its bars.
///
/// The ends stay where they were left. Their position is read from the keys, so an undo moves them back.
final _endsFrom = Expando<Map<String, Map<String, (double, double, double)>>>();

mixin EaseEnds on State<EaseTool> {
  String? trouble;

  // Each property keyed at both ends of the span, as (name, key frames, key values, index of the key at the dragged end).
  Iterable<(String, List<int>, List<double>, int)> _ends(
    WorkspaceController ws,
    EaseSpan span,
    bool start,
  ) sync* {
    final t = span.layer.id;
    for (final name in layerMoving(ws, t)) {
      // When one property line is selected, only that property's ends are used.
      if (ws.stretch case final s? when s.name != name) continue;
      final at = [
            for (final s in layerKeyTimes(ws, t, name))
              (s * WorkspaceController.fps).round(),
          ],
          vs = layerKeyValues(ws, t, name);
      final i = at.indexOf(span.from),
          j = at.indexOf(span.to),
          k = start ? i : j;
      if (i < 0 || j < 0 || k >= vs.length || j >= vs.length) continue;
      yield (name, at, vs, k);
    }
  }

  Map<String, (double, double, double)> _from(
    WorkspaceController ws,
    EaseSpan span,
  ) => (_endsFrom[ws] ??= {}).putIfAbsent(
    '${spanId(span)}:${span.to}',
    () => {},
  );

  // Where the two ends stand on their bars.
  (double, double) endsOf(WorkspaceController ws, EaseSpan? span) {
    if (!isConnected(ws) || span == null || _from(ws, span).isEmpty) {
      return (0, 1);
    }
    final from = _from(ws, span);
    for (final (name, at, vs, _) in _ends(ws, span, true)) {
      if (from[name] case (final a, final b, final scale)?) {
        return (
          (vs[at.indexOf(span.from)] - a) / scale,
          1 + (vs[at.indexOf(span.to)] - b) / scale,
        );
      }
    }
    return (0, 1);
  }

  // State of an end drag. Every update is sent to the document as part of one undo step, newest value first, one at a time.
  // The key values from when the drag began are kept, because the document's own values change underneath the drag.
  List<(String, List<int>, List<double>, int)>? _pull;
  double? _pullNext;
  bool _pullGoing = false, _pullDone = false;
  double _toward(
    EaseSpan span,
    WorkspaceController ws,
    String name,
    double was,
    double by,
  ) {
    final shown = propertyLook(ws, name),
        lo = shown?.low ?? -double.infinity,
        hi = shown?.high ?? double.infinity;
    return (was + by * _from(ws, span)[name]!.$3).clamp(
      math.min(lo, was),
      math.max(hi, was),
    );
  }

  void toEnd(
    WorkspaceController ws,
    EaseSpan? span,
    bool start,
    double by, {
    bool done = false,
  }) {
    if (!isConnected(ws) || span == null) return;
    if (_pullGoing) {
      _pullNext = by;
      _pullDone = _pullDone || done;
      return;
    }
    if (_pull == null && done && by.abs() < 1e-4) return;
    final t = span.layer.id,
        key = start ? span.from : span.to,
        outside = start ? span.from - 1 : span.to + 1;
    if (_pull == null) {
      for (final (name, at, vs, _) in _ends(ws, span, start)) {
        // The scale of the bars from the keys as they are now, recorded once.
        final i = at.indexOf(span.from),
            j = at.indexOf(span.to),
            shown = propertyLook(ws, name);
        _from(ws, span).putIfAbsent(
          name,
          () => (
            vs[i],
            vs[j],
            (vs[j] - vs[i]).abs() > 1e-9
                ? vs[j] - vs[i]
                : (shown == null ? 1.0 : shown.high - shown.low),
          ),
        );
      }
      _pull = [..._ends(ws, span, start)];
      openEaseStep(ws);
      for (final (name, at, vs, k) in _pull!) {
        if (easeJump && outside >= 0 && !at.contains(outside)) {
          // With Jump on, add a key one frame outside the end that keeps the value from before the move.
          keyEaseProperty(
            ws,
            t,
            name,
            '${outside / WorkspaceController.fps}',
            vs[k],
          );
        }
      }
    }
    for (final (name, _, vs, k) in _pull!) {
      keyEaseProperty(
        ws,
        t,
        name,
        '${key / WorkspaceController.fps}',
        _toward(span, ws, name, vs[k], by),
      );
    }
    if (done) {
      final told = _pull!.length;
      _pull = null;
      closeEaseStep(
        ws,
        (ok, why) => mounted
            ? setState(
                () => trouble = ok
                    ? (told == 0 ? 'No value keyed at both ends' : null)
                    : why,
              )
            : null,
      );
      return;
    }
    _pullGoing = true;
    showEaseLayer(ws, t, (_, _) {
      _pullGoing = false;
      final next = _pullNext, last = _pullDone;
      _pullNext = null;
      _pullDone = false;
      if (next != null) toEnd(ws, span, start, next, done: last);
    });
  }

  // The text shown beside the dragged end: the first property keyed at both ends, with its value and unit as the inspector shows them.
  // After Effects' value graph also shows the value of the point being dragged.
  String? endSays(
    WorkspaceController ws,
    EaseSpan? span,
    bool start,
    double by,
  ) {
    if (!isConnected(ws) || span == null) return null;
    final t = span.layer.id;
    for (final (name, _, vs, i) in _pull ?? [..._ends(ws, span, start)]) {
      final now = _from(ws, span).containsKey(name)
          ? _toward(span, ws, name, vs[i], by)
          : vs[i];
      final (k, f) = layerReading(ws, t, name);
      final v = now * k + f, shown = propertyLook(ws, name);
      return '${shown?.label ?? name} ${v.toStringAsFixed(v.abs() >= 100 ? 0 : 2)}${shown?.unit ?? ''}';
    }
    return null;
  }
}
