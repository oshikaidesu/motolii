// Part of dock_make.dart: the Create shelf: what its tiles are and how many are ready.
part of 'dock_make.dart';

/// How many of the Create shelf's tiles make or lay out something of the document, of all it shows.
String createFact(Ws ws) {
  final recipes = _recipesOf(ws).$2.length, expressions = _expressionsOf(ws).length;   // (the recipes that are expressions are tiles of the Expression group's)
  return '${_asked.length + _worn.length + recipes + expressions} ready'; // (the shelf shows only these)
}

/// Joined: the inside's recipes, pictures in one call (as Cavalry's tutorials build them), each a tile.
(String, List<_Make>) _recipesOf(Ws ws) {
  final expressions = {for (final (name, _) in _expressionRecipes()) name};   // (not those that are expressions: their tiles are the Expression group's)
  final packs = {for (final (name, _) in ws.inside!.packs) name};   // (nor the closed packs: the Program shelf's, dock_program.dart)
  return ('Recipes', [for (final (name, what) in ws.inside!.recipes) if (!expressions.contains(name) && !packs.contains(name)) _Make(name, DockG.copies, Pop.tonePlace, '', what, recipe: true)]);
}

/// The elements kept (Edit › Save to My Elements), put in at the playhead linked to their file: Alight Motion's + ›
/// Object / Element › Element, AbsentMotion's ElementPicker (ElementUi.kt).
(String, List<_Make>) _elementsOf(Ws ws) => ('Elements', [for (final (name, _) in ws.inside!.elements) _Make(name, DockG.nullObj, Grey.g76, '', 'Element, linked to its file')]);
