// What the shelves hold, read once (docs/app/BRIDGE.md S): create scripts, effects and motions with their labels and images,
// font kinds, easing kinds, and how a property is displayed.
import 'package:ffi/ffi.dart';

import 'package:motolii/bridge/motolii.dart';

extension MotoliiShelves on Motolii {
  /// Each create script's name and what it makes, in one call.
  List<(String, String)> get createScripts => folders.putIfAbsent(
    'recipes',
    () => [for (final l in _createScriptLines) (l[0], l[1])],
  );

  /// The closed packs among the create scripts. They belong to the Program shelf, not Create (docs/design/create_and_program_shelves.md).
  /// Each is a name and file. [packKinds] gives what each was written for, such as Cavalry or p5.js.
  List<(String, String)> get packs => folders.putIfAbsent(
    'packs',
    () => [
      for (final l in _createScriptLines)
        if (l.length > 3) (l[0], l[3]),
    ],
  );
  List<(String, String)> get packKinds => folders.putIfAbsent(
    'packKinds',
    () => [
      for (final l in _createScriptLines)
        if (l.length > 3) (l[0], l[2]),
    ],
  );
  List<List<String>> get _createScriptLines => [
    for (final line
        in bindings.motolii_create_scripts(handle).toDartString().split('\n'))
      if (line.split('\t') case final l when l.length > 1 && l[0].isNotEmpty) l,
  ];

  /// The whole-screen effects on the shelf, each a name and file. The stage's script is made from the files of the effects that are on.
  List<(String, String)> get effects => folders.putIfAbsent(
    'effects',
    () => _labelled(bindings.motolii_effects(handle).toDartString(), 'screen'),
  );

  /// The effects a layer can be given, as (name, value that turns it on), for the Effects shelf.
  /// The effect's card shows while it is on (see [cards]).
  List<(String, String)> get layerEffects =>
      _labelled((documentSnapshot['effectNames'] as String?) ?? '', 'thing');

  /// The presets on the shelf: a layer's properties, effects and keyframes saved under a name (document/edit/presets.h). Each is a name and file.
  List<(String, String)> get presets => [
    for (final l in _presetLines)
      if (shelfItems[l.$2]?.label != 'Element') l,
  ];

  /// The elements on the shelf: a whole layer with its contents, inserted as a link (like Alight Motion's My Elements). Each is a name and file.
  List<(String, String)> get elements => [
    for (final l in _presetLines)
      if (shelfItems[l.$2]?.label == 'Element') l,
  ];
  List<(String, String)> get _presetLines => folders.putIfAbsent(
    'looks',
    () => _labelled(bindings.motolii_presets(handle).toDartString(), 'look'),
  );

  /// The motions a layer can be given (like Cavalry's Animators), each a name and file. A layer's script is the file of the motion it uses.
  List<(String, String)> get animators => folders.putIfAbsent(
    'animators',
    () =>
        _labelled(bindings.motolii_animators(handle).toDartString(), 'motion'),
  );

  /// The relations stored as files, each a name and file. A relation's script is its file.
  List<(String, String)> get relations => folders.putIfAbsent(
    'relations',
    () => _labelled(
      bindings.motolii_relations(handle).toDartString(),
      'relation',
    ),
  );

  /// The tile image of an effect or motion: a sample of what it does. Empty if none.
  ///
  /// Look it up by name or by file. A file-based effect can share a name with a built-in one, such as Datamosh and datamosh.wgsl.
  String tileImage(String name) {
    _said();
    return shelfItems[name]?.picture ?? '';
  }

  /// What an effect does, in its author's words from the file header (--about:). Empty if none. Look it up by name or file.
  String about(String name) {
    _said();
    return shelfItems[name]?.about ?? '';
  }

  /// An effect's tags, read from its file (the engine's isf_tags): transition, generator, sound, multipass, feedback, time, image.
  Set<String> tags(String name) {
    _said();
    return shelfItems[name]?.tags ?? const {};
  }

  /// Where the tile image drawn for an effect is stored. Empty if the effect draws its own tile. Look it up by name or file.
  String tileHome(String name) {
    _said();
    return shelfItems[name]?.home ?? '';
  }

  /// Records that the tile at [home] has been drawn, so the effects it belongs to show it from now on (see workspace/effect_tiles.dart).
  void tileRendered(String home, {bool same = false}) {
    for (final i in shelfItems.values) {
      if (i.home != home) continue;
      i.picture = home;
      i.same = same;
    }
  }

  /// The shelf item with this name or file, or null if there is none.
  ShelfItem? item(String id) {
    _said();
    return shelfItems[id];
  }

  /// The items in the listing [from] (screen, layer, preset, motion or relation), in the engine's order.
  List<ShelfItem> items(String from) {
    _said();
    return shelfListings[from] ?? const [];
  }

  // Reads both lists, which also loads their labels and images.
  void _said() => (effects, layerEffects);

  /// Parses lines of "name\tfile\tlabel\tpicture\thome\tsame\tabout\ttags" into (name, file) pairs.
  /// Each line also becomes a [ShelfItem], stored by name, by file and in the listing [from].
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
        tags: w.length > 7 && w[7].isNotEmpty
            ? w[7].split(' ').toSet()
            : const {},
        from: from,
      );
      shelfItems[w[0]] = shelfItems[w[1]] = i;
      listed.add(i);
    }
    if (from.isNotEmpty) shelfListings[from] = listed;
    return out;
  }

  /// How a property is shown to the user, as the engine describes it: widget style, unit, plain label,
  /// slider range in project units, and fold. Null means to follow the property's range.
  Shown? shown(String name) => shownOf.putIfAbsent(name, () {
    for (final part in layerSnapshots.values) {
      if ((part['shown'] as Map<String, dynamic>?)?[name]
          case final String said) {
        final f = said.split('\t');
        return f.length < 6
            ? null
            : Shown(
                f[0],
                f[1],
                f[2],
                double.parse(f[3]),
                double.parse(f[4]),
                f[5].isEmpty ? null : f[5],
                open: f.length > 6 && f[6] == '1',
              );
      }
    }
    return null;
  });

  /// A font file's kinds as CoreText reports them (serif, sans, script, mono, bold, light…). They come from the system, not from guessing at the name.
  Set<String> fontTags(String path) => fontKinds[path] ??= withStrings(
    [path],
    (s) => bindings.motolii_font_tags(s[0]).toDartString(),
  ).split(' ').where((w) => w.isNotEmpty).toSet();

  /// The characters of [words] that the font file lacks (each once, empty if none), and the font that draws them instead
  /// (empty if no font has them all).
  ///
  /// This is the engine's motolii_font_lacks. It checks the font's cmap and tries Noto Sans JP first.
  (String, String) fontLacks(String font, String words) {
    final said = withStrings(
      [font, words],
      (s) => bindings.motolii_font_lacks(s[0], s[1]).toDartString(),
    ).split('\t');
    return (said.first, said.length > 1 ? said[1] : '');
  }

  /// The kind of layer a file makes. Empty if none.
  String kindOf(String file) =>
      withStrings([file], (s) => bindings.motolii_kind_of(s[0]).toDartString());

  /// The five items that best match the text the user typed, best first (like RapidFuzz's extract).
  ///
  /// Each result is an id, name and label, and what the item does. The engine's motolii_find tolerates typos, partial
  /// words and abbreviations. Items scoring below [least] are left out, as with RapidFuzz's score_cutoff (0 keeps all).
  List<String> find(
    String words,
    Iterable<(String, String, String)> items, {
    double least = 0,
  }) {
    final lines = [
      for (final (id, name, about) in items)
        [
          id,
          name,
          about,
        ].map((w) => w.replaceAll(RegExp(r'[\t\n]'), ' ')).join('\t'),
    ].join('\n');
    return [
      for (final line in withStrings(
        [words, lines],
        (s) => bindings.motolii_find(handle, s[0], s[1], 0).toDartString(),
      ).split('\n'))
        if (line.lastIndexOf('\t') case final i
            when i > 0 &&
                (double.tryParse(line.substring(i + 1)) ?? 0) >= least)
          line.substring(0, i),
    ];
  }
}
