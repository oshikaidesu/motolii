// The Edit menu's commands: undo and redo, cut, copy and paste (layers, keyframes, styles and code from the web), selecting all, and the work area.
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/storage/pasteboard_files.dart' show clipboardFilePaths;
import 'package:motolii/storage/window_paths.dart' show clipboardFileThere;
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/document/command_writes.dart';
import 'package:motolii/workspace/state/media/create_service.dart'
    show adaptCode;
import 'package:motolii/workspace/state/media/media_service.dart'
    show placeFileLayer;
import 'package:motolii/workspace/state/document/document_writes.dart'
    show requestUndo;
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/stage/stage_service.dart'
    show stageSeconds;
import 'package:motolii/workspace/state/media/timeline_service.dart'
    show setWorkArea;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension EditCommands on WorkspaceState {
  Map<String, VoidCallback> editCommands() {
    final ws = this.ws;
    return {
      'edit.undo': () =>
          typed(const UndoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : requestUndo(ws, redo: false),
      'edit.redo': () =>
          typed(const RedoTextIntent(SelectionChangedCause.keyboard))
          ? null
          : requestUndo(ws, redo: true),
      'edit.cut': () {
        // Unless the user is typing text, copy the selected layer and then remove it, as one undo step each, as Live does.
        if (typed(
          const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        )) {
          return;
        }
        // Cut keyframes: copy then delete, as After Effects does.
        if (ws.keys.isNotEmpty) {
          copiedKeyframes = const [];
          copyKeyframes(ws, ws.keys);
          removeKeyframes(ws, ws.keys);
          return;
        }
        final t = int.tryParse(ws.selected ?? '');
        if (t == null) return;
        Clipboard.getData(Clipboard.kTextPlain)
            .then((said) => textWhenCopied = said?.text);
        copyLayerThing(ws, t);
        groupBegin(ws);
        for (final held in ws.under('$t')) {
          removeLayer(ws, int.parse(held));
        }
        removeLayer(ws, t);
        ws.after(groupEnd(ws));
        ws.select(null);
      },
      'edit.copy': () {
        if (typed(CopySelectionTextIntent.copy)) return;
        copiedKeyframes = const [];
        ws.keys.isEmpty ? copy() : copyKeyframes(ws, ws.keys);
      },
      'edit.paste': () {
        if (typed(const PasteTextIntent(SelectionChangedCause.keyboard))) {
          return;
        }
        // Pastes the app's own clipboard: the copied keyframes, else the copied layer at the playhead (Live's paste at the insert marker).
        // The pasted layer is selected.
        void own() => copiedKeyframes.isNotEmpty
            ? pasteKeyframes(ws)
            : clipboardFileThere('thing')
            ? ws.after(
                pasteLayer(ws, ws.frame / WorkspaceController.fps),
                null,
                (made) => ws.select('$made'),
              )
            : null;
        // Finder からコピーしたファイル、または画像データ (⌘⇧⌃4 のスクリーンショットなど) をクリップボードから拾って、
        // 1 ファイル 1 レイヤーとして置く (UAT 230/231/306). 以降のコード/キーフレームペーストは走らない。
        Future<bool> pasteFiles() async {
          final paths = await clipboardFilePaths();
          if (paths.isEmpty) return false;
          for (final p in paths) {
            placeFileLayer(
              ws,
              file: p,
              verb: 'add',
              fit: false,
              stillSeconds: null,
              cut: null,
              settled: (done, why) {
                if (!done && why.isNotEmpty) {
                  ws.notice = 'Not taken: ${why.split(':').first}';
                }
              },
            );
          }
          return true;
        }

        // Code copied from the web is run by the engine's adapter (adapter.h), whatever it is written for.
        // Whatever was copied last wins.
        Clipboard.getData(Clipboard.kTextPlain).then((said) async {
          final code = said?.text ?? '';
          if (code.trim().isEmpty || code == textWhenCopied) {
            if (await pasteFiles()) return;
            return own();
          }
          ws.after(adaptCode(ws, int.tryParse(ws.selected ?? '') ?? 0, code), (
            done,
            why,
          ) async {
            if (done) return;
            if (why.contains('not code')) {
              if (await pasteFiles()) return;
              own();
            } else {
              ws.notice = 'Not taken: $why';
            }
          }, (made) => made > 0 ? ws.select('$made') : null);
        });
      },
      'edit.copyStyle': () => copy(style: true),
      'edit.pasteStyle': () {
        // Applies to every selected layer.
        final all = {...ws.many, ?ws.selected};
        if (!clipboardFileThere('style') || all.isEmpty) {
          return;
        }
        for (final id in all) {
          if (int.tryParse(id) case final t?) {
            ws.after(pasteStyleTo(ws, t));
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
        extractWorkArea(ws),
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
            ? (0.0, stageSeconds(ws))
            : (
                bars.map((l) => l.inF).reduce(math.min) /
                    WorkspaceController.fps,
                bars.map((l) => l.outF).reduce(math.max) /
                    WorkspaceController.fps,
              );
        ws.after(setWorkArea(ws, from, to));
      },
    };
  }
}
