// The timeline's rows: the order they are laid out in, what each one shows, and the drag that reorders them.
import 'dart:math' as math;

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/audio_fade.dart'
    show layerHasAudio, readAudioFade;
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// The timeline's rows as they are laid out: each layer's own row, then, while it is expanded, a row naming each of
/// its targets and a lane for each of its animated properties.
/// The lanes follow Ableton's automation lanes, where every automated envelope has its own lane.
class TimelineRows {
  /// The rows of the workspace that `workspaceOf` returns, placed by `viewport`, showing what `media` and `slip`
  /// have read of each layer's file.
  TimelineRows({
    required this._workspaceOf,
    required this._viewport,
    required this._media,
    required this._slip,
  });

  final WorkspaceController? Function() _workspaceOf;
  final TimelineViewport _viewport;
  final TimelineMediaCache _media;
  final SlipEdit _slip;

  /// The workspace the timeline is shown in, read each time it is needed.
  WorkspaceController? get workspace => _workspaceOf();

  /// The rows in the order [layOut] last placed them, from the top.
  /// `layer` is the index of the row's layer. `value` is the property a lane shows, and null for the layer's own row.
  /// `aim` is set on a row that names one of the layer's targets; such a row has an empty value and no keyframes.
  List<({int layer, String? value, (String, int)? aim})> get order => _order;
  List<({int layer, String? value, (String, int)? aim})> _order = const [];

  double _lift = 0; // how far a label row has been carried up or down

  /// The lane for the property [name] of [l]: its keyframe times and values as the window last read them.
  TimelineRow laneRow(Layer l, String name) {
    final ws = workspace!, flags = RowFlags(ws);
    final lane = l.lanes.where((a) => a.name == name).firstOrNull;
    if (lane == null) {
      return TimelineRow(
        name: name,
        kind: l.kind,
        inF: l.inF,
        outF: l.outF,
        keys: const [],
        picked: const {},
        lane: const [],
      );
    }
    final keys = [
      for (final s in lane.at) (s * WorkspaceController.fps).round(),
    ];
    final lo = lane.values.fold(double.infinity, math.min),
        hi = lane.values.fold(-double.infinity, math.max);
    return TimelineRow(
      name: name,
      kind: l.kind,
      inF: l.inF,
      outF: l.outF,
      keys: keys,
      picked: const {},
      tone: l.tone,
      dim: flags.isHidden(l.id) || (flags.anySolo && !flags.isSolo(l.id)),
      locked: flags.isLocked(l.id),
      lane: [
        for (final (i, v) in lane.values.indexed)
          (keys[i], hi > lo ? (v - lo) / (hi - lo) : .5),
      ],
      laneWays: lane.curves,
      laneOn: switch (ws.stretches
          .where((s) => s.layer == l.id && s.name == name)
          .firstOrNull) {
        final s? => keys.indexOf(s.from),
        _ => null,
      },
    );
  }

  /// Places the rows of the project as it is now, and returns each row as it is drawn, in the same order as [order].
  List<TimelineRow> layOut() {
    final ws = workspace!;
    final away = ws.foldedAway, flags = RowFlags(ws);
    final sel = ws.selected,
        picks = ws.keys,
        ids = {for (final l in ws.layers) l.id},
        lit = {
          ...ws.many,
          // The layers the selected relation moves.
          for (final id in ws.layer?.members ?? const <int>[])
            if (ids.contains(id)) id,
          for (final p in [?sel, ...ws.many]) ?away[p],
        };
    // The lit layers are those selected together, those moved by the selected relation, and the closed group a selected layer is in.

    _order = [
      for (final (i, l) in ws.layers.indexed)
        if (!away.containsKey(l.id)) ...[
          (layer: i, value: null, aim: null),
          if (ws.aimsOpen(l.id))
            for (final a in l.links) (layer: i, value: '', aim: a),
          if (ws.lanesOpen(l.id))
            for (final a in l.lanes) (layer: i, value: a.name, aim: null),
        ],
    ];
    return <TimelineRow>[
      for (final o in order)
        if (o.value case final n?)
          laneRow(ws.layers[o.layer], n)
        else if (ws.layers[o.layer] case final l)
          () {
            final wave = _media.waveOf(ws, l);
            final audio = layerHasAudio(l) || wave != null;
            final fade = audio
                ? readAudioFade(l, fps: WorkspaceController.fps)
                : (fadeInF: 0, fadeOutF: 0, peak: 1.0);
            return TimelineRow(
              id: l.id,
              name: l.name,
              kind: l.kind,
              inF: l.inF,
              outF: l.outF,
              keys: l.keys,
              stretches: l.stretches,
              picked: {
                for (final k in picks)
                  if (k.layer == l.id) k.frame,
              },
              selected: l.id == sel || lit.contains(l.id),
              dim:
                  (l.kind != LayerKind.audio && flags.isHidden(l.id)) ||
                  (flags.anySolo && !flags.isSolo(l.id)),
              locked: flags.isLocked(l.id),
              clipped: l.clipped,
              hasAudio: audio,
              fadeInF: fade.fadeInF,
              fadeOutF: fade.fadeOutF,
              wave: wave,
              frames: _media.framesOf(ws, l),
              form: l.form?.shape,
              fill: l.form?.colour,
              outline: l.form?.outline ?? false,
              tone: l.tone,
              mix: switch (l.members) {
                final ms? => [for (final s in ms) layerLabelColor(s)],
                null => null,
              },
              whole: _slip.wholeOf(ws, l),
            );
          }(),
    ];
  }

  /// The row at vertical position [y]: its index, its layer, and the property it shows.
  /// The property is null for the layer's own row.
  ({int i, Layer l, String? value})? rowAt(double y) {
    final i = ((y + _viewport.verticalScroll) / TimelineMetrics.row).floor();
    if (i < 0 || i >= order.length) return null;
    return (i: i, l: workspace!.layers[order[i].layer], value: order[i].value);
  }

  /// How many layers a row dragged by [by] rows moves past. A collapsed group counts as itself plus all its members.
  int _places(WorkspaceController ws, Layer l, int by) {
    final away = ws.foldedAway,
        seen = [
          for (final o in order)
            if (o.value == null) ws.layers[o.layer].id,
        ],
        at = seen.indexOf(l.id);
    final past = by > 0
        ? seen.sublist(at + 1, math.min(at + 1 + by, seen.length))
        : seen.sublist(math.max(0, at + by), at);
    return past.fold(
      0,
      (n, id) => n + 1 + away.values.where((g) => g == id).length,
    );
  }

  /// A drag of a row's label up or down starts.
  void reorderStart() => _lift = 0;

  /// The label being dragged was carried [dy] pixels further down, or up when negative.
  void reorderBy(double dy) => _lift += dy;

  /// The drag of the label of [l] ended: moves the layer forward or back by as many rows as it was dragged.
  void reorderEnd(Layer l) {
    final ws = workspace!;
    final by = (_lift / TimelineMetrics.row).round();
    _lift = 0;
    if (by != 0) {
      ws.after(
        timeline_service.reorderLayer(
          ws,
          l.id,
          (by > 0 ? -1 : 1) * _places(ws, l, by).toDouble(),
        ),
      );
    }
  }

  /// Escape pressed while dragging: cancel without reordering.
  void reorderCancel() => _lift = 0;
}
