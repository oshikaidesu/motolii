// The Edit menu's commands: undo and redo, cut, copy and paste (layers, keyframes, styles and code from the web), selecting all, and the work area.
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension EditCommands on WorkspaceState {
  Map<String, VoidCallback> editCommands() {
    final m = engine!, ws = this.ws;
    return {
      'edit.undo': () =>
          typed(const UndoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.after(m.later('undo')),
      'edit.redo': () =>
          typed(const RedoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.after(m.later('redo')),
      'edit.cut': () {
        // Unless the user is typing text, copy the selected layer and then remove it, as one undo step each, as Live does.
        if (typed(
          const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        )) {
          return;
        }
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        Clipboard.getData(Clipboard.kTextPlain)
            .then((said) => textWhenCopied = said?.text);
        m.later('copy', layer: t, word: WorkspaceState.clipboard('thing'));
        m.later('together', number: 1);
        for (final held in ws.under('$t')) {
          m.later('remove', layer: int.parse(held));
        }
        m.later('remove', layer: t);
        ws.after(m.later('together'));
        ws.select(null);
      },
      'edit.copy': () {
        if (typed(CopySelectionTextIntent.copy)) return;
        copiedKeyframes = const [];
        ws.keys.isEmpty ? copy('copy', 'thing') : copyKeyframes(ws, ws.keys);
      },
      'edit.paste': () {
        if (typed(const PasteTextIntent(SelectionChangedCause.keyboard))) {
          return;
        }
        // Pastes the app's own clipboard: the copied keyframes, else the copied layer at the playhead (Live's paste at the insert marker).
        // The pasted layer is selected.
        void own() => copiedKeyframes.isNotEmpty
            ? pasteKeyframes(ws)
            : File(WorkspaceState.clipboard('thing')).existsSync()
            ? ws.after(
                m.later(
                  'paste',
                  word: WorkspaceState.clipboard('thing'),
                  number: ws.frame / WorkspaceController.fps,
                ),
                null,
                (made) => ws.select('$made'),
              )
            : null;
        // Code copied from the web is run by the engine's adapter (adapter.h), whatever it is written for.
        // Whatever was copied last wins.
        Clipboard.getData(Clipboard.kTextPlain).then((said) {
          final code = said?.text ?? '';
          if (code.trim().isEmpty || code == textWhenCopied) return own();
          ws.after(
            m.later(
              'adapter',
              layer: int.tryParse(ws.selected ?? '') ?? 0,
              word: code,
            ),
            (done, why) {
              if (done) return;
              why.contains('not code') ? own() : ws.notice = 'Not taken: $why';
            },
            (made) => made > 0 ? ws.select('$made') : null,
          );
        });
      },
      'edit.copyStyle': () => copy('copy_style', 'style'),
      'edit.pasteStyle': () {
        // Applies to every selected layer.
        final all = {...ws.many, ?ws.selected};
        if (!File(WorkspaceState.clipboard('style')).existsSync() ||
            all.isEmpty) {
          return;
        }
        for (final id in all) {
          if (int.tryParse(id) case final t?) {
            ws.after(
              m.later(
                'paste_style',
                layer: t,
                word: WorkspaceState.clipboard('style'),
              ),
            );
          }
        }
      },
      'edit.selectAll': () =>
          typed(const SelectAllTextIntent(SelectionChangedCause.keyboard))
          ? null
          : ws.pickMany([for (final l in ws.layers) l.id]), // Unless the user is typing: all layers, as Ableton's Cmd+A in the arrangement.
      // Selects nothing, as a click below the rows does (After Effects and Premiere Pro: Edit > Deselect All).
      // This is the only way to deselect when one layer covers the whole canvas.
      'edit.deselectAll': () => ws
        ..clearKeys()
        ..select(null),
      // Removes the work area and closes the gap (After Effects' Edit > Extract Work Area, under Split Layer).
      'edit.extractWork': () => ws.after(
        m.later('extract'),
        (done, why) => done || why.isEmpty
            ? null
            : ws.notice = 'Not taken: ${why.split(':').first}',
      ),
      // After Effects' Cmd+Opt+B: "set work area to duration of selected layers or, if no layers are selected, set
      // work area to composition duration". It brings back the whole project after Extract Work Area, which otherwise takes two drags.
      'edit.workToPicked': () {
        final picked = {for (final t in pickedLayers()) '$t'},
            bars = [
              for (final l in ws.layers)
                if (picked.contains(l.id)) l,
            ];
        final (from, to) = bars.isEmpty
            ? (0.0, m.seconds)
            : (
                bars.map((l) => l.inF).reduce(math.min) /
                    WorkspaceController.fps,
                bars.map((l) => l.outF).reduce(math.max) /
                    WorkspaceController.fps,
              );
        ws.after(m.later('work', number: from, word: '$to'));
      },
    };
  }
}
