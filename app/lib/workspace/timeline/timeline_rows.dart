// Each row's state as the project stores it (hidden, solo, locked, a group's colours) and the column of layer names.
part of 'timeline.dart';

extension _WsTimelineRows on _WsTimelineState {
  /// The label colours of the layers a behaviour affects, in order, or null for an ordinary layer row (which has a single colour).
  List<Color>? _mixOf(Ws ws, String id) {
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
  bool _isHidden(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.hidden);

  /// How many layers a row dragged by [by] rows moves past. A collapsed group counts as itself plus all its members.
  int _places(Ws ws, WsLayer l, int by) {
    final away = ws.foldedAway,
        seen = [
          for (final o in _order)
            if (o.value == null) ws.layers[o.layer].id,
        ],
        at = seen.indexOf(l.id);
    final past = by > 0 ? seen.sublist(at + 1, math.min(at + 1 + by, seen.length)) : seen.sublist(math.max(0, at + by), at);
    return past.fold(0, (n, id) => n + 1 + away.values.where((g) => g == id).length);
  }

  void _eye(Ws ws, String id) {
    ws.after(ws.inside!.later('set', layer: int.parse(id), name: 'visible', number: _isHidden(ws, id) ? 1 : 0));
  }

  // Solo and lock are stored in the project, as in After Effects. While any layer is solo, only the solo layers are shown.
  // The engine refuses to change a locked layer and reports an error.
  bool _isSolo(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.solo);

  bool _isLocked(Ws ws, String id) => ws.layers.any((l) => l.id == id && l.locked);

  bool _anySolo(Ws ws) => ws.layers.any((l) => _isSolo(ws, l.id));

  Widget _labels(Ws ws, List<WtRow> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _LabelHeader(count: ws.layers.length, solo: _anySolo(ws)),
      Expanded(
        child: WsMenu(
          key: _labelMenu,
          child: WsTwoFingers(
            onWheel: _scrollBy,
            // The labels scroll vertically together with the track rows.
            onPan: (by, _) => _scrollBy(Offset(0, -by.dy)),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, box) {
                  final top = _clampV(rows.length);
                  return Stack(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        if (_order[i].aim case (final said, final other)?)
                          Positioned(
                            key: ValueKey('ws-tl-aim-${ws.layers[_order[i].layer].id}-$said-$other'),
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
                        else if (_order[i].value case final n?)
                          Positioned(
                            key: ValueKey('ws-tl-lane-${ws.layers[_order[i].layer].id}-$n'),
                            left: Shape.s(34),
                            right: Shape.s(8),
                            top: i * WtM.row - top,
                            height: WtM.row,
                            // The lane shows the effect card's name, then the property's own label (for example Threshold, not js_am_rays_threshold).
                            // This follows Ableton's Device and Control choosers and Logic's plug-in and parameter names.
                            child: Row(
                              children: [
                                if (_laneCard(ws, ws.layers[_order[i].layer], n) case final card?) ...[
                                  Flexible(
                                    child: Text(card, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g56)),
                                  ),
                                  SizedBox(width: Shape.s(5)),
                                ],
                                Text(ws.inside?.shown(n)?.label ?? n, maxLines: 1, style: T.label(Grey.g76)),
                              ],
                            ),
                          )
                        else if (ws.layers[_order[i].layer] case final l)
                          Positioned(
                            key: ValueKey('ws-tl-label-${l.id}'),
                            left: 0,
                            right: 0,
                            top: i * WtM.row - top,
                            height: WtM.row,
                            // Dragging a row up or down moves the layer forward or back by as many rows as it was dragged.
                            child: GestureDetector(
                              supportedDevices: wsPressing,
                              onSecondaryTapDown: (d) => _labelRight(l, d.globalPosition),
                              // Count the whole drag from the pointer-down position.
                              dragStartBehavior: DragStartBehavior.down,
                              onVerticalDragStart: (_) => _lift = 0,
                              onVerticalDragUpdate: (d) => _lift += d.delta.dy,
                              onVerticalDragEnd: (_) {
                                final by = (_lift / WtM.row).round();
                                if (by != 0) {
                                  ws.after(ws.inside!.later('raise', layer: int.parse(l.id), number: (by > 0 ? -1 : 1) * _places(ws, l, by).toDouble()));
                                }
                              },
                              child: _LabelRow(
                                // The layer's number, not the row's: After Effects' # column counts layers only, not property lanes.
                                index: _order[i].layer,
                                depth: ws.depth(l),
                                row: rows[i],
                                hidden: _isHidden(ws, l.id),
                                solo: _isSolo(ws, l.id),
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
                        if (_order[i].value == null)
                          // The rename field is written over the label (Cmd+R).
                          if (_renameField(i, ws.layers[_order[i].layer].id, i * WtM.row - top) case final f?) f,
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
