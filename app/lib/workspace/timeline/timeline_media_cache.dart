// What the timeline's rows show of their media, requested from the engine once and kept: the beats of the layers'
// sound, a video's frames, an image's thumbnail, a sound's waveform and the length of a video file.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The media the timeline has read for its rows, kept until the project changes.
///
/// Each getter answers at once with what is known and asks the engine for what is missing. The engine answers on
/// another isolate, and the listeners are notified when an answer has been stored. After [dispose] late answers are
/// dropped.
class TimelineMediaCache extends ChangeNotifier {
  // The videos' beats (from their Beats property, computed by the engine).
  // They are requested from the engine on another isolate, only when the project changes, and shown when they arrive.
  (int, List<int>)? _beats;
  int? _beatsAsked;
  // A video's thumbnails on its bar: one frame from the middle of each sixth of the video, whatever its start or speed.
  // The engine makes them small (GStreamer, on another isolate) and the app reads them as images.
  // They are requested again only when the project changes.
  final _frames = <String, (Object, List<ui.Image>?)>{};
  final _framesAsked = <String, Object>{};
  // A video's waveform on its bar: read once on another isolate, then laid on the project's frames where the video plays.
  // It is requested again only when the project changes.
  // Per layer id: the project read, the from and to frames, and the loudness of each frame.
  final _waves = <String, (int, int, int, List<double>?)>{};
  final _asked = <String>{};
  final _waveAsked = <String, (int, int, int)>{};
  // The length of each video file in seconds; 0 while it is being read.
  final _filmSeconds = <String, double>{};

  bool _disposed = false;

  // Applies [change] and notifies the listeners, unless the timeline that owned this cache is gone.
  void _set(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Frames of the audio beats of every layer that has them, requested from the engine once per read of the project.
  List<int> beatsOf(WorkspaceController ws) {
    final m = ws.inside;
    if (m == null) return const [];
    if (_beats case (final r, final b) when r == ws.reads) return b;
    if (_beatsAsked == ws.reads) return _beats?.$2 ?? const [];
    final asks = <Future<List<double>>>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id),
          rise = t == null ? 0.0 : m.value(t, 'beats', 0) ?? 0;
      if (rise > 0 && waveOf(ws, l) != null) {
        asks.add(m.strikes(t!, rise)); // Only after its sound has been read.
      }
    }
    final reads = _beatsAsked = ws.reads;
    Future.wait(asks).then(
      (all) => _set(
        () => _beats = (
          reads,
          ws.strikes = [
            for (final s in all)
              for (final at in s) (at * WorkspaceController.fps).round(),
          ],
        ),
      ),
    );
    return _beats?.$2 ?? const [];
  }

  /// A few frames to draw along a video layer's bar, or the thumbnail of an image layer; null if there are none.
  List<ui.Image>? framesOf(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m != null && t != null && m.word(t, 'kind') == 'picture') {
      return _stillOf(m.whole(m.word(t, 'file')), l.id);
    }
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final file = m.whole(m.word(t, 'file')),
        begin = m.value(t, 'begin', 0) ?? 0,
        speed = m.value(t, 'speed', 0) ?? 1,
        start = m.value(t, 'start', 0) ?? 0;
    final key = (file, begin, speed, start, l.inF, l.outF);
    if (_frames[l.id] case (final k, final f) when k == key) return f;
    if (_framesAsked[l.id] != key) {
      _framesAsked[l.id] = key;
      const n = 6;
      final lasts = (l.outF - l.inF) / WorkspaceController.fps;
      final seconds = [
        for (var i = 0; i < n; i++)
          begin +
              (speed < 0
                      ? lasts - (i + .5) / n * lasts
                      : (i + .5) / n * lasts) *
                  speed.abs(),
      ];
      Future.wait([for (final s in seconds) m.videoFrame(file, s)])
          .then((pngs) async {
            // No frames could be read: the file has sound only.
            if (pngs.any((p) => p == null)) {
              return _set(() => _frames[l.id] = (key, null));
            }
            final read = [
              for (final p in pngs)
                (await (await ui.instantiateImageCodec(
                  File(p!).readAsBytesSync(),
                )).getNextFrame()).image,
            ];
            _set(() => _frames[l.id] = (key, read));
          });
    }
    return _frames[l.id]?.$2;
  }

  /// The image of an image layer, decoded once at a small height and repeated along the bar as in Alight Motion
  /// (see docs/design/alight_motion_ui.md). Null if Flutter cannot decode the file.
  List<ui.Image>? _stillOf(String file, String id) {
    if (_frames[id] case (final k, final f) when k == file) return f;
    if (_framesAsked[id] != file) {
      _framesAsked[id] = file;
      () async {
        try {
          final read = (await (await ui.instantiateImageCodec(
            await File(file).readAsBytes(),
            targetHeight: 48,
          )).getNextFrame()).image;
          _set(() => _frames[id] = (file, [read]));
        } catch (_) {
          _set(() => _frames[id] = (file, null));
        }
      }();
    }
    return _frames[id]?.$2;
  }

  /// The loudness of a video layer's sound over its bar, or null while it is unknown or the layer has no sound.
  List<double>? waveOf(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final key = (ws.reads, l.inF, l.outF);
    final had = _waves[l.id];
    if (had case (final r, final a, final b, final w) when (r, a, b) == key) {
      return w;
    }
    if (_waveAsked[l.id] != key) {
      // The engine answers on another isolate; the waveform is drawn on the bar when the answer arrives.
      _waveAsked[l.id] = key;
      m
          .loudnessOver(
            t,
            l.inF / WorkspaceController.fps,
            l.outF / WorkspaceController.fps,
            l.outF - l.inF,
          )
          .then((w) {
            if (_disposed) return;
            if (w == null) {
              if (_asked.add(l.id)) {
                m
                    .loudness(t)
                    .then(
                      (_) => _set(
                        () => (
                          _waveAsked.remove(l.id),
                          _beats = null,
                          _beatsAsked = null,
                        ),
                      ),
                    );
              }
              return;
            }
            _set(
              () => (
                _waves[l.id] = (key.$1, key.$2, key.$3, w.isEmpty ? null : w),
                _beats = null,
                _beatsAsked = null,
              ),
            ); // The sound has now been read, so the beats are requested again.
          });
    }
    return had?.$4;
  }

  /// The length of the video [file] in seconds: null the first time it is asked for, 0 until it has been read.
  double? secondsOf(Motolii m, String file) {
    final seconds = _filmSeconds[file];
    if (seconds == null) {
      _filmSeconds[file] = 0;
      mediaSecondsOf(
        m.libPath,
        file,
      ).then((s) => _set(() => _filmSeconds[file] = s));
    }
    return seconds;
  }
}
