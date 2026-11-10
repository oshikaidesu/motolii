// The Tool Panel's Ease tool: edits the easing curve between the selected keyframe and the next one.
// It shows the curve, its two handles, the presets as thumbnails and the numeric values.
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_state.dart';

import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

/// The span of time the easing shapes: from the first selected keyframe to the layer's next keyframe.
typedef EaseSpan = ({Layer layer, int from, int to, int picked});

EaseSpan? easeSpan(WorkspaceController ws) {
  if (ws.stretch case final s?) {
    if (ws.layers.where((l) => l.id == s.layer).firstOrNull case final l?) return (layer: l, from: s.from, to: s.to, picked: 1);
  }
  if (ws.keys.isEmpty) {
    // With no keyframe selected, use the span the playhead is in on the selected layer.
    // Alight Motion does the same when the playhead is between two keyframes: docs/design/alight_motion_ui.md.
    final layer = ws.layers.where((l) => l.id == ws.selected).firstOrNull, f = ws.frame;
    final keys = layer == null ? const <int>[] : ([...layer.keys]..sort());
    final from = keys.where((k) => k <= f).lastOrNull, to = keys.where((k) => k > f).firstOrNull, before = keys.where((k) => k < f).lastOrNull;
    if (from == f && to == null && before != null) {
      // On the last keyframe, use the span that ends there, as if that keyframe were selected below.
      return (layer: layer!, from: before, to: f, picked: 0);
    }
    return from == null || to == null ? null : (layer: layer!, from: from, to: to, picked: 0);
  }
  final picked = ws.keys.toList()..sort((a, b) => a.frame.compareTo(b.frame));
  final k = picked.first, layer = ws.layers.where((l) => l.id == k.layer).firstOrNull;
  if (layer == null) return null;
  final keys = [...layer.keys]..sort();
  final next = keys.where((f) => f > k.frame).firstOrNull, prev = keys.where((f) => f < k.frame).lastOrNull;
  return next != null
      ? (layer: layer, from: k.frame, to: next, picked: picked.length)
      : (layer: layer, from: prev ?? math.max(0, k.frame - 30), to: k.frame, picked: picked.length);
}

/// The easings the user edited, per document and per span, so they survive leaving the tool panel and coming back.
final eases = Expando<Map<String, Ease>>();
String spanId(EaseSpan? s) => s == null ? 'new' : '${s.layer.id}:${s.from}';

/// The Ease tool: curve editor for the easing of the selected span.
class EaseTool extends StatefulWidget {
  const EaseTool({super.key});
  @override
  State<EaseTool> createState() => EaseToolState();
}

/// The properties of the span's layer that have a keyframe where the span begins, each with the time of that keyframe.
Map<String, double> keysAt(WorkspaceController ws, EaseSpan span) {
  final m = ws.inside!, t = int.parse(span.layer.id);
  // When a single property line is selected, only that property counts.
  if (ws.stretch case final s?) return {s.name: s.at};
  // The result is cached and recomputed only when the document is read again, not on every frame of playback.
  if (_keysAtOf[ws] case (final r, final id, final f, final at) when r == ws.reads && id == span.layer.id && f == span.from) return at;
  final at = _keysAt(m, t, span);
  _keysAtOf[ws] = (ws.reads, span.layer.id, span.from, at);
  return at;
}

final _keysAtOf = Expando<(int, String, int, Map<String, double>)>();
Map<String, double> _keysAt(Motolii m, int t, EaseSpan span) {
  return {
    for (final name in m.moving(t))
      for (final s in m.keyTimes(t, name))
        if ((s * WorkspaceController.fps).round() == span.from) name: s,
  };
}

/// The easings of the document that the eight built-in tiles do not cover (Elastic, Cyclic, Random, Steps,
/// ElasticSteps and any the document defines), each as an [Ease] whose curve is sampled from the engine.
///
/// The result is recomputed only when the document is read again, so a newly defined easing shows at once.
final _untiledOf = Expando<(String, List<Ease>)>();
List<Ease> easingsWithoutTile(WorkspaceController ws) {
  final m = ws.inside;
  if (m == null) return const [];
  if (_untiledOf[m] case (final was, final tiles) when was == '${ws.reads}') return tiles;
  final names = m.easingNames, said = '${ws.reads}';
  final tiles = [
    for (final name in names)
      if (name != 'Bezier' && !easeIsLaid(name) && !easeIsTurned(name) && easingPresets.every((p) => p.name != name))
        Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), name, [for (var i = 0; i <= 32; i++) m.easingAt(name, i / 32)]),
  ];
  _untiledOf[m] = (said, tiles);
  return tiles;
}
