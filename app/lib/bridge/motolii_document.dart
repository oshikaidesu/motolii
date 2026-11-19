// The project snapshot reader (docs/app/BRIDGE.md D): layers, their properties and keyframes, cards, easings, markers and guides.
// The engine rebuilds the snapshot whenever the project changes.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/snapshot_parts.dart';

extension MotoliiDocument on Motolii {
  /// Puts what a read of the document snapshot handed over (the parts that differ) into what is held, and notes
  /// what came ([structureTaken], [layersTaken], [layerListTaken]).
  void put(Map<String, dynamic> all) {
    var listCame = false, shownCame = false;
    if (all['document'] case final Map<String, dynamic> parts) {
      structureTaken |= hasDocumentStructure(parts);
      listCame = parts.containsKey('layers');
      documentSnapshot = merged(documentSnapshot, parts);
    }
    (all['layer'] as Map<String, dynamic>? ?? const {}).forEach((t, parts) {
      final layer = int.parse(t);
      parts as Map<String, dynamic>;
      if (parts.isEmpty) return;
      structureTaken |= hasStructure(parts);
      shownCame |= parts.containsKey('shown');
      layersTaken.add(layer);
      layerSnapshots[layer] = merged(layerSnapshots[layer] ?? const {}, parts);
    });
    if (listCame) {
      // A layer that is gone leaves the list, and only then is its snapshot let go.
      layerListTaken = true;
      final are = {0, ...layers};
      layerSnapshots.removeWhere((t, _) => !are.contains(t));
      layersTaken.removeWhere((t) => !are.contains(t));
    }
    if (listCame || shownCame) shownOf.clear();
  }

  /// Whether [layer] is one of the document's layers.
  bool has(int layer) => layer != 0 && layerSnapshots.containsKey(layer);

  Map<String, dynamic> layerSnapshot(int layer) =>
      layerSnapshots[layer] ?? const {};

  /// One named entry of a part of a layer's snapshot ('word', 'value', 'range', ...). Null if it has none.
  Object? partOf(int layer, String part, String name) =>
      (layerSnapshot(layer)[part] as Map<String, dynamic>?)?[name];

  /// A part of a layer's snapshot as [parse] reads it, parsed once (see [parsedOnce]).
  T _layerOnce<T extends Object>(
    int layer,
    String part,
    T Function(Object? said) parse,
  ) {
    final s = layerSnapshot(layer);
    return parsedOnce(s, part, () => parse(s[part]));
  }

  /// The same for one named entry of a part: each name is parsed when it is first read.
  T _namedOnce<T extends Object>(
    int layer,
    String part,
    String name,
    T Function(Object? said) parse,
  ) {
    final s = layerSnapshot(layer);
    return parsedOnce(
      s,
      part,
      () => <String, T>{},
    ).putIfAbsent(name, () => parse((s[part] as Map<String, dynamic>?)?[name]));
  }

  /// A part of the document snapshot as [parse] reads it, parsed once.
  T _documentOnce<T extends Object>(
    String part,
    T Function(Object? said) parse,
  ) {
    final s = documentSnapshot;
    return parsedOnce(s, part, () => parse(s[part]));
  }

  /// The default of a property the project does not store, if the layer's kind has that property (the engine's `doc_usual` and `doc_knows` tables).
  double? usual(int layer, String name) {
    if (!layerSnapshots.containsKey(layer)) return null;
    final kind = layer == 0 ? 'stage' : word(layer, 'kind');
    final knows = kindProperties.putIfAbsent(
      kind,
      () =>
          spaced((documentSnapshot['knows'] as Map<String, dynamic>?)?[kind])
              .toSet(),
    );
    return knows.contains(name)
        ? ((documentSnapshot['usual'] as Map<String, dynamic>?)?[name] as num?)
              ?.toDouble()
        : null;
  }

  double get seconds => (documentSnapshot['seconds'] as num?)?.toDouble() ?? 0;

  /// A layer's string property by name (kind, file, shape, blend, text, fill). Empty if it has none.
  String word(int layer, String name) =>
      (partOf(layer, 'word', name) as String?) ?? '';

  /// How long a layer is on, in seconds. A negative value means it never ends.
  double lasts(int layer) =>
      (layerSnapshot(layer)['lasts'] as num?)?.toDouble() ?? -1;

  /// The time of every keyframe of any property of a layer, each once and in order. The timeline bar draws these.
  List<double> layerKeyTimes(int layer) => _layerOnce(layer, 'keys', numbers);

  /// The times of a property's keyframes. Empty if it has none.
  List<double> keyTimes(int layer, String name) =>
      _namedOnce(layer, 'keyTimes', name, numbers);

  /// The value of each keyframe of a property, in the order of [keyTimes].
  List<double> keyValues(int layer, String name) =>
      _namedOnce(layer, 'keyValues', name, numbers);

  /// What the undo steps changed since the last call (calling clears it).
  ///
  /// `layers` is true when a layer was added or removed. `values` holds each changed property as (layer, name),
  /// taken from each step's changeset.
  ({bool layers, Set<(int, String)> values}) changes() {
    final said = (documentSnapshot['changes'] as String?) ?? '';
    return (
      layers: said.split('\n').contains('layers'),
      values: {
        for (final (layer, name) in named(said)) (int.parse(layer), name),
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
  (int, int) get size => switch (documentSnapshot['size']) {
    [final int w, final int h] => (w, h),
    _ => (0, 0),
  };

  /// The work area in seconds: the range that loops on playback and is exported. If unset it covers the whole project. Changing it is an undo step.
  (double, double) get work => switch (documentSnapshot['work']) {
    [final num a, final num b] => (a.toDouble(), b.toDouble()),
    _ => (0.0, 0.0),
  };

  /// The markers, each a time and a name, in time order. Setting a marker's name to empty removes it.
  List<(double, String)> get marks => _documentOnce(
    'marks',
    (said) => List.unmodifiable([
      for (final (at, name) in named(said)) (double.parse(at), name),
    ]),
  );

  /// The app's choices saved with the project. They are not undo steps. Keyed by name.
  Map<String, String> get settings => _documentOnce(
    'settings',
    (said) => Map.unmodifiable({
      for (final (name, value) in named(said)) name: value,
    }),
  );

  /// The markers that have a colour, mapping each marker's time to a label colour from 1 to 16.
  Map<double, int> get markColors => _documentOnce(
    'markColours',
    (said) => Map.unmodifiable({
      for (final (at, color) in named(said)) double.parse(at): int.parse(color),
    }),
  );

  /// The guides: 'x' for vertical and 'y' for horizontal, each at a distance in points from the canvas's left or top edge.
  List<(String, double)> get guides => _documentOnce(
    'guides',
    (said) => List.unmodifiable([
      for (final line in ((said as String?) ?? '').split('\n'))
        if (line.length > 2) (line[0], double.parse(line.substring(2))),
    ]),
  );

  /// Whether the open stage matches the project's size. It is false after a resize or an undo of one, until the project is reopened.
  bool get fits => (documentSnapshot['fits'] as bool?) ?? true;

  /// The names of a layer's properties that can have keyframes.
  List<String> moving(int layer) => _layerOnce(layer, 'moving', spaced);

  /// Whether a layer's property can have keyframes: [moving] as a set, for the reads made on every frame.
  bool isMoving(int layer, String name) {
    final s = layerSnapshot(layer);
    return parsedOnce(
      s,
      'moving',
      () => spaced(s['moving']).toSet(),
      as: 'set',
    ).contains(name);
  }

  /// The names of all of a layer's properties.
  List<String> values(int layer) => _layerOnce(layer, 'values', spaced);

  /// The cards that show a layer's properties, besides its position and fill. Each is a title and its property names.
  List<(String, List<String>)> cards(int layer) => [
    ..._layerOnce(layer, 'cards', cardsIn),
    for (final c in _layerOnce(layer, 'more', cardsIn))
      if (asked[layer]?.contains(c.$1) ?? false) c,
  ];

  /// The titles of the cards a layer can have but is not showing. They appear in the More shelf and are not shown unless the user asks.
  List<String> moreCards(int layer) => [
    for (final (title, _) in _layerOnce(layer, 'more', cardsIn))
      if (!(asked[layer]?.contains(title) ?? false)) title,
  ];

  /// The titles of a layer's effect cards in effect order (motolii_fx_titles). Reorder them with `fx_move`.
  List<String> fxTitles(int layer) => _layerOnce(
    layer,
    'fx',
    (said) => List.unmodifiable([
      for (final t in ((said as String?) ?? '').split(';'))
        if (t.isNotEmpty) t,
    ]),
  );

  /// The lowest and highest value of a numeric property. Null if the layer has no such property.
  (double, double)? range(int layer, String name) =>
      switch (partOf(layer, 'range', name)) {
        [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
        _ => null,
      };

  /// The strings a property may take, such as blend modes. Empty if any string is allowed or the layer has no such property.
  List<String> words(int layer, String name) =>
      _namedOnce(layer, 'words', name, spaced);

  List<String> get easingNames => _documentOnce('easingNames', spaced);

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

  /// An easing evaluated exactly by the engine, not interpolated from the snapshot's few samples. Use it for large curves.
  double easingExact(String easing, double u) =>
      withStrings([easing], (s) => bindings.motolii_easing_at(handle, s[0], u));

  /// Every keyframed span of a layer as (from, to, easing), with times in seconds, so the timeline can draw each easing.
  List<(double, double, String)> layerStretches(int layer) => _layerOnce(
    layer,
    'stretches',
    (said) => List.unmodifiable([
      for (final l in ((said as String?) ?? '').split('\n'))
        if (l.split('\t') case [final a, final b, final w])
          (double.parse(a), double.parse(b), w),
    ]),
  );

  /// The easing of the span that starts at a property's keyframe. Empty if there is no keyframe at [at].
  String easingOf(int layer, String name, double at) {
    final keys = keyTimes(layer, name),
        easings = partOf(layer, 'keyEasings', name) as List<dynamic>?;
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

  /// Canvas points per stage unit at z = 0.
  double get point => (documentSnapshot['point'] as num?)?.toDouble() ?? 1;

  /// Total time spent editing the project, in whole seconds (like Alight Motion's Total Edit Time; see doc_edited).
  int get edited => ((documentSnapshot['edited'] as num?) ?? 0).round();

  /// How a stored value converts to the displayed one: shown = value * scale + offset, returned as (scale, offset).
  /// For example positions are in canvas points from the top left, and fractions are shown as percentages.
  /// Asked once per layer and name.
  (double, double) reading(int layer, String name) =>
      _namedOnce(layer, 'reading', name, (said) {
        final f = ((said as String?) ?? '').split(' ');
        return f.length < 2
            ? (1.0, 0.0)
            : (double.parse(f[0]), double.parse(f[1]));
      });
}
