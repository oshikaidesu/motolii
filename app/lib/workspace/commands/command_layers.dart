// The commands of the selected layers: save as a preset or element, remove, duplicate, split, group and ungroup, outline, sound extraction, ducking and sequencing.
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension LayerCommands on WorkspaceState {
  Map<String, VoidCallback> layerCommands() {
    final m = engine!, ws = this.ws;
    // Groups the selected layers under a new null layer placed at their centre, as one undo step.
    // Like Figma's group, it is not a container of its own.
    // [mask] is 'mask' or 'exclude' (Alight Motion's Group and Mask, Group and Exclude): the top layer's shape
    // then shows the others inside it, or cuts them out. The engine side is group_mask in document/evaluate/evaluate.h.
    // See docs/design/alight_motion_ui.md.
    void group(String mask) {
      final m = engine, all = pickedLayers();
      final frames = [for (final t in all) ?m?.bounds(t)];
      if (m == null || frames.isEmpty) return;
      final c = Offset(
        frames.map((f) => f[0]).reduce((a, b) => a + b) / frames.length,
        frames.map((f) => f[1]).reduce((a, b) => a + b) / frames.length,
      );
      final order = m.layers, top = order.lastIndexWhere(all.contains);
      m.later('together', number: 1);
      // The group's row takes the place of the top layer and the rest gather under it (After Effects' Pre-compose, Figma's group).
      for (final (i, t) in order.indexed.toList().reversed) {
        final past = order
            .sublist(math.min(i, top), top)
            .where((x) => !all.contains(x))
            .length;
        if (all.contains(t) && past > 0) {
          m.later('raise', layer: t, number: past.toDouble());
        }
      }
      ws.after(
        m.later('add', name: 'shape', word: 'null'),
        null,
        (g) => ws.select('$g'),
      );
      if (top + 1 < order.length) {
        m.later(
          'raise',
          layer: -1,
          number: (top + 1 - order.length).toDouble(),
        );
      }
      m.later(
        'say',
        layer: -1,
        name: 'name',
        word: mask.isEmpty ? 'Group' : 'Group and Mask',
      );
      // The group's bar spans the bars of its layers, as a precomposed layer's does.
      final from = all.map((t) => m.value(t, 'start', 0) ?? 0).reduce(math.min),
          ends = [
            for (final t in all)
              m.lasts(t) < 0
                  ? double.infinity
                  : (m.value(t, 'start', 0) ?? 0) + m.lasts(t),
          ];
      m.later('set', layer: -1, name: 'start', number: from);
      // The group also keeps the length of its contents. Its Element card's Re-timing plays that content longer or shorter.
      // In Alight Motion a group is a scene of that length (AbsentMotion's StructureActions.kt: totalTime = end - start).
      if (ends.reduce(math.max).isFinite) {
        for (final n in const ['duration', 'element_length']) {
          m.later(
            'set',
            layer: -1,
            name: n,
            number: ends.reduce(math.max) - from,
          );
        }
      }
      if (mask.isNotEmpty) {
        m.later('say', layer: -1, name: 'group_mask', word: mask);
      }
      m.later(
        'set',
        layer: -1,
        name: 'x',
        number: (c.dx - ArtGeometry.centre.dx) / m.point,
      );
      m.later(
        'set',
        layer: -1,
        name: 'y',
        number: (ArtGeometry.centre.dy - c.dy) / m.point,
      );
      for (final t in all) {
        m.later(
          'set',
          layer: t,
          name: 'parent',
          word: 'last_added',
        ); // Each layer follows the group and stays where it is.
      }
      ws.after(m.later('together'), (_, _) => ws.reread());
    }

    return {
      'thing.saveLook': () {
        // Saves the layer as a preset on the Effects shelf, named after the layer (Alight Motion's Save as Preset).
        final m = engine, l = ws.layer;
        if (m == null || l == null) return;
        ws.after(m.later('keep_preset', layer: int.parse(l.id), word: l.name), (
          done,
          why,
        ) {
          m.forgetFolders();
          ws.notice = done ? 'Look kept: ${l.name}' : 'Not kept: $why';
          ws.reread();
        });
      },
      'thing.saveElement': () {
        // Saves the layer with its contents among the elements on the Create shelf (Alight Motion's Save to My Elements).
        final m = engine, l = ws.layer;
        if (m == null || l == null) return;
        ws.after(
          m.later('keep_element', layer: int.parse(l.id), word: l.name),
          (done, why) {
            m.forgetFolders();
            ws.notice = done
                ? 'Saved to My Elements: ${l.name}'
                : 'Not saved: $why';
            ws.reread();
          },
        );
      },
      'thing.deactivate': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        final hidden = ws.layers.any((l) => l.id == ws.selected && l.hidden);
        ws.after(
          m.later('set', layer: t, name: 'visible', number: hidden ? 1 : 0),
        );
      },
      'thing.remove': () {
        if (selectedMarker.value case (final at, _)?) {
          // A selected marker is deleted first, as Live deletes a locator like a clip.
          selectedMarker.value = null;
          return ws.after(m.later('mark', number: at));
        }
        if (ws.stretch case final s?) {
          // A selected span between keyframes resets its easing to Linear instead of deleting the layer.
          return ws.after(
            m.later(
              'easing',
              layer: int.parse(s.layer),
              name: s.name,
              number: s.at,
              word: 'Linear',
            ),
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
        m.later('together', number: 1);
        for (final t in ts) {
          m.later(
            'remove',
            layer: t,
          ); // Does not wait for the result. Undo brings the layer back.
        }
        ws.after(m.later('together'));
        ws.select(
          null,
        ); // Nothing stays selected, so a second Delete removes nothing else.
      },
      'thing.duplicate': () {
        final all = pickedLayers(), made = <String>[];
        if (all.isEmpty) return;
        m.later('together', number: 1);
        for (final t in all) {
          ws.after(m.later('duplicate', layer: t), null, (one) {
            made.add('$one');
            if (made.length < all.length) return;
            ws.select(
              made.last,
            ); // The new layers become selected, as in After Effects.
            if (made.length > 1) ws.pickMany(made);
          });
        }
        ws.after(m.later('together'));
      },
      'thing.outline': () {
        // Alight Motion's Convert to Outline: turns a shape into a path of the outline it shows, whose points then belong to the Pen tool (doc_to_path).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null ||
            m.word(t, 'kind') != 'shape' ||
            const ['path', 'null', 'solid'].contains(m.word(t, 'shape'))) {
          return;
        }
        ws.after(m.later('outline', layer: t), (_, _) => ws.reread());
      },
      'thing.extractSound': () {
        // Moves a video's sound to a layer of its own and mutes the video (Alight Motion's Extract Audio).
        final t = int.tryParse(ws.selected ?? '');
        if (t == null || m.word(t, 'kind') != 'film') return;
        ws.after(
          m.later('extract_sound', layer: t),
          null,
          (made) => ws.select('$made'),
        );
      },
      'thing.group': () => group(''),
      'thing.groupMask': () => group('mask'),
      'thing.groupExclude': () => group('exclude'),
      'thing.ungroup': () {
        // Releases the layers of the selected group where they are and removes the null, as one undo step.
        final m = engine, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'shape') != 'null') return;
        final kids = [
          for (final t in m.layers)
            if (m.parentOf(t) == g) t,
        ];
        m.later('together', number: 1);
        for (final t in kids) {
          m.later('set', layer: t, name: 'parent', number: 0);
        }
        m.later('remove', layer: g);
        ws.after(m.later('together'), (_, _) => ws.reread());
        ws.pickMany([for (final t in kids) '$t']);
      },
      'thing.unlinkElement': () {
        // The element becomes a plain group and no longer follows its file (AbsentMotion's Unlink from Asset, ElementUi.kt).
        final m = engine, g = int.tryParse(ws.selected ?? '');
        if (m == null || g == null || m.word(g, 'element').isEmpty) return;
        ws.after(
          m.later('say', layer: g, name: 'element', word: ''),
          (_, _) => ws.reread(),
        );
      },
      'thing.split': () {
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        // The part after the playhead becomes selected, as in Live.
        ws.after(
          m.later(
            'split',
            layer: t,
            number: ws.frame / WorkspaceController.fps,
          ),
          null,
          (made) => ws.select('$made'),
        );
      },
      'layers.sequence': () => ws.after(m.later('sequence')),
      'sound.duck': () async {
        // Audacity's Auto Duck: lowers each selected video under the sound of all the other layers, whose loudness is read first.
        final m = engine, all = pickedLayers();
        if (m == null || all.isEmpty) return;
        for (final t in m.layers) {
          if (!all.contains(t)) await m.loudness(t);
        }
        for (final t in all) {
          ws.after(
            m.later('duck', layer: t),
            (done, why) => done ? null : ws.notice = 'Not ducked: $why',
          );
        }
      },
    };
  }
}
