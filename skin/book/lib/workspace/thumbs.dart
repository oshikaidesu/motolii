// thumbs.dart: a thing's small picture, as the timeline shows it at the head of its row (WtThumb) and the inspector
// shows a group's things on its Copies card: a film's pictures along its bar, a photo itself, a shape's form in its
// fill. Read once and kept here; the one who holds this is told when a picture has come in, to draw again.
// (moved out of timeline.dart as it was there, so the two draw the same picture from the same reads)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'ws.dart';

class WsThumbs {
  WsThumbs({required this.onLoaded, required this.mounted});
  final VoidCallback onLoaded;   // (a picture has come in: draw again)
  final bool Function() mounted;

  // A film's pictures on its bar: the one it plays in the middle of each sixth of it (its begin, its speed, either way),
  // made small by the inside (GStreamer, another isolate) and read as pictures; asked again only when the document changes.
  final _frames = <String, (Object, List<ui.Image>?)>{};
  final _framesAsked = <String, Object>{};
  List<ui.Image>? framesOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m != null && t != null && m.word(t, 'kind') == 'picture') return stillOf(m.whole(m.word(t, 'file')), l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final file = m.whole(m.word(t, 'file')), begin = m.value(t, 'begin', 0) ?? 0, speed = m.value(t, 'speed', 0) ?? 1, start = m.value(t, 'start', 0) ?? 0;
    final key = (file, begin, speed, start, l.inF, l.outF);
    if (_frames[l.id] case (final k, final f) when k == key) return f;
    if (_framesAsked[l.id] != key) {
      _framesAsked[l.id] = key;
      const n = 6;
      final lasts = (l.outF - l.inF) / Ws.fps;
      final seconds = [for (var i = 0; i < n; i++) begin + (speed < 0 ? lasts - (i + .5) / n * lasts : (i + .5) / n * lasts) * speed.abs()];
      Future.wait([for (final s in seconds) m.filmFrame(file, s)]).then((pngs) async {
        if (pngs.any((p) => p == null)) return _got(l.id, key, null);   // (no pictures: its sound alone)
        final read = [for (final p in pngs) (await (await ui.instantiateImageCodec(File(p!).readAsBytesSync())).getNextFrame()).image];
        _got(l.id, key, read);
      });
    }
    return _frames[l.id]?.$2;
  }

  // A shape's form and its fill, as the document says them: its own small picture at the row's left.
  // (no fill: its outline in its stroke's colour)
  (String, Color?, bool)? formOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) => hex.length == 6 && int.tryParse(hex, radix: 16) != null ? Color(0xFF000000 | int.parse(hex, radix: 16)) : null;
    final outline = m.word(t, 'fill') == 'none';
    return (m.word(t, 'shape'), colour(m.word(t, outline ? 'stroke' : 'fill')), outline);
  }

  // A photo on its bar: itself, read once small (as tall as a bar needs), laid along the bar again and again as
  // Alight Motion's photo bar is (reports/alight_ui.md: タイムラインの絵); one Flutter cannot read: none.
  List<ui.Image>? stillOf(String file, String id) {
    if (_frames[id] case (final k, final f) when k == file) return f;
    if (_framesAsked[id] != file) {
      _framesAsked[id] = file;
      () async {
        try {
          final read = (await (await ui.instantiateImageCodec(await File(file).readAsBytes(), targetHeight: 48)).getNextFrame()).image;
          _got(id, file, [read]);
        } catch (_) {
          _got(id, file, null);
        }
      }();
    }
    return _frames[id]?.$2;
  }

  void _got(String id, Object key, List<ui.Image>? pictures) {
    if (!mounted()) return;
    _frames[id] = (key, pictures);
    onLoaded();
  }
}
