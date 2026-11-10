// An easing: a kind, two bezier handles and the presets that have a tile.
import 'package:flutter/widgets.dart';

enum EaseKind { bezier, hold }

/// One easing: a kind and two bezier handles.
/// The handles are kept even when another kind is shown, so dragging a handle switches back to bezier.
class Ease {
  const Ease(this.kind, this.p1, this.p2, [this.name, this.drawn]);
  final EaseKind kind;
  final Offset p1, p2;
  final String? name;

  /// Samples of an easing that has no tile in the tool panel, as the document evaluates it, at even steps along the span.
  final List<double>? drawn;

  double at(double x) => drawn != null
      ? easeAlong(drawn!, x)
      : switch (kind) {
          EaseKind.bezier => Cubic(
            p1.dx,
            p1.dy,
            p2.dx,
            p2.dy,
          ).transform(x.clamp(0.0, 1.0)),
          EaseKind.hold => x < 1 ? 0 : 1,
        };

  Ease withHandles(Offset a, Offset b) => Ease(EaseKind.bezier, a, b);
  Ease reversed() => Ease(
    kind,
    Offset(1 - p2.dx, 1 - p2.dy),
    Offset(1 - p1.dx, 1 - p1.dy),
    name,
  );

  @override
  bool operator ==(Object other) =>
      other is Ease &&
      other.kind == kind &&
      other.p1 == p1 &&
      other.p2 == p2 &&
      identical(other.drawn, drawn);
  @override
  int get hashCode => Object.hash(kind, p1, p2);
}

/// Interpolates the evenly spaced samples [ys] at [x], which is clamped to 0 to 1.
double easeAlong(List<double> ys, double x) {
  final at = x.clamp(0.0, 1.0) * (ys.length - 1),
      i = at.floor().clamp(0, ys.length - 2);
  return ys[i] + (ys[i + 1] - ys[i]) * (at - i);
}

const easingPresets = [
  Ease(EaseKind.bezier, Offset(0, 0), Offset(1, 1), 'Linear'),
  Ease(EaseKind.bezier, Offset(.25, .1), Offset(.25, 1), 'Ease'),
  Ease(EaseKind.bezier, Offset(.42, 0), Offset(1, 1), 'In'),
  Ease(EaseKind.bezier, Offset(0, 0), Offset(.58, 1), 'Out'),
  Ease(EaseKind.bezier, Offset(.42, 0), Offset(.58, 1), 'In-out'),
  Ease(EaseKind.bezier, Offset(.34, 1.56), Offset(.64, 1), 'Back'),
  Ease(EaseKind.hold, Offset(.25, .1), Offset(.25, 1), 'Hold'),
];

/// Finds a preset by its name, not by its position, so adding a tile never changes the others.
Ease easingPreset(String name) =>
    easingPresets.firstWhere((p) => p.name == name);

/// Whether [e] is an easing of the document that has no tile in the tool panel yet (Elastic, Random, Steps...).
/// Such an easing is identified by its name alone.
bool easeOther(Ease e) =>
    e.name != null && easingPresets.every((p) => p.name != e.name);
String? easeName(Ease e) => easeOther(e)
    ? e.name
    : easingPresets.where((p) => p == e).firstOrNull?.name;
