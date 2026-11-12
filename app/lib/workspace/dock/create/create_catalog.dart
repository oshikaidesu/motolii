// What the Create shelf offers in a project: the tiles that come from the engine and the user's folders, how many
// tiles are ready, and every name on the shelf.
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/create/built_in_tiles.dart';
import 'package:motolii/workspace/dock/create/code_file.dart';
import 'package:motolii/workspace/dock/create/create_tile.dart';
import 'package:motolii/workspace/dock/create/expressions.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The "N ready" count: how many of the Create shelf's tiles can make or lay out something in the project.
String createFact(WorkspaceController ws) {
  // Scripts that are expressions have tiles in the Expression group, so they are counted with the expressions.
  final recipes = recipeGroup(ws).$2.length,
      expressions = expressionsOf(ws).length;
  // The shelf shows only these tiles.
  return '${layerOfTile.length + shadingOfTile.length + recipes + expressions + codeGroup().$2.length} ready';
}

/// The engine's create scripts, each shown as a tile, as the group Recipes. A script builds a whole image in one call,
/// as Cavalry's tutorials do.
(String, List<CreateTile>) recipeGroup(WorkspaceController ws) {
  // Scripts that are expressions are left out: their tiles are in the Expression group.
  final expressions = {for (final (name, _) in expressionRecipes()) name};
  // Code the user pasted is left out too: its tile is in the group Code, with the user's own name for it.
  final pasted = {for (final p in codeFiles()) p.stem};
  return (
    'Recipes',
    [
      for (final (name, what) in ws.inside!.createScripts)
        if (!expressions.contains(name) && !pasted.contains(name))
          CreateTile(
            name,
            AppGlyphs.copies,
            InspectorSkin.tonePlace,
            '',
            what,
            recipe: true,
          ),
    ],
  );
}

/// The code the user pasted or dropped in, kept as written in the user's own folder, as the group Code.
/// Each makes a layer of its own through the adapter of what it was written for; its code is then a cell of the Code tab.
(String, List<CreateTile>) codeGroup() => (
  'Code',
  [
    for (final p in codeFiles())
      CreateTile(
        p.name,
        AppGlyphs.code,
        WindowTokens.toneText,
        '',
        p.first,
        file: p.file,
        pasted: true,
      ),
  ],
);

/// Goes up each time a pasted code file's tile has been drawn, so its tile shows the new picture.
final codeTilesDrawn = ValueNotifier<int>(0);

/// Saved elements (Edit > Save to My Elements). Each is added at the playhead and stays linked to its file, as in
/// Alight Motion (+ > Object / Element > Element) and AbsentMotion's ElementPicker
/// (engine/third_party/AbsentMotion/app/src/main/kotlin/app/absentmotion/ui/editor/ElementUi.kt).
(String, List<CreateTile>) elementGroup(WorkspaceController ws) => (
  'Elements',
  [
    for (final (name, _) in ws.inside!.elements)
      CreateTile(
        name,
        AppGlyphs.nullObj,
        Grey.g76,
        '',
        'Element, linked to its file',
      ),
  ],
);

/// All names on Create, the library's and the user's. An expression cannot be added under one of them (shelf_add.dart).
Set<String> createNames(WorkspaceController ws) => {
  for (final (_, items) in [
    if (ws.inside != null) ...[recipeGroup(ws), elementGroup(ws)],
    ...builtInGroups,
    solidGroup,
    materialGroup,
    lightGroup,
  ])
    ...items.map((m) => m.name),
  for (final m in expressionsOf(ws)) m.name,
};
