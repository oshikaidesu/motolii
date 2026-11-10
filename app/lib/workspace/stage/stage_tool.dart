// The stage's tools: the list the tool column shows, and the active one with the options chosen for it.
import 'package:flutter/foundation.dart' show immutable;

import 'package:motolii/widgets/glyphs.dart';

/// The tools of the stage's tool column, in order: each one's glyph, its name and the letter that selects it.
const stageTools = [
  (Glyphs.select, 'Select', 'V'),
  (Glyphs.move, 'Move', 'M'),
  (Glyphs.rect, 'Rectangle', 'R'),
  (Glyphs.ellipse, 'Ellipse', 'E'),
  (Glyphs.pen, 'Pen', 'P'),
  (Glyphs.text, 'Text', 'T'),
  // Freehand path, as in Alight Motion. B is the brush key in Photoshop and After Effects.
  (Glyphs.brush, 'Brush', 'B'),
  // After Effects' Unified Camera tool: a drag orbits the camera, the wheel dollies it.
  (Glyphs.camera, 'Camera', 'C'),
];

/// The active tool of the stage, with the options chosen for it in the strip under the stage.
@immutable
class StageTool {
  /// A tool that creates [make], or selects and moves layers when [make] is null.
  const StageTool({
    this.make,
    this.axis = 0,
    this.fromCentre = false,
    this.snap = false,
    this.pivots = false,
    this.group = false,
    this.mask = false,
    this.brushSize = 16,
    this.brushTool = 1,
  });

  /// What the selected tool creates when dragged across the stage (rect, circle, line, text, brush).
  ///
  /// Null means the user is selecting and moving layers instead.
  final String? make;

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

  /// How wide the Brush draws, in image points (perfect-freehand's size).
  final double brushSize;

  /// The brush kind, as in Alight Motion: 0 pen, 1 brush, 2 fill (doc_brush).
  final int brushTool;
}
