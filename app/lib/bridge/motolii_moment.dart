// The time snapshot reader (docs/app/BRIDGE.md M): where layers are and what they show at the snapshot's time.
// Hot-path data (bounds, seen, shows) comes from the binary time layout; detail
// data (gizmo, value, points, handles) from the JSON detail snapshot.
import 'dart:typed_data' show Float64List;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/snapshot_parts.dart' show numbers;

extension MotoliiMoment on Motolii {
  // Shows property name → offset within the 14-double shows block.
  static const _showsOff = {
    'x': 0,
    'y': 2,
    'z': 4,
    'rotate': 6,
    'scale_x': 8,
    'scale_y': 10,
    'opacity': 12,
  };

  /// The layer that [t] is parented to, or 0 when it has none.
  int parentOf(int t) => (value(t, 'parent', 0) ?? 0).round();

  /// The outermost ancestor of [t] (itself when it has no parent), following the parents up to 64 steps.
  int outermost(int t) {
    for (var p = parentOf(t), n = 0; p > 0 && n < 64; p = parentOf(t), n++) {
      t = p;
    }
    return t;
  }

  Map<String, dynamic>? _momentOf(int layer) =>
      (momentSnapshot['layer'] as Map<String, dynamic>)['$layer']
          as Map<String, dynamic>?;

  /// Whether [at] is the time of the time snapshot, to within a frame.
  bool _isNow(double at) {
    final t = timeLayout.isNotEmpty
        ? timeLayout[0]
        : (momentSnapshot['now'] as num?)?.toDouble() ?? -1;
    return (t - at).abs() < .5 / rate;
  }

  /// The time of the frame the stage last drew. The playhead follows it during playback.
  double get now => timeLayout.isNotEmpty
      ? timeLayout[0]
      : (momentSnapshot['now'] as num?)?.toDouble() ?? 0;

  /// A property's own value at [at], not what a relation makes of it (see [shows]).
  /// A property without keyframes comes from the project snapshot. An animated one comes from the time snapshot.
  double? value(int layer, String name, double at) {
    if (!isMoving(layer, name) || at == 0) {
      return (partOf(layer, 'value', name) as num?)?.toDouble() ??
          usual(
            layer,
            name,
          ); // The project snapshot holds each property's value at time 0.
    }
    if (_isNow(at)) {
      // The time snapshot holds the selected layer and the layers being watched (see [subscribe]).
      if ((_momentOf(layer)?['value'] as Map<String, dynamic>?)?[name]
          case final num v) {
        return v.toDouble();
      }
    }
    final keys = keyTimes(layer, name),
        i = keys.indexWhere((k) => (k - at).abs() < .5 / rate);
    if (i >= 0) {
      return ((partOf(layer, 'keyValues', name) as List<dynamic>?)?[i] as num?)
          ?.toDouble(); // [at] is on a keyframe, so use that keyframe's value.
    }
    return _unasked('value', layer, name, at);
  }

  /// Handles a read that neither snapshot holds, such as another time of a layer that is not watched.
  /// It does not ask the engine, because the app would block (docs/app/BRIDGE.md rule 1). Ask with [shownAt] or watch
  /// the layer with [subscribe]. A message is printed once per property.
  double? _unasked(String what, int layer, String name, double at) {
    // Just started watching: the value arrives with the next frame.
    if (watched.contains(layer)) return null;
    if (unaskedSaid.add('$what $name')) {
      debugPrint(
        'BRIDGE: $what($layer, $name, $at) is not in the pictures: ask it ([shownAt]) or watch the thing',
      );
    }
    return null;
  }

  /// A property as the stage shows it, after any relation or behaviour, and whether one drives it. Null if unavailable.
  (double, bool)? shows(int layer, String name, double at) {
    if (!_isNow(at)) {
      _unasked('shows', layer, name, at);
      return null;
    }
    // Binary path.
    final base = timeIndex[layer];
    final off = _showsOff[name];
    if (base != null && off != null) {
      final v = timeLayout[base + 12 + off];
      if (v.isNaN) return null;
      return (v, timeLayout[base + 12 + off + 1] != 0);
    }
    // JSON fallback (old dylib without motolii_time_layout).
    final v =
        (_momentOf(layer)?['shows'] as Map<String, dynamic>?)?[name]
            as List<dynamic>?;
    return v == null ? null : ((v[0] as num).toDouble(), v[1] as bool);
  }

  /// How the working camera sees a camera layer, as the engine describes it (doc_gizmo). Empty means through its own view.
  String gizmo(int layer) => _momentOf(layer)?['gizmo'] as String? ?? '';

  /// A layer's box on the canvas at the stage's time, or null if it is not shown.
  /// The numbers are center (x, y), width, height (canvas points from the top left), rotation (degrees, clockwise),
  /// the rotation anchor (x, y) and depth (0 is flat).
  List<double>? bounds(int layer) {
    final base = timeIndex[layer];
    if (base != null) {
      if (timeLayout[base].isNaN) return null;
      return Float64List.sublistView(timeLayout, base, base + 8);
    }
    return switch (_momentOf(layer)?['bounds']) {
      final List<dynamic> f => numbers(f),
      _ => null,
    };
  }

  /// The axis-aligned bounding box of the layer's visible outline, in canvas points from the top left. Null if it is not shown.
  Rect? seen(int layer) {
    final base = timeIndex[layer];
    if (base != null) {
      if (timeLayout[base + 8].isNaN) return null;
      return Rect.fromLTRB(
        timeLayout[base + 8],
        timeLayout[base + 9],
        timeLayout[base + 10],
        timeLayout[base + 11],
      );
    }
    return switch (_momentOf(layer)?['seen']) {
      final List<dynamic> b => Rect.fromLTRB(
        (b[0] as num).toDouble(),
        (b[1] as num).toDouble(),
        (b[2] as num).toDouble(),
        (b[3] as num).toDouble(),
      ),
      _ => null,
    };
  }

  /// The points of a path shape as drawn on the canvas, for the selected layer only and without handles. Empty if none.
  List<Offset> points(int layer) {
    final p = numbers(_momentOf(layer)?['points']);
    return [for (var i = 0; i + 1 < p.length; i += 2) Offset(p[i], p[i + 1])];
  }

  /// The path's curve handles in the same way, each paired with the point it belongs to.
  List<(Offset, Offset)> handles(int layer) {
    final h = numbers(_momentOf(layer)?['handles']),
        of = numbers(_momentOf(layer)?['of']);
    return [
      for (var i = 0; i + 1 < h.length; i += 2)
        (
          Offset(h[i], h[i + 1]),
          i + 1 < of.length ? Offset(of[i], of[i + 1]) : Offset(h[i], h[i + 1]),
        ),
    ];
  }
}
