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

  /// The marks: moments with a name, in time; a mark said with '' is taken away.
  List<(double, String)> get marks => [
    for (final line in ((_document['marks'] as String?) ?? '').split('\n'))
      if (line.indexOf(' ') case final i when i > 0) (double.parse(line.substring(0, i)), line.substring(i + 1)),
  ];

  /// Whether the stage is the size the document says now (not, after [resize] or an undo of one: open it again).
  bool get fits => (_document['fits'] as bool?) ?? true;

  /// The names of a thing's values that take keys.
  List<String> moving(int layer) => Motolii._spaced(_of(layer)['moving']);

  /// The names of all a thing's values.
  List<String> values(int layer) => Motolii._spaced(_of(layer)['values']);

  /// The cards a maker sees a thing's values on, besides where it is and its fill: each a title and the values on it.
  List<(String, List<String>)> cards(int layer) => _cardsIn(_of(layer)['cards']);

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

  /// A number value's lowest and highest (null: the thing has no such number).
  (double, double)? range(int layer, String name) => switch ((_of(layer)['range'] as Map<String, dynamic>?)?[name]) {
    [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
    _ => null,
  };

  /// The words a value of a thing may be (a blend's): none if any word will do, or the thing has no such value.
  List<String> words(int layer, String name) => Motolii._spaced((_of(layer)['words'] as Map<String, dynamic>?)?[name]);

  /// How a hand reads a thing's value, as the inside says it: shown = value x times + from (places in points of the
  /// picture from its top left, shares in hundredths...). Asked once a thing and a name.
  (double, double) reading(int layer, String name) {
    final f = (((_of(layer)['reading'] as Map<String, dynamic>?)?[name] as String?) ?? '').split(' ');
    return f.length < 2 ? (1.0, 0.0) : (double.parse(f[0]), double.parse(f[1]));
  }
}
