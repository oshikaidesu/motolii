// The selected layer, handed to the agent with a request, as an After Effects user sees it: every card of the
// Inspector with its values now (asked of the engine, m.cards), the code of each card that has some (found as the Code
// tab finds its cells, EffectCode.ofCard), the property picked in the Timeline, and the expression reference the
// Functions list reads. Before the request each code file is made the layer's own copy, as a cell's first edit does,
// so the agent writes the layer's file and never the shelf's. Something new goes in a new file in a folder of its
// own; the pane puts each file written there on the layer (putEffectFile), so code already there is not written over.
// The files go as ACP resource links, the way Zed sends a file mentioned with @.
import 'package:acpd/acpd.dart'
    show ContentBlock, ResourceLink, TextContentBlock;

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/shelf/effect_code.dart';
import 'package:motolii/workspace/state/agent_context.dart';
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show writeAgentSceneSnapshot;
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/document/expression_engine.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class LayerCode {
  const LayerCode(this.thing, this.layer, this.cards, this.values, this.picked);
  final int thing;
  final String layer;

  /// Each card that has code: its title, its file as the layer's slot names it, and the slot.
  final List<(String, String, String)> cards;

  /// Every card of the Inspector as a line: its title, then each value as `Label (name)=value`.
  final List<String> values;

  /// The property picked in the Timeline (a stretch between two of its keyframes), or ''.
  final String picked;

  /// What is sent with a request, as one line: the layer, its cards with code and the picked property.
  String get line => [
    layer,
    if (cards.isNotEmpty) [for (final c in cards) c.$1].join(', '),
    if (picked.isNotEmpty) picked,
  ].join(' · ');
}

/// The selected layer as the agent is told of it, or null with no layer selected.
LayerCode? layerCode(WorkspaceController ws) {
  final t = ws.selected;
  if (!projectOpen(ws) || t == null) return null;
  final name = ws.layers.where((l) => l.id == t).firstOrNull?.name;
  final stretch = ws.selection.stretch;
  return LayerCode(
    t,
    name ?? 'Layer $t',
    [
      for (final c in valueCards(ws, ws.selected) ?? const <CardDeclaration>[])
        if (EffectCode.ofCard(ws, t, c.name, [for (final p in c.params) p.id])
            case final code?)
          (c.name, code.word, code.slot),
    ],
    cardValueLines(ws, t),
    stretch != null && stretch.layer == ws.selected ? stretch.name : '',
  );
}

/// The folder a request's new files go in: a fresh one under the own programs, as an empty expression's (empty_effect.dart).
String newFolder() =>
    '${ownFolder()}/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// Builds ACP context blocks for the full scene (and the selected layer's cards
/// and own code copies when [code] is non-null).
Future<List<ContentBlock>> ownedFor(
  WorkspaceController ws,
  LayerCode? code,
  String fresh,
) async {
  final snap = writeAgentSceneSnapshot(ws, fresh);
  final files = code == null
      ? const <(String, String)>[]
      : [
          for (final (title, word, slot) in code.cards)
            (
              title,
              EffectCode.alone(ws, code.thing, word, slot)
                  ? EffectCode.source(word)
                  : EffectCode.copyOwn(ws, code.thing, word, slot).$2,
            ),
        ];
  if (code != null) ws.reread();
  final runs = <String>{};
  for (final (_, f) in files) {
    if (f.endsWith('.js')) {
      runs.addAll((await supportedIn(ws, f))?.keys ?? const []);
    }
  }
  final reference =
      '${engineFolder()}/third_party/js/expression-globals-typescript/index.d.ts';
  final opsPath = '$fresh/ops.json';
  return [
    TextContentBlock(
      text: [
        if (code != null) ...[
          'In Motolii the layer "${code.layer}" (id ${code.thing}) is selected. Its cards in the '
              'Inspector, with their values now (a value set on a card wins over '
              'the default in a code file\'s head):',
          for (final v in code.values) '- $v',
          if (code.picked.isNotEmpty)
            'The property picked in the Timeline: ${code.picked}.',
          if (files.isNotEmpty) ...[
            'Its code, one file per card. Each is this layer\'s own copy: no '
                'other layer runs it, and a saved file shows in the picture at '
                'once. Change these only when asked to change that card:',
            for (final (t, f) in files) '- $t: $f',
          ],
        ] else
          'In Motolii no single layer is selected; you may inspect and edit the whole scene.',
        if (snap.sceneJson != null)
          'Full scene snapshot (all layers with id, name, kind, parent, order, transform, anchor, size, clip, fx, bpm, marks): ${snap.sceneJson}.',
        if (snap.stagePng != null)
          'Current stage preview image: ${snap.stagePng}.',
        'To edit multiple layers, rig hierarchies, set joint pivots, add Null controllers, or attach scripts to specific layers in ONE undo step, write a JSON array (or {"ops":[...],"notice":"..."}) to $opsPath. Supported ops: '
            '{"op":"add","kind":"shape","file":"null"} (or rect/ellipse/path/text/image; layer:-1 targets the last added layer), '
            '{"op":"psd","file":"/abs/path.psd"}, '
            '{"op":"pivot","layer":ID,"x":AX,"y":AY} (moves normalized anchor -1..1 without shifting visuals), '
            '{"op":"set","layer":ID,"name":"parent|x|y|z|order|clip|rotate|scale_x|scale_y|opacity|...","value":N}, '
            '{"op":"say","layer":ID,"name":"name|fill|text|split|space|...","word":"..."}, '
            '{"op":"key","layer":ID,"name":"...","at":SEC,"value":N,"ease":"Bezier x1 y1 x2 y2"}, '
            '{"op":"fx","layer":ID,"file":"/abs/path/to/expr.js"}, '
            '{"op":"explode","layer":ID,"mode":"letters|strokes"}, '
            '{"op":"remove","layer":ID}, {"op":"select","layers":[ID]}, {"op":"time","at":SEC}. '
            'After ops.json runs, scene.json and stage.png are refreshed automatically.',
        'For a single new expression or shader on the selected layer, write a .js or .fs file in $fresh (files referenced by ops.json are attached only where ops.json specifies). '
            'An After Effects expression is a .js holding the expression as posted; a first line '
            '`// --property:position` (or rotation, scale, opacity) says what it is on (shelves/README.md). '
            'Multi-layer expressions can read other layers with `layerValue(id, name, t)` (including past time `t - delay` for secondary physics).',
        'Expression reference: $reference.'
            '${runs.isEmpty ? '' : ' Running on selected layer: ${(runs.toList()..sort()).join(', ')}.'}',
      ].join('\n'),
    ),
    if (snap.sceneJson case final s?)
      ResourceLink(
        name: 'scene.json',
        title: 'Scene JSON',
        uri: Uri.file(s).toString(),
      ),
    if (snap.stagePng case final p?)
      ResourceLink(
        name: 'stage.png',
        title: 'Stage Preview',
        uri: Uri.file(p).toString(),
      ),
    for (final (t, f) in files)
      ResourceLink(name: t, title: t, uri: Uri.file(f).toString()),
  ];
}
