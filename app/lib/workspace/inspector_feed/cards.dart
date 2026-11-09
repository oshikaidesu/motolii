// cards.dart: the inspector's cards, made from what the inside says a thing has (its cards, their values' ranges and looks, the kind's word).
part of '../workspace.dart';

/// Joined: the document's word for what a thing is, where the inspector's kinds have none (film, picture, solid).
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

/// An effect's colour: three numbers (_x _y _z) whose red channel's label ends in " r" (one colour on the card).
String? _colourBase(Motolii m, String n, List<String> names) {
  if (!n.endsWith('_x')) return null;
  final base = n.substring(0, n.length - 2);
  return names.contains('${base}_y') && names.contains('${base}_z') && (m.shown(n)?.label ?? '').endsWith(' r') ? base : null;
}

String _hex(Motolii m, int t, String base, double at) => [
  for (final c in ['x', 'y', 'z']) ((m.value(t, '${base}_$c', at) ?? 0).clamp(0, 1) * 255).round().toRadixString(16).padLeft(2, '0'),
].join().toUpperCase();

/// A word the card shows. None said: a dash. Words as typed, a file by its name, numbers as they are, a colour or a gradient's stops.
String _asShown(Motolii m, int t, String n) {
  final look = m.shown(n)?.look, w = m.word(t, n);
  if (look == 'words') return w;
  if (w.isEmpty || w == 'none') return '—';
  if (look == 'file') return w.split('/').last;
  if (look == 'numbers') return w;
  return [
    for (final c in w.split(' ').where((c) => c.isNotEmpty).map((c) => c.split('@').first))
      int.tryParse(c, radix: 16) != null && (c.length == 6 || c.length == 8) ? '#${c.toUpperCase()}' : c.replaceRange(0, 1, c[0].toUpperCase()),
  ].join(' ');
}

/// Joined: the colours and words on the inside's own cards, as the inspector writes them.
Map<String, String> _cardColors(Motolii m, int t, double at) {
  final out = <String, String>{};
  for (final (_, names) in m.cards(t)) {
    for (final n in names) {
      if (_colourBase(m, n, names) case final base?) out['v_$base'] = '#${_hex(m, t, base, at)}';
      if (m.words(t, n).isEmpty && m.range(t, n) == null) out['v_$n'] = _asShown(m, t, n);
    }
  }
  return out;
}

/// Joined: the cards the inside shows a thing's values on beyond the sample's (motolii_cards), each as Params in the
/// effects' manner: a number its range and what it is now, a word the words it may be. Nothing of them is typed here.
List<Fx>? _valueCards(Ws ws, String? id) {
  final m = ws.inside, t = id == null ? 0 : int.tryParse(id); // (nothing picked: the stage's own, thing 0)
  if (m == null || t == null) return null;
  // (made again only when the cards it has, their values or the things it may name change: a number let go of changes
  //  none of them, and the numbers the cards show are read from wsTransform; what a card says a number is now, its
  //  @default, the inspector takes only when it makes its cards anew)
  final shape = '${m.cards(t)}|${ws.layers.map((l) => l.name).join(',')}';
  final made = _cardsMade[t];
  if (made != null && made.$1 == shape && identical(made.$3, m)) return made.$2;
  final cards = _makeCards(ws, m, t);
  _cardsMade[t] = (shape, cards, m);
  return cards;
}

final _cardsMade = <int, (String, List<Fx>, Motolii)>{};

List<Fx> _makeCards(Ws ws, Motolii m, int t) {
  final at = _drawn(ws); // (as the picture shown has it)
  String field(String n) {
    final sh = m.shown(n), label = '@label(${sh?.label ?? n.replaceAll('_', ' ').replaceRange(0, 1, n[0].toUpperCase())})';
    if (sh?.look == 'thing') {
      // (another thing, by the names the timeline shows: None, then the others; its number is the document's)
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
      // (the card's span is how far it slides; a number typed goes as far as the inside takes it, as After Effects'
      //  slider range and valid range, PF_FloatSliderDef: Datamosh's From slides to 10 s and is typed to the inside's)
      final va = _shown(m, t, n, lo0),
          vb = _shown(m, t, n, hi0),
          valid = sh?.open != true && (math.min(va, vb) < lo || math.max(va, vb) > hi) ? ' @valid(${math.min(va, vb)}, ${math.max(va, vb)})' : '';
      final turned =
          sh?.look == '' && hi - lo >= 90 && angleLabel(sh!.label); // (an effect's angle in degrees, by its label: a dial, as After Effects' PF_ADD_ANGLE)
      final ui = switch (turned ? 'angle' : sh?.look) {
        'onoff' => '@toggle',
        'angle' => '@ui(angle)',
        'share' when lo >= 0 && hi <= 100 => '@ui(percent)',
        _ => lo < 0 && hi > 0 ? '@ui(bipolar)' : '',
      };
      final whole = sh?.look == 'count' || sh?.look == 'onoff' || sh?.look == 'seed';
      return '  /// $label $ui @range($lo, $hi)${sh?.open == true ? ' @open' : ''}$valid @unit(${turned ? '°' : sh?.unit ?? ''}) @default(${_shown(m, t, n, m.value(t, n, at) ?? lo0)})\n  $n: ${whole ? 'u32' : 'f32'},';
    }
    return '  /// $label${const ['numbers', 'colours', 'words', 'file'].contains(sh?.look) ? ' @unit(${sh!.look})' : ''}\n  $n: vec3<f32>,'; // (any word: colours, six digits each, given from the Colors shelf; or numbers, one for each copy)
  }

  String colour(String base) {
    final label = m.shown('${base}_x')!.label;
    return '  /// @label(${label.substring(0, label.length - 2)}) @unit(colours)\n  $base: vec3<f32>,';
  }
  return [
    for (final (title, names) in m.cards(t))
      if (title == 'Sound' ||
          !wsSound(m, t)) // (a sound has its volume and no picture to place: Alight Motion's audio layer, docs/internal/reports/alight_motion/alight_ui.md 177)
        Fx(
          'v',
          title,
          'struct Params {\n${[
            for (final n in names)
              if (m.shown(n)?.fold == null)
                if (_colourBase(m, n, names) case final base?) colour(base) else if (!{
                  for (final x in names)
                    if (_colourBase(m, x, names) case final b?) ...['${b}_y', '${b}_z'],
                }.contains(n)) field(n),
            for (final fold in {for (final n in names) ?m.shown(n)?.fold}) ...['  // @advanced($fold)', for (final n in names)
              if (m.shown(n)?.fold == fold) field(n)],
          ].join('\n')}\n}',
          toneOf: () => Pop.toneLayer,
        ),
  ];
}

/// Joined: how many of a knob's units make one of the document's (the inside's shown look: a length of the stage in
/// points of the picture, a share in hundredths; else as it is).
/// A value of the inside's own cards as the inspector counts it: another thing by its place (None first), a number
/// in the card's units, a word by its place among those it may be (the stage's and a thing's alike).
double _onCard(Ws ws, Motolii m, int t, String n, double at) {
  final seen = const {'x', 'y', 'z', 'rotate', 'scale_x', 'scale_y', 'opacity'}.contains(n)
      ? m.shows(t, n, at)
      : null; // (the values the moment's copy carries as the stage shows them: snapshot.h)
  if (seen != null) {
    return _shown(m, t, n, seen.$1); // (where it shows: a hand carrying it, a relation moving it, as After Effects shows a value an expression drives)
  }
  return m.shown(n)?.look == 'thing'
      ? (_others(ws, t).values.toList().indexOf((m.value(t, n, 0) ?? 0).round()) + 1).toDouble()
      : m.words(t, n).isEmpty
      ? _shown(m, t, n, m.value(t, n, at) ?? 0)
      : math.max(0, m.words(t, n).indexOf(m.word(t, n))).toDouble(); // (the inside's own cards: a number as it is, a word by its place among those it may be)
}
