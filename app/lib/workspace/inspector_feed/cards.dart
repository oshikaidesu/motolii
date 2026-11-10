// The inspector's cards, built from what the engine reports for a layer: its cards, and the range and look of each value.
import 'dart:math' as math;

import 'package:motolii/workspace/shelf/effect_tiles_review.dart';

import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/workspace/inspector_feed/values.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The cards the engine shows for a layer's values beyond the sample's (motolii_cards), each written as a Params struct
/// the way effects are: a number gets its range and current value, a word gets the list of words it may take.
/// The values named in code are the exceptions in values.dart (`_onCard`, `writeNumbers`): position, scale, rotation and
/// opacity as the stage shows them, `speed`, and the other layer a value may point at.
List<CardDeclaration>? valueCards(WorkspaceController ws, String? id) {
  // With nothing selected the cards belong to the stage itself, layer 0.
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id);
  if (m == null || t == null) return null;
  // The cards are rebuilt only when the set of cards, their values or the layers they may name change.
  // Ending a drag changes none of these, and the numbers on the cards come from layerTransform.
  // The inspector takes a card's current value (its @default) only when it builds the cards anew.
  final shape = '${m.cards(t)}|${ws.layers.map((l) => l.name).join(',')}';
  final made = _cardsMade[t];
  if (made != null && made.$1 == shape && identical(made.$3, m)) return made.$2;
  final cards = _makeCards(ws, m, t);
  _cardsMade[t] = (shape, cards, m);
  return cards;
}

final _cardsMade = <int, (String, List<CardDeclaration>, Motolii)>{};

List<CardDeclaration> _makeCards(WorkspaceController ws, Motolii m, int t) {
  // The time of the frame on screen.
  final at = drawnTime(ws);
  // How much each parameter of the layer's effects moves its result, as the effect tiles show it.
  final weights = {
    for (final f in WorkspaceController.fxFiles(
      '${m.word(t, 'fx')} ${m.word(t, 'script')}',
    ))
      ...TileReview.weighed(motoliiShelves, f),
  };
  String field(String n) {
    final sh = m.shown(n),
        label =
            '@label(${sh?.label ?? n.replaceAll('_', ' ').replaceRange(0, 1, n[0].toUpperCase())})${weights[n] == null ? '' : ' @weight(${weights[n]})'}';
    if (sh?.look == 'thing') {
      // Another layer, listed by the names the timeline shows: None first, then the others. The stored number is the document's.
      final others = otherLayers(ws, t),
          at = others.values.toList().indexOf((m.value(t, n, 0) ?? 0).round());
      return '  /// $label @enum(${['None', ...others.keys.map((o) => o.replaceAll(',', ' '))].join(', ')}) @default(${at + 1})\n  $n: u32,';
    }
    if (m.words(t, n) case final words when words.isNotEmpty) {
      return '  /// $label @enum(${words.join(', ')}) @default(${math.max(0, words.indexOf(m.word(t, n)))})\n  $n: u32,';
    }
    if (m.range(t, n) case (final lo0, final hi0)) {
      final a = shownNumber(
            m,
            t,
            n,
            sh != null && sh.high > sh.low ? sh.low : lo0,
          ),
          b = shownNumber(
            m,
            t,
            n,
            sh != null && sh.high > sh.low ? sh.high : hi0,
          ),
          lo = math.min(a, b),
          hi = math.max(a, b);
      // The card's range is how far the slider goes. A typed number may go as far as the engine accepts.
      // After Effects does the same with a slider range and a valid range (PF_FloatSliderDef).
      // Example: the From value of Datamosh slides to 10 s but can be typed up to the engine's limit.
      final va = shownNumber(m, t, n, lo0),
          vb = shownNumber(m, t, n, hi0),
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
      return '  /// $label $ui @range($lo, $hi)${sh?.open == true ? ' @open' : ''}$valid @unit(${turned ? '°' : sh?.unit ?? ''}) @default(${shownNumber(m, t, n, m.value(t, n, at) ?? lo0)})\n  $n: ${whole ? 'u32' : 'f32'},';
    }
    // Any word: colours of six digits each, taken from the Colors shelf, or numbers with one for each copy.
    return '  /// $label${const ['numbers', 'colours', 'words', 'file'].contains(sh?.look) ? ' @unit(${sh!.look})' : ''}\n  $n: vec3<f32>,';
  }

  // An ISF colour input is stored by the engine as three numbers (_x, _y, _z) plus an alpha.
  // It is shown as one colour on the card, as the effect colour is in After Effects and Alight Motion,
  // and choosing from the Colors shelf sets all three numbers.
  // Without this, a white colour took three number fields.
  String colour(String base) =>
      '  /// @label(${m.shown('${base}_x')!.label.substring(0, m.shown('${base}_x')!.label.length - 2)})${weights['${base}_x'] == null ? '' : ' @weight(${weights['${base}_x']})'} @unit(colours)\n  $base: vec3<f32>,';
  return [
    for (final (title, names) in m.cards(t))
      // A sound layer has a volume and nothing to place on the canvas, as in Alight Motion's audio layer
      // (docs/design/alight_motion_ui.md).
      if (title == 'Sound' || !isSoundLayer(m, t))
        CardDeclaration(
          title,
          'struct Params {\n${[
            for (final n in names)
              if (m.shown(n)?.fold == null)
                if (colourBase(m, n, names) case final base?) colour(base) else if (!{
                  for (final x in names)
                    if (colourBase(m, x, names) case final b?) ...['${b}_y', '${b}_z'],
                }.contains(n)) field(n),
            for (final fold in {for (final n in names) ?m.shown(n)?.fold}) ...['  // @advanced($fold)', for (final n in names)
              if (m.shown(n)?.fold == fold) field(n)],
          ].join('\n')}\n}',
          toneOf: () => InspectorSkin.toneLayer,
        ),
  ];
}
