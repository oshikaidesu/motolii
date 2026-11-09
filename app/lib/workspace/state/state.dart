// The workspace: one window that gathers the lab's panels (browser dock, stage, inspector, timeline, tool panel).
// This file is what every panel shares: the mock document they all read (Ws), and the window's own tokens (WsT).
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

part 'window.dart';
part 'picked.dart';
part 'scope.dart';
part 'panel_header.dart';

/// The window's own sizes and colours. A panel names one of these; it never types a number that is the window's business.
abstract final class WsT {
  /// The gutter between panels: the dark you see between tiles.
  static const gutter = 2.0;

  /// Grounds: the gutter, and a panel's body.
  static Color get ground => Grey.g00;
  static Color get body => Grey.g07;
}

enum WsKind { shape, text, image, camera, group, audio }

/// One layer of the mock composition: where it lives in time, and where its keys are (frames).
class WsLayer {
  WsLayer(this.id, this.name, this.kind, this.inF, this.outF, this.keys);
  final String id, name;
  final WsKind kind;
  int inF, outF;
  final List<int> keys;
}

/// The window's state: the document's things (read again from the inside), what is picked, the moment.
/// What of the window changed. [WsAspect.document]: the inside's picture of the document was read again.
enum WsAspect { document, picked, playing, animating }
