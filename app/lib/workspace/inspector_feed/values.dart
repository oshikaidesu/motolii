// Values as the inspector shows them, read from the engine at the time of the frame on screen,
// and the user's changes to them (numbers, words, choices, switches) written back to the document.
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The layer being dragged in the inspector, or null.
/// The drag starts once, updates at every step and ends when the user releases.
int? _dragged;

/// Converts a document value to the number shown in the inspector (see Motolii.reading).
double shownNumber(Motolii m, int t, String n, double v) {
  final (k, f) = m.reading(t, n);
  return v * k + f;
}

/// Converts a number shown in the inspector back to the document's value.
double _unshown(Motolii m, int t, String n, double x) {
  final (k, f) = m.reading(t, n);
  return (x - f) / k;
}

/// Maps an inspector id and shown number to the document's value name and value, or null when the id has no document value.
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
      _unshown(m, t, n, x) -
          (seen.$1 - (m.value(t, n, drawnTime(ws)) ?? seen.$1)),
    );
  }
  // A value on the engine's own cards: the value of that name in the document's units.
  if (id.startsWith('v_')) return (n, _unshown(m, t, n, x));
  return null;
}

/// The time of the frame on the canvas.
/// The engine records what is read at that time while drawing, so the value is available
/// without waiting for the engine to be told a time the playhead has just moved to.
double drawnTime(WorkspaceController ws) =>
    ws.inside?.now ?? ws.frame / WorkspaceController.fps;

/// Only the position, scale and rotation of a layer, as the canvas readout shows them.
/// [layerTransform] reads all of the cards' numbers instead.
Map<String, double> layerPlacement(WorkspaceController ws, String id) {
  final m = ws.inside, t = int.tryParse(id);
  if (m == null || t == null) return const {};
  final at = drawnTime(ws);
  double r1(double x) => (x * 10).roundToDouble() / 10 + 0;
  return {
    for (final n in const ['x', 'y', 'scale_y', 'rotate'])
      n: r1(
        shownNumber(
          m,
          t,
          n,
          (n == 'x' || n == 'y' ? m.shows(t, n, at)?.$1 : null) ??
              m.value(t, n, at) ??
              (n == 'scale_y' ? 1 : 0),
        ),
      ),
  };
}

/// The selected layer's transform as the stage draws it at this frame, in the Inspector's ids.
Map<String, double> layerTransform(WorkspaceController ws, String? id) {
  if (ws.inside case final m?) {
    // The document's own values, as the inspector counts them.
    final t = int.tryParse(id ?? '');
    if (id == null) {
      // With nothing selected these are the stage's own cards, layer 0.
      final at = drawnTime(ws);
      return {
        for (final (_, names) in m.cards(0))
          for (final n in names) 'v_$n': _onCard(ws, m, 0, n, at),
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
        for (final n in names) 'v_$n': _onCard(ws, m, t, n, at),
    };
  }
  return const {};
}

/// Writes values changed in the inspector. The engine has one form of change, a drag: drag_start, then drag_update with the numbers.
/// While the user is dragging ([live]) the value is only displayed. On release it becomes the document's, by the document's rules.
void writeNumbers(
  WorkspaceController ws,
  String? id,
  Map<String, double> changed, {
  required bool live,
}) {
  // With nothing selected the target is the stage's own layer 0.
  final m = ws.inside!, t = id == null ? 0 : int.tryParse(id);
  // A word chosen on one of the engine's own cards is written as that word, in one undo step.
  final said = {
    for (final e in changed.entries)
      if (t != null &&
          e.key.startsWith('v_') &&
          m.words(t, e.key.substring(2)).isNotEmpty)
        e.key: e.value,
  };
  if (said.isNotEmpty) {
    if (live) return;
    // One undo step, without waiting.
    m.later('together', number: 1);
    for (final e in said.entries) {
      final ways = m.words(t!, e.key.substring(2));
      for (final o in [t, ..._withIt(ws, t)]) {
        m.later(
          'say',
          layer: o,
          name: e.key.substring(2),
          word: ways[e.value.round().clamp(0, ways.length - 1)],
        );
      }
    }
    ws.after(m.later('together'), (done, why) => _told(ws, done ? null : why));
    changed = {
      for (final e in changed.entries)
        if (!said.containsKey(e.key)) e.key: e.value,
    };
    if (changed.isEmpty) return;
  }
  if (t == null) return;
  if (changed['v_speed'] case final speed? when t > 0) {
    // Speed stretches the layer in time around the hold point, like Time Stretch in After Effects. It applies on release, not during the drag.
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
        (done, why) => done ? ws.reread() : _told(ws, why),
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
    if (why != null) _told(ws, why);
  } else {
    final also = _withIt(ws, t);
    if (also.isNotEmpty) m.later('together', number: 1);
    var kept = m.later('drag_end', number: 1);
    for (final o in also) {
      // As in After Effects and Figma, a value changed with several layers selected changes on every selected layer that has it.
      // A dragged number moves by the same amount, and a typed number is set to the typed value.
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
    // The user has released, so the app does not wait for the step to finish.
    ws.after(kept, (done, no) => _told(ws, why ?? (done ? null : no)));
  }
}

/// The values as they were when the drag started.
final _found = <String, double>{};

/// The other layers selected together with [t].
List<int> _withIt(WorkspaceController ws, int t) => ws.many.contains('$t')
    ? [
        for (final id in ws.many)
          if (int.tryParse(id) case final o? when o != t) o,
      ]
    : const [];

/// The selected layer's words in the inspector's ids, such as a text's content or how it blends with what is behind.
Map<String, String> layerWords(WorkspaceController ws, String? id) {
  // With nothing selected these are the stage's own cards.
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id);
  if (m == null || t == null) return const {};
  return {
    ..._cardColors(m, t, drawnTime(ws)),
    // Which light it is (sun, point, spot). The Light card draws it that way.
    if (m.word(t, 'kind') == 'light') 'light': m.word(t, 'file'),
    // Letters the font lacks, which are drawn in another font. Shown under the text.
    if (m.word(t, 'kind') == 'text') 'lacks': _lacks(m, t),
    for (final (_, names) in m.cards(t))
      for (final n in names)
        if (m.shown(n)?.look == 'thing')
          // Another layer, by its name.
          'v_$n':
              otherLayers(ws, t).entries
                  .where((e) => e.value == (m.value(t, n, 0) ?? 0))
                  .firstOrNull
                  ?.key ??
              'None'
        else if (m.words(t, n).isNotEmpty)
          // One of its words. If none is set, the first.
          'v_$n': m.word(t, n).isEmpty ? m.words(t, n).first : m.word(t, n),
  };
}

/// The message shown under a text when its font lacks some letters, or '' when nothing is missing.
/// It names the missing letters and the font used instead, so the user sees a reason rather than empty boxes.
String _lacks(Motolii m, int t) {
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

/// How the inspector is displayed, such as its folds and whether an effect's Advanced section is open.
/// This is part of the app's view, not the document.
Map<String, bool> layerFlags(WorkspaceController ws, String? id) => {
  for (final e in ws.view.entries)
    if (e.key.startsWith('inspector.') && e.value is bool)
      e.key.substring(10): e.value as bool,
};

bool writeFlags(WorkspaceController ws, String? id, Map<String, bool> changed) {
  // The suffixes mean: .past is a card allowed past its ends (PastRange), and .code is a script's code open under its parameters (effect_code.dart).
  bool looked(String k) =>
      k.endsWith('.open') ||
      k.endsWith('.adv') ||
      k.endsWith('.code') ||
      k.endsWith('.past') ||
      k.startsWith('fold.');
  for (final e in changed.entries) {
    if (looked(e.key)) ws.view['inspector.${e.key}'] = e.value;
  }
  final other = changed.keys.where((k) => !looked(k)).firstOrNull;
  if (other == null) return true;
  // The .on flag is an effect switched off, which the document keeps as bypass.
  _told(
    ws,
    'the document has no ${other.endsWith('.on') ? 'bypass' : other}: ',
  );
  return false;
}

/// Writes words chosen in the inspector to the document. Returns false when no layer is selected.
bool writeWords(
  WorkspaceController ws,
  String? id,
  Map<String, String> changed,
) {
  final m = ws.inside!, t = int.tryParse(id ?? '');
  if (t == null) return false;
  // One undo step, requested without waiting: the app carries on while the engine works, then reads the result.
  // If the engine refuses, the words return to the document's own when it is read again.
  m.later('together', number: 1);
  for (final e in changed.entries) {
    if (!e.key.startsWith('v_')) continue;
    final n = e.key.substring(2);
    m.shown(n)?.look == 'thing'
        // Another layer, chosen by name: the value follows that layer.
        ? m.later(
            'set',
            layer: t,
            name: n,
            number: (otherLayers(ws, t)[e.value] ?? 0).toDouble(),
          )
        // A card's value of that name.
        : m.later('say', layer: t, name: n, word: e.value);
  }
  ws.after(m.later('together'), (done, no) => _told(ws, done ? null : no));
  return true;
}

/// The other layers, keyed by their row number on the timeline and the name shown there.
Map<String, int> otherLayers(WorkspaceController ws, int t) {
  // Layers only, not relations or behaviours.
  final rows = ws.layers.where(
    (l) =>
        l.id != '$t' && ws.inside?.word(int.parse(l.id), 'kind') != 'behaviour',
  );
  // Like After Effects' parent list: the row number on the timeline, then the name.
  return {
    for (final l in rows)
      '${ws.layers.indexOf(l) + 1}. ${l.name}': int.parse(l.id),
  };
}

/// Shows a change the document refused in the top bar, using the engine's reason (its first clause).
/// The reason must be read right when the change is refused, because every engine call forgets the last one.
/// The next accepted change clears the message.
void _told(WorkspaceController ws, String? why) {
  if (why != null && why.isNotEmpty) {
    ws.notice = 'Not taken: ${why.split(':').first}';
  } else if (why == null && (ws.notice?.startsWith('Not taken') ?? false)) {
    ws.notice = null;
  }
}

/// The text of each value on the engine's own cards, as the inspector writes it. A value with no text shows a dash.
Map<String, String> _cardColors(Motolii m, int t, [double at = 0]) => {
  // First an effect's colour: three numbers shown as one colour (see _makeCards), read at the time drawn like the card's numbers.
  for (final (_, names) in m.cards(t))
    for (final n in names)
      if (n.endsWith('_x') &&
          names.contains('${n.substring(0, n.length - 2)}_y') &&
          names.contains('${n.substring(0, n.length - 2)}_z') &&
          (m.shown(n)?.label ?? '').endsWith(' r'))
        'v_${n.substring(0, n.length - 2)}':
            '#${[for (final c in 'xyz'.split('')) ((m.value(t, '${n.substring(0, n.length - 2)}_$c', at) ?? 0).clamp(0, 1) * 255).round().toRadixString(16).padLeft(2, '0')].join().toUpperCase()}',
  for (final (_, names) in m.cards(t))
    for (final n in names)
      if (m.words(t, n).isEmpty && m.range(t, n) == null)
        // Words are shown as they are so the user can type over them. A file shows its name. Numbers, one per copy, are shown as they are.
        // Anything else is a colour or a list of colours in order, or a word such as a material name, shown as it is (Glass).
        // A gradient stop is shown by its colour only, without its position.
        'v_$n': m.shown(n)?.look == 'words'
            ? m.word(t, n)
            : m.word(t, n).isEmpty || m.word(t, n) == 'none'
            ? '—'
            : m.shown(n)?.look == 'file'
            ? m.word(t, n).split('/').last
            : m.shown(n)?.look == 'numbers'
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

/// A value on the engine's own cards as the inspector counts it.
/// Another layer is its position in the list (None first), a number is in the card's units,
/// and a word is its position among the words it may take. This holds for the stage and for layers alike.
double _onCard(WorkspaceController ws, Motolii m, int t, String n, double at) {
  // These values are read from the snapshot as the stage shows them (see snapshot.h).
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
    // Use the displayed value, which includes a drag in progress or a relation moving it, as After Effects shows a value driven by an expression.
    return shownNumber(m, t, n, seen.$1);
  }
  return m.shown(n)?.look == 'thing'
      ? (otherLayers(
                  ws,
                  t,
                ).values.toList().indexOf((m.value(t, n, 0) ?? 0).round()) +
                1)
            .toDouble()
      : m.words(t, n).isEmpty
      ? shownNumber(m, t, n, m.value(t, n, at) ?? 0)
      : math.max(0, m.words(t, n).indexOf(m.word(t, n))).toDouble();
}
