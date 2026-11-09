// values.dart: a value as the inspector shows it, read from the inside at the picture's moment, and a hand's change of it told back (numbers, words, choices, switches).
part of '../workspace.dart';

int? _dragged; // (the thing a hand on the inspector holds now: held once, carried at every step, let go when it lets go)

/// A value as a hand reads it, and back (Motolii.reading).
double _shown(Motolii m, int t, String n, double v) {
  final (k, f) = m.reading(t, n);
  return v * k + f;
}

double _unshown(Motolii m, int t, String n, double x) {
  final (k, f) = m.reading(t, n);
  return (x - f) / k;
}

(String, double)? _asDocument(Ws ws, String id, double x) {
  if (id.startsWith('v_') && ws.inside!.shown(id.substring(2))?.look == 'thing') {
    // (another thing: None, then the others by their place)
    final others = _others(ws, int.tryParse(ws.selected ?? '') ?? 0).values.toList(), i = x.round();
    return (id.substring(2), i >= 1 && i <= others.length ? others[i - 1].toDouble() : 0);
  }
  final m = ws.inside!, t = int.tryParse(ws.selected ?? '') ?? 0, n = id.substring(2);
  final seen = id.startsWith('v_') && (n == 'x' || n == 'y') ? m.shows(t, n, _drawn(ws)) : null;
  if (seen != null && seen.$2) {
    return (
      n,
      _unshown(m, t, n, x) - (seen.$1 - (m.value(t, n, _drawn(ws)) ?? seen.$1)),
    ); // (shown where it shows: its own value moved as far as the hand moved that)
  }
  if (id.startsWith('v_')) return (n, _unshown(m, t, n, x)); // (a card of the inside's own: the value of that name, in the document's own units)
  return null;
}

// (the moment of the picture on the stage, at a frame: what is read there was set down by the inside as it drew it,
//  not waited for while it tells the stage a moment the playhead has just been put at)
double _drawn(Ws ws) => ws.inside?.now ?? ws.frame / Ws.fps;

/// The selected layer's transform as the stage draws it at this frame, in the Inspector's ids.
Map<String, double> wsTransform(Ws ws, String? id) {
  if (ws.inside case final m?) {
    // (the document's own values, as the inspector counts them; nothing picked: the stage's own, thing 0)
    final t = id == null ? 0 : int.tryParse(id);
    if (t == null) return const {};
    final at = _drawn(ws);
    return {
      for (final (_, names) in m.cards(t))
        for (final n in names) 'v_$n': _onCard(ws, m, t, n, at),
    };
  }
  return const {};
}

/// Joined: what was changed in the inspector is a thing held and its numbers carried (the inside's one form of a
/// drag): while a hand is on it, it only shows; when the hand lets go it is the document's, by the document's rules.
void _write(Ws ws, String? id, Map<String, double> changed, {required bool live}) {
  final m = ws.inside!, t = id == null ? 0 : int.tryParse(id); // (nothing picked: the stage's own, thing 0)
  // (a word on a card of the inside's own, picked: the word in that place, said; one step)
  final said = {
    for (final e in changed.entries)
      if (t != null && e.key.startsWith('v_') && m.words(t, e.key.substring(2)).isNotEmpty) e.key: e.value,
  };
  if (said.isNotEmpty) {
    if (live) return;
    m.later('together', number: 1); // (one step, without waiting)
    for (final e in said.entries) {
      final ways = m.words(t!, e.key.substring(2));
      m.later('say', layer: t, name: e.key.substring(2), word: ways[e.value.round().clamp(0, ways.length - 1)]);
    }
    ws.after(m.later('together'));
    changed = {
      for (final e in changed.entries)
        if (!said.containsKey(e.key)) e.key: e.value,
    };
    if (changed.isEmpty) return;
  }
  if (t == null) return;
  if (changed['v_speed'] case final speed? when t > 0) {
    // (its speed: the thing stretched in time round where it is held, After Effects' Time Stretch; let go, not while dragged)
    changed = {...changed}..remove('v_speed');
    if (!live) {
      ws.after(
        m.later('time_stretch', layer: t, number: speed, word: '${m.word(t, 'speed_hold').isEmpty ? 'start' : m.word(t, 'speed_hold')} ${ws.frame / Ws.fps}'),
        (done, _) => done ? ws.reread() : null,
      );
    }
    if (changed.isEmpty) return;
  }
  final dragged = _dragged == t;
  if (!dragged) m.take(t); // (held once a hand: each step after only carries)
  _dragged = live ? t : null;
  for (final e in changed.entries) {
    final to = _asDocument(ws, e.key, e.value);
    if (to != null) m.dragUpdate(to.$1, to.$2);
  }
  if (live) {
    if (ws.playing) ws.playing = false; // (a hand on a value stops the play: what is changed is changed at one moment)
  } else {
    ws.after(m.later('drag_end', number: 1)); // (the hand let go: the window does not wait for the step)
  }
}

/// Joined: the picked thing's words in the inspector's ids (a text's content; how it lies on what is behind), and a change of them told to the document.
Map<String, String> _words(Ws ws, String? id) {
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id); // (nothing picked: the stage's own cards)
  if (m == null || t == null) return const {};
  return {
    ..._cardColors(m, t, _drawn(ws)),
    for (final (_, names) in m.cards(t))
      for (final n in names)
        if (m.shown(n)?.look == 'thing')
          'v_$n':
              _others(ws, t).entries.where((e) => e.value == (m.value(t, n, 0) ?? 0)).firstOrNull?.key ??
              'None' // (another thing, by its name)
        else if (m.words(t, n).isNotEmpty)
          'v_$n': m.word(t, n).isEmpty ? m.words(t, n).first : m.word(t, n), // (one of its words; none said: the first, as it comes)
  };
}

/// What a card's value may be, for a hand-drawn card's chooser: its words, or another thing by name (None first).
Map<String, List<String>> _choices(Ws ws, String? id) {
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id);
  if (m == null || t == null) return const {};
  return {
    for (final (_, names) in m.cards(t))
      for (final n in names)
        if (m.shown(n)?.look == 'thing') 'v_$n': ['None', ..._others(ws, t).keys] else if (m.words(t, n).isNotEmpty) 'v_$n': m.words(t, n),
  };
}

/// How the inspector is looked at (its folds, an effect's Advanced shown): the window's view, not the document's.
Map<String, bool> _flags(Ws ws) => {
  for (final e in ws.view.entries)
    if (e.key.startsWith('inspector.') && e.value is bool) e.key.substring(10): e.value as bool,
};

bool _flag(Ws ws, Map<String, bool> changed) {
  bool looked(String k) =>
      k.endsWith('.open') ||
      k.endsWith('.adv') ||
      k.endsWith('.past') ||
      k.startsWith('fold.'); // (.past: a card let past its ends, PastRange)
  for (final e in changed.entries) {
    if (looked(e.key)) ws.view['inspector.${e.key}'] = e.value;
  }
  return changed.keys.every(looked);
}

bool _say(Ws ws, String? id, Map<String, String> changed) {
  final m = ws.inside!, t = int.tryParse(id ?? '');
  if (t == null) return false;
  // (asked without waiting, one step: the window goes on while the inside works it, then reads it again; refused, the
  //  words go back to the document's own when it is read)
  m.later('together', number: 1);
  for (final e in changed.entries) {
    if (!e.key.startsWith('v_')) continue;
    final n = e.key.substring(2);
    m.shown(n)?.look == 'thing'
        ? m.later('set', layer: t, name: n, number: (_others(ws, t)[e.value] ?? 0).toDouble()) // (another thing, told by its name: it goes with that one)
        : m.later('say', layer: t, name: n, word: e.value); // (a card's value of that name)
  }
  ws.after(m.later('together'));
  return true;
}

/// Joined: the other things by their row's number on the timeline and the name it shows there.
Map<String, int> _others(Ws ws, int t) {
  final rows = ws.layers.where((l) => l.id != '$t' && ws.inside?.word(int.parse(l.id), 'kind') != 'behaviour'); // (things, not relations or behaviours)
  return {
    for (final l in rows) '${ws.layers.indexOf(l) + 1}. ${l.name}': int.parse(l.id),
  }; // (as After Effects' parent list: the row's number on the timeline, then the name)
}

