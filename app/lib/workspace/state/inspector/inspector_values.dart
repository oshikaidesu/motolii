// Inspector values: read from the engine at the drawn frame, written back on user changes.
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/document/document_reads.dart'
    show documentNow;
import 'package:motolii/workspace/state/inspector/inspector_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

int? _dragged;

/// The time of the frame on the canvas (available without waiting for the playhead to sync).
double drawnTime(WorkspaceController ws) =>
    documentNow(ws) ?? ws.frame / WorkspaceController.fps;

/// Document value → inspector display number (see Motolii.reading).
double shownNumber(WorkspaceController ws, int t, String n, double v) {
  final (k, f) = ws.inside!.reading(t, n);
  return v * k + f;
}

/// Inspector display number → document value.
double _unshown(WorkspaceController ws, int t, String n, double x) {
  final (k, f) = ws.inside!.reading(t, n);
  return (x - f) / k;
}

/// Inspector id + shown number → document (name, value), or null.
(String, double)? _asDocument(
  WorkspaceController ws,
  int t,
  String id,
  double x,
) {
  if (id.startsWith('v_') &&
      ws.inside!.shown(id.substring(2))?.look == 'thing') {
    // Another layer: None first, then the others by position.
    final others = otherLayers(ws, t).values.toList(), i = x.round();
    return (
      id.substring(2),
      i >= 1 && i <= others.length ? others[i - 1].toDouble() : 0,
    );
  }
  final m = ws.inside!, n = id.substring(2);
  final seen = id.startsWith('v_') && (n == 'x' || n == 'y')
      ? m.shows(t, n, drawnTime(ws))
      : null;
  if (seen != null && seen.$2) {
    // The value is displayed somewhere other than where it is stored, so the stored value moves by as much as the user moved the display.
    return (
      n,
      _unshown(ws, t, n, x) -
          (seen.$1 - (m.value(t, n, drawnTime(ws)) ?? seen.$1)),
    );
  }
  // A value on the engine's own cards: the value of that name in the document's units.
  if (id.startsWith('v_')) return (n, _unshown(ws, t, n, x));
  return null;
}

/// Position, scale and rotation only. [layerTransform] reads all cards.
Map<String, double> layerPlacement(WorkspaceController ws, int id) {
  final m = ws.inside, t = id;
  if (m == null) return const {};
  final at = drawnTime(ws);
  double r1(double x) => (x * 10).roundToDouble() / 10 + 0;
  return {
    for (final n in const ['x', 'y', 'scale_y', 'rotate'])
      n: r1(
        shownNumber(
          ws,
          t,
          n,
          (n == 'x' || n == 'y' ? m.shows(t, n, at)?.$1 : null) ??
              m.value(t, n, at) ??
              (n == 'scale_y' ? 1 : 0),
        ),
      ),
  };
}

/// All card values for the selected layer, in the inspector's ids.
Map<String, double> layerTransform(WorkspaceController ws, int? id) {
  if (ws.inside case final m?) {
    final t = id;
    if (id == null) {
      // No selection → stage values (layer 0).
      final at = drawnTime(ws);
      return {
        for (final (_, names) in m.cards(0))
          for (final n in names) 'v_$n': _onCard(ws, 0, n, at),
      };
    }
    if (t == null) return const {};
    final at = drawnTime(ws);
    // Adding 0 turns -0.0 into 0.0.
    double r1(double x) => (x * 10).roundToDouble() / 10 + 0;
    return {
      // The depth in canvas points. A flat layer shows Flat.
      'depth': r1(m.bounds(t)?[7] ?? 0),
      for (final (_, names) in m.cards(t))
        for (final n in names) 'v_$n': _onCard(ws, t, n, at),
    };
  }
  return const {};
}

/// Writes values changed in the inspector. The engine has one form of change, a drag: drag_start, then drag_update with the numbers.
/// While the user is dragging ([live]) the value is only displayed. On release it becomes the document's, by the document's rules.
void writeNumbers(
  WorkspaceController ws,
  int? id,
  Map<String, double> changed, {
  required bool live,
}) {
  final m = ws.inside!, t = id ?? 0;
  // A word chosen on one of the engine's own cards is written as that word.
  final said = {
    for (final e in changed.entries)
      if (e.key.startsWith('v_') && m.words(t, e.key.substring(2)).isNotEmpty)
        e.key: e.value,
  };
  if (said.isNotEmpty) {
    if (live) return;
    // One undo step, without waiting.
    m.later('together', number: 1);
    for (final e in said.entries) {
      final ways = m.words(t, e.key.substring(2));
      for (final o in [t, ..._withIt(ws, t)]) {
        m.later(
          'say',
          layer: o,
          name: e.key.substring(2),
          word: ways[e.value.round().clamp(0, ways.length - 1)],
        );
      }
    }
    ws.after(
      m.later('together'),
      (done, why) => tellRefusal(ws, done ? null : why),
    );
    changed = {
      for (final e in changed.entries)
        if (!said.containsKey(e.key)) e.key: e.value,
    };
    if (changed.isEmpty) return;
  }
  if (changed['v_speed'] case final speed? when t > 0) {
    // Speed stretches the layer in time around the hold point. Applies on release only.
    changed = {...changed}..remove('v_speed');
    if (!live) {
      ws.after(
        m.later(
          'time_stretch',
          layer: t,
          number: speed,
          word:
              '${m.word(t, 'speed_hold').isEmpty ? 'start' : m.word(t, 'speed_hold')} ${ws.frame / WorkspaceController.fps}',
        ),
        (done, why) => done ? ws.reread() : tellRefusal(ws, why),
      );
    }
    if (changed.isEmpty) return;
  }
  final now = ws.frame / WorkspaceController.fps, dragged = _dragged == t;
  if (!dragged) {
    // The drag starts once. Later steps only update it.
    m.take(t);
    _found.clear();
  }
  _dragged = live ? t : null;
  String? why;
  final carried = <String, double>{};
  for (final e in changed.entries) {
    final to = _asDocument(ws, t, e.key, e.value);
    if (to != null) _found[to.$1] ??= m.value(t, to.$1, now) ?? to.$2;
    if (to != null && !m.dragUpdate(to.$1, to.$2)) why ??= m.error;
    if (to != null) carried[to.$1] = to.$2;
    // A property the document has no value for reports that, instead of silently keeping the number.
    if (to == null) why ??= 'the document has no ${e.key}: ';
  }
  if (live) {
    // Changing a value stops playback, so the change applies at one time.
    if (ws.playing) ws.playing = false;
    if (why != null) tellRefusal(ws, why);
  } else {
    final also = _withIt(ws, t);
    if (also.isNotEmpty) m.later('together', number: 1);
    var kept = m.later('drag_end', number: 1);
    for (final o in also) {
      // Multi-select: a dragged number moves by the same delta, a typed number sets the absolute value.
      m.take(o);
      for (final e in carried.entries) {
        m.dragUpdate(
          e.key,
          dragged
              ? (m.value(o, e.key, now) ?? e.value) + e.value - _found[e.key]!
              : e.value,
        );
      }
      m.later('drag_end', number: 1);
    }
    if (also.isNotEmpty) kept = m.later('together');
    // Released: fire-and-forget.
    ws.after(kept, (done, no) => tellRefusal(ws, why ?? (done ? null : no)));
  }
}

/// Values at drag start, for computing deltas.
final _found = <String, double>{};

/// The other layers in the multi-selection besides [t].
List<int> _withIt(WorkspaceController ws, int t) => ws.many.contains(t)
    ? [
        for (final id in ws.many)
          if (id != t) id,
      ]
    : const [];

/// Writes words to the document. While [live], shown immediately; on release, committed as one undo step.
bool writeWords(
  WorkspaceController ws,
  int? id,
  Map<String, String> changed, {
  bool live = false,
}) {
  final t = id;
  if (t == null) return false;
  Iterable<int> say(Motolii m) {
    for (final e in changed.entries) {
      if (e.key.startsWith('v_')) {
        m.later('say', layer: t, name: e.key.substring(2), word: e.value);
      }
    }
    return [t];
  }

  live ? ws.live.move(say) : ws.live.done(say, (why) => tellRefusal(ws, why));
  return true;
}

/// Shows a refusal in the top bar. Must be read immediately: each engine call forgets the last error.
void tellRefusal(WorkspaceController ws, String? why) {
  if (why != null && why.isNotEmpty) {
    ws.notice = 'Not taken: ${why.split(':').first}';
  } else if (why == null && (ws.notice?.startsWith('Not taken') ?? false)) {
    ws.notice = null;
  }
}

/// The selected layer's word values in the inspector's ids.
Map<String, String> inspectorWords(WorkspaceController ws, int? id) {
  final m = ws.inside, t = id ?? 0;
  if (m == null) return const {};
  return {
    ..._cardColors(ws, t, drawnTime(ws)),
    // Which light it is (sun, point, spot). The Light card draws it that way.
    if (m.word(t, 'kind') == 'light') 'light': m.word(t, 'file'),
    // Letters the font lacks, which are drawn in another font. Shown under the text.
    if (m.word(t, 'kind') == 'text') 'lacks': _lacks(ws, t),
    // The shape type (rect, polygon, star, …) so the Paths preview matches the engine's rendering.
    'shape': m.word(t, 'shape'),
  };
}

/// Missing-glyph message for a text layer, or ''.
String _lacks(WorkspaceController ws, int t) {
  final m = ws.inside!;
  final file = m.whole(m.word(t, 'file')), words = m.word(t, 'text');
  // With no text, the font's own name is checked, as the engine sets it.
  final (lacks, instead) = m.fontLacks(
    file,
    words.isEmpty
        ? file.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '')
        : words,
  );
  if (lacks.isEmpty) return '';
  return instead.isEmpty
      ? 'Not in this font: $lacks. No font here has them all: they are left out'
      : 'Not in this font: $lacks. Shown in ${instead.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '')}';
}

/// Card values formatted for display. A value with no text shows a dash.
Map<String, String> _cardColors(
  WorkspaceController ws,
  int t, [
  double at = 0,
]) {
  final m = ws.inside!;
  return {
    // Effect colour: three separate xyz numbers shown as one #RRGGBB.
    for (final (_, names) in layerCardsOf(ws, t))
      for (final n in names)
        if (colourBaseOf(ws, n, names) case final base?)
          'v_$base':
              '#${[for (final c in 'xyz'.split('')) ((m.value(t, '${base}_$c', at) ?? 0).clamp(0, 1) * 255).round().toRadixString(16).padLeft(2, '0')].join().toUpperCase()}',
    for (final (_, names) in layerCardsOf(ws, t))
      for (final n in names)
        if (m.words(t, n).isEmpty && m.range(t, n) == null)
          // Gradient stops shown by colour only (without position).
          'v_$n': shownFactOf(ws, n)?.look == 'words'
              ? m.word(t, n)
              : m.word(t, n).isEmpty || m.word(t, n) == 'none'
              ? '—'
              : shownFactOf(ws, n)?.look == 'file'
              ? m.word(t, n).split('/').last
              : shownFactOf(ws, n)?.look == 'numbers'
              ? m.word(t, n)
              : m
                    .word(t, n)
                    .split(' ')
                    .where((c) => c.isNotEmpty)
                    .map((w) => w.split('@').first)
                    .map(
                      (c) =>
                          int.tryParse(c, radix: 16) != null &&
                              (c.length == 6 || c.length == 8)
                          ? '#${c.toUpperCase()}'
                          : c.replaceRange(0, 1, c[0].toUpperCase()),
                    )
                    .join(' '),
  };
}

/// A card value in inspector units: layer refs → list position, words → index, numbers → display scale.
double _onCard(WorkspaceController ws, int t, String n, double at) {
  final m = ws.inside!;
  // Read from the stage snapshot so a drag-in-progress is included.
  final seen =
      const {
        'x',
        'y',
        'z',
        'rotate',
        'scale_x',
        'scale_y',
        'opacity',
      }.contains(n)
      ? m.shows(t, n, at)
      : null;
  if (seen != null) {
    // Use the displayed value (includes drags and relations).
    return shownNumber(ws, t, n, seen.$1);
  }
  return shownFactOf(ws, n)?.look == 'thing'
      ? (otherLayers(
                  ws,
                  t,
                ).values.toList().indexOf((m.value(t, n, 0) ?? 0).round()) +
                1)
            .toDouble()
      : m.words(t, n).isEmpty
      ? shownNumber(ws, t, n, m.value(t, n, at) ?? 0)
      : math.max(0, m.words(t, n).indexOf(m.word(t, n))).toDouble();
}
