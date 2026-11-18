// Reading layers, properties, keyframes, cards, easings, markers and guides from the engine's snapshot.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_watch.dart';

extension MotoliiDocument on Motolii {
  Map<String, dynamic> layerSnapshot(int layer) =>
      layerSnapshots[layer] ?? const {};

  /// The default of an unset property, or null if the kind doesn't have it.
  double? usual(int layer, String name) {
    if (!layerSnapshots.containsKey(layer)) return null;
    final kind = layer == 0 ? 'stage' : word(layer, 'kind');
    final knows = kindProperties.putIfAbsent(
      kind,
      () =>
          _spaced((documentSnapshot['knows'] as Map<String, dynamic>?)?[kind])
              .toSet(),
    );
    return knows.contains(name)
        ? ((documentSnapshot['usual'] as Map<String, dynamic>?)?[name] as num?)
              ?.toDouble()
        : null;
  }

  double get seconds => (documentSnapshot['seconds'] as num?)?.toDouble() ?? 0;

  /// A layer's string property. Empty if unset.
  String word(int layer, String name) =>
      ((layerSnapshot(layer)['word'] as Map<String, dynamic>?)?[name]
          as String?) ??
      '';

  /// Duration in seconds. Negative = never ends.
  double lasts(int layer) =>
      (layerSnapshot(layer)['lasts'] as num?)?.toDouble() ?? -1;

  /// All keyframe times of a layer, deduplicated and in order.
  List<double> layerKeyTimes(int layer) =>
      Motolii.numbers(layerSnapshot(layer)['keys']);

  /// Keyframe times of a single property.
  List<double> keyTimes(int layer, String name) => Motolii.numbers(
    (layerSnapshot(layer)['keyTimes'] as Map<String, dynamic>?)?[name],
  );

  /// Keyframe values, in [keyTimes] order.
  List<double> keyValues(int layer, String name) => Motolii.numbers(
    (layerSnapshot(layer)['keyValues'] as Map<String, dynamic>?)?[name],
  );

  /// What changed since the last call (calling clears it).
  ({bool layers, Set<(int, String)> values}) changes() {
    final lines = ((documentSnapshot['changes'] as String?) ?? '').split('\n');
    return (
      layers: lines.contains('layers'),
      values: {
        for (final l in lines)
          if (l.indexOf(' ') case final i when i > 0)
            (int.parse(l.substring(0, i)), l.substring(i + 1)),
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

  /// The project's stage size. May differ from the open stage until reopened (see [fits]).
  (int, int) get size => switch (documentSnapshot['size']) {
    [final int w, final int h] => (w, h),
    _ => (0, 0),
  };

  /// The work area in seconds (loops on playback and is exported).
  (double, double) get work => switch (documentSnapshot['work']) {
    [final num a, final num b] => (a.toDouble(), b.toDouble()),
    _ => (0.0, 0.0),
  };

  /// Markers as (time, name). Empty name removes it.
  List<(double, String)> get marks => [
    for (final line in ((documentSnapshot['marks'] as String?) ?? '').split(
      '\n',
    ))
      if (line.indexOf(' ') case final i when i > 0)
        (double.parse(line.substring(0, i)), line.substring(i + 1)),
  ];

  /// Per-project app settings (not undo steps).
  Map<String, String> get settings => {
    for (final line in ((documentSnapshot['settings'] as String?) ?? '').split(
      '\n',
    ))
      if (line.indexOf(' ') case final i when i > 0)
        line.substring(0, i): line.substring(i + 1),
  };

  /// Marker time → label colour (1–16).
  Map<double, int> get markColors => {
    for (final line
        in ((documentSnapshot['markColours'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0)
        double.parse(line.substring(0, i)): int.parse(line.substring(i + 1)),
  };

  /// Guides: ('x'=vertical, 'y'=horizontal) at a distance in points from the edge.
  List<(String, double)> get guides => [
    for (final line in ((documentSnapshot['guides'] as String?) ?? '').split(
      '\n',
    ))
      if (line.length > 2) (line[0], double.parse(line.substring(2))),
  ];

  /// False after a resize until the project is reopened.
  bool get fits => (documentSnapshot['fits'] as bool?) ?? true;

  List<String> moving(int layer) => _spaced(layerSnapshot(layer)['moving']);

  List<String> values(int layer) => _spaced(layerSnapshot(layer)['values']);

  /// The layer's property cards as (title, [property names]).
  List<(String, List<String>)> cards(int layer) => [
    ..._cardsIn(layerSnapshot(layer)['cards']),
    for (final c in _cardsIn(layerSnapshot(layer)['more']))
      if (asked[layer]?.contains(c.$1) ?? false) c,
  ];

  /// Cards the layer can have but isn't showing (the More shelf).
  List<String> moreCards(int layer) => [
    for (final (title, _) in _cardsIn(layerSnapshot(layer)['more']))
      if (!(asked[layer]?.contains(title) ?? false)) title,
  ];

  static List<String> _spaced(Object? said) => [
    for (final w in ((said as String?) ?? '').split(' '))
      if (w.isNotEmpty) w,
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

  /// Effect card titles in order. Reorder with `fx_move`.
  List<String> fxTitles(int layer) => [
    for (final t in ((layerSnapshot(layer)['fx'] as String?) ?? '').split(';'))
      if (t.isNotEmpty) t,
  ];

  /// (low, high) range, or null.
  (double, double)? range(int layer, String name) =>
      switch ((layerSnapshot(layer)['range'] as Map<String, dynamic>?)?[name]) {
        [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
        _ => null,
      };

  /// Allowed values for a word property. Empty = any string.
  List<String> words(int layer, String name) =>
      _spaced((layerSnapshot(layer)['words'] as Map<String, dynamic>?)?[name]);

  List<String> get easingNames => _spaced(documentSnapshot['easingNames']);

  double easingAt(String easing, double u) {
    // An easing stored in the project is sampled from its curve in the snapshot.
    // One given by its numbers is evaluated by the engine, which does not read the project.
    if ((documentSnapshot['easingCurves'] as Map<String, dynamic>?)?[easing]
        case final List<dynamic> c when c.length > 1) {
      final at = u.clamp(0.0, 1.0) * (c.length - 1),
          i = at.floor().clamp(0, c.length - 2),
          f = at - i;
      return (c[i] as num).toDouble() * (1 - f) +
          (c[i + 1] as num).toDouble() * f;
    }
    return withStrings([
      easing,
    ], (s) => bindings.motolii_easing_at(handle, s[0], u));
  }

  /// Exact easing evaluation (not interpolated from snapshot samples).
  double easingExact(String easing, double u) =>
      withStrings([easing], (s) => bindings.motolii_easing_at(handle, s[0], u));

  /// Keyframed spans as (from, to, easing) in seconds.
  List<(double, double, String)> layerStretches(int layer) => [
    for (final l
        in ((layerSnapshot(layer)['stretches'] as String?) ?? '').split('\n'))
      if (l.split('\t') case [final a, final b, final w])
        (double.parse(a), double.parse(b), w),
  ];

  /// The easing at a keyframe. Empty if no keyframe at [at].
  String easingOf(int layer, String name, double at) {
    final keys = keyTimes(layer, name),
        easings =
            (layerSnapshot(layer)['keyEasings'] as Map<String, dynamic>?)?[name]
                as List<dynamic>?;
    // Pick the keyframe nearest [at] within half a frame. Two can fall in one frame when a bar is stretched off the frame grid.
    var i = -1;
    var near = .5 / rate;
    for (final (k, s) in keys.indexed) {
      if ((s - at).abs() < near) (i, near) = (k, (s - at).abs());
    }
    return i < 0 || easings == null || i >= easings.length
        ? ''
        : easings[i] as String;
  }

  double get point => (documentSnapshot['point'] as num?)?.toDouble() ?? 1;

  /// Total time spent editing the project, in whole seconds.
  int get edited => ((documentSnapshot['edited'] as num?) ?? 0).round();

  /// Display transform: shown = value * scale + offset.
  (double, double) reading(int layer, String name) {
    final f =
        (((layerSnapshot(layer)['reading'] as Map<String, dynamic>?)?[name]
                    as String?) ??
                '')
            .split(' ');
    return f.length < 2 ? (1.0, 0.0) : (double.parse(f[0]), double.parse(f[1]));
  }
}
