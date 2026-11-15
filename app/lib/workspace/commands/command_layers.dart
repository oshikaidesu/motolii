// The commands of the selected layers: save as a preset or element, remove, duplicate, split, group and ungroup, outline, sound extraction, ducking and sequencing.
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/document/command_writes.dart';
import 'package:motolii/workspace/state/media/create_service.dart'
    show addLayer;
import 'package:motolii/workspace/state/engine_access.dart' show projectOpen;
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd, sayWord, setNumber, valueOf, wordOf;
import 'package:motolii/workspace/state/layers/layer_reads.dart'
    show layerBounds;
import 'package:motolii/workspace/state/stage/stage_service.dart'
    show stageLasts, stageLayers, stageParentOf, stagePointsPerUnit;
import 'package:motolii/workspace/state/media/timeline_service.dart'
    show loudnessOf, removeMarker, reorderLayer, setLayerVisible;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension LayerCommands on WorkspaceState {
  Map<String, VoidCallback> layerCommands() {
    final ws = this.ws;
    // Groups the selected layers under a new null layer placed at their centre, as one undo step.
    // Like Figma's group, it is not a container of its own.
    // [mask] is 'mask' or 'exclude' (Alight Motion's Group and Mask, Group and Exclude): the top layer's shape
    // then shows the others within it, or cuts them out. The engine side is group_mask in document/evaluate/evaluate.h.
    // See docs/design/alight_motion_ui.md.
    void group(String mask) {
      final all = pickedLayers();
      final frames = [for (final t in all) ?layerBounds(ws, t)];
      if (!projectOpen(ws) || frames.isEmpty) return;
      final c = Offset(
        frames.map((f) => f[0]).reduce((a, b) => a + b) / frames.length,
        frames.map((f) => f[1]).reduce((a, b) => a + b) / frames.length,
      );
      final order = stageLayers(ws), top = order.lastIndexWhere(all.contains);
      groupBegin(ws);
      // The group's row takes the place of the top layer and the rest gather under it (After Effects' Pre-compose, Figma's group).
      for (final (i, t) in order.indexed.toList().reversed) {
        final past = order
            .sublist(math.min(i, top), top)
            .where((x) => !all.contains(x))
            .length;
        if (all.contains(t) && past > 0) {
          reorderLayer(ws, t, past.toDouble());
        }
      }
      ws.after(addLayer(ws, 'shape', 'null'), null, (g) => ws.select('$g'));
      if (top + 1 < order.length) {
        reorderLayer(ws, -1, (top + 1 - order.length).toDouble());
      }
      sayWord(ws, -1, 'name', mask.isEmpty ? 'Group' : 'Group and Mask');
      // The group's bar spans the bars of its layers, as a precomposed layer's does.
      final from = all
              .map((t) => valueOf(ws, t, 'start', 0) ?? 0)
              .reduce(math.min),
          ends = [
            for (final t in all)
              stageLasts(ws, t) < 0
                  ? double.infinity
                  : (valueOf(ws, t, 'start', 0) ?? 0) + stageLasts(ws, t),
          ];
      setNumber(ws, -1, 'start', from);
      // The group also keeps the length of its contents. Its Element card's Re-timing plays that content longer or shorter.
      // In Alight Motion a group is a scene of that length (AbsentMotion's StructureActions.kt: totalTime = end - start).
      if (ends.reduce(math.max).isFinite) {
        for (final n in const ['duration', 'element_length']) {
          setNumber(ws, -1, n, ends.reduce(math.max) - from);
        }
      }
      if (mask.isNotEmpty) {
        sayWord(ws, -1, 'group_mask', mask);
      }
      setNumber(
        ws,
        -1,
        'x',
        (c.dx - ArtGeometry.centre.dx) / stagePointsPerUnit(ws),
      );
      setNumber(
        ws,
        -1,
        'y',
        (ArtGeometry.centre.dy - c.dy) / stagePointsPerUnit(ws),
      );
      for (final t in all) {
        // Each layer follows the group and stays where it is.
        followLastAdded(ws, t);
      }
      ws.after(groupEnd(ws), (_, _) => ws.reread());
    }

    return {
      'thing.saveLook': () {
        // Saves the layer as a preset on the Effects shelf, named after the layer (Alight Motion's Save as Preset).
        final l = ws.layer;
        if (!projectOpen(ws) || l == null) return;
        keepLook(ws, int.parse(l.id), l.name, (done, why) {
          ws.notice = done ? 'Look kept: ${l.name}' : 'Not kept: $why';
          ws.reread();
        });
      },
      'thing.saveElement': () {
        // Saves the layer with its contents among the elements on the Create shelf (Alight Motion's Save to My Elements).
        final l = ws.layer;
        if (!projectOpen(ws) || l == null) return;
        keepElement(ws, int.parse(l.id), l.name, (done, why) {
          ws.notice = done
              ? 'Saved to My Elements: ${l.name}'
              : 'Not saved: $why';
          ws.reread();
        });
      },
      'thing.deactivate': () {
        // Every selected layer takes the state opposite to the one clicked or first selected, as Live's 0 on several clips.
        final hidden = ws.layers.any((l) => l.id == ws.selected && l.hidden);
        eachPicked((t) => setLayerVisible(ws, t, hidden));
      },
      'thing.remove': () {
        if (selectedMarker.value case (final at, _)?) {
          // A selected marker is deleted first, as Live deletes a locator like a clip.
          selectedMarker.value = null;
          return ws.after(removeMarker(ws, at));
        }
        if (ws.stretch case final s?) {
          // A selected span between keyframes resets its easing to Linear instead of deleting the layer.
          return ws.after(
            resetEasing(ws, int.parse(s.layer), s.name, s.at),
            (_, _) => ws.reread(),
          );
        }
        // Selected keyframes are removed instead of the layer.
        if (ws.keys.isNotEmpty) return removeKeyframes(ws, ws.keys.toList());
        // All selected layers are removed in one undo step.
        final all = ws.many.isNotEmpty
            ? ws.many.toList()
            : [if (ws.selected != null) ws.selected!];
        // A group is removed together with the layers it holds, as copying does.
        final ts = [
          for (final id in {for (final id in all) ...ws.under(id), ...all})
            ?int.tryParse(id),
        ];
        if (ts.isEmpty) return;
        groupBegin(ws);
        for (final t in ts) {
          removeLayer(
            ws,
            t,
          ); // Does not wait for the result. Undo brings the layer back.
        }
        ws.after(groupEnd(ws));
        ws.select(
          null,
        ); // Nothing stays selected, so a second Delete removes nothing else.
      },
      'thing.duplicate': () {
        final all = pickedLayers(), made = <String>[];
        if (all.isEmpty) return;
        groupBegin(ws);
        for (final t in all) {
          ws.after(duplicateLayer(ws, t), null, (one) {
            made.add('$one');
            if (made.length < all.length) return;
            ws.select(
              made.last,
            ); // The new layers become selected, as in After Effects.
            if (made.length > 1) ws.pickMany(made);
          });
        }
        ws.after(groupEnd(ws));
      },
      'thing.outline': () {
        // Alight Motion's Convert to Outline: turns a shape into a path of the outline it shows, whose points then belong to the Pen tool (doc_to_path).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null ||
            wordOf(ws, t, 'kind') != 'shape' ||
            const ['path', 'null', 'solid'].contains(wordOf(ws, t, 'shape'))) {
          return;
        }
        ws.after(outlineLayer(ws, t), (_, _) => ws.reread());
      },
      'thing.extractSound': () {
        // Moves a video's sound to a layer of its own and mutes the video (Alight Motion's Extract Audio).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null || wordOf(ws, t, 'kind') != 'film') return;
        ws.after(extractSoundOf(ws, t), null, (made) => ws.select('$made'));
      },
      'thing.group': () => group(''),
      'thing.groupMask': () => group('mask'),
      'thing.groupExclude': () => group('exclude'),
      'thing.ungroup': () {
        // Releases the layers of the selected group where they are and removes the null, as one undo step.
        final g = int.tryParse(ws.selected ?? '');
        if (!projectOpen(ws) || g == null || wordOf(ws, g, 'shape') != 'null') {
          return;
        }
        final kids = [
          for (final t in stageLayers(ws))
            if (stageParentOf(ws, t) == g) t,
        ];
        groupBegin(ws);
        for (final t in kids) {
          setNumber(ws, t, 'parent', 0);
        }
        removeLayer(ws, g);
        ws.after(groupEnd(ws), (_, _) => ws.reread());
        ws.pickMany([for (final t in kids) '$t']);
      },
      'thing.unlinkElement': () {
        // The element becomes a plain group and no longer follows its file (AbsentMotion's Unlink from Asset, ElementUi.kt).
        final g = int.tryParse(ws.selected ?? '');
        if (!projectOpen(ws) || g == null || wordOf(ws, g, 'element').isEmpty) {
          return;
        }
        ws.after(sayWord(ws, g, 'element', ''), (_, _) => ws.reread());
      },
      'thing.split': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        // The part after the playhead becomes selected, as in Live.
        ws.after(
          splitLayerAt(ws, t, ws.frame / WorkspaceController.fps),
          null,
          (made) => ws.select('$made'),
        );
      },
      'layers.sequence': () => ws.after(sequenceLayers(ws)),
      'sound.duck': () async {
        // Audacity's Auto Duck: lowers each selected video under the sound of all the other layers, whose loudness is read first.
        final all = pickedLayers();
        if (!projectOpen(ws) || all.isEmpty) return;
        for (final t in stageLayers(ws)) {
          if (!all.contains(t)) await loudnessOf(ws, t);
        }
        for (final t in all) {
          ws.after(
            duckLayer(ws, t),
            (done, why) => done ? null : ws.notice = 'Not ducked: $why',
          );
        }
      },
    };
  }
}
