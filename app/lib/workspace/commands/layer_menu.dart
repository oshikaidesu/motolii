import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/context_menu.dart' show ContextMenuItem;
import 'package:motolii/workspace/commands/keymap.dart'
    show CommandIntent, keyLabel;
import 'package:motolii/workspace/edits/keyframe_edits.dart'
    show copiedKeyframes, copyKeyframes, pasteKeyframes, removeKeyframes;
import 'package:motolii/workspace/stage/camera_gestures.dart'
    show cameraLockTarget, cameraReleaseTarget, cameraTargetOf;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart'
    show stageCameraLayer;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart' show WorkspaceState;

/// The context menu for layer [l], opened by a right-click on its bar, its row or the stage.
/// It follows Ableton Live's clip menu (Rename, Duplicate, Split, Deactivate, Delete) and Figma's right-click on a layer.
/// Each row runs the same command as the menu bar and the keys, and shows the key the user has bound to it.
/// As in Finder and Figma, a right-click on one of the selected layers keeps them all, so the rows act on all of them;
/// on a layer that is not selected it selects that one alone.
List<ContextMenuItem> layerContextMenu(
  BuildContext context,
  WorkspaceController ws,
  Layer l,
) {
  final kept = ws.many.isNotEmpty
      ? ws.many.contains(l.id)
      : ws.selected == l.id;
  if (!kept) ws.select(l.id);
  final (say, keys) = _commands(context);
  final cam = l.kind == LayerKind.camera || l.kind == LayerKind.audio
      ? null
      : stageCameraLayer(ws, null);
  final lockedHere = cam != null && cameraTargetOf(ws, cam) == l.id;
  return [
    if (cam != null) ...[
      ContextMenuItem(
        lockedHere ? 'Release Camera Target' : 'Focus Camera Here',
        () {
          if (lockedHere) {
            cameraReleaseTarget(ws, cam);
            ws.notice = 'Camera target released';
          } else {
            cameraLockTarget(ws, cam, l.id);
            ws.notice = 'Camera locked on ${l.name}';
          }
        },
      ),
      const ContextMenuItem.rule(),
    ],
    ContextMenuItem(
      'Rename…',
      () => say('thing.rename'),
      keys: keys('thing.rename'),
    ),
    ContextMenuItem(
      'Duplicate',
      () => say('thing.duplicate'),
      keys: keys('thing.duplicate'),
    ),
    ContextMenuItem(
      'Split',
      ws.frame > l.inF && ws.frame < l.outF ? () => say('thing.split') : null,
      keys: keys('thing.split'),
      why: 'The playhead is not inside it',
    ),
    const ContextMenuItem.rule(),
    ContextMenuItem(
      l.hidden ? 'Show' : 'Hide',
      () => say('thing.deactivate'),
      keys: keys('thing.deactivate'),
    ),
    ContextMenuItem(
      'Delete',
      () => say('thing.remove'),
      keys: keys('thing.remove'),
    ),
  ];
}

/// The context menu for a right-click where there is no layer: the empty stage, or the timeline below the rows.
/// It offers what can be done there, as Finder's and Figma's right-click on empty space does.
List<ContextMenuItem> emptyContextMenu(
  BuildContext context,
  WorkspaceController ws,
) {
  final (say, keys) = _commands(context);
  return [
    ContextMenuItem('Paste', () => say('edit.paste'), keys: keys('edit.paste')),
    const ContextMenuItem.rule(),
    ContextMenuItem(
      'Select All',
      ws.layers.isEmpty ? null : () => say('edit.selectAll'),
      keys: keys('edit.selectAll'),
      why: 'No layers',
    ),
    ContextMenuItem(
      'Deselect All',
      ws.selected == null && ws.many.isEmpty
          ? null
          : () => say('edit.deselectAll'),
      keys: keys('edit.deselectAll'),
      why: 'Nothing is selected',
    ),
  ];
}

/// The context menu for a right-click on a keyframe or a property lane that has keyframes.
List<ContextMenuItem> keyframeContextMenu(
  BuildContext context,
  WorkspaceController ws,
) {
  final (say, keys) = _commands(context);
  final hasKeys = ws.keys.isNotEmpty;
  return [
    ContextMenuItem(
      'Copy',
      hasKeys ? () => copyKeyframes(ws, ws.keys) : null,
      keys: keys('edit.copy'),
      why: 'No keyframes selected',
    ),
    ContextMenuItem(
      'Paste',
      copiedKeyframes.isNotEmpty ? () => pasteKeyframes(ws) : null,
      keys: keys('edit.paste'),
      why: 'Nothing copied',
    ),
    const ContextMenuItem.rule(),
    ContextMenuItem(
      'Delete',
      hasKeys ? () => removeKeyframes(ws, ws.keys) : null,
      keys: keys('thing.remove'),
      why: 'No keyframes selected',
    ),
  ];
}

// Runs a command by name, and the key bound to it as the menus write it (keymap.dart).
(void Function(String), String Function(String)) _commands(
  BuildContext context,
) {
  final keymap = context.findAncestorStateOfType<WorkspaceState>()?.keymap;
  return (
    (c) => Actions.maybeInvoke(context, CommandIntent(c, false)),
    (c) => keyLabel(keymap?.keyOf(c)),
  );
}
