// How much of the project the timeline shows (zoom, scroll, the size of the track area) and where each frame lands.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:motolii/workspace/timeline/timeline_metrics.dart';

/// Where frames land on the track area at one moment: x = padL + (frame - scroll) * pixelsPerFrame.
///
/// Painters are given one of these and repaint when it differs from the last one.
@immutable
class TimelineView {
  /// A view that draws each frame [pixelsPerFrame] wide, with frame [scroll] at the left.
  const TimelineView(this.pixelsPerFrame, this.scroll);

  /// The width of one frame on screen.
  final double pixelsPerFrame;

  /// The frame drawn at the left end of the track area, just after the left padding.
  final double scroll;

  /// The horizontal position of frame [f] in the track area.
  double x(num f) => TimelineMetrics.padL + (f - scroll) * pixelsPerFrame;

  /// The frame at horizontal position [x], with its fraction.
  double frameAt(double x) =>
      (x - TimelineMetrics.padL) / pixelsPerFrame + scroll;

  @override
  bool operator ==(Object other) =>
      other is TimelineView &&
      other.pixelsPerFrame == pixelsPerFrame &&
      other.scroll == scroll;
  @override
  int get hashCode => Object.hash(pixelsPerFrame, scroll);
}

/// The timeline's zoom and scroll, and the size of its track area.
///
/// It notifies its listeners when a gesture changes the zoom or the scroll. [layout] does not notify, because it is
/// called while the timeline is being built.
class TimelineViewport extends ChangeNotifier {
  /// A viewport over a project whose length in frames is what the given function returns each time it is asked.
  TimelineViewport(this._duration);

  final int Function() _duration;

  /// The project's length in frames.
  int get duration => _duration();

  /// How far the timeline is zoomed in: 1 shows the whole project, [TimelineMetrics.maxZoom] is the closest.
  double get zoom => _zoom;
  double _zoom = 1;

  /// The frame drawn at the left end of the track area.
  double get scroll => _scroll;
  double _scroll = 0;

  /// How far the rows are scrolled down, in pixels.
  double get verticalScroll => _verticalScroll;
  double _verticalScroll = 0;

  /// The width of the track area, in pixels.
  double get trackWidth => _trackWidth;
  double _trackWidth = 1000;

  /// The height left for the rows between the ruler and the overview strip, in pixels.
  double get rowsHeight => _rowsHeight;
  double _rowsHeight = 200;

  /// The width of one frame at zoom 1, where the whole project fits between the left and right padding.
  double get fit => math.max(
    .1,
    (_trackWidth - TimelineMetrics.padL - TimelineMetrics.padR) / duration,
  );

  /// Where frames land at the present zoom and scroll.
  TimelineView get view => TimelineView(fit * _zoom, _scroll);

  /// How many frames of the project are shown at the present zoom.
  double get visible => duration / _zoom;

  /// The scroll [s] kept between the project's start and the last position that still fills the track area.
  double clampScroll(double s) =>
      s.clamp(0.0, math.max(0.0, duration - visible)).toDouble();

  /// The vertical scroll kept between the first row and the last position that still fills the rows area,
  /// when there are [rows] rows.
  double clampVerticalScroll(int rows) => _verticalScroll
      .clamp(0.0, math.max(0.0, rows * TimelineMetrics.row - _rowsHeight))
      .toDouble();

  /// Takes the size of the track area as it was laid out, and keeps both scrolls inside it.
  void layout({
    required double trackWidth,
    required double rowsHeight,
    required int rows,
  }) {
    _trackWidth = trackWidth;
    _rowsHeight = rowsHeight;
    _scroll = clampScroll(_scroll);
    _verticalScroll = clampVerticalScroll(rows);
  }

  /// Zooms to [z], keeping frame [anchor] where it is on screen as far as the scroll limits allow.
  void setZoom(double z, {required int anchor}) {
    final nz = z.clamp(1.0, TimelineMetrics.maxZoom);
    final a = anchor, ax = view.x(a);
    _zoom = nz;
    _scroll = clampScroll(a - (ax - TimelineMetrics.padL) / (fit * nz));
    notifyListeners();
  }

  /// Keeps frame [f] in view when zoomed in: the view pages along when [f] is off either edge.
  void follow(int f) {
    if (_zoom <= 1) return;
    final v = view, x = v.x(f);
    if (x >= 0 && x <= _trackWidth - TimelineMetrics.padR) return;
    _scroll = clampScroll(f - visible * .1);
    notifyListeners();
  }

  /// Scrolls so that frame [s] is at the left end, as far as the scroll limits allow.
  void scrollTo(double s) {
    _scroll = clampScroll(s);
    notifyListeners();
  }

  /// Scrolls sideways by [pixels] of track.
  void scrollBy(double pixels) {
    _scroll = clampScroll(_scroll + pixels / view.pixelsPerFrame);
    notifyListeners();
  }

  /// Scrolls the rows down by [pixels]. The next [layout] keeps the result inside the rows.
  void scrollRowsBy(double pixels) {
    _verticalScroll = _verticalScroll + pixels;
    notifyListeners();
  }
}
