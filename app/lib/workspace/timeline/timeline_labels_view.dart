// The column of layer names beside the timeline's tracks: a row for each layer (its eye, solo and lock, its number and name, its twirl), the
// lanes of properties under a layer, the targets of a relation, and the rename field. Dragging a row reorders the layer.
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/row_flags.dart';
import 'package:motolii/workspace/timeline/timeline_labels.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_requests.dart';

/// Mixed into the timeline's State, which provides the scrolling (the labels scroll with the rows).
mixin TimelineLabelsView<T extends StatefulWidget>
    on State<T>, TimelineRequests<T> {
  /// Scrolls the rows (and the tracks beside them) by the wheel or two-finger movement [d].
  void scrollBy(Offset d);

  /// The layer's row number and name, as After Effects' Parent column shows it. Several layers may share a name.
  String numbered(WorkspaceController ws, String id) {
    final i = ws.layers.indexWhere((l) => l.id == id);
    return i < 0 ? id : '${i + 1} ${ws.layers[i].name}';
  }

  // The column of layer names beside the tracks.
  Widget labels(WorkspaceController ws, List<TimelineRow> drawn) => Column(
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
                  final top = viewport.clampVerticalScroll(drawn.length);
                  return Stack(
                    children: [
                      for (var i = 0; i < drawn.length; i++)
                        if (rows.order[i].aim case (final said, final other)?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-aim-${ws.layers[rows.order[i].layer].id}-$said-$other',
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
                                      numbered(ws, other),
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
                        else if (rows.order[i].value case final n?)
                          Positioned(
                            key: ValueKey(
                              'ws-tl-lane-${ws.layers[rows.order[i].layer].id}-$n',
                            ),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * TimelineMetrics.row - top,
                            height: TimelineMetrics.row,
                            // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                            // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                            child: Row(
                              children: [
                                if (rows.laneCard(
                                      ws.layers[rows.order[i].layer],
                                      n,
                                    )
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
                        else if (ws.layers[rows.order[i].layer] case final l)
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
                              onVerticalDragStart: (_) => rows.reorderStart(),
                              onVerticalDragUpdate: (d) =>
                                  rows.reorderBy(d.delta.dy),
                              onVerticalDragEnd: (_) => rows.reorderEnd(l),
                              child: TimelineLabelRow(
                                // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                                index: rows.order[i].layer,
                                depth: ws.depth(l),
                                row: drawn[i],
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
                      for (var i = 0; i < drawn.length; i++)
                        if (rows.order[i].value == null)
                          // The rename field is written over the label (Cmd+R).
                          ?renameField(
                            i,
                            ws.layers[rows.order[i].layer].id,
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
