// The column of layer names beside the tracks, and a relation row's colours.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_labels.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

extension TimelinePaneRows on TimelinePaneState {
  /// The label colours of the layers a behaviour affects, in order, or null for an ordinary layer row (which has a single colour).
  List<Color>? mixOf(WorkspaceController ws, String id) {
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

  /// The layer's row number and name, as After Effects' Parent column shows it. Several layers may share a name.
  String _numbered(WorkspaceController ws, String id) {
    final i = ws.layers.indexWhere((l) => l.id == id);
    return i < 0 ? id : '${i + 1} ${ws.layers[i].name}';
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

  Widget labels(WorkspaceController ws, List<TimelineRow> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TimelineLabelHeader(count: ws.layers.length, solo: RowFlags(ws).anySolo),
      Expanded(
        child: ContextMenu(
          key: labelMenu,
          child: TwoFingerGestures(
            onWheel: scrollBy,
            // The labels scroll vertically together with the track rows.
            onPan: (by, _) => scrollBy(Offset(0, -by.dy)),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, box) {
                  final top = viewport.clampVerticalScroll(rows.length);
                  return Stack(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        if (order[i].aim case (final said, final other)?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-aim-${ws.layers[order[i].layer].id}-$said-$other',
                            ),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            child: NakedButton(
                              enableFeedback: false,
                              mouseCursor: SystemMouseCursors.basic,
                              // Pressing selects the target layer, like Cavalry's connection list.
                              onPressed: () => ws.select(other),
                              child: Row(
                                children: [
                                  Text(
                                    said,
                                    maxLines: 1,
                                    style: TextStyles.label(Grey.g56),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                  Flexible(
                                    child: Text(
                                      _numbered(ws, other),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.label(Grey.g91),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // A property lane shows the property name under its layer's name, as Ableton names a lane after its control.
                        else if (order[i].value case final n?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-lane-${ws.layers[order[i].layer].id}-$n',
                            ),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                            // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                            child: Row(
                              children: [
                                if (laneCard(ws, ws.layers[order[i].layer], n)
                                    case final card?) ...[
                                  Flexible(
                                    child: Text(
                                      card,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.label(Grey.g56),
                                    ),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                ],
                                Text(
                                  ws.inside?.shown(n)?.label ?? n,
                                  maxLines: 1,
                                  style: TextStyles.label(Grey.g76),
                                ),
                              ],
                            ),
                          )
                        else if (ws.layers[order[i].layer] case final l)
                          Positioned(
                            key: ValueKey('ws-tl-label-${l.id}'),
                            left: 0,
                            right: 0,
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            // Dragging a row up or down moves the layer forward or back by as many rows as it was dragged.
                            child: GestureDetector(
                              supportedDevices: pressingDevices,
                              onSecondaryTapDown: (d) =>
                                  labelRight(l, d.globalPosition),
                              // Count the whole drag from the pointer-down position.
                              dragStartBehavior: DragStartBehavior.down,
                              onVerticalDragStart: (_) => lift = 0,
                              onVerticalDragUpdate: (d) => lift += d.delta.dy,
                              onVerticalDragEnd: (_) {
                                final by = (lift / TimelineMetrics.row).round();
                                if (by != 0) {
                                  ws.after(
                                    ws.inside!.later(
                                      'raise',
                                      layer: int.parse(l.id),
                                      number:
                                          (by > 0 ? -1 : 1) *
                                          _places(ws, l, by).toDouble(),
                                    ),
                                  );
                                }
                              },
                              child: TimelineLabelRow(
                                // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                                index: order[i].layer,
                                depth: ws.depth(l),
                                row: rows[i],
                                hidden: RowFlags(ws).isHidden(l.id),
                                solo: RowFlags(ws).isSolo(l.id),
                                lanes: l.kind == LayerKind.group
                                    ? ws.groupOpen(l.id)
                                    : l.keys.isEmpty &&
                                          linkTargets(ws, l.id).isEmpty &&
                                          !l.lined
                                    ? null
                                    : ws.lanesOpen(l.id),
                                onLanes: () => l.kind == LayerKind.group
                                    ? ws.turnGroup(l.id)
                                    : ws.twirl([l.id]),
                                onSelect: () =>
                                    HardwareKeyboard.instance.isShiftPressed
                                    // Shift selects every row from the last picked one to this one, as in After Effects.
                                    ? selectRange(ws, l.id)
                                    : HardwareKeyboard.instance.isMetaPressed
                                    ? selectAlso(ws, l.id)
                                    // Cmd adds this layer to the selection, or removes it.
                                    : ws.select(l.id),
                                onEye: () => RowFlags(ws).toggleHidden(l.id),
                                onSolo: () => RowFlags(ws).toggle('solo', l.id),
                                onLock: () => RowFlags(ws).toggle('lock', l.id),
                              ),
                            ),
                          ),
                      for (var i = 0; i < rows.length; i++)
                        if (order[i].value == null)
                          // The rename field is written over the label (Cmd+R).
                          ?renameField(
                            i,
                            ws.layers[order[i].layer].id,
                            i * TimelineMetrics.row - top,
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
