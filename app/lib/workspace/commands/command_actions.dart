// The window's keys as Ableton Live 12 has them (its reference manual, chapter 42 "Live Keyboard Shortcuts":
// www.ableton.com/en/manual/live-keyboard-shortcuts/), each said beside the section it comes from; where Live has no
// such key, the tool that has one is named. The commands here are what each does to the window's state; keymap.dart
// says which key says which, and the maker's keybindings.json may say otherwise.
import '../state/state.dart';

/// Where playing began (Live 42.20: Space plays from the start marker and stops back there; Shift+Space goes on from
/// where it stopped).
int? _playFrom;

Map<String, void Function()> wsAbletonCommands(Ws ws) {
  void step(int by) {
    ws.playing = false;
    ws.frame = ws.frame + by;
  }

  /// The playhead on the nearest stop that way (After Effects' J and K).
  void hop(int way) {
    final all = ws.stops().where((f) => (f - ws.frame) * way > 0).toList()..sort();
    if (all.isNotEmpty) step((way > 0 ? all.first : all.last) - ws.frame);
  }

  /// The picked thing's bar carried [by] frames (Live 42.16: Nudge Selection Left/Right); with nothing picked, the playhead.
  void nudge(int by) {
    final m = ws.inside;
    if (m == null) return;
    final t = int.tryParse(ws.selected ?? '');
    if (t == null) return step(by);
    m.take(t);
    m.dragUpdate('bar', by / Ws.fps);
    ws.after(m.later('drag_end', number: 1));
  }

  /// The row above or below the picked one picked (Live 42.15/42.16: the arrow keys move between tracks).
  void row(int by) {
    if (ws.layers.isEmpty) return;
    final i = ws.layers.indexWhere((l) => l.id == ws.selected);
    ws.select(ws.layers[(i < 0 ? 0 : i + by).clamp(0, ws.layers.length - 1)].id);
  }

  return {
    'play.fromStart': () {
      // (Live 42.20 Space: play from the start marker / stop, back at it)
      if (ws.playing) {
        ws.playing = false;
        if (_playFrom case final f?) ws.frame = f;
      } else {
        _playFrom = ws.frame;
        ws.playing = true;
      }
    },
    'play.continue': () {
      // (Live 42.20 Shift+Space: continue play from the stop point)
      _playFrom = null;
      ws.playing = !ws.playing;
    },
    for (final (n, by) in [('left', -1), ('right', 1), ('left10', -10), ('right10', 10)]) 'nudge.$n': () => nudge(by),
    for (final (n, by) in [('previous', -1), ('next', 1)]) 'layer.$n': () => row(by),
    'mark.animate': () => ws.animating = !ws.animating, // (Apple Motion's A: Record Animation, the inspector's Animate all)
    for (final (n, by) in [('previous', -1), ('next', 1)]) 'frame.$n': () => step(by), // (Live has no frame step; Rive's and Jitter's , and .)
    for (final (n, by) in [('previousStop', -1), ('nextStop', 1)]) 'frame.$n': () => hop(by),
    for (final (n, by) in [('back10', -10), ('forward10', 10)]) 'frame.$n': () => step(by),
    'frame.first': () => step(-ws.frame),
    'frame.last': () => step(Ws.duration - ws.frame),
  };
}
