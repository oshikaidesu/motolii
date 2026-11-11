// The Relations map: the world rotated and fitted to the panel, and the painter that draws it.
import 'package:motolii/workspace/tool_panel/relations_world.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart';

/// The world rotated and fitted to the map.
class MapView {
  MapView(
    this.world,
    this.size,
    double yaw,
    double pitch, {
    Map<String, List<MapPoint3>> paths = const {},
    double zoom = 1,
  }) : _cy = math.cos(yaw),
       _sy = math.sin(yaw),
       _cp = math.cos(pitch),
       _sp = math.sin(pitch) {
    // Fit to the layers and their paths, not the camera's frame, so what moves fills the map. Scrolling zooms in.
    final all = [
      for (final (p, _, _) in world.things.values) _turn(p),
      for (final w in paths.values)
        for (final p in w) _turn(p),
    ];
    if (all.isEmpty) all.addAll([for (final p in _frame) _turn(p)]);
    var r = Rect.fromCenter(center: all.first, width: .2, height: .2);
    for (final p in all) {
      r = r.expandToInclude(Rect.fromCenter(center: p, width: 0, height: 0));
    }
    _fit = r.inflate(r.longestSide * .08 + .05);
    _scale =
        math.min(size.width / _fit.width, size.height / _fit.height) * zoom;
  }
  final MapWorld world;
  final Size size;
  final double _cy, _sy, _cp, _sp;
  late final Rect _fit;
  late final double _scale;

  List<MapPoint3> get _frame => [
    for (final (sx, sy) in const [
      (-1.0, -1.0),
      (1.0, -1.0),
      (1.0, 1.0),
      (-1.0, 1.0),
    ])
      (x: sx * world.half.width, y: sy * world.half.height, z: 0.0),
  ];

  Offset _turn(MapPoint3 p) {
    // Rotated about the up axis, then tilted: x to the right, y up on the map.
    final x = p.x * _cy + p.z * _sy, z = -p.x * _sy + p.z * _cy;
    return Offset(x, p.y * _cp - z * _sp);
  }

  Offset on(MapPoint3 p) {
    final q = _turn(p);
    return Offset(
      size.width / 2 + (q.dx - _fit.center.dx) * _scale,
      size.height / 2 - (q.dy - _fit.center.dy) * _scale,
    );
  }

  /// The axes gizmo in the corner, as in Blender: the end of each axis, rotated with the world (x red, y green, z blue).
  Offset get axisMiddle => Offset(size.width - 38, size.height - 38);
  Map<String, Offset> get axisEnds => {
    for (final (n, p) in const [
      ('x', (x: 1.0, y: 0.0, z: 0.0)),
      ('y', (x: 0.0, y: 1.0, z: 0.0)),
      ('z', (x: 0.0, y: 0.0, z: 1.0)),
    ])
      n: axisMiddle + Offset(_turn(p).dx, -_turn(p).dy) * 20,
  };
  String? axisAt(Offset at) {
    for (final e in axisEnds.entries) {
      if ((e.value - at).distance < 9) return e.key;
    }
    return null;
  }

  /// The layer nearest the tap.
  String? hit(Offset at) {
    String? best;
    var d = 16.0;
    for (final e in world.things.entries) {
      final o = (on(e.value.$1) - at).distance;
      if (o < d) (best, d) = (e.key, o);
    }
    return best;
  }
}

class RelationsMapPainter extends CustomPainter {
  RelationsMapPainter(this.v, this.selected, this.paths, this.stations);
  final MapView v;
  final String? selected;
  // paths: the picked layer's path. stations: a picked relation's shapes at its keyframes.
  final Map<String, List<MapPoint3>> paths, stations;

  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // The camera's frame and where the camera stands.
    line.color = WindowTokens.toneCamera;
    c.drawPath(
      Path()..addPolygon([for (final p in v._frame) v.on(p)], true),
      line,
    );
    if (v.world.camera case final cam?) {
      c.drawCircle(v.on(cam), 5, Paint()..color = WindowTokens.toneCamera);
    }
    // Each relation's leader and its threads to its layers, in its own colour.
    for (final r in v.world.relations) {
      final hue = layerLabelColor(r.id),
          picked = r.id == selected; // The same label colour as its row.
      line
        ..color = hue.withValues(alpha: picked ? 1 : .7)
        ..strokeWidth = picked ? 2 : 1;
      final lead = v.world.things[r.leader]?.$1;
      if (lead != null) {
        for (final m in r.members) {
          if (v.world.things[m]?.$1 case final p?) {
            c.drawLine(v.on(lead), v.on(p), line);
          }
        }
        c.drawCircle(v.on(lead), 9, line); // Ring the leader.
      }
      for (final m in r.members) {
        if (v.world.things[m]?.$1 case final p?) {
          c.drawCircle(v.on(p), 7, Paint()..color = hue.withValues(alpha: .25));
        }
      }
    }
    // A layer's path as a thin line in its colour, and the points of it on the map.
    (Color, List<Offset>) trace(String id, List<MapPoint3> way, double alpha) {
      final hue = v.world.things[id]?.$2 ?? WindowTokens.accent,
          pts = [for (final p in way) v.on(p)];
      c.drawPath(
        Path()..addPolygon(pts, false),
        Paint()
          ..color = hue.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      return (hue, pts);
    }

    // Each moving layer's path over the duration, in its colour, with a dot per step.
    // A morph from one relation to another shows as the paths bending from one shape into the other.
    // An easing shows as the dots bunching up and spreading out.
    for (final e in paths.entries) {
      // As in After Effects, only the picked layer's path, with a dot per step.
      final (hue, pts) = trace(e.key, e.value, .6);
      for (final p in pts) {
        c.drawCircle(p, 1.4, Paint()..color = hue);
      }
    }
    for (final e in stations.entries) {
      // For a picked relation: where each layer stands at each of its keyframes, joined by straight lines and ringed.
      final (hue, pts) = trace(e.key, e.value, .35);
      for (final p in pts) {
        c.drawCircle(
          p,
          5,
          Paint()
            ..color = hue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
    // The layers, with the picked one ringed.
    for (final e in v.world.things.entries) {
      final at = v.on(e.value.$1);
      c.drawCircle(at, 4, Paint()..color = e.value.$2);
      // The outline keeps a dark layer visible on the dark map.
      c.drawCircle(
        at,
        4,
        Paint()
          ..color = Grey.g56
          ..style = PaintingStyle.stroke
          ..strokeWidth = .75,
      );
      if (e.key == selected) {
        c.drawCircle(
          at,
          8,
          Paint()
            ..color = WindowTokens.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    // The axes gizmo: a line to the end of each axis and a coloured ball with its letter. Tapping a ball looks from that side.
    const hue = {
      'x': Color(0xFFFF3352),
      'y': Color(0xFF8BDC00),
      'z': Color(0xFF2890FF),
    };
    final mid = v.axisMiddle;
    for (final e in v.axisEnds.entries) {
      c.drawLine(
        mid,
        e.value,
        Paint()
          ..color = hue[e.key]!
          ..strokeWidth = 1.5,
      );
      c.drawCircle(
        mid - (e.value - mid),
        3,
        Paint()..color = hue[e.key]!.withValues(alpha: .4),
      ); // The opposite end, faint.
    }
    for (final e in v.axisEnds.entries) {
      c.drawCircle(e.value, 7, Paint()..color = hue[e.key]!);
      toolText(
        c,
        e.key.toUpperCase(),
        e.value,
        TextStyles.micro(const Color(0xFF111111))
            .copyWith(fontWeight: FontWeight.w700),
        ax: .5,
        ay: .5,
      );
    }
  }

  @override
  bool shouldRepaint(RelationsMapPainter o) => true;
}
