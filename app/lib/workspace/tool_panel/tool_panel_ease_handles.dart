// Draggable handles on an easing curve, ported one for one from AbsentMotion's Keyframes.kt (Alight Motion's easing kinds).
// The Kotlin is ported rather than run because Kotlin does not run in this app.
// A yellow handle changes the shape of the curve; a white one marks where the curve starts and ends.
// Each handle carries the function that turns its new position into the changed easing.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart';

/// One draggable handle on an easing curve.
class EaseHandle {
  const EaseHandle(
    this.x,
    this.y,
    this.moved, {
    this.param = false,
    this.fromX,
    this.fromY,
    this.dashed = false,
    this.overshoot = false,
    this.damping = 1,
    this.along = false,
  });

  /// Position of the handle on the graph, both in 0..1 unless [overshoot] is set.
  final double x, y;

  /// Whether this is a shape handle, drawn yellow.
  final bool param;

  /// Whether only the stem is drawn dashed. Used by Random.
  final bool dashed;

  /// Whether the handle can go past 0 and 1.
  final bool overshoot;

  /// Whether the handle moves along the line x = y, so x and y change together.
  final bool along;

  /// Where the stem of the handle starts.
  final double? fromX, fromY;

  final double damping;

  /// Returns the easing that results from dragging the handle to (x, y).
  final Ease Function(double x, double y) moved;
}

const _shortest = 0.02;
double _legal(double v, double lo, double hi) => v.clamp(lo, hi);

/// The handles of an easing. Bezier has its two control points; the other kinds take theirs from the numbers in the name.
List<EaseHandle> easeHandles(Ease e) {
  if (easeIsTurned(said(e))) {
    // A reversed easing uses the handles of the original, flipped end for end, as AbsentMotion's handles() does.
    return [
      for (final h in easeHandles(heard(easeTurn(said(e)))))
        EaseHandle(
          1 - h.x,
          1 - h.y,
          (x, y) => heard(easeTurn(said(h.moved(1 - x, 1 - y)))),
          param: h.param,
          fromX: h.fromX == null ? null : 1 - h.fromX!,
          fromY: h.fromY == null ? null : 1 - h.fromY!,
          dashed: h.dashed,
          overshoot: h.overshoot,
          damping: h.damping,
        ),
    ];
  }
  if (e.kind == EaseKind.hold) return const [];
  if (e.name == 'Linear') {
    // A curve dragged straight is still a curve: its handles stay where the user dropped them.
    return [
      EaseHandle(.25, .25, (x, y) => e.withHandles(Offset(x, y), const Offset(.75, .75)), fromX: 0, fromY: 0),
      EaseHandle(.75, .75, (x, y) => e.withHandles(const Offset(.25, .25), Offset(x, y)), fromX: 1, fromY: 1),
    ];
  }
  if (!easeOther(e)) {
    return [
      EaseHandle(e.p1.dx, e.p1.dy, (x, y) => e.withHandles(Offset(x, y), e.p2), fromX: 0, fromY: 0),
      EaseHandle(e.p2.dx, e.p2.dy, (x, y) => e.withHandles(e.p1, Offset(x, y)), fromX: 1, fromY: 1),
    ];
  }
  final w = e.name!.split(' '), kind = w.first, numbers = [for (final x in w.skip(1)) double.tryParse(x)];
  double p(int i, double usual, double lo, double hi) => (i < numbers.length ? numbers[i] ?? usual : usual).clamp(lo, hi);
  double raw(int i, double usual) => i < numbers.length ? numbers[i] ?? usual : usual;
  Ease as(List<double> q) => Ease(e.kind, e.p1, e.p2, '$kind ${q.join(' ')}');
  switch (kind) {
    case 'Bounce':
      final length = p(0, .3, _shortest, 1), bounciness = p(1, .8, 0, .95);
      return [
        EaseHandle(
          length * (1 + bounciness) / 2,
          1 - bounciness,
          (x, y) {
            final b = _legal(1 - y, 0, .95);
            return as([_legal(2 * x / (1 + b), _shortest, 1), b]);
          },
          param: true,
          fromX: length / 2,
          fromY: 1,
        ),
      ];
    case 'Elastic':
      final half = p(0, .25, _shortest, 1 - _shortest), unused = raw(1, 1), decay = p(2, .5, 0, 1), strength = p(3, 1, 0, 1);
      double left(double a, double c) => math.pow(1 - a, 1 + 15 * c * c).toDouble();
      final tail = (1 + half) / 2;
      return [
        EaseHandle(
          half,
          1 + strength * left(half, decay),
          (x, y) {
            final a = _legal(x, _shortest, 1 - _shortest), room = left(a, decay);
            return as([a, unused, decay, room < 1e-4 ? strength : _legal((y - 1) / room, 0, 1)]);
          },
          param: true,
          fromX: half,
          fromY: 1,
          overshoot: true,
        ),
        EaseHandle(tail, 1.5 - decay / 2, (_, y) => as([half, unused, _legal(3 - 2 * y, 0, 1), strength]), param: true, fromX: tail, fromY: 1, overshoot: true),
      ];
    case 'Cyclic':
      final period = p(0, 2 / 7, _shortest, 1),
          sharpness = p(1, 0, 0, 1),
          crest = p(2, .5, _shortest, 1 - _shortest),
          floor = p(3, 0, 0, 1),
          unused = raw(4, 0);
      final top = crest * period;
      return [
        EaseHandle(period, floor * period, (x, _) => as([_legal(x, _shortest, 1), sharpness, crest, floor, unused]), param: true),
        EaseHandle(top, 1, (x, _) => as([period, sharpness, _legal(x / period, _shortest, 1 - _shortest), floor, unused]), param: true),
        EaseHandle(top, sharpness / 2, (_, y) => as([period, _legal(2 * y, 0, 1), crest, floor, unused]), param: true, fromX: top, fromY: 0),
        EaseHandle(1, floor, (_, y) => as([period, sharpness, crest, _legal(y, 0, 1), unused]), param: true, fromX: 0, fromY: 0),
      ];
    case 'Random':
      final frequency = p(0, .5, 0, 1),
          magnitude = p(1, .5, 0, 1),
          seed = p(2, .5, 0, 1),
          attenuation = p(3, .5, 0, 1),
          warp = p(4, .5, 0, 1),
          tilt = p(5, 0, 0, 1);
      final pulled = math.pow(.5, 1 + 10 * (warp - .5).abs()).toDouble(), bent = warp < .5 ? pulled : 1 - pulled;
      double warpAt(double y) {
        final v = y.clamp(1 / 64, 63 / 64), k = (v < .5 ? math.log(1 / v) : math.log(1 / (1 - v))) / math.ln2;
        return (v < .5 ? .5 - (k - 1) / 10 : .5 + (k - 1) / 10).clamp(0.0, 1.0);
      }
      final wobbleX = .85 - attenuation / 2, wobbleY = .5 + magnitude / 2;
      return [
        EaseHandle(0, tilt, (_, y) => as([frequency, magnitude, seed, attenuation, warp, _legal(y, 0, 1)]), param: true),
        EaseHandle(.5, bent, (_, y) => as([frequency, magnitude, seed, attenuation, warpAt(y), tilt]), param: true, fromX: .5, fromY: .5),
        EaseHandle(
          wobbleX,
          wobbleY,
          (x, y) => as([frequency, _legal(2 * y - 1, 0, 1), seed, _legal(1.7 - 2 * x, 0, 1), warp, tilt]),
          param: true,
          fromX: wobbleX,
          fromY: wobbleY,
          dashed: true,
        ),
        EaseHandle(frequency, 1, (x, _) => as([_legal(x, 0, 1), magnitude, seed, attenuation, warp, tilt]), param: true),
        EaseHandle(seed, 0, (x, _) => as([frequency, magnitude, _legal(x, 0, 1), attenuation, warp, tilt]), param: true),
      ];
    case 'Steps':
      final length = p(0, .25, _shortest, 1), smoothing = p(1, 0, 0, 1);
      return [
        EaseHandle(length, length, (x, y) => as([_legal((x + y) / 2, _shortest, 1), smoothing]), param: true, along: true),
        EaseHandle(length * (1 - smoothing), 0, (x, _) => as([length, _legal(1 - x / length, 0, 1)]), param: true, fromX: length, fromY: 0),
      ];
    case 'ElasticSteps':
      final length = p(0, .2, _shortest, 1), overshoot = p(1, .5, 0, 1), crest = math.min(1.0, length * (1.5 - .45 * overshoot));
      return [
        EaseHandle(length, 0, (x, _) => as([_legal(x, _shortest, 1), overshoot]), param: true),
        EaseHandle(
          crest,
          length + overshoot / 4,
          (_, y) => as([length, _legal(4 * (y - length), 0, 1)]),
          param: true,
          fromX: crest,
          fromY: length,
          overshoot: true,
          damping: .5,
        ),
      ];
  }
  return const [];
}

/// The vertical range the graph shows for an easing, as in AbsentMotion's EasingPanel.kt geoOf.
(double, double) easeReach(Ease e, [bool overshoot = false]) => overshoot
    ? (-2, 3)
    : easeIsTurned(said(e))
    ? switch ((easeReach(heard(easeTurn(said(e)))), said(e).startsWith('Reverse:Elastic') ? .6 : 1.0)) {
        ((final lo, final hi), final origin) => (origin - hi, origin - lo),
      }
    : switch (e.kind == EaseKind.hold || !easeOther(e) ? 'Bezier' : e.name!.split(' ').first) {
        'Elastic' => (-.3, 2.05),
        'Cyclic' => (-.5, 1.5),
        _ => (-.25, 1.25),
      };
