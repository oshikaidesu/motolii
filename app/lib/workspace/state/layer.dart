// A layer of the composition as the window lists it (Layer): its kind and the kind's colour, its bar and its keyframes.
// Also the records that name a keyframe, and a stretch between two keyframes, when the user selects one.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

/// The kinds of layer the timeline distinguishes.
enum LayerKind { shape, text, image, camera, group, particles, audio }

Color wsTone(LayerKind k) => switch (k) {
  LayerKind.shape => WindowTokens.toneShape,
  LayerKind.text => WindowTokens.toneText,
  LayerKind.image => WindowTokens.toneImage,
  LayerKind.camera => WindowTokens.toneCamera,
  LayerKind.group => WindowTokens.toneGroup,
  LayerKind.particles => WindowTokens.toneParticles,
  LayerKind.audio => WindowTokens.toneAudio,
};

/// One layer of the composition: when it is on, and where its keyframes are, in frames.
class Layer {
  Layer(
    this.id,
    this.name,
    this.kind,
    this.inF,
    this.outF,
    this.keys, {
    this.parent,
    this.lined = false,
    this.hidden = false,
    this.solo = false,
    this.locked = false,
    this.clipped = false,
    this.stretches = const [],
  });
  final String id, name;
  final LayerKind kind;
  int inF, outF;
  final List<int> keys;

  /// The easing between its keyframes, as the engine reports it. Drawn on the layer's bar.
  final List<Stretch> stretches;

  /// The id of the parent layer, if any.
  final String? parent;

  /// Whether this is a sketch whose drawn lines are parameters of it. When opened, each line gets a row.
  final bool lined;

  /// The layer's flags as the engine reported them at the last read, so a row asks nothing of the engine while the preview plays.
  /// [clipped] means it is shown only inside the layer below it (Clip to Below).
  final bool hidden, solo, locked, clipped;

  /// The layer's label colour.
  Color get tone => wsLabel(id);
}

/// The stretch between two keyframes: its frames, its easing, and the easing curve (0 to 1) sampled at 17 points.
typedef Stretch = ({int from, int to, String way, List<double> shape});

/// A keyframe the user selected: its layer and frame.
typedef SelectedKeyframe = ({String layer, int frame});

/// A stretch of one property selected by its line in the timeline, from the keyframe at [at] seconds to the next keyframe of that property.
typedef StretchPicked = ({String layer, String name, double at, int from, int to});
