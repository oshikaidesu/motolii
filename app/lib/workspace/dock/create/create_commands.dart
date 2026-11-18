// What the Create shelf asks the engine to do when a tile is run: make a layer, wear a material, put on an expression.
import 'package:motolii/storage/script_files.dart' show linesOf;
import 'package:motolii/workspace/dock/create/built_in_tiles.dart';
import 'package:motolii/workspace/dock/create/code_file.dart';
import 'package:motolii/workspace/dock/create/create_tile.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/media/create_service.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Create shelf asks the engine to do when a tile is run. Every call to the engine the shelf makes is a
/// method here.
class CreateCommands {
  /// [c] is the shelf as it is built now.
  CreateCommands(this.c);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// What a create call does with its answer: forget the tile's trouble when it was done, or keep why it was not.
  void Function(bool done, String why) _troubled(String name) =>
      (done, why) => c.set(
        () => done ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why,
      );

  /// Runs a tile: it creates a new layer and selects it. A tile of copies lays out the picked layer instead, and a material changes it.
  /// On failure the reason is stored under the tile's name, and the footer shows it.
  void make(CreateTile tile) {
    final name = tile.name;
    if (tile.recipe) {
      // A create script: one undo step, and the new layer is selected. It does not wait for the result.
      c.ws.after(
        makeRecipe(c.ws, name),
        _troubled(name),
        (made) => c.ws.select(made),
      );
      return;
    }
    if (tile.pasted) return _createFromCode(tile);
    if (tile.file != null) return _putExpression(tile);
    // After Effects: New > Adjustment Layer.
    if (name == 'Adjustment') return c.ws.adjustment();
    if (name == 'Empty') {
      // An empty expression for the user to write (empty_effect.dart). Any earlier error for this tile is cleared.
      c.set(() => c.mem.trouble.remove(name));
      return emptyPut(
        c.ws,
        expression: true,
        told: (why) => c.set(
          () => why.isEmpty
              ? c.mem.trouble.remove(name)
              : c.mem.trouble[name] = why,
        ),
      );
    }
    if (shadingOfTile[name] case final wears?) {
      // Replaces the picked layer's material. With nothing picked, creates a ball wearing it and selects the ball.
      final t = c.ws.selected;
      final told = _troubled(name);
      if (t != null) {
        if (!kindsThatWear.contains(wordOf(c.ws, t, 'kind'))) {
          return c.set(
            () => c.mem.trouble[name] = 'A camera, a light or a null wears nothing: pick a thing that is seen',
          );
        }
        c.ws.after(sayWord(c.ws, t, 'shading', wears), told);
        return;
      }
      // One undo step covers the ball and its material.
      groupBegin(c.ws);
      c.ws.after(
        addLayer(c.ws, 'solid', 'ball'),
        null,
        (made) => c.ws.select(made),
      );
      applyChosenInks(c.ws, 'solid', 'ball');
      sayWord(c.ws, -1, 'shading', wears);
      c.ws.after(groupEnd(c.ws), told);
      return;
    }
    if (!layerOfTile.containsKey(name)) {
      if (elementFile(c.ws, name) case final e?) {
        // Added at the playhead, in the middle, and selected
        c.ws.after(
          addElement(c.ws, e, c.ws.frame / WorkspaceController.fps),
          _troubled(name),
          (made) => c.ws.select(made),
        );
      }
      return;
    }
    final asked = layerOfTile[name]!;
    // One undo step covers the layer and its colors.
    groupBegin(c.ws);
    // Does not wait: the new layer is selected once it exists. A text layer uses the body font.
    c.ws.after(
      addLayer(c.ws, asked.$1, asked.$1 == 'text' ? c.ws.bodyFace : asked.$2),
      null,
      (made) => c.ws.select(made),
    );
    applyChosenInks(c.ws, asked.$1, asked.$2);
    for (final e
        in (startValuesOfTile[name] ?? const <String, double>{}).entries) {
      setNumber(c.ws, -1, e.key, e.value);
    }
    if (name == 'Floor') sayWord(c.ws, -1, 'name', name);
    if (asked.$1 == 'light' && (valueOf(c.ws, 0, 'environment', 0) ?? 1) == 1) {
      //, a light added to the project takes over from the default light. The room dims, and its old value is one field in Stage settings.
      setNumber(c.ws, 0, 'environment', .3);
    }
    c.ws.after(groupEnd(c.ws), _troubled(name));
  }

  /// Makes a layer from a pasted code file through the adapter of what it was written for, names it and selects it.
  void _createFromCode(CreateTile tile) {
    final code = CodeFile(tile.file!);
    c.ws.after(
      adaptCode(c.ws, c.ws.selected ?? 0, code.file),
      _troubled(tile.name),
      (made) {
        if (made <= 0) return;
        if (code.name != code.plain) {
          c.ws.after(sayWord(c.ws, made, 'name', code.name));
        }
        c.ws.select(made);
      },
    );
  }

  /// Puts an expression on the picked layer, or on a new layer when none is picked.
  void _putExpression(CreateTile tile) {
    final name = tile.name, file = tile.file!, t = c.ws.selected;
    void told(String why) => c.set(
      () =>
          why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why,
    );
    c.set(() => c.mem.trouble.remove(name));
    // Several layers, or the layers of a group, are a row as copies are: the expression moves layer i of n.
    if (expressionRow(c.ws) case final row when row.isNotEmpty) {
      return makeRelation(c.ws, file, of: row);
    }
    if (t == null && tile.made) {
      // Created the same way as a script tile.
      return c.ws.after(
        makeRecipe(c.ws, name),
        (done, why) => told(done ? '' : why),
        (made) => c.ws.select(made),
      );
    }
    final first =
        t != null &&
        !WorkspaceController.fxFiles(wordOf(c.ws, t, 'fx')).contains(file);
    putEffectFile(c.ws, file, expression: true, told: told);
    if (t == null) return;
    // If the script's head has a "// set copies N" line and the layer has no copies to lay out yet, set copies to N.
    // The first time the Repeater is added, its starting parameters are also set from firstValuesOfExpression.
    final head = linesOf(file).takeWhile((l) => l.startsWith('//'));
    if (head
            .map((l) => RegExp(r'^// set copies (\d+)').firstMatch(l)?[1])
            .nonNulls
            .firstOrNull
        case final n? when (valueOf(c.ws, t, 'copies', 0) ?? 1) <= 1) {
      setNumber(c.ws, t, 'copies', double.parse(n));
    }
    if (first) {
      for (final e
          in (firstValuesOfExpression[name] ?? const <String, double>{})
              .entries) {
        setNumber(c.ws, t, e.key, e.value);
      }
    }
  }
}
