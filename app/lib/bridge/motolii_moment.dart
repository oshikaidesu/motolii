// The time snapshot reader (docs/app/BRIDGE.md M): where layers are and what they show at the snapshot's time.
// The engine rebuilds the snapshot with each frame.
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_watch.dart';

extension MotoliiMoment on Motolii {
  Map<String, dynamic>? _momentOf(int layer) =>
      (momentSnapshot['layer'] as Map<String, dynamic>)['$layer']
          as Map<String, dynamic>?;

  /// Whether [at] is the time of the time snapshot, to within a frame.
  bool _isNow(double at) =>
      (((momentSnapshot['now'] as num?)?.toDouble() ?? -1) - at).abs() <
      .5 / rate;

  /// The time of the frame the stage last drew. The playhead follows it during playback.
  double get now => (momentSnapshot['now'] as num?)?.toDouble() ?? 0;

  /// A property's own value at [at], not what a relation makes of it (see [shows]).
  ///
  /// A property without keyframes comes from the project snapshot. An animated one comes from the time snapshot.
  double? value(int layer, String name, double at) {
    if (!moving(layer).contains(name) || at == 0) {
      return ((layerSnapshot(layer)['value'] as Map<String, dynamic>?)?[name]
                  as num?)
              ?.toDouble() ??
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
      return (((layerSnapshot(layer)['keyValues']
                      as Map<String, dynamic>?)?[name]
                  as List<dynamic>?)?[i]
              as num?)
          ?.toDouble(); // [at] is on a keyframe, so use that keyframe's value.
    }
    return _unasked('value', layer, name, at);
  }

  /// Handles a read that neither snapshot holds, such as another time of a layer that is not watched.
  ///
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
    final v =
        (_momentOf(layer)?['shows'] as Map<String, dynamic>?)?[name]
            as List<dynamic>?;
    return v == null ? null : ((v[0] as num).toDouble(), v[1] as bool);
  }

  /// How the working camera sees a camera layer, as the engine describes it (doc_gizmo). Empty means through its own view.
  String gizmo(int layer) => _momentOf(layer)?['gizmo'] as String? ?? '';

  /// A layer's box on the canvas at the stage's time, or null if it is not shown.
  ///
  /// The numbers are center (x, y), width, height (canvas points from the top left), rotation (degrees, clockwise),
  /// the rotation anchor (x, y) and depth (0 is flat).
  List<double>? bounds(int layer) => switch (_momentOf(layer)?['bounds']) {
    final List<dynamic> f => Motolii.numbers(f),
    _ => null,
  };

  /// The axis-aligned bounding box of the layer's visible outline, in canvas points from the top left. Null if it is not shown.
  Rect? seen(int layer) => switch (_momentOf(layer)?['seen']) {
    final List<dynamic> b => Rect.fromLTRB(
      (b[0] as num).toDouble(),
      (b[1] as num).toDouble(),
      (b[2] as num).toDouble(),
      (b[3] as num).toDouble(),
    ),
    _ => null,
  };

  /// The points of a path shape as drawn on the canvas, for the selected layer only and without handles. Empty if none.
  List<Offset> points(int layer) {
    final p = Motolii.numbers(_momentOf(layer)?['points']);
    return [for (var i = 0; i + 1 < p.length; i += 2) Offset(p[i], p[i + 1])];
  }

  /// The path's curve handles in the same way, each paired with the point it belongs to.
  List<(Offset, Offset)> handles(int layer) {
    final h = Motolii.numbers(_momentOf(layer)?['handles']),
        of = Motolii.numbers(_momentOf(layer)?['of']);
    return [
      for (var i = 0; i + 1 < h.length; i += 2)
        (
          Offset(h[i], h[i + 1]),
          i + 1 < of.length ? Offset(of[i], of[i + 1]) : Offset(h[i], h[i + 1]),
        ),
    ];
  }
}
