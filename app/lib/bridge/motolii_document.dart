// The project snapshot reader (docs/app/BRIDGE.md D): layers, their properties and keyframes, cards, easings, markers and guides.
// The engine rebuilds the snapshot whenever the project changes.
part of 'motolii.dart';

extension MotoliiDocument on Motolii {
  Map<String, dynamic> _of(int layer) => _layer[layer] ?? const {};

  /// The default of a property the project does not store, if the layer's kind has that property (the engine's `doc_usual` and `doc_knows` tables).
  double? _usual(int layer, String name) {
    if (!_layer.containsKey(layer)) return null;
    final kind = layer == 0 ? 'stage' : word(layer, 'kind');
    final knows = _knows.putIfAbsent(kind, () => Motolii._spaced((_document['knows'] as Map<String, dynamic>?)?[kind]).toSet());
    return knows.contains(name) ? ((_document['usual'] as Map<String, dynamic>?)?[name] as num?)?.toDouble() : null;
  }

  double get seconds => (_document['seconds'] as num?)?.toDouble() ?? 0;

  /// The ids of all layers.
  List<int> get layers => [for (final t in (_document['layers'] as List<dynamic>?) ?? const []) t as int];

  /// A layer's string property by name (kind, file, shape, blend, text, fill). Empty if it has none.
  String word(int layer, String name) => ((_of(layer)['word'] as Map<String, dynamic>?)?[name] as String?) ?? '';

  /// How long a layer is on, in seconds. A negative value means it never ends.
  double lasts(int layer) => (_of(layer)['lasts'] as num?)?.toDouble() ?? -1;

  /// The time of every keyframe of any property of a layer, each once and in order. The timeline bar draws these.
  List<double> layerKeyTimes(int layer) => Motolii._numbers(_of(layer)['keys']);

  /// The times of a property's keyframes. Empty if it has none.
  List<double> keyTimes(int layer, String name) => Motolii._numbers((_of(layer)['keyTimes'] as Map<String, dynamic>?)?[name]);

  /// The value of each keyframe of a property, in the order of [keyTimes].
  List<double> keyValues(int layer, String name) => Motolii._numbers((_of(layer)['keyValues'] as Map<String, dynamic>?)?[name]);

  /// What the undo steps changed since the last call (calling clears it).
  ///
  /// `layers` is true when a layer was added or removed. `values` holds each changed property as (layer, name),
  /// taken from each step's changeset.
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

  /// The stage size in the project. It differs from the open stage until the project is reopened (see [fits]).
  (int, int) get size => switch (_document['size']) {
    [final int w, final int h] => (w, h),
    _ => (0, 0),
  };

  /// The work area in seconds: the range that loops on playback and is exported. If unset it covers the whole project. Changing it is an undo step.
  (double, double) get work => switch (_document['work']) {
    [final num a, final num b] => (a.toDouble(), b.toDouble()),
    _ => (0.0, 0.0),
  };

  /// The markers, each a time and a name, in time order. Setting a marker's name to empty removes it.
  List<(double, String)> get marks => [
    for (final line in ((_document['marks'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) (double.parse(line.substring(0, i)), line.substring(i + 1)),
  ];

  /// The app's choices saved with the project. They are not undo steps. Keyed by name.
  Map<String, String> get settings => {
    for (final line in ((_document['settings'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) line.substring(0, i): line.substring(i + 1),
  };

  /// The markers that have a colour, mapping each marker's time to a label colour from 1 to 16.
  Map<double, int> get markColors => {
    for (final line in ((_document['markColours'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) double.parse(line.substring(0, i)): int.parse(line.substring(i + 1)),
  };

  /// The guides: 'x' for vertical and 'y' for horizontal, each at a distance in points from the canvas's left or top edge.
  List<(String, double)> get guides => [
    for (final line in ((_document['guides'] as String?) ?? '').split('\n'))
      if (line.length > 2) (line[0], double.parse(line.substring(2))),
  ];

  /// Whether the open stage matches the project's size. It is false after a resize or an undo of one, until the project is reopened.
  bool get fits => (_document['fits'] as bool?) ?? true;

  /// The names of a layer's properties that can have keyframes.
  List<String> moving(int layer) => Motolii._spaced(_of(layer)['moving']);

  /// The names of all of a layer's properties.
  List<String> values(int layer) => Motolii._spaced(_of(layer)['values']);

  /// The cards that show a layer's properties, besides its position and fill. Each is a title and its property names.
  List<(String, List<String>)> cards(int layer) => [
    ..._cardsIn(_of(layer)['cards']),
    for (final c in _cardsIn(_of(layer)['more']))
      if (asked[layer]?.contains(c.$1) ?? false) c,
  ];

  /// The titles of the cards a layer can have but is not showing. They appear in the More shelf and are not shown unless the user asks.
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
        ), // An effect with no parameters gives a card with none (see doc_cards_of).
  ];

  /// The titles of a layer's effect cards in effect order (motolii_fx_titles). Reorder them with `fx_move`.
  List<String> fxTitles(int layer) => [
    for (final t in ((_of(layer)['fx'] as String?) ?? '').split(';'))
      if (t.isNotEmpty) t,
  ];

  /// The lowest and highest value of a numeric property. Null if the layer has no such property.
  (double, double)? range(int layer, String name) => switch ((_of(layer)['range'] as Map<String, dynamic>?)?[name]) {
    [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
    _ => null,
  };

  /// The strings a property may take, such as blend modes. Empty if any string is allowed or the layer has no such property.
  List<String> words(int layer, String name) => Motolii._spaced((_of(layer)['words'] as Map<String, dynamic>?)?[name]);

  /// The effects a layer can be given, as (name, value that turns it on), for the Effects shelf.
  /// The effect's card shows while it is on (see [cards]).
  List<(String, String)> get layerEffects => _labelled((_document['effectNames'] as String?) ?? '', 'thing');

  List<String> get easingNames => Motolii._spaced(_document['easingNames']);

  double easingAt(String easing, double u) {
    // An easing stored in the project is sampled from its curve in the snapshot.
    // One given by its numbers is evaluated by the engine, which does not read the project.
    if ((_document['easingCurves'] as Map<String, dynamic>?)?[easing] case final List<dynamic> c when c.length > 1) {
      final at = u.clamp(0.0, 1.0) * (c.length - 1), i = at.floor().clamp(0, c.length - 2), f = at - i;
      return (c[i] as num).toDouble() * (1 - f) + (c[i + 1] as num).toDouble() * f;
    }
    return _with([easing], (s) => _easingAt(_m, s[0], u));
  }

  /// An easing evaluated exactly by the engine, not interpolated from the snapshot's few samples. Use it for large curves.
  double easingExact(String easing, double u) => _with([easing], (s) => _easingAt(_m, s[0], u));

  /// Every keyframed span of a layer as (from, to, easing), with times in seconds, so the timeline can draw each easing.
  List<(double, double, String)> layerStretches(int layer) => [
    for (final l in ((_of(layer)['stretches'] as String?) ?? '').split('\n'))
      if (l.split('\t') case [final a, final b, final w]) (double.parse(a), double.parse(b), w),
  ];

  /// The easing of the span that starts at a property's keyframe. Empty if there is no keyframe at [at].
  String easingOf(int layer, String name, double at) {
    final keys = keyTimes(layer, name), easings = (_of(layer)['keyEasings'] as Map<String, dynamic>?)?[name] as List<dynamic>?;
    // Pick the keyframe nearest [at] within half a frame. Two can fall in one frame when a bar is stretched off the frame grid.
    var i = -1;
    var near = .5 / rate;
    for (final (k, s) in keys.indexed) {
      if ((s - at).abs() < near) (i, near) = (k, (s - at).abs());
    }
    return i < 0 || easings == null || i >= easings.length ? '' : easings[i] as String;
  }

  /// Canvas points per stage unit at z = 0.
  double get point => (_document['point'] as num?)?.toDouble() ?? 1;

  /// Total time spent editing the project, in whole seconds (like Alight Motion's Total Edit Time; see doc_edited).
  int get edited => ((_document['edited'] as num?) ?? 0).round();

  /// How a stored value converts to the displayed one: shown = value * scale + offset, returned as (scale, offset).
  /// For example positions are in canvas points from the top left, and fractions are shown as percentages.
  /// Asked once per layer and name.
  (double, double) reading(int layer, String name) {
    final f = (((_of(layer)['reading'] as Map<String, dynamic>?)?[name] as String?) ?? '').split(' ');
    return f.length < 2 ? (1.0, 0.0) : (double.parse(f[0]), double.parse(f[1]));
  }
}
