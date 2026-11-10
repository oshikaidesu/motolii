// The workspace: one window that gathers the panels (browser dock, preview, inspector, timeline, tool panel).
// This file holds what every panel shares: the document state they all read (Ws) and the window's design tokens (WsT).
// The look follows the Inspector's rules: square containers tiled edge to edge, round controls,
// flat opaque colour, one lime accent, and one hue per layer kind.
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async' show Timer;
import 'dart:developer' show Timeline, TimelineTask;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';

import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/storage/free_name.dart' show firstFree;
import 'package:motolii/workspace/state/beats.dart';

part 'window.dart';
part 'effects.dart';
part 'picked.dart';

/// The kinds of layer the timeline distinguishes.
enum WsKind { shape, text, image, camera, group, particles, audio }

Color wsTone(WsKind k) => switch (k) {
  WsKind.shape => WsT.toneShape,
  WsKind.text => WsT.toneText,
  WsKind.image => WsT.toneImage,
  WsKind.camera => WsT.toneCamera,
  WsKind.group => WsT.toneGroup,
  WsKind.particles => WsT.toneParticles,
  WsKind.audio => WsT.toneAudio,
};

/// One layer of the composition: when it is on, and where its keyframes are, in frames.
class WsLayer {
  WsLayer(
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
  final WsKind kind;
  int inF, outF;
  final List<int> keys;

  /// The easing between its keyframes, as the engine reports it. Drawn on the layer's bar.
  final List<WsStretch> stretches;

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
typedef WsStretch = ({int from, int to, String way, List<double> shape});

/// A keyframe the user selected: its layer and frame.
typedef WsKey = ({String layer, int frame});

/// A stretch of one property selected by its line in the timeline, from the keyframe at [at] seconds to the next keyframe of that property.
typedef WsStretchPicked = ({String layer, String name, double at, int from, int to});

/// What part of the window's state changed. A widget rebuilds only when an aspect it reads changes (see [WsScope.of]).
///
/// [document] means the engine's snapshot of the document was read again.
enum WsAspect { document, picked, playing, view, fronted, animating, notice, stage }
