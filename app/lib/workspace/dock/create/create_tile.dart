// One tile of the Create shelf.
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/app_glyphs.dart';

/// One tile of the Create shelf. [key] is the keyboard shortcut shown on the tile and [what] the line shown in the footer.
class CreateTile {
  const CreateTile(
    this.name,
    this.g,
    this.hue,
    this.key,
    this.what, {
    this.recipe = false,
    this.file,
    this.made = false,
    this.pasted = false,
  });
  final String name, key, what;
  final AppGlyphs g;
  final Color hue;

  /// True for a create script, which builds a whole image in one call. It may share a name with a built-in tile:
  /// AbsentMotion's Rectangle, Star, Cube and Sun sit beside Motolii's shape, solid and light of the same names.
  final bool recipe;

  /// For an expression tile, its file. It is added to the picked layer as a card of its own.
  final String? file;

  /// True for an expression whose head makes its own layer (a script's "// make" line). With nothing picked, that layer is created.
  final bool made;

  /// True for code that came from outside by paste or drop, kept as written in [file] (code_file.dart). It makes a
  /// layer of its own through the adapter of what it was written for.
  final bool pasted;
  String get id => file ?? (recipe ? 'recipe:$name' : name);

  /// True if the tile goes on the picked layer, or on a new layer when none is picked.
  bool get onPicked => (file != null && !pasted) || _onPicked.contains(name);
}

// Tiles that go on the picked layer, or on a new layer when none is picked (empty_effect.dart).
const _onPicked = {'Empty'};
