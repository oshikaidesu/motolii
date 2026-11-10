// The Expression group of the Create shelf: which files are expressions, and their tiles.
import 'dart:io';

import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/dock_make_create.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

// ---- The Expression group: every JS file that goes on a layer and moves its values (docs/design/create_and_program_shelves.md).
// It gathers three kinds in one place:
// - scripts with each(): the Repeater, After Effects expressions, Maze, Sunflower and others
// - motions: Cavalry's Animators, in expressions/
// - the user's own, added with Add to shelf (shelf_add.dart)
// Each is added to the picked layer as a card of its own, as many times as wanted (fx_file, empty_fx.dart fxPut).
// With nothing picked, a script creates its own layer as its head says, and the others go on a new layer.

/// The create scripts that are expressions, as (name from the file's head, file path).
/// A user's file replaces a library file of the same name, as the engine's doc_folders does.
List<(String, String)> expressionRecipes() {
  final by = <String, String>{};
  for (final dir in ['$motoliiShelves/create', '${EffectTiles.own}/recipes', '${EffectTiles.own}/create']) {
    // recipes/ is the user's folder under its former name, which doc_folders still reads.
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {
      // Subfolders: shapes/, cavalry/, repeats/, over_footage/.
      final n = f.path.split('/').last;
      if (n.endsWith('.js') && f.readAsStringSync().contains(RegExp(r'function\s+each\b'))) by[n] = f.path;
    }
  }
  return [
    for (final f in by.values)
      if (File(f).readAsLinesSync().firstOrNull case final first? when first.startsWith('// ') && first.contains(':'))
        (first.substring(3, first.indexOf(':')), f),
  ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
}

/// The tiles of the Expression group: scripts that are expressions, then the engine's motions, then the user's own.
List<CreateTile> expressionsOf(Ws ws) => [
  for (final (name, file) in expressionRecipes())
    CreateTile(name, DockG.copies, Pop.tonePlace, '', 'On the picked thing, a card of its own (nothing picked: makes its own thing)', file: file, made: true),
  for (final (name, file) in ws.inside?.animators ?? const <(String, String)>[])
    // A motion the user added is also in expressions/, the engine's motions folder. Its tile is the one below, with its own name.
    if (!shelfAdded(file))
      CreateTile(name, DockG.copies, Pop.tonePlace, '', 'A motion, on the picked thing, a card of its own (nothing picked: on a new board)', file: file),
  for (final (name, file) in shelfExpressions())
    CreateTile(
      name,
      DockG.copies,
      Pop.tonePlace,
      '',
      'Your expression, on the picked thing (nothing picked: on a new board); its knobs are on its card',
      file: file,
    ),
];
