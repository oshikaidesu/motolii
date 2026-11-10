// The timeline's tracks area as widgets: the painted rows, pointer handling on bars, keys, lanes and the selection box,
// wheel and pinch gestures, and the playhead drawn over them.
// setState is called from an extension on the State itself, which the analyzer only allows with this ignore.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_drag.dart';
import 'package:motolii/workspace/timeline/timeline_kept.dart';
import 'package:motolii/workspace/timeline/timeline_media.dart';
import 'package:motolii/workspace/timeline/timeline_overview.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_ruler.dart';
import 'package:motolii/workspace/timeline/timeline_tracks_paint.dart';
import 'package:motolii/workspace/timeline/timeline_view.dart';

extension WsTimelineTracks on WsTimelineState {
  Widget tracks(Ws ws, List<WtRow> rows) => LayoutBuilder(
    builder: (context, box) {
      trackW = box.maxWidth;
      rowsH = math.max(0, box.maxHeight - WtM.ruler - WtM.overview);
      scroll = clampScroll(scroll);
      vscroll = clampV(rows.length);
      final v = view;
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WsMenu(
                key: rulerMenu,
                child: GestureDetector(
                  key: const ValueKey('ws-tl-ruler'),
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: wsPressing,
                  onTapUp: (d) => rulerTap(d.localPosition), // Like Ableton Live's scrub area.
                  onDoubleTapDown: (d) => rulerDouble(d.localPosition),
                  onDoubleTap: () {},
                  onSecondaryTapDown: (d) => rulerRight(d.localPosition),
                  onPanDown: (d) => rulerDown(d.localPosition),
                  onPanUpdate: (d) => rulerMove(d.localPosition),
                  onPanEnd: (_) => workDragEnd(),
                  onPanCancel: workDragEnd,
                  child: SizedBox(
                    height: WtM.ruler,
                    child: CustomPaint(
                      painter: WtRulerPainter(
                        view: v,
                        fps: Ws.fps,
                        workIn: workIn,
                        workOut: workOut,
                        markers: marksOf(workspace!),
                        markColors: markColorsOf(workspace!),
                        beats: beatsOf(ws),
                        tempo: ws.beats,
                        retimed: retimedOf(ws),
                      ),
                      foregroundPainter: WtKeptPainter(view: v, kept: ws.kept), // Marks the frames cached on disk for playback.
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: cursor,
                  onHover: (e) {
                    final c = cursorAt(e.localPosition);
                    if (c != cursor) setState(() => cursor = c);
                  },
                  child: WsTwoFingers(
                    onWheel: scrollBy,
                    onPan: fingers,
                    onPinch: pinch,
                    child: WsMenu(
                      key: trackMenu,
                      child: GestureDetector(
                        key: const ValueKey('ws-tl-tracks'),
                        behavior: HitTestBehavior.opaque,
                        supportedDevices: wsPressing,
                        dragStartBehavior: DragStartBehavior.down,
                        onTapDown: (d) => trackDown(d.localPosition),
                        onSecondaryTapDown: (d) => trackRight(d.localPosition),
                        onTapUp: (d) => laneTap(d.localPosition), // Only fires once the gesture is known not to be a drag.
                        onPanStart: (d) => barDown(d.localPosition),
                        onPanUpdate: (d) => barMove(d.localPosition),
                        onPanEnd: (_) => barUp(),
                        onPanCancel: () => barUp(keep: false),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: WtTracksPainter(rows: rows, view: v, fps: Ws.fps, vscroll: vscroll, restAt: restAt),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ws.moment,
                builder: (_, frame, _) => TimelineOverview(from: scroll, to: scroll + visible, frame: frame, onDrag: (p) => overview(p, box.maxWidth)),
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
          if (selectionBox case (final a, final b)?)
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
          if (naming case (final at, _)?)
            Positioned(
              left: v.x((at * Ws.fps).round()).roundToDouble(),
              top: WtM.band + 2,
              height: 12,
              child: ListenableBuilder(
                listenable: markWords,
                builder: (_, child) =>
                    Container(width: wtFlagWidth('${markWords.text}  '), color: WsT.toneText, padding: const EdgeInsets.symmetric(horizontal: 4), child: child),
                child: TextGestures(
                  key: const ValueKey('ws-tl-mark-name'),
                  field: (k) => EditableText(
                    key: k,
                    rendererIgnoresPointer: true,
                    controller: markWords,
                    focusNode: markFocus,
                    style: T.micro(Grey.g13).copyWith(fontWeight: FontWeight.w700),
                    cursorColor: Grey.g13,
                    backgroundCursorColor: Grey.g38,
                    selectionColor: Grey.g13.withValues(alpha: .3), // Highlight for selected text.
                    maxLines: 1,
                    onSubmitted: (_) => markFocus.unfocus(),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
