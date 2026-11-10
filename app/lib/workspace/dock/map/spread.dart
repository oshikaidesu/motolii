// Pushes the items of a shelf's map apart until none covers another.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:force_graph/force_graph.dart'
    show CollideForce, Force, ForceNode, ForceSimulation;

/// A tile's collision radius on the map, in canvas pixels (FontMap uses 13).
const mapTileRadius = 13.0;

/// Pushes [at] apart until no two are within two [mapTileRadius] of each other, keeping each near where it was.
///
/// [at] holds positions from 0 to 1 on each axis. [aspect] is the viewport's width to height. The canvas has the area of
/// FontMap's 1920 x 1080, in the shape of the viewport. Returns the positions on that canvas.
///
/// This follows FontMap's scripts/apply-overlap-removal.mjs (MIT) with its numbers: 40 px padding, radius 13, 140 ticks
/// and a pull back to the start position of 0.03. It uses force_graph (MIT), a Dart port of d3-force, with d3's cooling.
///
/// [squeeze], from 0 to 1, also pulls every item toward the middle, at most at d3's default forceX strength of 0.1.
/// This is Obsidian's graph "Center force". Afterwards the pulls are removed and 40 more collision ticks clear any
/// overlap they caused, as FontMap's cartogram.js (src/experiments/engine/cartogram.js, relax) does.
List<Offset> spreadApart(List<Offset> at, double aspect, double squeeze) {
  const pad = 40.0, r = mapTileRadius, pull = 0.03;
  final w = math.sqrt(1920 * 1080 * aspect), h = 1920 * 1080 / w;
  final nodes = [
    for (final (i, p) in at.indexed)
      ForceNode(id: '$i')
        ..x = p.dx * (w - 2 * pad) + pad
        ..y = p.dy * (h - 2 * pad) + pad,
  ];
  final collide = CollideForce(radius: (_) => r),
      sim = ForceSimulation(nodes)
        ..alphaDecay =
            1 -
            math
                .pow(0.001, 1 / 300)
                // d3's value. force_graph keeps the one from its Apeirron graph.
                .toDouble()
        ..alphaTarget = 0
        ..addForce(collide)
        ..addForce(_Toward([for (final n in nodes) Offset(n.x, n.y)], pull));
  if (squeeze > 0) {
    sim.addForce(
      _Toward(List.filled(nodes.length, Offset(w / 2, h / 2)), squeeze * .1),
    );
  }
  for (var tick = 0; tick < 140; tick++) {
    sim.tick();
  }
  if (squeeze > 0) {
    sim
      ..clearForces()
      ..addForce(collide);
    for (var tick = 0; tick < 40; tick++) {
      sim.tick();
    }
  }
  return [for (final n in nodes) Offset(n.x, n.y)];
}

/// d3-force's forceX and forceY (x.js, y.js; ISC) in one force, which force_graph leaves out.
/// Each node is pulled toward its own point in [to], scaled by [strength] and the current alpha.
class _Toward implements Force {
  _Toward(this.to, this.strength);
  final List<Offset> to;
  final double strength;
  var _nodes = const <ForceNode>[];
  @override
  void initialize(List<ForceNode> nodes, _) => _nodes = nodes;
  @override
  void apply(double alpha) {
    for (final (i, n) in _nodes.indexed) {
      n
        ..vx += (to[i].dx - n.x) * strength * alpha
        ..vy += (to[i].dy - n.y) * strength * alpha;
    }
  }
}
