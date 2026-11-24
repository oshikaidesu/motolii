// The column of layer names beside the timeline's tracks: a row for each layer (its eye, solo and lock, its number and name, its twirl), the
// lanes of properties under a layer, the targets of a relation, and the rename field. Dragging a row reorders the layer.
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
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

  /// The layer's row number and name
  String numbered(WorkspaceController ws, int id) {
    final i = ws.layers.indexWhere((l) => l.id == id);
    return i < 0 ? '$id' : '${i + 1} ${ws.layers[i].name}';
  }

  // The lane a property row shows.
  Lane? _lane(WorkspaceController ws, int i, String name) => ws
      .layers[rows.order[i].layer]
      .lanes
      .where((a) => a.name == name)
      .firstOrNull;

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
                  final dragRow = rows.draggingRowIndex;
                  final reordering = rows.isReordering;
                  final lift = rows.liftAmount;
                  const slideDuration = Duration(milliseconds: 120);

                  Widget buildRow(int i) {
                    final offset = rows.rowVisualOffset(i);
                    final rowTop = i * TimelineMetrics.row - top + offset;
                    final isDragged = i == dragRow;
                    final dur = reordering && !isDragged
                        ? slideDuration
                        : Duration.zero;
                    if (rows.order[i].aim case (final said, final other)?) {
                      return AnimatedPositioned(
                        key: ValueKey(
                          'ws-tl-aim-${ws.layers[rows.order[i].layer].id}-$said-$other',
                        ),
                        duration: dur,
                        curve: Curves.easeOutCubic,
                        left: Shape.s(34),
                        right: Shape.s(8),
                        top: rowTop,
                        height: TimelineMetrics.row,
                        child: NakedButton(
                          enableFeedback: false,
                          mouseCursor: SystemMouseCursors.basic,
                          // Pressing selects the target layer
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
                      );
                    }
                    // A property lane shows the property name under its layer's name
                    if (rows.order[i].value case final n?) {
                      return AnimatedPositioned(
                        key: ValueKey(
                          'ws-tl-lane-${ws.layers[rows.order[i].layer].id}-$n',
                        ),
                        duration: dur,
                        curve: Curves.easeOutCubic,
                        left: Shape.s(34),
                        right: Shape.s(8),
                        top: rowTop,
                        height: TimelineMetrics.row,
                        // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                        // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                        child: Row(
                          children: [
                            if (_lane(ws, i, n)?.card case final card?) ...[
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
                              _lane(ws, i, n)?.label ?? n,
                              maxLines: 1,
                              style: TextStyles.label(Grey.g76),
                            ),
                          ],
                        ),
                      );
                    }
                    final l = ws.layers[rows.order[i].layer];
                    Widget rowWidget = MouseRegion(
                      cursor: isDragged
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab,
                      child: GestureDetector(
                        supportedDevices: pressingDevices,
                        onDoubleTap: l.kind == LayerKind.group
                            ? () => ws.isolateGroup(
                                ws.isolatedGroup == l.id ? null : l.id,
                              )
                            : null,
                        onSecondaryTapDown: (d) =>
                            labelRight(l, d.globalPosition),
                        // Count the whole drag from the pointer-down position.
                        dragStartBehavior: DragStartBehavior.down,
                        onVerticalDragStart: (_) => rows.reorderStart(l, i),
                        onVerticalDragUpdate: (d) => rows.reorderBy(d.delta.dy),
                        onVerticalDragEnd: (_) => rows.reorderEnd(l),
                        onVerticalDragCancel: rows.reorderCancel,
                        child: TimelineLabelRow(
                          // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                          index: rows.order[i].layer,
                          depth: ws.depth(l),
                          row: drawn[i],
                          hidden: RowFlags(ws).isHidden(l.id),
                          solo: RowFlags(ws).isSolo(l.id),
                          lanes: l.kind == LayerKind.group
                              ? ws.groupOpen(l.id)
                              : l.keys.isEmpty && l.links.isEmpty && !l.lined
                              ? null
                              : ws.lanesOpen(l.id),
                          onLanes: () => l.kind == LayerKind.group
                              ? ws.turnGroup(l.id)
                              : ws.twirl([l.id]),
                          // Shift takes the rows from the last one picked; Cmd adds or removes this layer.
                          onSelect: () => clickLayer(
                            ws,
                            l.id,
                            order: [for (final k in ws.layers) k.id],
                          ),
                          onEye: () => RowFlags(ws).toggleHidden(l.id),
                          onSolo: () => RowFlags(ws).toggle('solo', l.id),
                          onLock: () => RowFlags(ws).toggle('lock', l.id),
                          clip: l.clipped,
                          onClip: () => RowFlags(ws).toggleClipped(l.id),
                        ),
                      ),
                    );
                    if (isDragged && lift > 0) {
                      // AbsentMotion-style depth lift: subtle scale + shadow, zero borders or drop lines.
                      rowWidget = Transform.scale(
                        scale: 1.0 + 0.015 * lift,
                        alignment: Alignment.center,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Grey.g00.withValues(alpha: 0.55 * lift),
                                blurRadius: 14 * lift,
                                offset: Offset(0, 5 * lift),
                              ),
                            ],
                          ),
                          child: rowWidget,
                        ),
                      );
                    }
                    return AnimatedPositioned(
                      key: ValueKey('ws-tl-label-${l.id}'),
                      duration: dur,
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      top: rowTop,
                      height: TimelineMetrics.row,
                      child: rowWidget,
                    );
                  }

                  return Stack(
                    children: [
                      for (var i = 0; i < drawn.length; i++)
                        if (i != dragRow) buildRow(i),
                      if (reordering && lift > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: WindowTokens.body.withValues(
                                alpha: 0.42 * lift,
                              ),
                            ),
                          ),
                        ),
                      if (dragRow != null && dragRow < drawn.length)
                        buildRow(dragRow),
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
