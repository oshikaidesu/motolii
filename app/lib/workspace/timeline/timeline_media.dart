// What the timeline's rows show of their media, asked of the inside once and kept: a sound's beats, the picked one's
// retimed ends, a film's frames, a shape's form, a still, a sound's wave.
// (setState from an extension on the State itself: the analyzer allows it only in a class or mixin)
// ignore_for_file: invalid_use_of_protected_member
part of 'timeline.dart';

extension _WsTimelineMedia on _WsTimelineState {
  // The picked group's end of intro and start of outro, kept with it as an element (its Element card's End of intro,
  // Start of outro: doc_element_clock), where they fall on the ruler.
  List<int> _retimedOf(Ws ws) {
    final m = ws.inside, t = int.tryParse(ws.selected ?? '');
    if (m == null || t == null) return const [];
    final start = m.value(t, 'start', 0) ?? 0;
    return [
      for (final n in const ['retime_in', 'retime_out'])
        if ((m.value(t, n, 0) ?? 0) > 0) ((start + m.value(t, n, 0)!) * Ws.fps).round(),
    ];
  }

  List<int> _beatsOf(Ws ws) {
    final m = ws.inside;
    if (m == null) return const [];
    if (_beats case (final r, final b) when r == ws.reads) return b;
    if (_beatsAsked == ws.reads) return _beats?.$2 ?? const [];
    final asks = <Future<List<double>>>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id), rise = t == null ? 0.0 : m.value(t, 'beats', 0) ?? 0;
      if (rise > 0 && _waveOf(ws, l) != null) asks.add(m.strikes(t!, rise)); // (only once its sound is read)
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
        if (pngs.any((p) => p == null)) return mounted ? setState(() => _frames[l.id] = (key, null)) : null; // (no pictures: its sound alone)
        final read = [for (final p in pngs) (await (await ui.instantiateImageCodec(File(p!).readAsBytesSync())).getNextFrame()).image];
        if (mounted) setState(() => _frames[l.id] = (key, read));
      });
    }
    return _frames[l.id]?.$2;
  }

  // A shape's form and its fill, as the document says them: its own small picture at the row's left.
  // (no fill: its outline in its stroke's colour)
  (String, Color?, bool)? _formOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) => hex.length == 6 && int.tryParse(hex, radix: 16) != null ? Color(0xFF000000 | int.parse(hex, radix: 16)) : null;
    final outline = m.word(t, 'fill') == 'none';
    return (m.word(t, 'shape'), colour(m.word(t, outline ? 'stroke' : 'fill')), outline);
  }

  // A photo on its bar: itself, read once small (as tall as a bar needs), laid along the bar again and again as
  // Alight Motion's photo bar is (docs/internal/reports/alight_motion/alight_ui.md: タイムラインの絵); one Flutter cannot read: none.
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

  List<double>? _waveOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final key = (ws.reads, l.inF, l.outF);
    final had = _waves[l.id];
    if (had case (final r, final a, final b, final w) when (r, a, b) == key) return w;
    if (_waveAsked[l.id] != key) {
      // (a question of the inside, another isolate: laid on the bar when it comes)
      _waveAsked[l.id] = key;
      m.loudnessOver(t, l.inF / Ws.fps, l.outF / Ws.fps, l.outF - l.inF).then((w) {
        if (!mounted) return;
        if (w == null) {
          if (_asked.add(l.id)) m.loudness(t).then((_) => mounted ? setState(() => (_waveAsked.remove(l.id), _beats = null, _beatsAsked = null)) : null);
          return;
        }
        setState(
          () => (_waves[l.id] = (key.$1, key.$2, key.$3, w.isEmpty ? null : w), _beats = null, _beatsAsked = null),
        ); // (its sound now read: the beats asked again)
      });
    }
    return had?.$4;
  }
}
