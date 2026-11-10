// The timeline's tracks area as widgets: the painted rows, pointer handling on bars, keys, lanes and the selection box,
// wheel and pinch gestures, and the playhead drawn over them.
// setState is called from an extension on the State itself, which the analyzer only allows with this ignore.
// ignore_for_file: invalid_use_of_protected_member
part of 'timeline.dart';

extension _WsTimelineTracks on _WsTimelineState {
  Widget _tracks(Ws ws, List<WtRow> rows) => LayoutBuilder(
    builder: (context, box) {
      _trackW = box.maxWidth;
      _rowsH = math.max(0, box.maxHeight - WtM.ruler - WtM.overview);
      _scroll = _clampScroll(_scroll);
      _vscroll = _clampV(rows.length);
      final v = _view;
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WsMenu(
                key: _rulerMenu,
                child: GestureDetector(
                  key: const ValueKey('ws-tl-ruler'),
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: wsPressing,
                  onTapUp: (d) => _rulerTap(d.localPosition), // Like Ableton Live's scrub area.
                  onDoubleTapDown: (d) => _rulerDouble(d.localPosition),
                  onDoubleTap: () {},
                  onSecondaryTapDown: (d) => _rulerRight(d.localPosition),
                  onPanDown: (d) => _rulerDown(d.localPosition),
                  onPanUpdate: (d) => _rulerMove(d.localPosition),
                  onPanEnd: (_) => _workDragEnd(),
                  onPanCancel: _workDragEnd,
                  child: SizedBox(
                    height: WtM.ruler,
                    child: CustomPaint(
                      painter: WtRulerPainter(
                        view: v,
                        fps: Ws.fps,
                        workIn: _workIn,
                        workOut: _workOut,
                        markers: _marksOf(_ws!),
                        markColors: _markColorsOf(_ws!),
                        beats: _beatsOf(ws),
                        tempo: ws.beats,
                        retimed: _retimedOf(ws),
                      ),
                      foregroundPainter: WtKeptPainter(view: v, kept: ws.kept), // Marks the frames cached on disk for playback.
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: _cursor,
                  onHover: (e) {
                    final c = _cursorAt(e.localPosition);
                    if (c != _cursor) setState(() => _cursor = c);
                  },
                  child: WsTwoFingers(
                    onWheel: _scrollBy,
                    onPan: _fingers,
                    onPinch: _pinch,
                    child: WsMenu(
                      key: _trackMenu,
                      child: GestureDetector(
                        key: const ValueKey('ws-tl-tracks'),
                        behavior: HitTestBehavior.opaque,
                        supportedDevices: wsPressing,
                        dragStartBehavior: DragStartBehavior.down,
                        onTapDown: (d) => _trackDown(d.localPosition),
                        onSecondaryTapDown: (d) => _trackRight(d.localPosition),
                        onTapUp: (d) => _laneTap(d.localPosition), // Only fires once the gesture is known not to be a drag.
                        onPanStart: (d) => _barDown(d.localPosition),
                        onPanUpdate: (d) => _barMove(d.localPosition),
                        onPanEnd: (_) => _barUp(),
                        onPanCancel: () => _barUp(keep: false),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: WtTracksPainter(rows: rows, view: v, fps: Ws.fps, vscroll: _vscroll, restAt: _restAt),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ws.moment,
                builder: (_, frame, _) => _Overview(from: _scroll, to: _scroll + _visible, frame: frame, onDrag: (p) => _overview(p, box.maxWidth)),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: WtM.overview,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    painter: WtPlayheadPainter(
                      view: v,
                      frame: ws.frame,
                      headTop: WtM.band + 1,
                      moment: ws.moment,
                    ), // Repainted as the playhead moves; no widgets are rebuilt.
                  ),
                ),
              ),
            ),
          ),
          if (_box case (final a, final b)?)
            Positioned.fromRect(
              rect: Rect.fromPoints(a, b).shift(Offset(0, WtM.ruler)),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WsT.accent.withAlpha(36),
                    border: Border.all(color: WsT.accent, width: 1),
                  ),
                ),
              ),
            ),
          // The flag name is edited in place, as wide as its text, like renaming a layer in Figma.
          if (_naming case (final at, _)?)
            Positioned(
              left: v.x((at * Ws.fps).round()).roundToDouble(),
              top: WtM.band + 2,
              height: 12,
              child: ListenableBuilder(
                listenable: _markWords,
                builder: (_, child) => Container(
                  width: wtFlagWidth('${_markWords.text}  '),
                  color: WsT.toneText,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
                child: TextGestures(
                  key: const ValueKey('ws-tl-mark-name'),
                  field: (k) => EditableText(
                    key: k,
                    rendererIgnoresPointer: true,
                    controller: _markWords,
                    focusNode: _markFocus,
                    style: T.micro(Grey.g13).copyWith(fontWeight: FontWeight.w700),
                    cursorColor: Grey.g13,
                    backgroundCursorColor: Grey.g38,
                    selectionColor: Grey.g13.withValues(alpha: .3), // Highlight for selected text.
                    maxLines: 1,
                    onSubmitted: (_) => _markFocus.unfocus(),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
