// The Tool Panel's Ease tool: edits the easing curve between the selected keyframe and the next one.
// It shows the curve, its two handles, the presets as thumbnails and the numeric values.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart' show easeIsLaid, easeIsTurned;
import 'package:motolii/workspace/tool_panel/tool_panel_ease_state.dart';

import 'package:motolii/workspace/state/state.dart';

enum EaseKind { bezier, hold }

/// One easing: a kind and two bezier handles.
/// The handles are kept even when another kind is shown, so dragging a handle switches back to bezier.
class Ease {
  const Ease(this.kind, this.p1, this.p2, [this.name, this.drawn]);
  final EaseKind kind;
  final Offset p1, p2;
  final String? name;

  /// Samples of an easing that has no tile in the tool panel, as the document evaluates it, at even steps along the span.
  final List<double>? drawn;

  double at(double x) => drawn != null
      ? easeAlong(drawn!, x)
      : switch (kind) {
          EaseKind.bezier => Cubic(p1.dx, p1.dy, p2.dx, p2.dy).transform(x.clamp(0.0, 1.0)),
          EaseKind.hold => x < 1 ? 0 : 1,
        };

  Ease withHandles(Offset a, Offset b) => Ease(EaseKind.bezier, a, b);
  Ease reversed() => Ease(kind, Offset(1 - p2.dx, 1 - p2.dy), Offset(1 - p1.dx, 1 - p1.dy), name);

  @override
  bool operator ==(Object other) => other is Ease && other.kind == kind && other.p1 == p1 && other.p2 == p2 && identical(other.drawn, drawn);
  @override
  int get hashCode => Object.hash(kind, p1, p2);
}

/// Interpolates the evenly spaced samples [ys] at [x], which is clamped to 0 to 1.
double easeAlong(List<double> ys, double x) {
  final at = x.clamp(0.0, 1.0) * (ys.length - 1), i = at.floor().clamp(0, ys.length - 2);
  return ys[i] + (ys[i + 1] - ys[i]) * (at - i);
}

const easingPresets = [
  Ease(EaseKind.bezier, Offset(0, 0), Offset(1, 1), 'Linear'),
  Ease(EaseKind.bezier, Offset(.25, .1), Offset(.25, 1), 'Ease'),
  Ease(EaseKind.bezier, Offset(.42, 0), Offset(1, 1), 'In'),
  Ease(EaseKind.bezier, Offset(0, 0), Offset(.58, 1), 'Out'),
  Ease(EaseKind.bezier, Offset(.42, 0), Offset(.58, 1), 'In-out'),
  Ease(EaseKind.bezier, Offset(.34, 1.56), Offset(.64, 1), 'Back'),
  Ease(EaseKind.hold, Offset(.25, .1), Offset(.25, 1), 'Hold'),
];

/// Finds a preset by its name, not by its position, so adding a tile never changes the others.
Ease easingPreset(String name) => easingPresets.firstWhere((p) => p.name == name);

/// Whether [e] is an easing of the document that has no tile in the tool panel yet (Elastic, Random, Steps...).
/// Such an easing is identified by its name alone.
bool easeOther(Ease e) => e.name != null && easingPresets.every((p) => p.name != e.name);
String? easeName(Ease e) => easeOther(e) ? e.name : easingPresets.where((p) => p == e).firstOrNull?.name;

/// The span of time the easing shapes: from the first selected keyframe to the layer's next keyframe.
typedef EaseSpan = ({WsLayer layer, int from, int to, int picked});

EaseSpan? easeSpan(Ws ws) {
  if (ws.stretch case final s?) {
    if (ws.layers.where((l) => l.id == s.layer).firstOrNull case final l?) return (layer: l, from: s.from, to: s.to, picked: 1);
  }
  if (ws.keys.isEmpty) {
    // With no keyframe selected, use the span the playhead is in on the selected layer.
    // Alight Motion does the same when the playhead is between two keyframes: docs/internal/reports/alight_motion/alight_ui.md.
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

/// Converts an [Ease] to the text the document stores, and [heard] converts it back.
/// Three of the nine built-in kinds have a tile in the tool panel.
String said(Ease e) => easeOther(e)
    ? e.name!
    : switch (e.kind) {
        EaseKind.hold => 'Hold',
        EaseKind.bezier => e.name == 'Linear' ? 'Linear' : 'Bezier ${e.p1.dx} ${e.p1.dy} ${e.p2.dx} ${e.p2.dy}',
      };
Ease heard(String said) {
  // The engine returns an easing as the kind's name followed by all its numbers.
  final w = said.split(' '), n = [for (final x in w.skip(1)) double.tryParse(x) ?? 0];
  return switch (w.first) {
    'Hold' => easingPreset('Hold'),
    'Linear' => easingPreset('Linear'),
    'Bezier' when n.length == 4 => Ease(EaseKind.bezier, Offset(n[0], n[1]), Offset(n[2], n[3])),
    // A kind with no tile yet is kept by its text, over a straight line.
    _ => Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), said),
  };
}

/// The properties of the span's layer that have a keyframe where the span begins, each with the time of that keyframe.
Map<String, double> keysAt(Ws ws, EaseSpan span) {
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
        if ((s * Ws.fps).round() == span.from) name: s,
  };
}

/// The easings of the document that the eight built-in tiles do not cover (Elastic, Cyclic, Random, Steps,
/// ElasticSteps and any the document defines), each as an [Ease] whose curve is sampled from the engine.
///
/// The result is recomputed only when the document is read again, so a newly defined easing shows at once.
final _untiledOf = Expando<(String, List<Ease>)>();
List<Ease> easingsWithoutTile(Ws ws) {
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
