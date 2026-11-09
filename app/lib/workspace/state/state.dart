// The workspace: one window that gathers the lab's panels (browser dock, stage, inspector, timeline, tool panel).
// This file is what every panel shares: the mock document they all read (Ws), and the window's own tokens (WsT).
import 'dart:developer' show Timeline, TimelineTask;

import 'package:flutter/scheduler.dart';
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
        MotoliiWatch; // (the inside's reads, an extension of Motolii: whoever holds the window's Ws.inside can call them)
import '../../skin/tokens.dart';
import '../stage/stage_art.dart' show WsArt;

part 'window.dart';
part 'picked.dart';
part 'scope.dart';
part 'panel_header.dart';

/// The window's own sizes and colours. A panel names one of these; it never types a number that is the window's business.
abstract final class WsT {
  /// The gutter between panels: the dark you see between tiles.
  static const gutter = 2.0;

  static const minWindow = Size(1280, 800);

  /// Grounds: the gutter, a panel's body, a card or row inside it.
  static Color get ground => Grey.g00;
  static Color get body => Grey.g07;
  static Color get card => Grey.g13;
  static Color get raised => Grey.g20;

  /// The one accent (same as the Inspector's) and the ink drawn on it.
  static Color get accent => Accent.fill;

  /// The accent drawn as a line or text on a ground. Lime reads on dark but vanishes on white, so the light shade inks it darker; fills stay [accent].
  static Color get accentInk => Accent.ink;
}

enum WsKind { shape, text, image, camera, group, particles, audio }

/// One layer of the mock composition: where it lives in time, and where its keys are (frames).
class WsLayer {
  WsLayer(this.id, this.name, this.kind, this.inF, this.outF, this.keys, {this.solo = false});
  final String id, name;
  final WsKind kind;
  int inF, outF;
  final List<int> keys;
  final bool solo;
}

/// A key the user picked: which layer, which frame.
typedef WsKey = ({String layer, int frame});

/// The window's state: the document's things as rows (read again from the inside), what is picked, the moment, the
/// view. Every panel listens to this and nothing else; a panel never keeps a copy of what is here.
/// contract: changes notify once per user action; nothing here ticks while idle (play advances only while [playing]).
/// What of the window changed: a part of it is built again only when one it reads did (Flutter's InheritedModel
/// aspects: [WsScope.of]). [WsAspect.document]: the inside's picture of the document was read again.
enum WsAspect { document, picked, playing, view, route, animating, stage }
