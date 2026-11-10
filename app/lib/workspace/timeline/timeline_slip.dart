// Slip editing for video layers that are trimmed shorter than the source file.
//
// The part of the source outside the trim is drawn as a pale bar along the row. Dragging it changes which part of the
// source the layer shows, while the layer's in and out points stay where they are.
// This follows After Effects' slip edit and Premiere Pro's Slip tool.
import 'dart:math' as math;

import 'package:motolii/bridge/motolii.dart' show Motolii, mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline.dart';

// ignore_for_file: invalid_use_of_protected_member

extension WsTimelineSlip on WsTimelineState {
  /// The frame range the whole source file would cover at the layer's current trim, or null.
  ///
  /// It is null when the layer is not a video or the file's length has not been read yet.
  (int, int)? wholeOf(Ws ws, WsLayer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'film') return null;
    final said = m.word(t, 'file'), file = said.startsWith('/') ? said : '${m.home}/$said';
    final seconds = filmSeconds[file];
    if (seconds == null) {
      filmSeconds[file] = 0;
      mediaSecondsOf(m.libPath, file).then((s) => mounted ? setState(() => filmSeconds[file] = s) : null);
    }
    if (seconds == null || seconds <= 0) return null;
    final rate = Ws.fps / _speedOf(m, t), from = l.inF - (m.value(t, 'begin', 0) ?? 0) * rate;
    return (from.round(), (from + seconds * rate).round());
  }

  double _speedOf(Motolii m, int t) => switch ((m.value(t, 'speed', 0) ?? 1).abs()) {
    0 => 1,
    final s => s,
  };

  void slip(Ws ws, int t, int by) {
    final whole = barWhole, m = ws.inside!;
    if (whole == null) return;
    final to = by.clamp(math.min(0, barOut - whole.$2), math.max(0, barIn - whole.$1));
    m.dragUpdate('begin', (barIn - whole.$1 - to) * _speedOf(m, t) / Ws.fps);
    setState(() {});
  }
}
