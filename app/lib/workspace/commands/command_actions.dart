// Keyboard commands that follow Ableton Live 12.
//
// Source: the Live reference manual, chapter 42 "Live Keyboard Shortcuts" (www.ableton.com/en/manual/live-keyboard-shortcuts/).
// Each command names the manual section it comes from. Where Live has no such key, the app that does is named.
// This file defines what each command does to the workspace state. keymap.dart maps keys to commands,
// and the user's keybindings.json can override that mapping.
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/edits/keyframe_edits.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_writes.dart';

/// The frame where playback started.
///
/// Live 42.20: Space plays from the start marker and stops back there. Shift+Space continues from where playback stopped.
int? _playFrom;

Map<String, void Function()> abletonCommands(WorkspaceController ws) {
  void step(int by) {
    ws.playing = false;
    ws.frame = ws.frame + by;
  }

  /// Moves the playhead to the nearest stop in direction [way] (After Effects' J and K).
  void hop(int way) {
    final all = ws.stops().where((f) => (f - ws.frame) * way > 0).toList()..sort();
    if (all.isNotEmpty) step((way > 0 ? all.first : all.last) - ws.frame);
  }

  /// Moves the selected keyframes by [by] frames, else the selected layer's bar. With nothing selected it moves the playhead.
  ///
  /// Live 42.16: Nudge Selection Left/Right. Live moves its insert marker the same way.
  void nudge(int by) {
    final m = ws.inside;
    if (m == null) return;
    if (ws.keys.isNotEmpty) {
      slideKeyframes(ws, ws.keys.toList(), by);
      ws.pickKeys([
        for (final k in ws.keys) (layer: k.layer, frame: (k.frame + by).clamp(0, WorkspaceController.duration)),
      ]); // The keyframes stay selected at their new frames.
      return;
    }
    final t = int.tryParse(ws.selected ?? '');
    if (t == null) return step(by);
    m.take(t);
    m.dragUpdate('bar', by / WorkspaceController.fps);
    ws.after(m.later('drag_end', number: 1));
  }

  /// Selects the layer [by] rows from the selected one (Live 42.15 and 42.16: the arrow keys move between tracks).
  void row(int by) {
    if (ws.layers.isEmpty) return;
    final i = ws.layers.indexWhere((l) => l.id == ws.selected);
    ws.select(ws.layers[(i < 0 ? 0 : i + by).clamp(0, ws.layers.length - 1)].id);
  }

  return {
    'play.fromStart': () {
      // Live 42.20 Space: play from the start marker, or stop and return to it.
      if (ws.playing) {
        ws.playing = false;
        if (_playFrom case final f?) ws.frame = f;
      } else {
        _playFrom = ws.frame;
        ws.playing = true;
      }
    },
    'play.continue': () {
      // Live 42.20 Shift+Space: continue playing from where it stopped.
      _playFrom = null;
      ws.playing = !ws.playing;
    },
    'nudge.left': () => nudge(-1),
    'nudge.right': () => nudge(1),
    'nudge.left10': () => nudge(-10),
    'nudge.right10': () => nudge(10),
    'layer.previous': () => row(-1),
    'layer.next': () => row(1),
    // Live 42.5 and 42.19 Cmd+R: renames the selected track, or the selected locator.
    'thing.rename': () => ws.selected == null && selectedMarker.value == null ? null : renameRequested.value++,
    'thing.solo': () {
      // Live 42.15 and 42.19 S: solo the selected tracks.
      final t = int.tryParse(ws.selected ?? ''), m = ws.inside;
      if (t == null || m == null) return;
      ws.after(m.later('set', layer: t, name: 'solo', number: ws.layer?.solo == true ? 0 : 1));
    },
    'thing.lanes': () {
      // After Effects' U: shows the keyframed properties of the selected layers, and hides them when pressed again.
      final ids = {...ws.many, ?ws.selected};
      if (ids.isNotEmpty) ws.twirl(ids);
    },
    // Apple Motion's A (Mark > Record Animation). The top bar's Animate and the inspector's Animate All do the same.
    'mark.animate': () => ws.animating = !ws.animating,
    'loop.toggle': () => requestTimeline('loop'), // Live 42.16 Cmd+L: toggle the loop brace.
    'zoom.in': () => requestTimeline('in'), // Live 42.9 +: zoom in on the time ruler.
    'zoom.out': () => requestTimeline('out'), // Live 42.9 -.
    'zoom.selection': () => requestTimeline('selection'), // Live 42.16 Z: zoom to the time selection.
    'zoom.back': () => requestTimeline('back'), // Live 42.16 X: zoom back.
    'zoom.width': () => requestTimeline('fit'), // Live 42.16 W: fit the whole width.
    // Live has no frame step. These are the Rive and Jitter keys, comma and period.
    'frame.previous': () => step(-1),
    'frame.next': () => step(1),
    'frame.previousStop': () => hop(-1),
    'frame.nextStop': () => hop(1),
    'frame.back10': () => step(-10),
    'frame.forward10': () => step(10),
  };
}
