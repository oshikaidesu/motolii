// The inspector's cards, built from what the engine reports for a layer: its cards, the range and look of each value, and the kind's name.
part of '../workspace.dart';

/// The document's name for a layer's kind, for kinds the inspector's own [Kind] has no entry for (video, image, solid).
String? _kindWord(Ws ws, String? id) {
  final t = int.tryParse(id ?? ''), w = t == null ? '' : ws.inside?.word(t, 'kind') ?? '';
  if (w == 'behaviour') return wsRelations.contains(ws.inside?.word(t!, 'file')) ? 'Relation' : 'Behaviour';
  if (w == 'film' && wsSound(ws.inside!, t!)) return 'Sound';
  return const {'film', 'picture', 'solid', 'light'}.contains(w) ? w.replaceRange(0, 1, w[0].toUpperCase()) : null;
}

Kind _kindOf(WsLayer? l) => switch (l?.kind) {
  null => Kind.none,
  WsKind.text => Kind.text,
  WsKind.camera => Kind.camera,
  WsKind.group => Kind.group,
  _ => Kind.shape,
};

/// The text of each value on the engine's own cards, as the inspector writes it. A value with no text shows a dash.
Map<String, String> _cardColors(Motolii m, int t, [double at = 0]) => {
  // First an effect's colour: three numbers shown as one colour (see _makeCards), read at the time drawn like the card's numbers.
  for (final (_, names) in m.cards(t))
    for (final n in names)
      if (n.endsWith('_x') &&
          names.contains('${n.substring(0, n.length - 2)}_y') &&
          names.contains('${n.substring(0, n.length - 2)}_z') &&
          (m.shown(n)?.label ?? '').endsWith(' r'))
        'v_${n.substring(0, n.length - 2)}':
            '#${[for (final c in 'xyz'.split('')) ((m.value(t, '${n.substring(0, n.length - 2)}_$c', at) ?? 0).clamp(0, 1) * 255).round().toRadixString(16).padLeft(2, '0')].join().toUpperCase()}',
  for (final (_, names) in m.cards(t))
    for (final n in names)
      if (m.words(t, n).isEmpty && m.range(t, n) == null)
        // Words are shown as they are so the user can type over them. A file shows its name. Numbers, one per copy, are shown as they are.
        // Anything else is a colour or a list of colours in order, or a word such as a material name, shown as it is (Glass).
        // A gradient stop is shown by its colour only, without its position.
        'v_$n': m.shown(n)?.look == 'words'
            ? m.word(t, n)
            : m.word(t, n).isEmpty || m.word(t, n) == 'none'
            ? '—'
            : m.shown(n)?.look == 'file'
            ? m.word(t, n).split('/').last
            : m.shown(n)?.look == 'numbers'
            ? m.word(t, n)
            : m
                  .word(t, n)
                  .split(' ')
                  .where((c) => c.isNotEmpty)
                  .map((w) => w.split('@').first)
                  .map(
                    (c) => int.tryParse(c, radix: 16) != null && (c.length == 6 || c.length == 8)
                        ? '#${c.toUpperCase()}'
                        : c.replaceRange(0, 1, c[0].toUpperCase()),
                  )
                  .join(' '),
};

/// The cards the engine shows for a layer's values beyond the sample's (motolii_cards), each written as a Params struct
/// the way effects are: a number gets its range and current value, a word gets the list of words it may take.
/// Nothing about the individual values is hard-coded here.
List<Fx>? _valueCards(Ws ws, String? id) {
  // With nothing selected the cards belong to the stage itself, layer 0.
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id);
  if (m == null || t == null) return null;
  // The cards are rebuilt only when the set of cards, their values or the layers they may name change.
  // Ending a drag changes none of these, and the numbers on the cards come from wsTransform.
  // The inspector takes a card's current value (its @default) only when it builds the cards anew.
  final shape = '${m.cards(t)}|${ws.layers.map((l) => l.name).join(',')}';
  final made = _cardsMade[t];
  if (made != null && made.$1 == shape && identical(made.$3, m)) return made.$2;
  final cards = _makeCards(ws, m, t);
  _cardsMade[t] = (shape, cards, m);
  return cards;
}

final _cardsMade = <int, (String, List<Fx>, Motolii)>{};

List<Fx> _makeCards(Ws ws, Motolii m, int t) {
  // The time of the frame on screen.
  final at = _drawn(ws);
  // How much each parameter of the layer's effects moves its result, as the effect tiles show it.
  final weights = {for (final f in Ws.fxFiles('${m.word(t, 'fx')} ${m.word(t, 'script')}')) ...EffectTiles.weighed(motoliiShelves, f)};
  String field(String n) {
    final sh = m.shown(n),
        label = '@label(${sh?.label ?? n.replaceAll('_', ' ').replaceRange(0, 1, n[0].toUpperCase())})${weights[n] == null ? '' : ' @weight(${weights[n]})'}';
    if (sh?.look == 'thing') {
      // Another layer, listed by the names the timeline shows: None first, then the others. The stored number is the document's.
      final others = _others(ws, t), at = others.values.toList().indexOf((m.value(t, n, 0) ?? 0).round());
      return '  /// $label @enum(${['None', ...others.keys.map((o) => o.replaceAll(',', ' '))].join(', ')}) @default(${at + 1})\n  $n: u32,';
    }
    if (m.words(t, n) case final words when words.isNotEmpty) {
      return '  /// $label @enum(${words.join(', ')}) @default(${math.max(0, words.indexOf(m.word(t, n)))})\n  $n: u32,';
    }
    if (m.range(t, n) case (final lo0, final hi0)) {
      final a = _shown(m, t, n, sh != null && sh.high > sh.low ? sh.low : lo0),
          b = _shown(m, t, n, sh != null && sh.high > sh.low ? sh.high : hi0),
          lo = math.min(a, b),
          hi = math.max(a, b);
      // The card's range is how far the slider goes. A typed number may go as far as the engine accepts.
      // After Effects does the same with a slider range and a valid range (PF_FloatSliderDef).
      // Example: the From value of Datamosh slides to 10 s but can be typed up to the engine's limit.
      final va = _shown(m, t, n, lo0),
          vb = _shown(m, t, n, hi0),
          valid = sh?.open != true && (math.min(va, vb) < lo || math.max(va, vb) > hi) ? ' @valid(${math.min(va, vb)}, ${math.max(va, vb)})' : '';
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
      final whole = sh?.look == 'count' || sh?.look == 'onoff' || sh?.look == 'seed';
      return '  /// $label $ui @range($lo, $hi)${sh?.open == true ? ' @open' : ''}$valid @unit(${turned ? '°' : sh?.unit ?? ''}) @default(${_shown(m, t, n, m.value(t, n, at) ?? lo0)})\n  $n: ${whole ? 'u32' : 'f32'},';
    }
    // Any word: colours of six digits each, taken from the Colors shelf, or numbers with one for each copy.
    return '  /// $label${const ['numbers', 'colours', 'words', 'file'].contains(sh?.look) ? ' @unit(${sh!.look})' : ''}\n  $n: vec3<f32>,';
  }

  // An ISF colour input is stored by the engine as three numbers (_x, _y, _z) plus an alpha.
  // It is shown as one colour on the card, as the effect colour is in After Effects and Alight Motion,
  // and choosing from the Colors shelf sets all three numbers.
  // Without this, a white colour took three number fields.
  String? colorOf(String n, List<String> names) =>
      n.endsWith('_x') &&
          names.contains('${n.substring(0, n.length - 2)}_y') &&
          names.contains('${n.substring(0, n.length - 2)}_z') &&
          (m.shown(n)?.label ?? '').endsWith(' r')
      ? n.substring(0, n.length - 2)
      : null;
  String colour(String base) =>
      '  /// @label(${m.shown('${base}_x')!.label.substring(0, m.shown('${base}_x')!.label.length - 2)})${weights['${base}_x'] == null ? '' : ' @weight(${weights['${base}_x']})'} @unit(colours)\n  $base: vec3<f32>,';
  return [
    for (final (title, names) in m.cards(t))
      // A sound layer has a volume and nothing to place on the canvas, as in Alight Motion's audio layer
      // (docs/internal/reports/alight_motion/alight_ui.md).
      if (title == 'Sound' || !wsSound(m, t))
        Fx(
          title,
          'struct Params {\n${[
            for (final n in names)
              if (m.shown(n)?.fold == null)
                if (colorOf(n, names) case final base?) colour(base) else if (!{
                  for (final x in names)
                    if (colorOf(x, names) case final b?) ...['${b}_y', '${b}_z'],
                }.contains(n)) field(n),
            for (final fold in {for (final n in names) ?m.shown(n)?.fold}) ...['  // @advanced($fold)', for (final n in names)
              if (m.shown(n)?.fold == fold) field(n)],
          ].join('\n')}\n}',
          toneOf: () => Pop.toneLayer,
        ),
  ];
}

/// A value on the engine's own cards as the inspector counts it.
/// Another layer is its position in the list (None first), a number is in the card's units,
/// and a word is its position among the words it may take. This holds for the stage and for layers alike.
double _onCard(Ws ws, Motolii m, int t, String n, double at) {
  // These values are read from the snapshot as the stage shows them (see snapshot.h).
  final seen = const {'x', 'y', 'z', 'rotate', 'scale_x', 'scale_y', 'opacity'}.contains(n) ? m.shows(t, n, at) : null;
  if (seen != null) {
    // Use the displayed value, which includes a drag in progress or a relation moving it, as After Effects shows a value driven by an expression.
    return _shown(m, t, n, seen.$1);
  }
  return m.shown(n)?.look == 'thing'
      ? (_others(ws, t).values.toList().indexOf((m.value(t, n, 0) ?? 0).round()) + 1).toDouble()
      : m.words(t, n).isEmpty
      ? _shown(m, t, n, m.value(t, n, at) ?? 0)
      : math.max(0, m.words(t, n).indexOf(m.word(t, n))).toDouble();
}
