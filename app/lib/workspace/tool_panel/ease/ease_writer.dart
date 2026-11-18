// The Ease tool's writing to the document. While the pointer is down each new ease is sent so the canvas and the bars follow it, one at a
// time (any between are skipped), and the whole drag is one undo step; on release it is sent once more and the step is closed.
// EaseToolState keeps what is on the screen; this keeps where the write has got to. It draws nothing.
import 'dart:async' show scheduleMicrotask;

import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/workspace/state/ease/ease_writes.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// The segments of every picked keyframe, on any layer, one for each property keyed there.
// A last keyframe has no segment after it, so the segment ending at it is used.
List<(int, String, double)> easeStretches(WorkspaceController ws) => [
  if (ws.stretch case final s?)
    (s.layer, s.name, s.at)
  else if (ws.keys.isEmpty) // Nothing picked: the segment the playhead is in.
    if (easeSpan(ws) case final s?)
      for (final at in keysAt(ws, s).entries) (s.layer.id, at.key, at.value),
  for (final k in ws.keys)
    if (ws.layers.where((l) => l.id == k.layer).firstOrNull case final l?)
      for (final at in keysAt(ws, _spanOfKey(l, k.frame)).entries)
        (l.id, at.key, at.value),
];

// The span a picked keyframe belongs to, using the same last-keyframe fallback as easeSpan.
EaseSpan _spanOfKey(Layer l, int frame) {
  final keys = [...l.keys]..sort();
  final next = keys.where((f) => f > frame).firstOrNull,
      prev = keys.where((f) => f < frame).lastOrNull;
  return next != null
      ? (layer: l, from: frame, to: next, picked: frame)
      : (layer: l, from: prev ?? frame, to: frame, picked: frame);
}

class EaseWriter {
  EaseWriter({
    required this.alive,
    required this.rebuild,
    required this.showTrouble,
  });

  /// Whether the panel is still on screen, the panel's setState, and how it shows (or clears, with null) why a write failed.
  final bool Function() alive;
  final void Function(VoidCallback change) rebuild;
  final void Function(String? why) showTrouble;

  // While the pointer is down each new ease is a step of the workspace's LiveEdit, so the canvas and the bars follow
  // it, and the whole drag is one undo step.
  bool down = false;
  Ease? pending;

  // The ease sent to the document and not yet confirmed. It is shown meanwhile instead of the old one.
  Ease? told;

  // The easing before a preview started. The preview runs in an open undo step and is kept only if the tile is dropped there.
  Ease? base;

  // Hears why a write failed, or null when it was kept.
  void _heard(String? why) => alive() ? showTrouble(why) : null;

  // Sends the newest ease while the pointer is down.
  void live(WorkspaceController ws, Ease e) {
    final all = easeStretches(ws);
    if (all.isEmpty) return;
    liveEase(ws, e, all);
  }

  // Abandons a preview or a drag: the undo step it opened is removed whole.
  void giveUp(WorkspaceController ws) {
    ws.live.cancel();
    if (base != null && alive()) rebuild(() => base = null);
    base = null;
  }

  void settle(WorkspaceController ws, EaseSpan? span) {
    final e = pending;
    pending = null;
    if (e == null && base != null) {
      // A tile was previewed and released. A drop on the graph or the flow is handled in this same event.
      scheduleMicrotask(() => pending == null && !down ? giveUp(ws) : null);
      return;
    }
    base = null;
    if (e == null || span == null) return;
    told = e;
    final to = said(e), open = ws.live.isOpen;
    final all = easeStretches(ws);
    // Segments that already have this easing are skipped, so numbers with no field here are not overwritten.
    // If the drag already sent the ease, it is sent once more on release and the undo step is closed.
    final toTell = [
      for (final (t, name, at) in all)
        if (open || said(heard(layerEasingAt(ws, t, name, at))) != to)
          (t, name, at),
    ];
    if (!open && toTell.isEmpty) {
      return showTrouble(
        all.isEmpty ? 'No key where the stretch begins' : null,
      );
    }
    settleEase(ws, to, toTell, _heard);
  }

  // Applies the curve after every keyframe of each picked keyframe's layer, for every property keyed there, as one undo step.
  void onEveryKey(WorkspaceController ws, Ease e) {
    final layers = ws.keys.isNotEmpty
        ? {for (final k in ws.keys) k.layer}
        // Nothing picked: the layer of the segment the playhead is in.
        : {if (easeSpan(ws) case final s?) s.layer.id};
    final stretches = [
      for (final l in ws.layers.where((l) => layers.contains(l.id)))
        for (final f in l.keys)
          for (final at in keysAt(ws, (
            layer: l,
            from: f,
            to: f,
            picked: f,
          )).entries)
            (l.id, at.key, at.value),
    ];
    everyKeyEase(ws, e, stretches, _heard);
  }
}
