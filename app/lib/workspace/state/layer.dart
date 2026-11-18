// A layer of the composition as the window lists it (Layer): its kind and the kind's colour, its bar and its keyframes.
// Also the records that name a keyframe, and a stretch between two keyframes, when the user selects one.
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

/// What the engine calls a relation's file: every relation is written as a file in relations/*.js.
const relationKinds = ['relate'];

/// The kinds of layer the timeline distinguishes.
enum LayerKind { shape, text, image, camera, group, particles, audio }

Color layerKindColor(LayerKind k) => switch (k) {
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
    this.form,
    this.members,
    this.links = const [],
    this.lanes = const [],
    this.retimed = const [],
    this.media,
  });
  final int id;
  final String name;
  final LayerKind kind;
  int inF, outF;
  final List<int> keys;

  /// The easing between its keyframes, as the engine reports it. Drawn on the layer's bar.
  final List<Stretch> stretches;

  /// The id of the parent layer, if any.
  final int? parent;

  /// Whether this is a sketch whose drawn lines are parameters of it. When opened, each line gets a row.
  final bool lined;

  /// The layer's flags as the engine reported them at the last read, so a row asks nothing of the engine while the preview plays.
  /// [clipped] means it is shown only inside the layer below it (Clip to Below).
  final bool hidden, solo, locked, clipped;

  /// A shape's form as the engine names it (rect, circle, star...), its colour, and whether it is an outline (no fill,
  /// so the colour is the stroke's). Null for other layers.
  final ({String shape, Color? colour, bool outline})? form;

  /// A relation's layers, in its own order. Null for any other layer.
  final List<int>? members;

  /// The layers it points at, each with its label: those its properties name (Parent, Leader, Join, Into...), and a
  /// relation's layers ('Moves'). Like the Parent & Link column of After Effects.
  final List<(String, int)> links;

  /// Its properties with keyframes (and a sketch's lines), in its own order: each a lane under its row, as in Ableton.
  final List<Lane> lanes;

  /// For a group with an intro and outro (its Element card), the frames where the intro ends and the outro starts.
  final List<int> retimed;

  /// A video's or image's file, where in the file the layer begins and how fast it plays. Null for other layers.
  final ({String file, double begin, double speed, bool still})? media;

  /// Whether [o] is listed the same: what the timeline draws of it is unchanged.
  bool same(Layer o) =>
      id == o.id &&
      name == o.name &&
      kind == o.kind &&
      inF == o.inF &&
      outF == o.outF &&
      listEquals(keys, o.keys) &&
      parent == o.parent &&
      lined == o.lined &&
      hidden == o.hidden &&
      solo == o.solo &&
      locked == o.locked &&
      clipped == o.clipped &&
      form == o.form &&
      listEquals(members, o.members) &&
      listEquals(links, o.links) &&
      listEquals(lanes, o.lanes) &&
      listEquals(retimed, o.retimed) &&
      media == o.media &&
      stretches.length == o.stretches.length &&
      [
        for (var i = 0; i < stretches.length; i++)
          stretches[i].from == o.stretches[i].from &&
              stretches[i].to == o.stretches[i].to &&
              stretches[i].way == o.stretches[i].way &&
              listEquals(stretches[i].shape, o.stretches[i].shape),
      ].every((same) => same);

  /// The layer's label colour.
  Color get tone => layerLabelColor(id);

  /// The layers this one is inside: its parent, that layer's parent and so on, nearest first.
  /// [byId] maps the id of every layer to the layer.
  Iterable<Layer> ancestors(Map<int, Layer> byId) sync* {
    var p = byId[parent];
    for (var n = 0; p != null && n < 64; p = byId[p.parent], n++) {
      // The limit of 64 matches the stage's own walk up a layer's parents.
      yield p;
    }
  }
}

/// One animated property of a layer, as its lane shows it: its keyframes' times (seconds) and values, and the easing
/// curve (0 to 1) from each keyframe to the next.
@immutable
class Lane {
  const Lane({
    required this.name,
    required this.label,
    required this.card,
    required this.at,
    required this.values,
    required this.curves,
  });

  /// The property as the project names it, as its own label shows it, and the title of the card that holds it.
  final String name, label;
  final String? card;
  final List<double> at, values;
  final List<List<double>> curves;

  @override
  bool operator ==(Object other) =>
      other is Lane &&
      other.name == name &&
      other.label == label &&
      other.card == card &&
      listEquals(other.at, at) &&
      listEquals(other.values, values) &&
      other.curves.length == curves.length &&
      [
        for (var i = 0; i < curves.length; i++)
          listEquals(other.curves[i], curves[i]),
      ].every((same) => same);
  @override
  int get hashCode => Object.hash(name, label, card, Object.hashAll(at));
}

/// The stretch between two keyframes: its frames, its easing, and the easing curve (0 to 1) sampled at 17 points.
typedef Stretch = ({int from, int to, String way, List<double> shape});

/// A keyframe the user selected: its layer and frame.
typedef SelectedKeyframe = ({int layer, int frame});

/// A stretch of one property selected by its line in the timeline, from the keyframe at [at] seconds to the next keyframe of that property.
typedef StretchPicked = ({int layer, String name, double at, int from, int to});
