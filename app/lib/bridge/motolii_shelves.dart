// motolii_shelves.dart: what the maker has, read once (docs/app/BRIDGE.md S): the recipes, effects and motions on the shelves, their labels and pictures, a font's kinds, the kinds of way, what a value is shown as.
part of 'motolii.dart';

/// One thing on a shelf, as the inside's one line says it: "name\tfile\tlabel\tpicture\thome\tsame\tabout\ttags". [from] is the listing it came in (screen, thing, look, motion, relation).
class ShelfItem {
  ShelfItem(this.id, this.name, {this.label = '', this.picture = '', this.home = '', this.same = false, this.about = '', this.tags = const {}, this.from = ''});
  final String id, name, label, home, about, from;
  final Set<String> tags;
  String picture;
  bool same;
}

extension MotoliiShelves on Motolii {
  /// Pictures in one call: each recipe's name and what it makes.
  List<(String, String)> get createScripts => _folders.putIfAbsent('recipes', () => [for (final l in _createScriptLines) (l[0], l[1])]);

  /// The closed packs among them, the Program shelf's and not Create's (docs/internal/notes/CREATE_PROGRAM.md): each one's name
  /// and file, and what it was written for ([packKinds]: Cavalry, p5.js…), as the inside says.
  List<(String, String)> get packs => _folders.putIfAbsent(
    'packs',
    () => [
      for (final l in _createScriptLines)
        if (l.length > 3) (l[0], l[3]),
    ],
  );
  List<(String, String)> get packKinds => _folders.putIfAbsent(
    'packKinds',
    () => [
      for (final l in _createScriptLines)
        if (l.length > 3) (l[0], l[2]),
    ],
  );
  List<List<String>> get _createScriptLines => [
    for (final line in _createScripts(_m).toDartString().split('\n'))
      if (line.split('\t') case final l when l.length > 1 && l[0].isNotEmpty) l,
  ];

  /// The whole-screen effects on the shelf: each one's name and file (the stage's script is the files of those on it).
  List<(String, String)> get effects => _folders.putIfAbsent('effects', () => _labelled(_effects(_m).toDartString(), 'screen'));

  /// The looks on the shelf (a thing's values, effects and keys kept by a name: document/presets.h): each one's name and file.
  List<(String, String)> get presets => [
    for (final l in _presetLines)
      if (_items[l.$2]?.label != 'Element') l,
  ];

  /// The elements (a thing kept whole with what it holds, put in linked: Alight Motion's My Elements): each one's name and file.
  List<(String, String)> get elements => [
    for (final l in _presetLines)
      if (_items[l.$2]?.label == 'Element') l,
  ];
  List<(String, String)> get _presetLines => _folders.putIfAbsent('looks', () => _labelled(_presets(_m).toDartString(), 'look'));

  /// The motions a thing may be given (Cavalry's Animators): each one's name and file (a thing's script is the file of the one it has).
  List<(String, String)> get animators => _folders.putIfAbsent('animators', () => _labelled(_animators(_m).toDartString(), 'motion'));

  /// The relations written as files (a relation's script is the file of the one it is): each one's name and file.
  List<(String, String)> get relations => _folders.putIfAbsent('relations', () => _labelled(_relations(_m).toDartString(), 'relation'));

  /// What an effect (of a thing or of the whole screen) or a motion is for, as the inside says: the shelf's kind ('' none said).
  String label(String name) {
    _said();
    return _items[name]?.label ?? '';
  }

  /// An effect's (or a motion's) picture for its tile, as the inside says: what it does to a sample ('' none). By its
  /// name, or by its file (a file's effect may share a name with one of the inside's own, Datamosh and datamosh.wgsl).
  String tileImage(String name) {
    _said();
    return _items[name]?.picture ?? '';
  }

  /// What an effect does, in its maker's words, as its file's head says (--about:; '' none said): by name or file.
  String about(String name) {
    _said();
    return _items[name]?.about ?? '';
  }

  /// What an effect is, read from its file (the inside's isf_tags: transition, generator, sound, multipass, feedback, time, image).
  Set<String> tags(String name) {
    _said();
    return _items[name]?.tags ?? const {};
  }

  /// Where a tile drawn for an effect goes, as the inside says ('' none: an effect of its own, drawn by its look); by name or file.
  String tileHome(String name) {
    _said();
    return _items[name]?.home ?? '';
  }

  /// Whether an effect's tile is seen to change nothing on the sample (its defaults show nothing, or it is a helper of others).
  bool tileSame(String name) {
    _said();
    return _items[name]?.same ?? false;
  }

  /// A tile drawn where [home] says: the effects it is for show it from now on (workspace/effect_tiles.dart).
  void tileRendered(String home, {bool same = false}) {
    for (final i in _items.values) {
      if (i.home != home) continue;
      i.picture = home;
      i.same = same;
    }
  }

  /// One thing on a shelf by its name or its file (null: none said).
  ShelfItem? item(String id) {
    _said();
    return _items[id];
  }

  /// The things the listing [from] said (screen, thing, look, motion, relation), in the inside's order.
  List<ShelfItem> items(String from) {
    _said();
    return _listed[from] ?? const [];
  }

  void _said() => (effects, layerEffects); // (both lists read: their labels and pictures with them)

  /// "name\tfile\tlabel\tpicture\thome\tsame\tabout\ttags" lines: the names and files, and one [ShelfItem] each, kept by name and by file (the file's is its own) and in the list [from].
  List<(String, String)> _labelled(String lines, [String from = '']) {
    final out = <(String, String)>[], listed = <ShelfItem>[];
    for (final w in [for (final l in lines.split('\n')) l.split('\t')]) {
      if (w.length < 2 || w[0].isEmpty) continue;
      out.add((w[0], w[1]));
      final i = ShelfItem(
        w[1],
        w[0],
        label: w.length > 2 ? w[2] : '',
        picture: w.length > 3 ? w[3] : '',
        home: w.length > 4 ? w[4] : '',
        same: w.length > 5 && w[5] == 'same',
        about: w.length > 6 ? w[6] : '',
        tags: w.length > 7 && w[7].isNotEmpty ? w[7].split(' ').toSet() : const {},
        from: from,
      );
      _items[w[0]] = _items[w[1]] = i;
      listed.add(i);
    }
    if (from.isNotEmpty) _listed[from] = listed;
    return out;
  }

  /// How a value is shown to a hand, as the inside says (null: as its range says): its look, the unit it is read in,
  /// its name in plain words, the span its knob covers (in the document's units) and the fold it lies in.
  Shown? shown(String name) => _shownOf.putIfAbsent(name, () {
    for (final part in _layer.values) {
      if ((part['shown'] as Map<String, dynamic>?)?[name] case final String said) {
        final f = said.split('\t');
        return f.length < 6
            ? null
            : Shown(f[0], f[1], f[2], double.parse(f[3]), double.parse(f[4]), f[5].isEmpty ? null : f[5], open: f.length > 6 && f[6] == '1');
      }
    }
    return null;
  });

  /// A font file's kinds as CoreText reads them (serif, sans, script, mono, bold, light…): the system's own, not guessed from a name.
  Set<String> fontTags(String path) => _fontKinds[path] ??= _with([path], (s) => _fontTags(s[0]).toDartString()).split(' ').where((w) => w.isNotEmpty).toSet();

  /// The letters of [words] a font file has not (each once; '' none), and the font a text of them is drawn in instead
  /// ('' none has them all): the inside's motolii_font_lacks, a font's own letters by its cmap, Noto Sans JP first.
  (String, String) fontLacks(String font, String words) {
    final said = _with([font, words], (s) => _fontLacks(s[0], s[1]).toDartString()).split('\t');
    return (said.first, said.length > 1 ? said[1] : '');
  }

  /// A kind's numbers as a hand takes them: each one's name, lowest and highest (none: a kind without, or one defined).
  List<(String, double, double)> easingNumbers(String kind) {
    final w = _with([kind], (s) => _easingNumbers(_m, s[0]).toDartString()).split(' ').where((x) => x.isNotEmpty).toList();
    return [for (var i = 0; i + 2 < w.length; i += 3) (w[i], double.parse(w[i + 1]), double.parse(w[i + 2]))];
  }

  /// What kind of thing a file makes ('': none).
  String kindOf(String file) => _with([file], (s) => _kindOf(s[0]).toDartString());

  /// The items nearest the words a hand types, best first, the best [limit] (0: 5, as RapidFuzz's extract): each its id,
  /// its name and label, and what it does (the inside's motolii_find: RapidFuzz, typos, parts, abbreviations). Those
  /// scored under [least] left out, as RapidFuzz's extract's score_cutoff (0: none).
  List<String> find(String words, Iterable<(String, String, String)> items, {int limit = 0, double least = 0}) {
    final lines = [
      for (final (id, name, about) in items) [id, name, about].map((w) => w.replaceAll(RegExp(r'[\t\n]'), ' ')).join('\t'),
    ].join('\n');
    return [
      for (final line in _with([words, lines], (s) => _find(_m, s[0], s[1], limit).toDartString()).split('\n'))
        if (line.lastIndexOf('\t') case final i when i > 0 && (double.tryParse(line.substring(i + 1)) ?? 0) >= least) line.substring(0, i),
    ];
  }
}
