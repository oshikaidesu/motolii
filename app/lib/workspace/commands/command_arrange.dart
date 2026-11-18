// The commands that place the selected layers: align, fit, flip and stacking order, and the time commands that align them on the timeline.
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/document/command_writes.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    show reorderLayer;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

/// The time commands and the arrange commands, as the menu lists them: the label and the command's ending.
const workspaceTimes = [
  ('Align Starts', 'start'),
  ('Align Ends', 'end'),
  ('Move to Playhead', 'playhead'),
  ('Move End to Playhead', 'playhead_end'),
  ('Stagger', 'stagger'),
  ('Extend Start to Playhead', 'extend'),
  ('Trim End to Playhead', 'trim_end'),
];

const workspaceAligns = [
  ('Align Left', 'left'),
  ('Align Centre', 'centre'),
  ('Align Right', 'right'),
  ('Align Top', 'top'),
  ('Align Middle', 'middle'),
  ('Align Bottom', 'bottom'),
  ('Spread Across', 'across'),
  ('Spread Down', 'down'),
];

extension ArrangeCommands on WorkspaceState {
  Map<String, VoidCallback> arrangeCommands() {
    final ws = this.ws;
    return {
      for (final (_, how) in workspaceAligns)
        'arrange.$how': () {
          // One selected layer aligns to the canvas, several align to their combined box.
          final all = pickedLayers();
          if (all.isNotEmpty) {
            ws.after(alignPicked(ws, how, all));
          }
        },
      for (final how in const ['fit', 'fill', 'stretch'])
        'arrange.$how': () => eachPicked((t) => fitLayer(ws, t, how)),
      'thing.forward': () => eachPicked((t) => reorderLayer(ws, t, 1)),
      'thing.backward': () => eachPicked((t) => reorderLayer(ws, t, -1)),
      'arrange.flipX': () => eachPicked((t) => flipLayer(ws, t, 'x')),
      'arrange.flipY': () => eachPicked((t) => flipLayer(ws, t, 'y')),
      for (final (_, how) in workspaceTimes)
        'time.$how': () {
          // Acts on the selected layers in the order they were selected.
          final all = pickedLayers();
          if (all.isNotEmpty) {
            ws.after(
              timeAlignPicked(ws, how, all, ws.frame / WorkspaceController.fps),
            );
          }
        },
    };
  }
}
