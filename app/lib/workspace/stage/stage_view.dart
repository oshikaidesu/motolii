// The stage's viewport: the composition centred on a dark surround, rulers and guides, overlays, the selection,
// the zoom HUD and the navigator.
// It repaints only when the scene, the selection, the hover or the view changes. The pointer readout repaints the rulers alone.
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/stage/stage_art.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiMoment, MotoliiWrites, MotoliiQuestions;
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/timeline_painters.dart' show TpGlyph;
import 'package:motolii/inspector/inspector_state.dart' show textToType;
import 'package:motolii/widgets/controls.dart' show Badge, Chip, ChipLook, Hov;
import 'package:motolii/workspace/edits/make_relation.dart';

import 'package:perfect_freehand/perfect_freehand.dart' show getStrokeOutlinePoints, getStrokePoints, PointVector, StrokeOptions;
import 'package:perfect_freehand/src/get_stroke_radius.dart'
    show getStrokeRadius; // How wide the pressure makes a point. The package keeps it private, so it is imported from src.

import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
part 'stage_view_state.dart';
part 'stage_view_drag.dart';
part 'stage_view_draw.dart';
part 'stage_view_camera.dart';
part 'stage_view_relations.dart';
part 'stage_view_painter.dart';

/// Zoom steps of the header chip: fit, then fixed scales.
const stageZooms = ['Fit', '50%', '100%'];
const _fixed = [0.0, .5, 1.0];

/// Viewport sizes: the ruler band, the margin a fit leaves around the composition, the HUD pill and the navigator.
abstract final class _V {
  static double get ruler => Shape.z(16.0);
  static double get fitMargin => Shape.s(28.0);
  static double get hud => Shape.z(22.0);
  static double get mapW => Shape.z(136.0);
  static double get pad => Shape.s(8.0);
  static double get handle => Shape.z(7.0);
  static double get stem => Shape.z(18.0);
  static double get tagH => Shape.z(16.0);
  static Color get surround => Grey.g10;
  static Color get rulerGround => Grey.g13;
  static Color get rulerSpan => Grey.g15;
  static Color get tick => Grey.g38;
  static Color get guide => WsT.toneAudio;
  static const overlay = Color(0x40FFFFFF), safe = Color(0x99F6EFDD);
}

/// Composition px to screen px: the composition's top-left at [o], [s] screen px per composition px, inside [area].
@immutable
class _View {
  const _View(this.o, this.s, this.area);
  final Offset o;
  final double s;
  final Rect area;
  Rect get comp => o & WsArt.comp * s;
  Offset toScreen(Offset p) => o + p * s;
  Offset toComp(Offset p) => (p - o) / s;
  @override
  bool operator ==(Object x) => x is _View && x.o == o && x.s == s && x.area == area;
  @override
  int get hashCode => Object.hash(o, s, area);
}

/// The stage viewport.
///
/// It draws the scene, handles pointer input for selecting, moving and drawing layers, and reports the pointer position.
class StageView extends StatefulWidget {
  const StageView({
    super.key,
    required this.scene,
    required this.selected,
    required this.zoom,
    required this.grid,
    required this.safe,
    required this.cursor,
    this.onPoke,
    this.texture,
    this.make,
    this.axis = 0,
    this.fromCentre = false,
    this.snap = false,
    this.pivots = false,
    this.group = false,
    this.mask = false,
    this.brushSize = 16,
    this.brushTool = 1,
    this.snapshot,
  });

  /// How wide the Brush draws, in image points (perfect-freehand's size).
  final double brushSize;

  /// The brush kind, as in Alight Motion: 0 pen, 1 brush, 2 fill (doc_brush).
  final int brushTool;

  /// The Move tool's constraint: 0 free, 1 along x only, 2 along y only.
  final int axis;

  /// Whether an ellipse is drawn out from its centre.
  final bool fromCentre;

  /// Whether a dragged layer snaps to the edges of other layers, of the image, and to the guides.
  final bool snap;

  /// Whether every layer's pivot point is shown.
  final bool pivots;

  /// Whether a click selects the outermost group that contains the layer instead of the layer itself.
  final bool group;

  /// Whether a drawn shape cuts the selected layer: it is placed just behind that layer, which is clipped by it.
  final bool mask;

  /// What the selected tool creates when dragged across the stage (rect, circle, line, text, brush).
  ///
  /// Null means the user is selecting and moving layers instead.
  final String? make;

  /// The engine's image of the stage as a Flutter texture id. When null, the stand-in art is painted.
  final int? texture;

  /// A still image taken earlier (After Effects' Take Snapshot), laid over the stage while it is shown.
  final String? snapshot;
  final ArtScene scene;
  final String? selected;
  final int zoom;
  final bool grid, safe;

  /// The pointer in composition px while it is over the viewport; the HUD and the rulers read it.
  final ValueNotifier<Offset?> cursor;
  final VoidCallback? onPoke;
  @override
  State<StageView> createState() => _StageViewState();
}

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
Map<String, Offset> _handles(
  Offset Function(Offset doc) scr,
  ArtBox b, {
  required bool knob,
  String form = '',
  double round = 0,
  List<double> crop = const [],
}) {
  final top = scr(b.top), dir = top - scr(b.c), n = dir.distance < 1 ? const Offset(0, -1) : dir / dir.distance;
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
    if (knob) 'turn': top + n * _V.stem,
    'anchor': scr(b.anchor),
    'body': scr(b.c),
    if (const ['rect', 'polygon', 'star', 'squircle', 'chamfer', 'cog'].contains(form)) 'round': _gripOf(c).roundAt(round),
    if (const ['polygon', 'star', 'cog'].contains(form)) 'points': (c[1] + c[2]) / 2 + _gripOf(c).u * 18,
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
({Offset c0, Offset u, Offset w, double short}) _gripOf(List<Offset> c) {
  final top = c[1] - c[0], side = c[3] - c[0];
  return (
    c0: c[0],
    u: top.distance < 1e-6 ? const Offset(1, 0) : top / top.distance,
    w: side.distance < 1e-6 ? const Offset(0, 1) : side / side.distance,
    short: math.max(1.0, math.min(top.distance, side.distance)),
  );
}

extension on ({Offset c0, Offset u, Offset w, double short}) {
  /// The roundness handle: in along the diagonal as far as the corners are round, never on the corner itself.
  Offset roundAt(double round) => c0 + (u + w) * math.max(round.clamp(0.0, .5) * short, 12.0);

  /// How round the corners become when the handle is dragged to [at].
  ///
  /// It is how far in along the diagonal the handle is, as a share of the shorter side.
  double roundOf(Offset at) => (((at - c0).dx * (u + w).dx + (at - c0).dy * (u + w).dy) / 2 / short).clamp(0.0, .5);
}
