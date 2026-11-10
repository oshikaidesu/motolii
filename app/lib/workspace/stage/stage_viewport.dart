// The stage's viewport geometry: where the composition lies in the pane at a zoom step and a pan, and the conversion
// between composition pixels and screen pixels.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart' show immutable;

/// Zoom steps of the header chip: fit, then fixed scales.
const stageZooms = ['Fit', '50%', '100%'];

/// The scale of each zoom step. The first step has none: it fits the composition to the pane.
const _fixedScales = [0.0, .5, 1.0];

/// Where the composition lies on the screen.
///
/// The composition's top-left corner is at [origin], it is drawn at [scale] screen pixels per composition pixel, and
/// [area] is the part of the pane it is shown in.
@immutable
class StageViewport {
  /// A viewport with the composition's top-left at [origin] and [scale] screen pixels per composition pixel.
  const StageViewport(this.origin, this.scale, this.area, this.composition);

  /// The viewport of a pane of [size] that has a [ruler] band along its top and its left.
  ///
  /// At [zoom] 0 the composition is fitted into the rest of the pane with [margin] left free on every side, and never
  /// drawn smaller than a fiftieth of its size. At a later step of [stageZooms] it has that step's scale. It is
  /// centred in the area and then moved by [pan].
  factory StageViewport.of(
    Size size, {
    required Size composition,
    required int zoom,
    required Offset pan,
    required double ruler,
    required double margin,
  }) {
    final area = Rect.fromLTRB(ruler, ruler, size.width, size.height);
    final fit = math.max(
      .02,
      math.min(
        (area.width - margin * 2) / composition.width,
        (area.height - margin * 2) / composition.height,
      ),
    );
    final s = zoom == 0 ? fit : _fixedScales[zoom];
    final half = Offset(composition.width * s, composition.height * s) / 2;
    return StageViewport(area.center - half + pan, s, area, composition);
  }

  /// The screen position of the composition's top-left corner.
  final Offset origin;

  /// Screen pixels per composition pixel.
  final double scale;

  /// The part of the pane the composition is shown in: the pane without its rulers.
  final Rect area;

  /// The composition's size in its own pixels.
  final Size composition;

  /// The composition's rectangle on the screen.
  Rect get compositionRect => origin & composition * scale;

  /// The screen position of the composition point [p].
  Offset toScreen(Offset p) => origin + p * scale;

  /// The composition point shown at the screen position [p].
  Offset toComposition(Offset p) => (p - origin) / scale;

  /// The [pan] nearest to the one asked for that keeps the composition in reach.
  ///
  /// The composition may be moved off the middle of [area] until 60 screen pixels of it are left inside, on each axis.
  Offset clampPan(Offset pan) {
    final limit = Offset(
      composition.width * scale / 2 + area.width / 2 - 60,
      composition.height * scale / 2 + area.height / 2 - 60,
    );
    return Offset(
      pan.dx.clamp(-limit.dx, limit.dx),
      pan.dy.clamp(-limit.dy, limit.dy),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StageViewport &&
      other.origin == origin &&
      other.scale == scale &&
      other.area == area &&
      other.composition == composition;
  @override
  int get hashCode => Object.hash(origin, scale, area, composition);
}
