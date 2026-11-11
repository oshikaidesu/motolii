// The tracks of the timeline: the ruler, the painted rows with their pointer handling, the overview strip, the playhead drawn over them, the
// box of a selection being dragged and the marker name being edited in place.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline_cache_painter.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_overview.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_ruler_painter.dart';
import 'package:motolii/workspace/timeline/timeline_requests.dart';
import 'package:motolii/workspace/timeline/timeline_tracks_paint.dart';
import 'package:motolii/workspace/timeline/track_drag.dart';

/// Mixed into the timeline's State, which provides the drag on the tracks, the media read for the rows and the gestures.
mixin TimelineTracksView<T extends StatefulWidget>
    on State<T>, TimelineRequests<T> {
  /// The bar, keyframe or selection box being dragged on the tracks, and the cursor over them.
  TrackDrag get drag;

  /// The beats, video frames, thumbnails and waveforms read for the rows.
  TimelineMediaCache get media;

  /// The wheel, a two-finger slide and a pinch on the tracks.
  void scrollBy(Offset d);
  void fingers(Offset by, Offset _);
  void pinch(double by, Offset at);

  /// Scrolls the tracks to where the overview strip was pressed at [p], when the strip is [w] wide.
  void overviewTo(Offset p, double w);

  // The tracks area: the ruler, the painted rows with their pointer handling, the overview strip, and the playhead
  // drawn over them.
  Widget tracks(
    WorkspaceController ws,
    List<TimelineRow> drawn,
  ) => LayoutBuilder(
    builder: (context, box) {
      viewport.layout(
        trackWidth: box.maxWidth,
        rowsHeight: math.max(
          0,
          box.maxHeight - TimelineMetrics.ruler - TimelineMetrics.overview,
        ),
        rows: drawn.length,
      );
      final v = viewport.view;
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContextMenu(
                key: rulerMenu,
                child: GestureDetector(
                  key: const ValueKey('ws-tl-ruler'),
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: pressingDevices,
                  onTapUp: (d) => rulerTap(
                    d.localPosition,
                  ), // Like Ableton Live's scrub area.
                  onDoubleTapDown: (d) => rulerDouble(d.localPosition),
                  onDoubleTap: () {},
                  onSecondaryTapDown: (d) => rulerRight(d.localPosition),
                  onPanDown: (d) => ruler.down(d.localPosition),
                  onPanUpdate: (d) => ruler.move(d.localPosition),
                  onPanEnd: (_) => ruler.end(),
                  onPanCancel: ruler.end,
                  child: SizedBox(
                    height: TimelineMetrics.ruler,
                    child: CustomPaint(
                      painter: TimelineRulerPainter(
                        view: v,
                        fps: WorkspaceController.fps,
                        workIn: ruler.workIn,
                        workOut: ruler.workOut,
                        markers: ruler.markers,
                        markColors: ruler.markerColors,
                        beats: media.beatsOf(ws),
                        tempo: ws.beats,
                        retimed: ruler.retimed,
                      ),
                      foregroundPainter: TimelineCachePainter(
                        view: v,
                        kept: ws.kept,
                      ), // Marks the frames cached on disk for playback.
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: drag.cursor,
                  onHover: (e) => drag.hover(e.localPosition),
                  child: TwoFingerGestures(
                    onWheel: scrollBy,
                    onPan: fingers,
                    onPinch: pinch,
                    child: ContextMenu(
                      key: trackMenu,
                      child: GestureDetector(
                        key: const ValueKey('ws-tl-tracks'),
                        behavior: HitTestBehavior.opaque,
                        supportedDevices: pressingDevices,
                        dragStartBehavior: DragStartBehavior.down,
                        onTapDown: (d) => drag.tapDown(d.localPosition),
                        onSecondaryTapDown: (d) => trackRight(d.localPosition),
                        onTapUp: (d) => drag.tapUp(d.localPosition), // Only fires once the gesture is known not to be a drag.
                        onPanStart: (d) => drag.down(d.localPosition),
                        onPanUpdate: (d) => drag.move(d.localPosition),
                        onPanEnd: (_) => drag.up(),
                        onPanCancel: () => drag.up(keep: false),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: TimelineTracksPainter(
                              rows: drawn,
                              view: v,
                              fps: WorkspaceController.fps,
                              vscroll: viewport.verticalScroll,
                              restAt: drag.snappedAt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ws.moment,
                builder: (_, frame, _) => TimelineOverview(
                  from: viewport.scroll,
                  to: viewport.scroll + viewport.visible,
                  frame: frame,
                  onDrag: (p) => overviewTo(p, box.maxWidth),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: TimelineMetrics.overview,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    painter: TimelinePlayheadPainter(
                      view: v,
                      frame: ws.frame,
                      headTop: TimelineMetrics.band + 1,
                      moment: ws.moment,
                    ), // Repainted as the playhead moves; no widgets are rebuilt.
                  ),
                ),
              ),
            ),
          ),
          if (drag.selectionBox case (final a, final b)?)
            Positioned.fromRect(
              rect: Rect.fromPoints(
                a,
                b,
              ).shift(Offset(0, TimelineMetrics.ruler)),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WindowTokens.accent.withAlpha(36),
                    border: Border.all(color: WindowTokens.accent, width: 1),
                  ),
                ),
              ),
            ),
          // The flag name is edited in place, as wide as its text, like renaming a layer in Figma.
          if (naming case (final at, _)?)
            Positioned(
              left: v.x((at * WorkspaceController.fps).round()).roundToDouble(),
              top: TimelineMetrics.band + 2,
              height: 12,
              child: ListenableBuilder(
                listenable: markWords,
                builder: (_, child) => Container(
                  width: markerFlagWidth('${markWords.text}  '),
                  color: WindowTokens.toneText,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
                child: TextGestures(
                  key: const ValueKey('ws-tl-mark-name'),
                  field: (k) => EditableText(
                    key: k,
                    rendererIgnoresPointer: true,
                    controller: markWords,
                    focusNode: markFocus,
                    style: TextStyles.micro(Grey.g13)
                        .copyWith(fontWeight: FontWeight.w700),
                    cursorColor: Grey.g13,
                    backgroundCursorColor: Grey.g38,
                    selectionColor: Grey.g13.withValues(
                      alpha: .3,
                    ), // Highlight for selected text.
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
