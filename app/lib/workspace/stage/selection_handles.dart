// The selected layer's handles on the stage: where each one is drawn, and the frame a shape's own handles move in.
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/state/art_scene.dart';

/// The selected layer's handles where the stage draws them now, by name, in the stage's own coordinates.
///
/// The user, or a test as in tldraw and Excalidraw, presses a handle to take hold of it.
abstract interface class StageHandles {
  Map<String, Offset> get handles;

  /// The layer under a screen point, as a click there would select it, or null when there is none.
  String? hitAt(Offset global);
}

/// The selection's handles where they are drawn, by name.
///
/// They are the four corners, the rotation knob, the anchor point and the middle (the body).
/// The painter draws them from here and [StageHandles] hands them out from here.
///
/// A shape also has its own handles, as in Alight Motion. The corner roundness handle sits on the diagonal from the
/// first corner, as far in as the corners are rounded ([round] is a share of the shorter side). The points handle of a
/// polygon or star sits out from the middle of the right side.
///
/// While an image is being cropped (after a double click), [crop] holds the left, top, right and bottom amounts cut
/// away, as shares of its width or height. A bar is shown on each side where it is cut, in place of the side handles.
Map<String, Offset> selectionHandles(
  Offset Function(Offset doc) scr,
  ArtBox b, {
  required bool knob,
  String form = '',
  double round = 0,
  List<double> crop = const [],
}) {
  final top = scr(b.top),
      dir = top - scr(b.c),
      n = dir.distance < 1 ? const Offset(0, -1) : dir / dir.distance;
  final c = [for (final p in b.corners) scr(p)];
  return {
    for (final (i, p) in c.indexed) 'corner $i': p,
    if (knob && crop.length != 4) ...{
      // The middle of each side, resizing one way only, as in Figma, Alight Motion and Keynote: left, top, right, bottom.
      'side 0': (c[0] + c[3]) / 2,
      'side 1': (c[0] + c[1]) / 2,
      'side 2': (c[1] + c[2]) / 2,
      'side 3': (c[3] + c[2]) / 2,
    },
    if (knob) 'turn': top + n * StageTokens.stem,
    'anchor': scr(b.anchor),
    'body': scr(b.c),
    if (const [
      'rect',
      'polygon',
      'star',
      'squircle',
      'chamfer',
      'cog',
    ].contains(form))
      'round': gripOf(c).roundAt(round),
    if (const ['polygon', 'star', 'cog'].contains(form))
      'points': (c[1] + c[2]) / 2 + gripOf(c).u * 18,
    if (crop.length == 4) ...{
      'crop 0': (c[0] + c[3]) / 2 + (c[1] - c[0]) * crop[0],
      'crop 1': (c[0] + c[1]) / 2 + (c[3] - c[0]) * crop[1],
      'crop 2': (c[1] + c[2]) / 2 - (c[1] - c[0]) * crop[2],
      'crop 3': (c[3] + c[2]) / 2 - (c[3] - c[0]) * crop[3],
    },
  };
}

/// The reference frame for a shape's own handles, in app points.
///
/// It holds the first corner, the unit directions along the top and down the left side, and the shorter side's length.
({Offset c0, Offset u, Offset w, double short}) gripOf(List<Offset> c) {
  final top = c[1] - c[0], side = c[3] - c[0];
  return (
    c0: c[0],
    u: top.distance < 1e-6 ? const Offset(1, 0) : top / top.distance,
    w: side.distance < 1e-6 ? const Offset(0, 1) : side / side.distance,
    short: math.max(1.0, math.min(top.distance, side.distance)),
  );
}

extension GripFrame on ({Offset c0, Offset u, Offset w, double short}) {
  /// The roundness handle: in along the diagonal as far as the corners are round, never on the corner itself.
  Offset roundAt(double round) =>
      c0 + (u + w) * math.max(round.clamp(0.0, .5) * short, 12.0);

  /// How round the corners become when the handle is dragged to [at].
  ///
  /// It is how far in along the diagonal the handle is, as a share of the shorter side.
  double roundOf(Offset at) =>
      (((at - c0).dx * (u + w).dx + (at - c0).dy * (u + w).dy) / 2 / short)
          .clamp(0.0, .5);
}

/// The engine's value name for the crop of each side of an image, in the order of the crop handles: left, top,
/// right, bottom.
const cropSides = ['crop_left', 'crop_top', 'crop_right', 'crop_bottom'];
