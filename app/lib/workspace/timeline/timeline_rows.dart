// The timeline's rows: the order they are laid out in, what each one shows, and the drag that reorders them.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ChangeNotifier, VoidCallback;
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
class TimelineRows extends ChangeNotifier {
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
  int? _draggingLayerId;
  int? _draggingRowIndex;
  int _lastDelta = 0;
  double _liftAmount = 0;
  double _shiftProgress = 1;
  Map<int, double> _fromOffsets = const {};
  double? _settleFrom;
  double? _settleTo;
  double _settleStartLift = 1;
  double _settleProgress = 0;

  /// Animation hooks driven by the timeline's State (AbsentMotion lift/slide/drop timings).
  VoidCallback? onLiftStart;
  VoidCallback? onShiftChanged;
  void Function(VoidCallback done)? onDropSettle;

  /// Whether a layer row is currently lifted or settling into its drop slot.
  bool get isReordering => _draggingLayerId != null;

  /// Whether the dragged row is currently playing its drop-settle animation.
  bool get isSettling => _settleFrom != null;

  /// The layer currently being drag-reordered vertically, or null when idle.
  int? get draggingLayerId => _draggingLayerId;

  /// The index in [order] of the layer row being drag-reordered, or null when idle.
  int? get draggingRowIndex => _draggingRowIndex;

  /// Lift progress (0..1) controlling row elevation, scale, shadow, and background dim.
  double get liftAmount => _liftAmount;

  /// Updates lift progress (0..1) during drag pickup.
  void setLiftProgress(double t) {
    if (_draggingLayerId == null || isSettling) return;
    _liftAmount = t.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Advances the sibling-row slide animation (0..1).
  void setShiftProgress(double t) {
    if (_draggingLayerId == null) return;
    _shiftProgress = t.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Advances the drop-settle animation (0..1), lowering the row cleanly into its slot.
  void setDropProgress(double t) {
    if (!isSettling) return;
    _settleProgress = t.clamp(0.0, 1.0);
    _liftAmount = _settleStartLift * (1.0 - _settleProgress);
    notifyListeners();
  }

  /// Live vertical offset in pixels for the lifted row (clamped, or eased during drop-settle).
  double get dragOffsetY {
    final row = _draggingRowIndex;
    if (row == null || _order.isEmpty) return 0;
    if (_settleFrom != null && _settleTo != null) {
      return _settleFrom! + (_settleTo! - _settleFrom!) * _settleProgress;
    }
    final minLift = -row * TimelineMetrics.row;
    final maxLift = (_order.length - 1 - row) * TimelineMetrics.row;
    return _lift.clamp(minLift, maxLift);
  }

  List<int> _visibleLayerRows() => [
    for (var i = 0; i < _order.length; i++)
      if (_order[i].value == null) i,
  ];

  /// Signed count of visible layers the dragged row would move past if released now.
  int get dragDeltaLayers {
    final row = _draggingRowIndex;
    if (row == null || _order.isEmpty) return 0;
    if (isSettling) return _lastDelta;
    final layerRows = _visibleLayerRows();
    final at = layerRows.indexOf(row);
    if (at < 0) return 0;
    final offset = dragOffsetY;
    if (offset > 0) {
      final bottomEdge = (row + 1) * TimelineMetrics.row + offset;
      var passed = 0;
      for (var k = at + 1; k < layerRows.length; k++) {
        if (bottomEdge > (layerRows[k] + 0.5) * TimelineMetrics.row) {
          passed++;
        } else {
          break;
        }
      }
      return passed;
    }
    if (offset < 0) {
      final topEdge = row * TimelineMetrics.row + offset;
      var passed = 0;
      for (var k = at - 1; k >= 0; k--) {
        if (topEdge < (layerRows[k] + 0.5) * TimelineMetrics.row) {
          passed--;
        } else {
          break;
        }
      }
      return passed;
    }
    return 0;
  }

  int _targetBoundaryRow(int dragRow, int by) {
    final layerRows = _visibleLayerRows();
    final at = layerRows.indexOf(dragRow);
    if (at < 0) return dragRow;
    final target = (at + by).clamp(0, layerRows.length - 1);
    if (by < 0) return layerRows[target];
    return target + 1 < layerRows.length
        ? layerRows[target + 1]
        : _order.length;
  }

  /// Target vertical displacement in pixels for row [rowIndex] while dragging.
  double rowVisualOffset(int rowIndex) {
    final dragRow = _draggingRowIndex;
    if (dragRow == null || _order.isEmpty) return 0;
    if (rowIndex == dragRow) return dragOffsetY;
    final by = dragDeltaLayers;
    if (by == 0) return 0;
    final boundary = _targetBoundaryRow(dragRow, by);
    if (by < 0) {
      if (rowIndex >= boundary && rowIndex < dragRow) {
        return TimelineMetrics.row;
      }
    } else {
      final dragLayer = _order[dragRow].layer;
      if (rowIndex > dragRow &&
          rowIndex < boundary &&
          _order[rowIndex].layer != dragLayer) {
        return -TimelineMetrics.row;
      }
    }
    return 0;
  }

  /// Eased vertical displacement for row [rowIndex], shared by tracks and labels.
  double animatedRowOffset(int rowIndex) {
    final target = rowVisualOffset(rowIndex);
    if (rowIndex == _draggingRowIndex || _shiftProgress >= 1.0) return target;
    final from = _fromOffsets[rowIndex] ?? 0.0;
    return from + (target - from) * _shiftProgress;
  }

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

  /// A drag of a row's label up or down starts, lifting the row in depth.
  void reorderStart(Layer l, int rowIndex) {
    if (isSettling) return;
    _draggingLayerId = l.id;
    _draggingRowIndex = rowIndex;
    _lift = 0;
    _lastDelta = 0;
    _shiftProgress = 1;
    _fromOffsets = const {};
    _settleFrom = null;
    _settleTo = null;
    _settleProgress = 0;
    if (onLiftStart != null) {
      _liftAmount = 0;
      onLiftStart!();
    } else {
      _liftAmount = 1;
    }
    notifyListeners();
  }

  /// The label being dragged was carried [dy] pixels further down, or up when negative.
  void reorderBy(double dy) {
    if (_draggingLayerId == null || isSettling) return;
    final prevOffsets = <int, double>{
      for (var i = 0; i < _order.length; i++)
        if (i != _draggingRowIndex) i: animatedRowOffset(i),
    };
    _lift += dy;
    final nextDelta = dragDeltaLayers;
    if (nextDelta != _lastDelta) {
      _lastDelta = nextDelta;
      _fromOffsets = prevOffsets;
      if (onShiftChanged != null) {
        _shiftProgress = 0;
        onShiftChanged!();
      } else {
        _shiftProgress = 1;
      }
    }
    notifyListeners();
  }

  void _finishReorder(Layer? commitLayer, int by) {
    final ws = workspace;
    _draggingLayerId = null;
    _draggingRowIndex = null;
    _lift = 0;
    _lastDelta = 0;
    _liftAmount = 0;
    _shiftProgress = 1;
    _fromOffsets = const {};
    _settleFrom = null;
    _settleTo = null;
    _settleProgress = 0;
    notifyListeners();
    if (commitLayer != null &&
        ws != null &&
        timeline_service.isConnected(ws) &&
        by != 0) {
      ws.after(
        timeline_service.reorderLayer(
          ws,
          commitLayer.id,
          (by > 0 ? -1 : 1) * _places(ws, commitLayer, by).toDouble(),
        ),
      );
    }
  }

  double _landingOffset(int dragRow, int by) {
    if (by == 0) return 0;
    final boundary = _targetBoundaryRow(dragRow, by);
    final slotRow = by < 0 ? boundary : math.max(0, boundary - 1);
    return (slotRow - dragRow) * TimelineMetrics.row;
  }

  /// The drag of the label of [l] ended: settles the lifted row smoothly into its slot, then commits.
  void reorderEnd(Layer l) {
    final dragRow = _draggingRowIndex;
    if (dragRow == null || isSettling) return;
    final by = dragDeltaLayers;
    _lastDelta = by;
    if (onDropSettle != null) {
      _settleFrom = dragOffsetY;
      _settleTo = _landingOffset(dragRow, by);
      _settleStartLift = _liftAmount;
      _settleProgress = 0;
      notifyListeners();
      onDropSettle!(() => _finishReorder(l, by));
    } else {
      _finishReorder(l, by);
    }
  }

  /// Escape pressed while dragging: settles back to the original slot without reordering.
  void reorderCancel() {
    final dragRow = _draggingRowIndex;
    if (dragRow == null || isSettling) return;
    if (onDropSettle != null) {
      _lastDelta = 0;
      _fromOffsets = const {};
      _shiftProgress = 1;
      _settleFrom = dragOffsetY;
      _settleTo = 0;
      _settleStartLift = _liftAmount;
      _settleProgress = 0;
      notifyListeners();
      onDropSettle!(() => _finishReorder(null, 0));
    } else {
      _finishReorder(null, 0);
    }
  }
}
