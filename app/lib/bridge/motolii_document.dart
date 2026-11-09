// motolii_document.dart: the document's copy read (docs/app/BRIDGE.md D): its things, their values and keys, its cards, ways, marks, guides. Made by the inside when the document changes.
part of 'motolii.dart';

extension MotoliiDocument on Motolii {
  Map<String, dynamic> _of(int layer) => _layer[layer] ?? const {};

  /// A value said nowhere: as it comes, if the thing's kind has it (the inside's tables: its `doc_usual`, `doc_knows`).
  double? _usual(int layer, String name) {
    if (!_layer.containsKey(layer)) return null;
    final kind = layer == 0 ? 'stage' : word(layer, 'kind');
    final knows = _knows.putIfAbsent(kind, () => Motolii._spaced((_document['knows'] as Map<String, dynamic>?)?[kind]).toSet());
    return knows.contains(name) ? ((_document['usual'] as Map<String, dynamic>?)?[name] as num?)?.toDouble() : null;
  }

  double get seconds => (_document['seconds'] as num?)?.toDouble() ?? 0;

  /// The numbers of the things there are.
  List<int> get layers => [for (final t in (_document['layers'] as List<dynamic>?) ?? const []) t as int];

  /// A thing's word by name (kind, file, shape, blend, text, fill); '' if it has none.
  String word(int layer, String name) => ((_of(layer)['word'] as Map<String, dynamic>?)?[name] as String?) ?? '';

  /// How long a thing is on, in seconds; below 0: for good.
  double lasts(int layer) => (_of(layer)['lasts'] as num?)?.toDouble() ?? -1;

  /// Every moment a key of any of a thing's values stands at, each once, in time: a timeline bar's marks.
  List<double> layerKeyTimes(int layer) => Motolii._numbers(_of(layer)['keys']);

  /// The moments of a value's keys (none if the value stays): how many keys it has is their count.
  List<double> keyTimes(int layer, String name) => Motolii._numbers((_of(layer)['keyTimes'] as Map<String, dynamic>?)?[name]);

  /// What each of a value's keys holds, in the order of [keyMoments].
  List<double> keyValues(int layer, String name) => Motolii._numbers((_of(layer)['keyValues'] as Map<String, dynamic>?)?[name]);

  /// What the document's steps changed since last asked (asking forgets them): whether a thing came or went, and each
  /// value changed as (thing, name), from each step's own changeset.
  ({bool layers, Set<(int, String)> values}) changes() {
    final lines = ((_document['changes'] as String?) ?? '').split('\n');
    return (
      layers: lines.contains('layers'),
      values: {
        for (final l in lines)
          if (l.indexOf(' ') case final i when i > 0) (int.parse(l.substring(0, i)), l.substring(i + 1)),
      },
    );
  }

  int keyed(int layer, String name, double at) {
    final keys = keyTimes(layer, name);
    return keys.isEmpty
        ? 0
        : keys.any((k) => (k - at).abs() < .5 / rate)
        ? 2
        : 1;
  }

  /// The size of the stage the document is open on; and the size it is to be when it is next opened (close, open again).
  (int, int) get size => switch (_document['size']) {
    [final int w, final int h] => (w, h),
    _ => (0, 0),
  };

  /// The work area, in seconds: the stretch played round and written as a film (not said: all of it); a change is a step.
  (double, double) get work => switch (_document['work']) {
    [final num a, final num b] => (a.toDouble(), b.toDouble()),
    _ => (0.0, 0.0),
  };

  /// The marks: moments with a name, in time; a mark said with '' is taken away.
  List<(double, String)> get marks => [
    for (final line in ((_document['marks'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) (double.parse(line.substring(0, i)), line.substring(i + 1)),
  ];

  /// The window's choices kept with the document, not steps of it (asked later: setting): each by its name.
  Map<String, String> get settings => {
    for (final line in ((_document['settings'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) line.substring(0, i): line.substring(i + 1),
  };

  /// The marks that have a colour: the moment of each to its colour, 1 to 16 (the label colours).
  Map<double, int> get markColors => {
    for (final line in ((_document['markColours'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) double.parse(line.substring(0, i)): int.parse(line.substring(i + 1)),
  };

  /// The guides: lines across the picture, 'x' upright and 'y' level, at so many points from its left or top.
  List<(String, double)> get guides => [
    for (final line in ((_document['guides'] as String?) ?? '').split('\n'))
      if (line.length > 2) (line[0], double.parse(line.substring(2))),
  ];

  /// Whether the stage is the size the document says now (not, after [resize] or an undo of one: open it again).
  bool get fits => (_document['fits'] as bool?) ?? true;

  /// The names of a thing's values that take keys.
  List<String> moving(int layer) => Motolii._spaced(_of(layer)['moving']);

  /// The names of all a thing's values.
  List<String> values(int layer) => Motolii._spaced(_of(layer)['values']);

  /// The cards a maker sees a thing's values on, besides where it is and its fill: each a title and the values on it.
  List<(String, List<String>)> cards(int layer) => [
    ..._cardsIn(_of(layer)['cards']),
    for (final c in _cardsIn(_of(layer)['more']))
      if (asked[layer]?.contains(c.$1) ?? false) c,
  ];

  /// The titles of the cards it may be given and is not shown, as the shelf of More: not there unasked.
  List<String> moreCards(int layer) => [
    for (final (title, _) in _cardsIn(_of(layer)['more']))
      if (!(asked[layer]?.contains(title) ?? false)) title,
  ];

  static List<(String, List<String>)> _cardsIn(Object? said) => [
    for (final c in ((said as String?) ?? '').split('; '))
      if (c.indexOf(': ') case final at when at > 0)
        (
          c.substring(0, at),
          [
            for (final n in c.substring(at + 2).split(' '))
              if (n.isNotEmpty) n,
          ],
        ), // (an effect of no knobs: a card of none, doc_cards_of)
  ];

  /// The titles of a thing's effect cards in the order its effects are laid (motolii_fx_titles): moved with `fx_move`.
  List<String> fxTitles(int layer) => [
    for (final t in ((_of(layer)['fx'] as String?) ?? '').split(';'))
      if (t.isNotEmpty) t,
  ];

  /// A number value's lowest and highest (null: the thing has no such number).
  (double, double)? range(int layer, String name) => switch ((_of(layer)['range'] as Map<String, dynamic>?)?[name]) {
    [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
    _ => null,
  };

  /// The words a value of a thing may be (a blend's): none if any word will do, or the thing has no such value.
  List<String> words(int layer, String name) => Motolii._spaced((_of(layer)['words'] as Map<String, dynamic>?)?[name]);

  /// The ways a stretch may go, as the document says them: the nine kinds with their numbers, the named ones, and
  /// each defined here ('; defined here: Snappy').
  String get easings => (_document['easings'] as String?) ?? '';

  /// The effects a thing may be given, by name, with the value that puts each on (the Effects shelf); its card shows
  /// while it is on ([cards]).
  List<(String, String)> get layerEffects => _labelled((_document['effectNames'] as String?) ?? '', 'thing');

  List<String> get easingNames => Motolii._spaced(_document['easingNames']);

  double easingAt(String easing, double u) {
    // (a way of the document's, by its curve in the picture; one said with its numbers, by the inside's own reckoning, which asks nothing of the document)
    if ((_document['easingCurves'] as Map<String, dynamic>?)?[easing] case final List<dynamic> c when c.length > 1) {
      final at = u.clamp(0.0, 1.0) * (c.length - 1), i = at.floor().clamp(0, c.length - 2), f = at - i;
      return (c[i] as num).toDouble() * (1 - f) + (c[i + 1] as num).toDouble() * f;
    }
    return _with([easing], (s) => _easingAt(_m, s[0], u));
  }

  /// A way as the inside works it out, not as the picture's few steps say it: for a curve drawn large.
  double easingExact(String easing, double u) => _with([easing], (s) => _easingAt(_m, s[0], u));

  /// Every stretch of a thing's keyed values: from, to (seconds), its way, as the inside says them (a timeline draws how each goes).
  List<(double, double, String)> layerStretches(int layer) => [
    for (final l in ((_of(layer)['stretches'] as String?) ?? '').split('\n'))
      if (l.split('\t') case [final a, final b, final w]) (double.parse(a), double.parse(b), w),
  ];

  /// The way of the stretch that begins at a value's key, as it is said ('': no key there).
  String easingOf(int layer, String name, double at) {
    final keys = keyTimes(layer, name), easings = (_of(layer)['keyEasings'] as Map<String, dynamic>?)?[name] as List<dynamic>?;
    var i = -1; // (the nearest within half a frame: two keys may lie in one frame, a stretched bar leaving them off its grid)
    var near = .5 / rate;
    for (final (k, s) in keys.indexed) {
      if ((s - at).abs() < near) (i, near) = (k, (s - at).abs());
    }
    return i < 0 || easings == null || i >= easings.length ? '' : easings[i] as String;
  }

  /// Points of the picture to one unit of the stage, at z 0.
  double get point => (_document['point'] as num?)?.toDouble() ?? 1;

  /// How long the document has been worked on, in whole seconds (Alight Motion's Total Edit Time: doc_edited).
  int get edited => ((_document['edited'] as num?) ?? 0).round();

  /// How a hand reads a thing's value, as the inside says it: shown = value x times + from (places in points of the
  /// picture from its top left, shares in hundredths...). Asked once a thing and a name.
  (double, double) reading(int layer, String name) {
    final f = (((_of(layer)['reading'] as Map<String, dynamic>?)?[name] as String?) ?? '').split(' ');
    return f.length < 2 ? (1.0, 0.0) : (double.parse(f[0]), double.parse(f[1]));
  }
}
