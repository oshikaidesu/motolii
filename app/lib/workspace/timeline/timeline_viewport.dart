// How much of the project the timeline shows (zoom, scroll, the size of the track area) and where each frame lands.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:motolii/workspace/timeline/timeline_metrics.dart';

/// Where frames land on the track area at one moment.
@immutable
class TimelineView {
  const TimelineView(this.pixelsPerFrame, this.scroll);

  final double pixelsPerFrame;
  final double scroll;

  double x(num f) => TimelineMetrics.padL + (f - scroll) * pixelsPerFrame;

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

/// The timeline's zoom and scroll. [layout] does not notify (called while building).
class TimelineViewport extends ChangeNotifier {
  TimelineViewport(this._duration);

  final int Function() _duration;

  int get duration => _duration();

  /// 1 = whole project visible, [TimelineMetrics.maxZoom] = closest.
  double get zoom => _zoom;
  double _zoom = 1;

  double get scroll => _scroll;
  double _scroll = 0;

  double get verticalScroll => _verticalScroll;
  double _verticalScroll = 0;

  double get trackWidth => _trackWidth;
  double _trackWidth = 1000;

  double get rowsHeight => _rowsHeight;
  double _rowsHeight = 200;

  int _rows = 0;

  /// Pixels per frame at zoom 1 (whole project fits).
  double get fit => math.max(
    .1,
    (_trackWidth - TimelineMetrics.padL - TimelineMetrics.padR) / duration,
  );

  TimelineView get view => TimelineView(fit * _zoom, _scroll);

  double get visible => duration / _zoom;

  double clampScroll(double s) =>
      s.clamp(0.0, math.max(0.0, duration - visible)).toDouble();

  double clampVerticalScroll(int rows) => _verticalScroll
      .clamp(0.0, math.max(0.0, rows * TimelineMetrics.row - _rowsHeight))
      .toDouble();

  /// Updates track dimensions and clamps both scrolls.
  void layout({
    required double trackWidth,
    required double rowsHeight,
    required int rows,
  }) {
    _trackWidth = trackWidth;
    _rowsHeight = rowsHeight;
    _rows = rows;
    _scroll = clampScroll(_scroll);
    _verticalScroll = clampVerticalScroll(rows);
  }

  /// Zooms to [z], keeping frame [anchor] where it is on screen.
  void setZoom(double z, {required int anchor}) {
    final nz = z.clamp(1.0, TimelineMetrics.maxZoom);
    final a = anchor, ax = view.x(a);
    _zoom = nz;
    _scroll = clampScroll(a - (ax - TimelineMetrics.padL) / (fit * nz));
    notifyListeners();
  }

  /// Keeps frame [f] in view: jumps when it leaves, nudges in the outer 8 %.
  void follow(int f) {
    if (_zoom <= 1) return;
    final v = view, x = v.x(f);
    final right = _trackWidth - TimelineMetrics.padR;
    if (x < 0 || x > right) {
      _scroll = clampScroll(f - visible * .1);
      notifyListeners();
      return;
    }
    final margin = _trackWidth * .08;
    if (x < margin) {
      _scroll = clampScroll(_scroll - visible * .04 * ((margin - x) / margin));
    } else if (x > right - margin) {
      _scroll = clampScroll(
        _scroll + visible * .04 * ((x - (right - margin)) / margin),
      );
    } else {
      return;
    }
    notifyListeners();
  }

  /// Scrolls so that frame [s] is at the left end.
  void scrollTo(double s) {
    _scroll = clampScroll(s);
    notifyListeners();
  }

  void scrollBy(double pixels) {
    _scroll = clampScroll(_scroll + pixels / view.pixelsPerFrame);
    notifyListeners();
  }

  /// Scrolls the rows down by [pixels].
  void scrollRowsBy(double pixels) {
    final max = math.max(0.0, _rows * TimelineMetrics.row - _rowsHeight);
    _verticalScroll = (_verticalScroll + pixels).clamp(0.0, max).toDouble();
    notifyListeners();
  }
}
