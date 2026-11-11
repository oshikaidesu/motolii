// The Ease tool's writing to the document. While the pointer is down each new ease is sent so the canvas and the bars follow it, one at a
// time (any between are skipped), and the whole drag is one undo step; on release it is sent once more and the step is closed.
// EaseToolState keeps what is on the screen; this keeps where the write has got to. It draws nothing.
import 'dart:async' show scheduleMicrotask;

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

// The segments of every picked keyframe, on any layer, one for each property keyed there.
// A last keyframe has no segment after it, so the segment ending at it is used.
List<(int, String, double)> easeStretches(WorkspaceController ws) => [
  if (ws.stretch case final s?)
    (int.parse(s.layer), s.name, s.at)
  else if (ws.keys.isEmpty) // Nothing picked: the segment the playhead is in.
    if (easeSpan(ws) case final s?)
      for (final at in keysAt(ws, s).entries)
        (int.parse(s.layer.id), at.key, at.value),
  for (final k in ws.keys)
    if (ws.layers.where((l) => l.id == k.layer).firstOrNull case final l?)
      for (final at in keysAt(ws, (
        layer: l,
        from: l.keys.any((f) => f > k.frame)
            ? k.frame
            : (l.keys
                      .where((f) => f < k.frame)
                      .fold<int?>(null, (a, f) => a == null || f > a ? f : a) ??
                  k.frame),
        to: k.frame,
        picked: k.frame,
      )).entries)
        (int.parse(l.id), at.key, at.value),
];

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

  // While the pointer is down, each new ease is sent to the document so the canvas and the bars follow it.
  // While one is in flight the next waits and any in between are skipped. The whole drag is one undo step.
  bool down = false, open = false, going = false;
  Ease? pending, waiting;

  // The ease sent to the document and not yet confirmed. It is shown meanwhile instead of the old one.
  Ease? told;

  // The easing before a preview started. The preview runs in an open undo step and is kept only if the tile is dropped there.
  Ease? base;

  // Closes the undo step opened for a write, and shows why it failed, if it did.
  void close(WorkspaceController ws, Motolii m) => ws.after(
    m.later('together'),
    (done, why) => alive() ? showTrouble(done ? null : why) : null,
  );

  // Sends the newest ease while the pointer is down. The first call opens the undo step.
  void live(WorkspaceController ws, Ease e) {
    final m = ws.inside!;
    if (going) {
      waiting = e;
      return;
    }
    final all = easeStretches(ws);
    if (all.isEmpty) return;
    if (!open) {
      m.later('together', number: 1);
      open = true;
    }
    going = true;
    var last = 0;
    define(m, said(e));
    for (final (t, name, at) in all) {
      last = m.later('easing', layer: t, name: name, number: at, word: said(e));
    }
    for (final t in {for (final (t, _, _) in all) t}) {
      last = m.later('show', layer: t);
    }
    ws.after(last, (_, _) {
      going = false;
      final next = waiting;
      waiting = null;
      if (next != null) live(ws, next);
    });
  }

  // Abandons a preview: the undo step it opened is removed whole.
  void giveUp(WorkspaceController ws) {
    waiting = null;
    if (!open) {
      base = null;
      return;
    }
    open = false;
    ws.after(
      ws.inside!.later('together', number: -1),
      (_, _) => alive() ? rebuild(() => base = null) : null,
    );
  }

  void define(Motolii m, String word) {
    for (final (name, goes) in easeDefines(word)) {
      m.later('define', name: name, word: goes);
    }
  }

  void settle(WorkspaceController ws, EaseSpan? span) {
    final e = pending;
    pending = null;
    waiting = null;
    if (e == null && base != null) {
      // A tile was previewed and released. A drop on the graph or the flow is handled in this same event.
      scheduleMicrotask(() => pending == null && !down ? giveUp(ws) : null);
      return;
    }
    base = null;
    if (e == null || span == null) return;
    told = e;
    final m = ws.inside!, to = said(e);
    final all = easeStretches(ws);
    // Segments that already have this easing are skipped, so numbers with no field here are not overwritten.
    // If the drag already sent the ease, it is sent once more on release and the undo step is closed.
    final toTell = [
      for (final (t, name, at) in all)
        if (open || said(heard(m.easingOf(t, name, at))) != to) (t, name, at),
    ];
    if (open) {
      open = false;
      define(m, to);
      for (final (t, name, at) in toTell) {
        m.later('easing', layer: t, name: name, number: at, word: to);
      }
      define(m, to);
      close(ws, m);
      return;
    }
    if (toTell.isEmpty) {
      return showTrouble(
        all.isEmpty ? 'No key where the stretch begins' : null,
      );
    }
    m.later('together', number: 1);
    define(m, to);
    for (final (t, name, at) in toTell) {
      m.later('easing', layer: t, name: name, number: at, word: to);
    }
    define(m, to);
    close(ws, m);
  }

  // Applies the curve after every keyframe of each picked keyframe's layer, for every property keyed there, as one undo step.
  void onEveryKey(WorkspaceController ws, Ease e) {
    final m = ws.inside!,
        layers = ws.keys.isNotEmpty
            ? {for (final k in ws.keys) k.layer}
            // Nothing picked: the layer of the segment the playhead is in.
            : {if (easeSpan(ws) case final s?) s.layer.id};
    m.later('together', number: 1);
    define(m, said(e));
    for (final l in ws.layers.where((l) => layers.contains(l.id))) {
      for (final f in l.keys) {
        for (final at in keysAt(ws, (
          layer: l,
          from: f,
          to: f,
          picked: f,
        )).entries) {
          m.later(
            'easing',
            layer: int.parse(l.id),
            name: at.key,
            number: at.value,
            word: said(e),
          );
        }
      }
    }
    close(ws, m);
  }
}
