// The playhead (Playhead): the current frame, and whether the preview is playing.
import 'package:flutter/foundation.dart' show ValueNotifier, VoidCallback;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/composition_settings.dart';

/// The playhead: the frame the window shows, and whether the preview is playing.
class Playhead {
  /// Creates a playhead that is stopped. [onPlayingChanged] is called when playback starts or stops.
  Playhead({
    required this._engine,
    required this._composition,
    required this._onPlayingChanged,
  });

  final Motolii? Function() _engine;
  final CompositionSettings _composition;
  final VoidCallback _onPlayingChanged;

  /// The playhead frame. It is a separate notifier, so only widgets that show the current time listen to it
  /// (`WorkspaceScope.frameOf`) and the rest of the window is not rebuilt as it moves.
  final moment = ValueNotifier<int>(112);

  /// The playhead frame. Setting it keeps it inside the composition and, while stopped, moves the preview there.
  int get frame => moment.value;
  set frame(int f) {
    final v = f.clamp(0, _composition.duration);
    if (v == moment.value) return;
    moment.value = v;
    if (!_playing) {
      // While stopped, the preview jumps to the new time.
      _engine()?.at(v / _composition.frameRate);
    }
  }

  bool _playing = false;

  /// Whether the preview is playing.
  bool get playing => _playing;
  set playing(bool p) {
    if (p == _playing) return;
    _playing = p;
    if (p) _engine()?.at(frame / _composition.frameRate);
    // The engine keeps the clock and the playhead follows it (see timeline.dart).
    _engine()?.play(p);
    // The clock can run ahead of a preview that is late with its frames, so on stop it returns to the playhead.
    if (!p) _engine()?.at(frame / _composition.frameRate);
    _onPlayingChanged();
  }

  /// The frames where sounds strike, as the timeline last computed them for its beats.
  List<int> strikes = const [];

  /// Frame [f], or the playhead when null, written as minutes, seconds and frames.
  String timecode([int? f]) {
    final v = f ?? frame,
        s = v ~/ _composition.frameRate,
        fr = v % _composition.frameRate;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}:${fr.toString().padLeft(2, '0')}';
  }

  /// Releases the frame notifier.
  void dispose() => moment.dispose();
}
