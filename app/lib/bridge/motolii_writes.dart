// motolii_writes.dart: changes told to the inside (docs/app/BRIDGE.md W): thrown, not waited for, or done in one call; the hand's carrying, keys, ways, undo.
part of 'motolii.dart';

extension MotoliiWrites on Motolii {
  /// The things the window shows the moving values of (Anthem's subscription): their values are in the moment's picture
  /// from the next (later: watch). Told again only when they change.
  void subscribe(Set<int> layers) {
    if (setEquals(layers, _watched)) return;
    _watched = layers;
    later('watch', word: layers.join(' '));
  }

  /// The stage as it is now, as a picture (.png): for a hand that sees only pictures.
  bool still(String png) => _with([png], (s) => _still(_m, s[0])) != 0;

  /// The document's own picture (at its poster_at, else now), small, kept in the document with its size and length,
  /// written to [png] too.
  bool poster(String png) => _with([png], (s) => _b.motolii_poster(_m, s[0])) != 0;

  /// The document and the files its things are made of copied into [folder] (the document as [name].motolii), to be
  /// taken elsewhere whole: how many files (-1: not).
  int pack(String folder, String name) => _with([folder, name], (s) => _b.motolii_pack(_m, s[0], s[1]));

  bool play(bool on) => _play(_m, on ? 1 : 0) != 0;

  bool at(double seconds) => _at(_m, seconds) != 0;

  /// A sum typed in a number field worked out (+ - * / and brackets, by SQLite as the ways are): null, it is not one.
  double? workOut(String sum) => _with([sum], (s) {
    final out = malloc<Double>();
    try {
      return _workOut(_m, s[0], out) != 0 ? out.value : null;
    } finally {
      malloc.free(out);
    }
  });

  /// A new thing (film, picture, text, solid) from a file (a solid: a file, or ring, gem or cube): its number, 0 if it was not made.
  /// What a solid is made of is its `fill`: a colour, or `glass`.
  int add(String kind, String file) => _took(_with([kind, file], (s) => _add(_m, s[0], s[1])));

  bool remove(int layer) => _took(_remove(_m, layer) != 0);

  bool set(int layer, String name, double number) => _took(_with([name], (s) => _set(_m, layer, s[0], number)) != 0);

  /// A thing held by a hand, carried, and let go (motolii.h): the one form of everything a hand drags. [by] is
  /// 'place' (on the stage: how far the hand has gone, in points of the picture), 'bar', 'head' or 'tail' (its bar on
  /// the timeline: how many seconds), or a value's name (what the number is now). What is carried shows at once and
  /// is the document's only when it is let go and kept: one step.
  /// On: every value a hand changes or carries gets a key at that moment (the inspector's Animate all).
  void keying(bool on) => _keying(_m, on ? 1 : 0);

  /// Whether every change a hand makes is keyed now (Animate all).
  bool get keyingNow => _keying(_m, -1) != 0;

  /// A hand takes hold, without waiting (the window's way: refused, its let go says why).
  void take(int layer) => later('drag_start', layer: layer);

  bool dragUpdate(String by, double a, [double b = 0]) =>
      _with([by], (s) => _dragUpdate(_m, s[0], a, b)) != 0; // (sent, not waited for: what it carries shows in the moment's picture)

  /// A change asked without waiting for the inside's hand (say, set, let_go, undo, redo, together): queued in order behind
  /// every other, its ticket said at once ([answer] says when it is done).
  int later(String call, {int layer = 0, String name = '', String word = '', double number = 0}) =>
      _with([call, name, word], (s) => _later(_m, s[0], layer, s[1], s[2], number));
}
