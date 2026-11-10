// The workspace: one window that gathers the panels (browser dock, preview, inspector, timeline, tool panel).
// This file holds what every panel shares: the document state they all read (Ws) and the window's design tokens (WsT).
// The look follows the Inspector's rules: square containers tiled edge to edge, round controls,
// flat opaque colour, one lime accent, and one hue per layer kind.
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart' show easeCurve;

import 'dart:async' show Timer;
import 'dart:developer' show Timeline, TimelineTask;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import '../../bridge/motolii.dart';
export '../../bridge/motolii.dart'
    show
        MotoliiDocument,
        MotoliiMoment,
        MotoliiWrites,
        MotoliiQuestions,
        MotoliiShelves,
        MotoliiWatch; // Extensions of Motolii, so anything holding Ws.inside can call the engine's reads.
import '../../skin/theme.dart';
import '../../skin/tokens.dart';
import '../window/panes.dart' show WsAt, WsPane;
import '../window/settings_file.dart' show firstFree;
import 'beats.dart';
import '../stage/stage_art.dart' show WsArt;
export 'beats.dart';

part 'window.dart';
part 'effects.dart';
part 'picked.dart';
part 'scope.dart';
part 'panel_header.dart';

/// The window's own sizes and colours. A panel names one of these; it never types a number that is the window's business.
abstract final class WsT {
  /// The gutter between panels: the dark you see between tiles.
  static const gutter = 2.0;

  /// A panel's header strip (title, tabs, small actions).
  static double get header => Shape.z(28);

  /// The stage's tool column.
  static double get rail => Shape.z(40);

  /// Panel widths and the lower band's height, at the reference window (1600 x 960).
  static const dock = 300.0, inspector = 372.0, lower = 300.0;
  static double get topBar => Shape.z(40);
  static const minWindow = Size(1280, 800);

  /// Grounds: the gutter, a panel's body, a card or row inside it, a well (field) inside that.
  static Color get ground => Grey.g00;
  static Color get body => Grey.g07;
  static Color get card => Grey.g13;
  static Color get well => Grey.g15;
  static Color get raised => Grey.g20;
  static Color get line => Grey.g20;

  /// The one accent (same as the Inspector's) and the ink drawn on it.
  static Color get accent => Accent.fill;
  static Color get accentHot => Color.lerp(accent, const Color(0xFFFFFFFF), .14)!;
  static Color get onAccent => Accent.on;
  static Color get keyDot => Accent.key;

  /// The accent drawn as a line or text on a ground. Lime reads on dark but vanishes on white, so the light shade inks it darker; fills stay [accent].
  static Color get accentInk => Accent.ink;

  /// Round things you touch: fields, chips, tabs, buttons.
  static const radius = 6.0, chipRadius = 4.0;

  /// Paddings inside a panel.
  static double get inset => Shape.s(8);
  static double get gap => Shape.s(4);

  /// Hues per kind of layer or asset, shared by timeline bars, browser tiles and the preview artwork, so a kind keeps its colour everywhere.
  /// Modelled on Ableton's clip colours.
  static Color get toneShape => ColorTheme.of('Clip1', const Color(0xFFF08A5D));
  static Color get toneText => ColorTheme.of('Clip2', const Color(0xFFD9D2C3));
  static Color get toneImage => ColorTheme.of('Clip3', const Color(0xFF7FB8B0));
  static Color get toneCamera => ColorTheme.of('Clip4', const Color(0xFFA7B4C8));
  static Color get toneGroup => ColorTheme.of('Clip5', const Color(0xFFB0A6F0));
  static Color get toneParticles => ColorTheme.of('Clip6', const Color(0xFFF2A65A));
  static Color get toneAudio => ColorTheme.of('Clip7', const Color(0xFF5CC8E8));
  // The marks on the ruler for a layer's intro and outro, like Alight Motion's small yellow ones.
  static Color get toneMark => ColorTheme.of('ElementMark', const Color(0xFFF2C94C));

  /// The playhead line: the accent, so "now" is the loudest line in the window. Its head is an [accent] fill.
  static Color get playhead => accentInk;
}

/// The kinds of layer the timeline distinguishes.
enum WsKind { shape, text, image, camera, group, particles, audio }

/// The colours the user chose on the Note card, by layer id. Each value is an index into Ableton Live's 16 colours.
/// Read together with the document.
final wsChosenLabels = <String, int>{};

/// A layer's label colour, as Ableton gives each clip its own.
///
/// Without a chosen colour it is one of sixteen, five apart from the previous layer so that neighbours differ.
/// It is the same every time the document is opened. The layer's row, its dot on the Relations map, its frame in the
/// preview and its name in lists all use it. A skin can override each colour (Label1 to Label16).
Color wsLabel(String id) => wsLabelColor(wsChosenLabels[id] ?? ((int.tryParse(id) ?? 0) * 5) % _live.length);

/// The label colour [k], from 0 to 15. Marks use these colours too.
Color wsLabelColor(int k) => ColorTheme.of('Label${k + 1}', Color(_live[k]));
const _live = [
  0xFFFF94A6,
  0xFFFFA529,
  0xFFF7F47C,
  0xFFBFFB00,
  0xFF1AFF2F,
  0xFF25FFA8,
  0xFF5CFFE8,
  0xFF8BC5FF,
  0xFF5480E4,
  0xFF92A7FF,
  0xFFD86CE4,
  0xFFE553A0,
  0xFFFF3636,
  0xFFF66C03,
  0xFF10A4EE,
  0xFF00BFAF,
]; // Ableton Live's clip colours.

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
