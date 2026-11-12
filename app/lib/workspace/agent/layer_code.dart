// The selected layer, handed to the agent with a request, as an After Effects user sees it: every card of the
// Inspector with its values now (asked of the engine, m.cards), the code of each card that has some (found as the Code
// tab finds its cells, EffectCode.ofCard), the property picked in the Timeline, and the expression reference the
// Functions list reads. Before the request each code file is made the layer's own copy, as a cell's first edit does,
// so the agent writes the layer's file and never the shelf's. Something new goes in a new file in a folder of its
// own; the pane puts each file written there on the layer (putEffectFile), so code already there is not written over.
// The files go as ACP resource links, the way Zed sends a file mentioned with @.
import 'package:acpd/acpd.dart'
    show ContentBlock, ResourceLink, TextContentBlock;

import 'package:motolii/bridge/engine_paths.dart' show motoliiDir, motoliiOwn;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/workspace/code/expression_reference.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/shelf/effect_code.dart';
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
  final m = ws.inside, t = int.tryParse(ws.selected ?? '');
  if (m == null || t == null) return null;
  final name = ws.layers.where((l) => l.id == ws.selected).firstOrNull?.name;
  final stretch = ws.selection.stretch;
  String value(String n) =>
      m.words(t, n).isNotEmpty || m.value(t, n, m.now) == null
      ? m.word(t, n)
      : _number(m.value(t, n, m.now)!);
  return LayerCode(
    t,
    name ?? 'Layer $t',
    [
      for (final c in valueCards(ws, ws.selected) ?? const <CardDeclaration>[])
        if (EffectCode.ofCard(ws, t, c.name, [for (final p in c.params) p.id])
            case final code?)
          (c.name, code.word, code.slot),
    ],
    [
      for (final (title, names) in m.cards(t))
        '$title: ${[for (final n in names) '${m.shown(n)?.label ?? n} ($n)=${value(n)}'].join(', ')}',
    ],
    stretch != null && stretch.layer == ws.selected ? stretch.name : '',
  );
}

/// The folder a request's new files go in: a fresh one under the own programs, as an empty expression's (empty_effect.dart).
String newFolder() =>
    '$motoliiOwn/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// Makes each of [code]'s files the layer's own and returns what is sent with a request: the layer's cards and values,
/// its files as links, where new files go ([fresh]), and the expression reference with the names that run here.
Future<List<ContentBlock>> ownedFor(
  WorkspaceController ws,
  LayerCode code,
  String fresh,
) async {
  final files = [
    for (final (title, word, slot) in code.cards)
      (
        title,
        EffectCode.alone(ws, code.thing, word, slot)
            ? EffectCode.source(word)
            : EffectCode.copyOwn(ws, code.thing, word, slot).$2,
      ),
  ];
  ws.reread();
  final runs = <String>{};
  for (final (_, f) in files) {
    if (f.endsWith('.js')) {
      runs.addAll((await supportedIn(ws.inside!, f))?.keys ?? const []);
    }
  }
  final reference =
      '$motoliiDir/third_party/js/expression-globals-typescript/index.d.ts';
  return [
    TextContentBlock(
      text: [
        'In Motolii the layer "${code.layer}" is selected. Its cards in the '
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
        'Something new (a new expression or effect) goes in a new file in '
            '$fresh (make the folder), and Motolii puts it on the layer as a '
            'new card. An After Effects expression is a .js holding the '
            'expression as it is posted; a first line '
            '`// --property:position` (or rotation, scale, opacity) says what '
            'it is on (shelves/README.md). An effect is an ISF .fs.',
        'What an expression may name is the After Effects reference $reference.'
            '${runs.isEmpty ? '' : ' Of it these run here now: ${(runs.toList()..sort()).join(', ')}.'}',
      ].join('\n'),
    ),
    for (final (t, f) in files)
      ResourceLink(name: t, title: t, uri: Uri.file(f).toString()),
  ];
}

String _number(double v) => v == v.roundToDouble()
    ? '${v.toInt()}'
    : '${double.parse(v.toStringAsFixed(4))}';
