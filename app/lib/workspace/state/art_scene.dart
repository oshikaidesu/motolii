// The stage's artwork: a poster frame drawn from Ws.layers at one frame, plus the geometry the stage needs to select it.
// Everything here is a pure function of an [ArtScene]: no clock and no randomness at paint time, so a frame always looks the same.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiMoment;
import 'package:motolii/workspace/state/state.dart';

/// One layer as the artwork needs it: an immutable copy, so a scene can be compared with the previous one.
@immutable
class ArtLayer {
  ArtLayer(WsLayer l) : id = l.id, name = l.name, kind = l.kind, inF = l.inF, outF = l.outF, keys = List.unmodifiable([...l.keys]..sort());
  final String id, name;
  final WsKind kind;
  final int inF, outF;
  final List<int> keys;
  bool live(int f) => f >= inF && f <= outF;
  @override
  bool operator ==(Object other) =>
      other is ArtLayer && other.id == id && other.name == name && other.kind == kind && other.inF == inF && other.outF == outF && listEquals(other.keys, keys);
  @override
  int get hashCode => Object.hash(id, inF, outF, Object.hashAll(keys));
}

/// What the stage draws: the frame, the layers, and whether the camera layer frames the view.
///
/// Two scenes are equal when they would draw the same image.
@immutable
class ArtScene {
  final String title;

  /// The document's guides, in composition px.
  final List<double> guidesX, guidesY;
  ArtScene.of(Ws ws, {required this.camera})
    : frame = ws.frame,
      // The document's own name.
      title = ws.document == null ? 'CODA_main' : ws.document!.replaceFirst(RegExp(r'\.motolii$'), ''),
      guidesX = [
        for (final (a, at) in ws.guides)
          if (a == 'x') at,
      ],
      guidesY = [
        for (final (a, at) in ws.guides)
          if (a == 'y') at,
      ],
      layers = List.unmodifiable([for (final l in ws.layers) ArtLayer(l)]),
      rev = ws.rev,
      eye = ws.eye,
      gizmos = {
        if (ws.freeEye)
          for (final l in ws.layers)
            if (l.kind == WsKind.camera) l.id: ws.inside?.gizmo(int.parse(l.id)) ?? '',
      },
      _inside = ws.inside;

  final Motolii? _inside;
  final _asked = <String, ArtBox?>{};

  /// Where the view camera stood, and each camera layer as it sees the stage.
  ///
  /// The engine's text (doc_gizmo), read with each image.
  final List<double> eye;
  final Map<String, String> gizmos;

  /// A camera layer's points on the image: the four corners of its frame, the point it looks at and its position.
  ///
  /// A point is null when it lies behind the view camera.
  List<Offset?> gizmo(String id) {
    final n = (gizmos[id] ?? '').trim().split(' ').map(double.tryParse).toList();
    return [
      for (var i = 0; i + 1 < n.length; i += 2)
        if (n[i] case final x?) Offset(x, n[i + 1]!) else null,
    ];
  }

  /// A layer's box on the image as the engine sees it at this time, or null when the layer is not shown.
  ///
  /// It is asked for only when needed (a handle on the stage, the selected layer's outline), not for every layer
  /// on every image.
  ArtBox? box(String id) => _asked.putIfAbsent(id, () {
    final f = _inside?.bounds(int.tryParse(id) ?? -1);
    return f == null ? null : ArtBox(Offset(f[0], f[1]), Size(f[2], f[3]), f[4] * math.pi / 180, Offset(f[5], f[6]));
  });

  /// The box of every layer, asked for now.
  Map<String, ArtBox> get boxes => {
    for (final l in layers)
      if (box(l.id) case final b?) l.id: b,
  };

  /// How many times the document has been read again. A change at the same frame makes a different scene.
  final int rev;
  final int frame;
  final bool camera;
  final List<ArtLayer> layers;

  ArtLayer? layer(String? id) => layers.where((l) => l.id == id).firstOrNull;
  @override
  bool operator ==(Object other) =>
      other is ArtScene &&
      other.frame == frame &&
      other.rev == rev &&
      other.camera == camera &&
      identical(other.eye, eye) &&
      mapEquals(other.gizmos, gizmos) &&
      listEquals(other.layers, layers);
  @override
  int get hashCode => Object.hash(frame, camera, Object.hashAll(layers));
}

/// A layer's box in document px: centre, unscaled size, rotation and anchor.
class ArtBox {
  const ArtBox(this.c, this.size, this.rot, this.anchor);
  final Offset c, anchor;
  final Size size;
  final double rot;
  Offset _local(double x, double y) => c + _rot(Offset(x * size.width / 2, y * size.height / 2), rot);
  List<Offset> get corners => [_local(-1, -1), _local(1, -1), _local(1, 1), _local(-1, 1)];
  Offset get top => _local(0, -1);
  bool contains(Offset p, [double pad = 0]) {
    final q = _rot(p - c, -rot);
    return q.dx.abs() <= size.width / 2 + pad && q.dy.abs() <= size.height / 2 + pad;
  }
}

Offset _rot(Offset p, double a) => Offset(p.dx * math.cos(a) - p.dy * math.sin(a), p.dx * math.sin(a) + p.dy * math.cos(a));

/// The stage's image in document px: its size, the layers' boxes, and which layer a point is on.
abstract final class WsArt {
  // The document's own size, kept by the window's state.
  static Size get comp => Ws.comp;
  static Offset get centre => comp.center(Offset.zero);

  /// The box the stage frames when [id] is selected, or null when the layer has no image at this frame.
  ///
  /// The engine gives a box only to what it shows, so whether the layer is on is not worked out again here.
  static ArtBox? boxOf(ArtScene s, String? id) => s.layer(id) == null ? null : s.box(id!);

  /// The topmost layer under [p] (document px), or null. The background is locked: a click on it means "nothing".
  static String? hit(ArtScene s, Offset p) {
    for (final l in s.layers) {
      // The first layer in the list is the nearest, so the first box containing the point wins.
      if (s.box(l.id)?.contains(p) ?? false) return l.id;
    }
    return null;
  }
}
