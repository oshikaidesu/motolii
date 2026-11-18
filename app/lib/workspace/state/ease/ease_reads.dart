// Reads for the Ease tool: the keyframes at a frame, the easings the document defines that the tool's tiles do not
// cover, the card a word makes, and the curve pasted from text. They come from the engine's snapshot.
import 'package:flutter/widgets.dart' show Offset;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The properties of [layer] that have a keyframe at [from] (in frames), each with the time of that keyframe in seconds.
Map<String, double> easeKeysAt(WorkspaceController ws, int layer, int from) => {
  for (final name in layerMoving(ws, layer))
    for (final s in layerKeyTimes(ws, layer, name))
      if ((s * WorkspaceController.fps).round() == from) name: s,
};

/// The easings of the document that the eight built-in tiles do not cover (Elastic, Cyclic, Random, Steps,
/// ElasticSteps and any the document defines), each as an [Ease] whose curve is sampled from the engine.
/// The result is recomputed only when the document is read again, so a newly defined easing shows at once.
final _untiledOf = Expando<(String, List<Ease>)>();
List<Ease> easingsWithoutTile(WorkspaceController ws) {
  final m = ws.inside;
  if (m == null) return const [];
  if (_untiledOf[m] case (final was, final tiles) when was == '${ws.reads}') {
    return tiles;
  }
  final names = m.easingNames, said = '${ws.reads}';
  final tiles = [
    for (final name in names)
      if (name != 'Bezier' &&
          !easeIsLaid(name) &&
          !easeIsTurned(name) &&
          easingPresets.every((p) => p.name != name))
        Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), name, [
          for (var i = 0; i <= 32; i++) m.easingAt(name, i / 32),
        ]),
  ];
  _untiledOf[m] = (said, tiles);
  return tiles;
}

/// The card a word makes. The engine computes the kinds that have no tile of their own.
Ease easeCardFor(WorkspaceController ws, String word) =>
    easeCard(word, ws.inside);

/// The curve the text makes, such as a pasted cubic-bezier() or linear(), or the app's own copied curve (see easeFromText).
Ease? easeFromPaste(WorkspaceController ws, String? text) =>
    easeFromText(text, ws.inside);
