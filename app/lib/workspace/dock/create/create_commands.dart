// What the Create shelf asks the engine to do when a tile is run: make a layer, wear a material, put on an expression.
import 'dart:io';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/dock/create/built_in_tiles.dart';
import 'package:motolii/workspace/dock/create/create_tile.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/effects.dart';
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
    final m = c.ws.inside!, name = tile.name;
    if (tile.recipe) {
      // A create script: one undo step, and the new layer is selected. It does not wait for the result.
      c.ws.after(
        m.later('create', word: name),
        _troubled(name),
        (made) => c.ws.select('$made'),
      );
      return;
    }
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
      final t = int.tryParse(c.ws.selected ?? '');
      final told = _troubled(name);
      if (t != null) {
        if (!kindsThatWear.contains(m.word(t, 'kind'))) {
          return c.set(
            () => c.mem.trouble[name] = 'A camera, a light or a null wears nothing: pick a thing that is seen',
          );
        }
        c.ws.after(
          m.later('say', layer: t, name: 'shading', word: wears),
          told,
        );
        return;
      }
      // One undo step covers the ball and its material.
      m.later('together', number: 1);
      c.ws.after(
        m.later('add', name: 'solid', word: 'ball'),
        null,
        (made) => c.ws.select('$made'),
      );
      applyChosenInks(c.ws, 'solid', 'ball');
      m.later('say', layer: -1, name: 'shading', word: wears);
      c.ws.after(m.later('together'), told);
      return;
    }
    if (!layerOfTile.containsKey(name)) {
      if (m.elements.where((e) => e.$1 == name).firstOrNull case final e?) {
        // Added at the playhead, in the middle, and selected, as in AbsentMotion's addElement.
        c.ws.after(
          m.later(
            'element',
            word: e.$2,
            number: c.ws.frame / WorkspaceController.fps,
          ),
          _troubled(name),
          (made) => c.ws.select('$made'),
        );
      }
      return;
    }
    final asked = layerOfTile[name]!;
    // One undo step covers the layer and its colors.
    m.later('together', number: 1);
    // Does not wait: the new layer is selected once it exists. A text layer uses the body font.
    c.ws.after(
      m.later(
        'add',
        name: asked.$1,
        word: asked.$1 == 'text' ? c.ws.bodyFace : asked.$2,
      ),
      null,
      (made) => c.ws.select('$made'),
    );
    applyChosenInks(c.ws, asked.$1, asked.$2);
    for (final e
        in (startValuesOfTile[name] ?? const <String, double>{}).entries) {
      m.later('set', layer: -1, name: e.key, number: e.value);
    }
    if (name == 'Floor') m.later('say', layer: -1, name: 'name', word: name);
    if (asked.$1 == 'light' && (m.value(0, 'environment', 0) ?? 1) == 1) {
      // As in After Effects, a light added to the project takes over from the default light. The room dims, and its old value is one field in Stage settings.
      m.later('set', layer: 0, name: 'environment', number: .3);
    }
    c.ws.after(m.later('together'), _troubled(name));
  }

  /// Puts an expression on the picked layer, or on a new layer when none is picked.
  void _putExpression(CreateTile tile) {
    final m = c.ws.inside!,
        name = tile.name,
        file = tile.file!,
        t = int.tryParse(c.ws.selected ?? '');
    void told(String why) => c.set(
      () =>
          why.isEmpty ? c.mem.trouble.remove(name) : c.mem.trouble[name] = why,
    );
    c.set(() => c.mem.trouble.remove(name));
    if (t == null && tile.made) {
      // Created the same way as a script tile.
      return c.ws.after(
        m.later('create', word: name),
        (done, why) => told(done ? '' : why),
        (made) => c.ws.select('$made'),
      );
    }
    final first =
        t != null &&
        !WorkspaceController.fxFiles(m.word(t, 'fx')).contains(file);
    putEffectFile(c.ws, file, expression: true, told: told);
    if (t == null) return;
    // If the script's head has a "// set copies N" line and the layer has no copies to lay out yet, set copies to N.
    // The first time the Repeater is added, its starting parameters are also set from firstValuesOfExpression.
    final head = File(file)
        .readAsLinesSync()
        .takeWhile((l) => l.startsWith('//'));
    if (head
            .map((l) => RegExp(r'^// set copies (\d+)').firstMatch(l)?[1])
            .nonNulls
            .firstOrNull
        case final n? when (m.value(t, 'copies', 0) ?? 1) <= 1) {
      m.later('set', layer: t, name: 'copies', number: double.parse(n));
    }
    if (first) {
      for (final e
          in (firstValuesOfExpression[name] ?? const <String, double>{})
              .entries) {
        m.later('set', layer: t, name: e.key, number: e.value);
      }
    }
  }
}
