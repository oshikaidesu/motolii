// The inspector's cards, built from what the engine reports for a layer: its cards, and the range and look of each value.
import 'dart:math' as math;

import 'package:motolii/workspace/shelf/effect_tiles_review.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/inspector/inspector_reads.dart';
import 'package:motolii/workspace/state/inspector/inspector_values.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show soundLayer;
import 'package:motolii/workspace/state/layers/layer_reads.dart'
    show layerValue, layerWord, layerWords;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The cards the engine shows for a layer's values beyond the sample's (motolii_cards), each written as a Params struct
/// the way effects are: a number gets its range and current value, a word gets the list of words it may take.
/// The values named in code are the exceptions in state/inspector_values.dart (`_onCard`, `writeNumbers`): position, scale, rotation and
/// opacity as the stage shows them, `speed`, and the other layer a value may point at.
List<CardDeclaration>? valueCards(WorkspaceController ws, int? id) {
  // With nothing selected the cards belong to the stage itself, layer 0.
  final t = id ?? 0;
  if (!projectOpen(ws)) return null;
  // The cards are rebuilt only when the set of cards, their values or the layers they may name change.
  // Ending a drag changes none of these, and the numbers on the cards come from layerTransform.
  // The inspector takes a card's current value (its @default) only when it builds the cards anew.
  final shape =
      '${layerCardsOf(ws, t)}|${ws.layers.map((l) => l.name).join(',')}';
  final project = openProjectToken(ws);
  final made = _cardsMade[t];
  if (made != null && made.$1 == shape && identical(made.$3, project)) {
    return made.$2;
  }
  final cards = _makeCards(ws, t);
  _cardsMade[t] = (shape, cards, project);
  return cards;
}

/// The weight of the value [n] in [weights], which are keyed `js_<stem>_<knob>`: the engine puts the ID of the one use
/// of an effect in front of its values ("a1b2c3:js_blur_size"), and every use of a file weighs the same.
double? weightOf(Map<String, double> weights, String n) =>
    weights[n.replaceFirst(_useId, '')];

final _useId = RegExp(r'^[0-9a-f]{6}:');

final _cardsMade = <int, (String, List<CardDeclaration>, Object?)>{};

List<CardDeclaration> _makeCards(WorkspaceController ws, int t) {
  // The time of the frame on screen.
  final at = drawnTime(ws);
  // How much each parameter of the layer's effects moves its result, as the effect tiles show it.
  final weights = {
    for (final f in WorkspaceController.fxFiles(
      '${layerWord(ws, t, 'fx')} ${layerWord(ws, t, 'script')}',
    ))
      ...TileReview.weighed(shelvesFolder(), f),
  };
  String field(String n) {
    final sh = shownFactOf(ws, n),
        label =
            '@label(${sh?.label ?? n.replaceAll('_', ' ').replaceRange(0, 1, n[0].toUpperCase())})${switch (weightOf(weights, n)) {
              null => '',
              final w => ' @weight($w)',
            }}';
    if (sh?.look == 'thing') {
      // Another layer, listed by the names the timeline shows: None first, then the others. The stored number is the document's.
      final others = otherLayers(ws, t),
          at = others.values.toList().indexOf(
            (layerValue(ws, t, n, 0) ?? 0).round(),
          );
      return '  /// $label @enum(${['None', ...others.keys.map((o) => o.replaceAll(',', ' '))].join(', ')}) @default(${at + 1})\n  $n: u32,';
    }
    if (layerWords(ws, t, n) case final words when words.isNotEmpty) {
      return '  /// $label @enum(${words.join(', ')}) @default(${math.max(0, words.indexOf(layerWord(ws, t, n)))})\n  $n: u32,';
    }
    if (layerRangeOf(ws, t, n) case (final lo0, final hi0)) {
      final a = shownNumber(
            ws,
            t,
            n,
            sh != null && sh.high > sh.low ? sh.low : lo0,
          ),
          b = shownNumber(
            ws,
            t,
            n,
            sh != null && sh.high > sh.low ? sh.high : hi0,
          ),
          lo = math.min(a, b),
          hi = math.max(a, b);
      // The card's range is how far the slider goes. A typed number may go as far as the engine accepts.
      // After Effects does the same with a slider range and a valid range (PF_FloatSliderDef).
      // Example: the From value of Datamosh slides to 10 s but can be typed up to the engine's limit.
      final va = shownNumber(ws, t, n, lo0),
          vb = shownNumber(ws, t, n, hi0),
          valid =
              sh?.open != true &&
                  (math.min(va, vb) < lo || math.max(va, vb) > hi)
              ? ' @valid(${math.min(va, vb)}, ${math.max(va, vb)})'
              : '';
      // An effect's angle in degrees is recognised by its label and shown as a dial, like PF_ADD_ANGLE in After Effects.
      final turned = sh?.look == '' && hi - lo >= 90 && angleLabel(sh!.label);
      final ui = switch (turned ? 'angle' : sh?.look) {
        'onoff' => '@toggle',
        'angle' => '@ui(angle)',
        'seed' => '@ui(seed)',
        'count' => hi - lo <= 12 ? '@ui(stepper)' : '@ui(bar)',
        'share' when lo >= 0 && hi <= 100 => '@ui(percent)',
        _ => lo < 0 && hi > 0 ? '@ui(bipolar)' : '@ui(bar)',
      };
      final whole =
          sh?.look == 'count' || sh?.look == 'onoff' || sh?.look == 'seed';
      return '  /// $label $ui @range($lo, $hi)${sh?.open == true ? ' @open' : ''}$valid @unit(${turned ? '°' : sh?.unit ?? ''}) @default(${shownNumber(ws, t, n, layerValue(ws, t, n, at) ?? lo0)})\n  $n: ${whole ? 'u32' : 'f32'},';
    }
    // Any word: colours of six digits each, taken from the Colors shelf, or numbers with one for each copy.
    return '  /// $label${const ['numbers', 'colours', 'words', 'file'].contains(sh?.look) ? ' @unit(${sh!.look})' : ''}\n  $n: vec3<f32>,';
  }

  // An ISF colour input is stored by the engine as three numbers (_x, _y, _z) plus an alpha.
  // It is shown as one colour on the card, as the effect colour is in After Effects and Alight Motion,
  // and choosing from the Colors shelf sets all three numbers.
  // Without this, a white colour took three number fields.
  String colour(String base) =>
      '  /// @label(${shownFactOf(ws, '${base}_x')!.label.substring(0, shownFactOf(ws, '${base}_x')!.label.length - 2)})${switch (weightOf(weights, '${base}_x')) {
        null => '',
        final w => ' @weight($w)',
      }} @unit(colours)\n  $base: vec3<f32>,';
  return [
    for (final (title, names) in layerCardsOf(ws, t))
      // A sound layer has a volume and nothing to place on the canvas
      // (docs/design/alight_motion_ui.md).
      // The Matte card is shown only when the layer is clipped (clip=1): the clip toggle is in the timeline.
      if ((title == 'Sound' || !soundLayer(ws, t)) &&
          (title != 'Matte' || (layerValue(ws, t, 'clip', 0) ?? 0) > .5))
        CardDeclaration(
          title,
          'struct Params {\n${[
            for (final n in names)
              if (shownFactOf(ws, n)?.fold == null)
                if (colourBaseOf(ws, n, names) case final base?) colour(base) else if (!{
                  for (final x in names)
                    if (colourBaseOf(ws, x, names) case final b?) ...['${b}_y', '${b}_z'],
                }.contains(n)) field(n),
            for (final fold in {for (final n in names) ?shownFactOf(ws, n)?.fold}) ...['  // @advanced($fold)', for (final n in names)
              if (shownFactOf(ws, n)?.fold == fold) field(n)],
          ].join('\n')}\n}',
          toneOf: () => InspectorSkin.toneLayer,
        ),
  ];
}
