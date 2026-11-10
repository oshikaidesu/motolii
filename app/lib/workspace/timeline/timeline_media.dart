// What the timeline rows show of their media, requested from the engine once and cached: an audio layer's beats, the
// selected layer's retimed ends, a video's frames, a shape's form, an image's thumbnail and an audio waveform.
// setState is called from an extension on the State itself, which the analyzer only allows inside a class or mixin.
// ignore_for_file: invalid_use_of_protected_member
part of 'timeline.dart';

extension _WsTimelineMedia on _WsTimelineState {
  /// Frames where the selected group's intro ends and its outro starts, for marking on the ruler.
  ///
  /// They are the End of intro and Start of outro values of the group's Element card (the engine's doc_element_clock).
  List<int> _retimedOf(Ws ws) {
    final m = ws.inside, t = int.tryParse(ws.selected ?? '');
    if (m == null || t == null) return const [];
    final start = m.value(t, 'start', 0) ?? 0;
    return [
      for (final n in const ['retime_in', 'retime_out'])
        if ((m.value(t, n, 0) ?? 0) > 0) ((start + m.value(t, n, 0)!) * Ws.fps).round(),
    ];
  }

  /// Frames of the audio beats of every layer that has them, requested from the engine once per read of the project.
  List<int> _beatsOf(Ws ws) {
    final m = ws.inside;
    if (m == null) return const [];
    if (_beats case (final r, final b) when r == ws.reads) return b;
    if (_beatsAsked == ws.reads) return _beats?.$2 ?? const [];
    final asks = <Future<List<double>>>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id), rise = t == null ? 0.0 : m.value(t, 'beats', 0) ?? 0;
      if (rise > 0 && _waveOf(ws, l) != null) asks.add(m.strikes(t!, rise)); // Only after its sound has been read.
    }
    final reads = _beatsAsked = ws.reads;
    Future.wait(asks).then(
      (all) => mounted
          ? setState(
              () => _beats = (
                reads,
                ws.strikes = [
                  for (final s in all)
                    for (final at in s) (at * Ws.fps).round(),
                ],
              ),
            )
          : null,
    );
    return _beats?.$2 ?? const [];
  }

  /// A few frames to draw along a video layer's bar, or the thumbnail of an image layer; null if there are none.
  List<ui.Image>? _framesOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m != null && t != null && m.word(t, 'kind') == 'picture') return _stillOf(m.whole(m.word(t, 'file')), l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final file = m.whole(m.word(t, 'file')), begin = m.value(t, 'begin', 0) ?? 0, speed = m.value(t, 'speed', 0) ?? 1, start = m.value(t, 'start', 0) ?? 0;
    final key = (file, begin, speed, start, l.inF, l.outF);
    if (_frames[l.id] case (final k, final f) when k == key) return f;
    if (_framesAsked[l.id] != key) {
      _framesAsked[l.id] = key;
      const n = 6;
      final lasts = (l.outF - l.inF) / Ws.fps;
      final seconds = [for (var i = 0; i < n; i++) begin + (speed < 0 ? lasts - (i + .5) / n * lasts : (i + .5) / n * lasts) * speed.abs()];
      Future.wait([for (final s in seconds) m.videoFrame(file, s)]).then((pngs) async {
        // No frames could be read: the file has sound only.
        if (pngs.any((p) => p == null)) return mounted ? setState(() => _frames[l.id] = (key, null)) : null;
        final read = [for (final p in pngs) (await (await ui.instantiateImageCodec(File(p!).readAsBytesSync())).getNextFrame()).image];
        if (mounted) setState(() => _frames[l.id] = (key, read));
      });
    }
    return _frames[l.id]?.$2;
  }

  /// A shape's form name, colour and whether it is an outline, as stored in the project, for the small icon at the row's left.
  /// With no fill, the outline is drawn in the stroke colour.
  (String, Color?, bool)? _formOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) => hex.length == 6 && int.tryParse(hex, radix: 16) != null ? Color(0xFF000000 | int.parse(hex, radix: 16)) : null;
    final outline = m.word(t, 'fill') == 'none';
    return (m.word(t, 'shape'), colour(m.word(t, outline ? 'stroke' : 'fill')), outline);
  }

  /// The image of an image layer, decoded once at a small height and repeated along the bar as in Alight Motion
  /// (see docs/internal/reports/alight_motion/alight_ui.md). Null if Flutter cannot decode the file.
  List<ui.Image>? _stillOf(String file, String id) {
    if (_frames[id] case (final k, final f) when k == file) return f;
    if (_framesAsked[id] != file) {
      _framesAsked[id] = file;
      () async {
        try {
          final read = (await (await ui.instantiateImageCodec(await File(file).readAsBytes(), targetHeight: 48)).getNextFrame()).image;
          if (mounted) setState(() => _frames[id] = (file, [read]));
        } catch (_) {
          if (mounted) setState(() => _frames[id] = (file, null));
        }
      }();
    }
    return _frames[id]?.$2;
  }

  /// The loudness of a video layer's sound over its bar, or null while it is unknown or the layer has no sound.
  List<double>? _waveOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final key = (ws.reads, l.inF, l.outF);
    final had = _waves[l.id];
    if (had case (final r, final a, final b, final w) when (r, a, b) == key) return w;
    if (_waveAsked[l.id] != key) {
      // The engine answers on another isolate; the waveform is drawn on the bar when the answer arrives.
      _waveAsked[l.id] = key;
      m.loudnessOver(t, l.inF / Ws.fps, l.outF / Ws.fps, l.outF - l.inF).then((w) {
        if (!mounted) return;
        if (w == null) {
          if (_asked.add(l.id)) m.loudness(t).then((_) => mounted ? setState(() => (_waveAsked.remove(l.id), _beats = null, _beatsAsked = null)) : null);
          return;
        }
        setState(
          () => (_waves[l.id] = (key.$1, key.$2, key.$3, w.isEmpty ? null : w), _beats = null, _beatsAsked = null),
        ); // The sound has now been read, so the beats are requested again.
      });
    }
    return had?.$4;
  }
}
