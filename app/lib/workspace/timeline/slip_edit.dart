// Slip editing for video layers that are trimmed shorter than the source file.
// The part of the source outside the trim is drawn as a pale bar along the row. Dragging it changes which part of the
// source the layer shows, while the layer's in and out points stay where they are.
// This follows After Effects' slip edit and Premiere Pro's Slip tool.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/media/timeline_service.dart'
    as timeline_service;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';

/// The slip edit of a video layer: where its whole source file lies along the row, and the drag that moves it.
/// It notifies its listeners each time a drag has slipped the layer.
class SlipEdit extends ChangeNotifier {
  /// Slip editing that reads the length of each source file from `media`.
  SlipEdit({required this._media});

  final TimelineMediaCache _media;

  // The whole video's extent when the drag started.
  (int, int)? _whole;

  /// The frame range the whole source file would cover at the layer's current trim, or null.
  /// It is null when the layer is not a video or the file's length has not been read yet.
  (int, int)? wholeOf(WorkspaceController ws, Layer l) {
    final media = l.media;
    if (!timeline_service.isConnected(ws) || media == null || media.still) {
      return null;
    }
    final seconds = _media.secondsOf(ws, media.file);
    if (seconds == null || seconds <= 0) return null;
    final rate =
            WorkspaceController.fps /
            switch (media.speed.abs()) {
              0 => 1,
              final s => s,
            },
        from = l.inF - media.begin * rate;
    return (from.round(), (from + seconds * rate).round());
  }

  double _speedOf(WorkspaceController ws, int t) =>
      switch ((timeline_service.layerValue(ws, t, 'speed', 0) ?? 1).abs()) {
        0 => 1,
        final s => s,
      };

  /// Remembers where the whole source of [l] lies as a drag of its bar starts.
  void start(WorkspaceController ws, Layer l) {
    _whole = wholeOf(ws, l);
  }

  /// Slips the layer [t] by [by] frames from where the drag started, as far as its source reaches.
  /// [barIn] and [barOut] are the layer's in and out frames when the drag started; they do not move.
  void slipBy(
    WorkspaceController ws,
    int t,
    int by, {
    required int barIn,
    required int barOut,
  }) {
    final whole = _whole;
    if (whole == null) return;
    final to = by.clamp(
      math.min(0, barOut - whole.$2),
      math.max(0, barIn - whole.$1),
    );
    timeline_service.dragBarPart(
      ws,
      'begin',
      (barIn - whole.$1 - to) * _speedOf(ws, t) / WorkspaceController.fps,
    );
    notifyListeners();
  }
}
