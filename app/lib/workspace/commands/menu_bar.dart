// The workspace's commands by name, which a key, a menu item or the command line runs. The menu bar built from them is menu_items.dart.
//
// setState is called from an extension on the State itself, which the analyzer only allows in a class or mixin.
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/commands/command_arrange.dart';
import 'package:motolii/workspace/commands/command_edit.dart';
import 'package:motolii/workspace/commands/command_layers.dart';
import 'package:motolii/workspace/commands/command_actions.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/stage/stage.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/workspace.dart';

extension WorkspaceMenus on WorkspaceState {
  Map<String, VoidCallback> commands() {
    final m = engine!, ws = this.ws;
    void step(int by) {
      ws.playing = false;
      ws.frame = ws.frame + by;
    }

    return {
      'file.new': () {
        open(fresh());
        sizeBoxRequested.value = true; // Ask for its shape and resolution first, as Alight Motion's new-project box does.
      },
      'file.render': () =>
          renderRequested.value++, // Opens the render settings window first.
      'file.exportFrame': exportFrame,
      'file.home': () => setState(() {
        // Save the current project's picture first, so its card shows it as it is.
        keepPoster();
        home = true;
      }),
      'file.poster': () {
        // The frame the project picture is drawn at from now on (Alight Motion's Set Project Thumbnail).
        // The playhead frame is divided by 60 because the preview runs at sixty frames a second.
        if (m.set(0, 'poster_at', ws.frame / 60)) {
          ws.notice = 'Project picture: ${ws.frame}';
        }
      },
      'file.package': package,
      ...editCommands(),
      ...layerCommands(),
      ...arrangeCommands(),
      'play.toggle': () => ws.playing = !ws.playing,
      ...abletonCommands(ws), // Ableton Live's keys: see command_actions.dart.
      ...stageToolCommands(ws), // The canvas tools: see stage.dart.
      'frame.first': () => step(-ws.frame),
      'frame.last': () => step(WorkspaceController.duration - ws.frame),
    };
  }
}
