// Each row's state as the project stores it (hidden, solo, locked, a group's colours) and the column of layer names.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/bridge/motolii.dart' show MotoliiDocument, MotoliiWrites, MotoliiShelves;
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_labels.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';

extension WsTimelineRows on WsTimelineState {
  /// The label colours of the layers a behaviour affects, in order, or null for an ordinary layer row (which has a single colour).
  List<Color>? mixOf(Ws ws, String id) {
    final m = ws.inside, t = int.tryParse(id);
    if (m == null || t == null || m.word(t, 'kind') != 'behaviour' || !wsRelations.contains(m.word(t, 'file'))) return null;
    return [
      for (final s in m.word(t, 'members').split(' '))
        if (s.isNotEmpty && s != '_') wsLabel(s),
    ];
  }

  /// The layer's row number and name, as After Effects' Parent column shows it. Several layers may share a name.
  String _numbered(Ws ws, String id) {
    final i = ws.layers.indexWhere((l) => l.id == id);
    return i < 0 ? id : '${i + 1} ${ws.layers[i].name}';
  }

  // Hiding sets the layer's visible property to 0 in the project, so the layer is not on the canvas. It is one undo step.
  // This reads the last snapshot, so no engine call is made while a row is built.
  bool isHidden(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.hidden);

  /// How many layers a row dragged by [by] rows moves past. A collapsed group counts as itself plus all its members.
  int _places(Ws ws, WsLayer l, int by) {
    final away = ws.foldedAway,
        seen = [
          for (final o in order)
            if (o.value == null) ws.layers[o.layer].id,
        ],
        at = seen.indexOf(l.id);
    final past = by > 0 ? seen.sublist(at + 1, math.min(at + 1 + by, seen.length)) : seen.sublist(math.max(0, at + by), at);
    return past.fold(0, (n, id) => n + 1 + away.values.where((g) => g == id).length);
  }

  void _eye(Ws ws, String id) {
    ws.after(ws.inside!.later('set', layer: int.parse(id), name: 'visible', number: isHidden(ws, id) ? 1 : 0));
  }

  // Solo and lock are stored in the project, as in After Effects. While any layer is solo, only the solo layers are shown.
  // The engine refuses to change a locked layer and reports an error.
  bool isSolo(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.solo);

  bool isLocked(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.locked);

  bool anySolo(Ws ws) => ws.layers.any((l) => isSolo(ws, l.id));

  void _flag(Ws ws, String name, String id) {
    final m = ws.inside!;
    ws.after(m.later('set', layer: int.parse(id), name: name, number: (name == 'solo' ? isSolo(ws, id) : isLocked(ws, id)) ? 0 : 1));
  }

  Widget labels(Ws ws, List<WtRow> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TimelineLabelHeader(count: ws.layers.length, solo: anySolo(ws)),
      Expanded(
        child: WsMenu(
          key: labelMenu,
          child: WsTwoFingers(
            onWheel: scrollBy,
            // The labels scroll vertically together with the track rows.
            onPan: (by, _) => scrollBy(Offset(0, -by.dy)),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, box) {
                  final top = clampV(rows.length);
                  return Stack(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        if (order[i].aim case (final said, final other)?)
                          Positioned(
                            key: ValueKey('ws-tl-aim-${ws.layers[order[i].layer].id}-$said-$other'),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * WtM.row - top,
                            height: WtM.row,
                            child: NakedButton(
                              enableFeedback: false,
                              mouseCursor: SystemMouseCursors.basic,
                              // Pressing selects the target layer, like Cavalry's connection list.
                              onPressed: () => ws.select(other),
                              child: Row(
                                children: [
                                  Text(said, maxLines: 1, style: T.label(Grey.g56)),
                                  SizedBox(width: Shape.s(5)),
                                  Flexible(
                                    child: Text(_numbered(ws, other), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // A property lane shows the property name under its layer's name, as Ableton names a lane after its control.
                        else if (order[i].value case final n?)
                          Positioned(
                            key: ValueKey('ws-tl-lane-${ws.layers[order[i].layer].id}-$n'),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * WtM.row - top,
                            height: WtM.row,
                            // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                            // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                            child: Row(
                              children: [
                                if (laneCard(ws, ws.layers[order[i].layer], n) case final card?) ...[
                                  Flexible(
                                    child: Text(card, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g56)),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                ],
                                Text(ws.inside?.shown(n)?.label ?? n, maxLines: 1, style: T.label(Grey.g76)),
                              ],
                            ),
                          )
                        else if (ws.layers[order[i].layer] case final l)
                          Positioned(
                            key: ValueKey('ws-tl-label-${l.id}'),
                            left: 0,
                            right: 0,
                            top: i * WtM.row - top,
                            height: WtM.row,
                            // Dragging a row up or down moves the layer forward or back by as many rows as it was dragged.
                            child: GestureDetector(
                              supportedDevices: wsPressing,
                              onSecondaryTapDown: (d) => labelRight(l, d.globalPosition),
                              // Count the whole drag from the pointer-down position.
                              dragStartBehavior: DragStartBehavior.down,
                              onVerticalDragStart: (_) => lift = 0,
                              onVerticalDragUpdate: (d) => lift += d.delta.dy,
                              onVerticalDragEnd: (_) {
                                final by = (lift / WtM.row).round();
                                if (by != 0) {
                                  ws.after(ws.inside!.later('raise', layer: int.parse(l.id), number: (by > 0 ? -1 : 1) * _places(ws, l, by).toDouble()));
                                }
                              },
                              child: TimelineLabelRow(
                                // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                                index: order[i].layer,
                                depth: ws.depth(l),
                                row: rows[i],
                                hidden: isHidden(ws, l.id),
                                solo: isSolo(ws, l.id),
                                lanes: l.kind == WsKind.group
                                    ? ws.groupOpen(l.id)
                                    : l.keys.isEmpty && wsTargets(ws, l.id).isEmpty && !l.lined
                                    ? null
                                    : ws.lanesOpen(l.id),
                                onLanes: () => l.kind == WsKind.group ? ws.turnGroup(l.id) : ws.twirl([l.id]),
                                onSelect: () => HardwareKeyboard.instance.isShiftPressed
                                    // Shift selects every row from the last picked one to this one, as in After Effects.
                                    ? wsPickRange(ws, l.id)
                                    : HardwareKeyboard.instance.isMetaPressed
                                    ? wsPickAlso(ws, l.id)
                                    // Cmd adds this layer to the selection, or removes it.
                                    : ws.select(l.id),
                                onEye: () => _eye(ws, l.id),
                                onSolo: () => _flag(ws, 'solo', l.id),
                                onLock: () => _flag(ws, 'lock', l.id),
                              ),
                            ),
                          ),
                      for (var i = 0; i < rows.length; i++)
                        if (order[i].value == null)
                          // The rename field is written over the label (Cmd+R).
                          if (renameField(i, ws.layers[order[i].layer].id, i * WtM.row - top) case final f?) f,
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
