// The timeline's rows: the order they are laid out in, what each one shows, and the drag that reorders them.
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// The timeline's rows as they are laid out: each layer's own row, then, while it is expanded, a row naming each of
/// its targets and a lane for each of its animated properties.
///
/// The lanes follow Ableton's automation lanes (Live 12 manual 25.5), where every automated envelope has its own lane.
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
  ///
  /// `layer` is the index of the row's layer. `value` is the property a lane shows, and null for the layer's own row.
  /// `aim` is set on a row that names one of the layer's targets; such a row has an empty value and no keyframes.
  List<({int layer, String? value, (String, String)? aim})> get order => _order;
  List<({int layer, String? value, (String, String)? aim})> _order = const [];

  double _lift = 0; // how far a label row has been carried up or down

  // The properties of [l] that have keyframes, in the layer's own order.
  // Ableton does the same with "Show Automated Parameters Only". With Animate on, every property counts as moving, so its keyframes decide.
  List<String> _moving(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null) return const [];
    final moving = m.moving(t).toSet();
    return [
      for (final n in m.values(t))
        if (n.startsWith('js_line_') ||
            moving.contains(n) && m.keyTimes(t, n).isNotEmpty)
          n,
    ];
  }

  /// The title of the inspector card that holds the property [name] of [l]: an effect, or Transform and the like.
  String? laneCard(Layer l, String name) {
    final ws = workspace!;
    return [
      for (final (title, names) in ws.inside!.cards(int.parse(l.id)))
        if (names.contains(name)) title,
    ].firstOrNull;
  }

  /// The lane for the property [name] of [l]: its keyframe times and values, read from the project snapshot without
  /// asking the engine.
  TimelineRow laneRow(Layer l, String name) {
    final ws = workspace!;
    final m = ws.inside!,
        t = int.parse(l.id),
        at = m.keyTimes(t, name),
        vs = m.keyValues(t, name),
        flags = RowFlags(ws);
    final n = math.min(at.length, vs.length);
    final lo = vs.take(n).fold(double.infinity, math.min),
        hi = vs.take(n).fold(-double.infinity, math.max);
    return TimelineRow(
      name: name,
      kind: l.kind,
      inF: l.inF,
      outF: l.outF,
      keys: [
        for (var i = 0; i < n; i++) (at[i] * WorkspaceController.fps).round(),
      ],
      picked: const {},
      tone: l.tone,
      dim: flags.isHidden(l.id) || (flags.anySolo && !flags.isSolo(l.id)),
      locked: flags.isLocked(l.id),
      lane: [
        for (var i = 0; i < n; i++)
          (
            (at[i] * WorkspaceController.fps).round(),
            hi > lo ? (vs[i] - lo) / (hi - lo) : .5,
          ),
      ],
      laneWays: [
        for (var i = 0; i + 1 < n; i++)
          _wayShape(ws, m.easingOf(t, name, at[i])),
      ],
      laneOn: switch (ws.stretch) {
        final s? when s.layer == l.id && s.name == name => [
          for (var i = 0; i < n; i++) (at[i] * WorkspaceController.fps).round(),
        ].indexOf(s.from),
        _ => null,
      },
    );
  }

  // An easing's curve from 0 to 1, as drawn between keyframes.
  List<double> _wayShape(WorkspaceController ws, String way) =>
      way.isEmpty ? const [0, 1] : easeCurve(way, ws.inside!);

  /// The label colours of the layers a behaviour affects, in order, or null for an ordinary layer row (which has a single colour).
  List<Color>? _mixOf(WorkspaceController ws, String id) {
    final m = ws.inside, t = int.tryParse(id);
    if (m == null ||
        t == null ||
        m.word(t, 'kind') != 'behaviour' ||
        !relationKinds.contains(m.word(t, 'file'))) {
      return null;
    }
    return [
      for (final s in m.word(t, 'members').split(' '))
        if (s.isNotEmpty && s != '_') layerLabelColor(s),
    ];
  }

  /// A shape's form name, colour and whether it is an outline, as stored in the project, for the small icon at the row's left.
  /// With no fill, the outline is drawn in the stroke colour.
  (String, Color?, bool)? _formOf(WorkspaceController ws, Layer l) {
    final m = ws.inside, t = int.tryParse(l.id);
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) =>
        hex.length == 6 && int.tryParse(hex, radix: 16) != null
        ? Color(0xFF000000 | int.parse(hex, radix: 16))
        : null;
    final outline = m.word(t, 'fill') == 'none';
    return (
      m.word(t, 'shape'),
      colour(m.word(t, outline ? 'stroke' : 'fill')),
      outline,
    );
  }

  /// Places the rows of the project as it is now, and returns each row as it is drawn, in the same order as [order].
  List<TimelineRow> layOut() {
    final ws = workspace!;
    final away = ws.foldedAway, flags = RowFlags(ws);
    final sel = ws.selected,
        picks = ws.keys,
        lit = {
          ...ws.many,
          ...relationMembers(ws),
          for (final p in [?sel, ...ws.many]) ?away[p],
        };
    // The lit layers are those selected together, those moved by the selected relation, and the closed group a selected layer is in.

    _order = [
      for (final (i, l) in ws.layers.indexed)
        if (!away.containsKey(l.id)) ...[
          (layer: i, value: null, aim: null),
          if (ws.aimsOpen(l.id))
            for (final a in linkTargets(ws, l.id))
              (layer: i, value: '', aim: a),
          if (ws.lanesOpen(l.id))
            for (final n in _moving(ws, l)) (layer: i, value: n, aim: null),
        ],
    ];
    return <TimelineRow>[
      for (final o in order)
        if (o.value case final n?)
          laneRow(ws.layers[o.layer], n)
        else if (ws.layers[o.layer] case final l)
          TimelineRow(
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
            dim: flags.isHidden(l.id) || (flags.anySolo && !flags.isSolo(l.id)),
            locked: flags.isLocked(l.id),
            clipped: l.clipped,
            wave: _media.waveOf(ws, l),
            frames: _media.framesOf(ws, l),
            form: _formOf(ws, l)?.$1,
            fill: _formOf(ws, l)?.$2,
            outline: _formOf(ws, l)?.$3 ?? false,
            tone: l.tone,
            mix: _mixOf(ws, l.id),
            whole: _slip.wholeOf(ws, l),
          ),
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
    if (by != 0) {
      ws.after(
        ws.inside!.later(
          'raise',
          layer: int.parse(l.id),
          number: (by > 0 ? -1 : 1) * _places(ws, l, by).toDouble(),
        ),
      );
    }
  }
}
