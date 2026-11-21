// The Text card's inside: text well with in-well typesetting pills (Align,
// Direction, Metrics, Kinsoku, Hanging, Wrap), slim Font link row, OpenType
// feature toggles, and continuous typography parameters below. Selected letters
// in the box scope Size, Fill, Font, Tracking, Baseline and variable axes to
// that range; with none selected they edit the whole layer.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/link_line.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_meta.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/inspector/text/text_typeset_bar.dart';
import 'package:motolii/skin/hex_color.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/font_files.dart';
import 'package:motolii/widgets/text_gestures.dart';

/// The Text card's inside (see host_cards.dart).
class TextBody extends StatefulWidget {
  const TextBody(this.card, {super.key});
  final CardDeclaration card;

  /// Parameters drawn directly by TextBody; any remaining ones (such as Split)
  /// stay as standard parameter blocks below.
  static const drawn = {
    'text',
    'text_styles',
    'file',
    'size',
    'letter_spacing',
    'line_spacing',
    'italic',
    'align',
    'writing',
    'metrics',
    'kinsoku',
    'hanging',
    'font_features',
    'wrap',
    'wrap_at',
  };

  @override
  State<TextBody> createState() => _TextBodyState();
}

/// The characters selected in the box, counted in Unicode characters as text_styles counts them.
typedef _Letters = ({int start, int count});

class _TextBodyState extends State<TextBody> {
  InspectorValues? _range;
  String? _made;
  final _axesBy = <String, List<FontAxis>>{};
  final _metaBy = <String, FontMeta>{};

  /// Reads OpenType metadata via engine `skrifa` when available, falling back
  /// to async Dart fvar parsing for variable-font axes when running engine-free.
  FontMeta _metaOf(InspectorValues doc, String file) {
    if (file.isEmpty) return emptyFontMeta;
    if (_metaBy[file] case final m?) return m;
    final raw = doc.actions.fontMeta?.call(file) ?? '';
    if (raw.isNotEmpty) {
      return _metaBy[file] = parseFontMeta(raw);
    }
    if (_axesBy[file] case final a?) {
      return (features: const {}, axes: a);
    }
    _axesBy[file] = const [];
    fontFileAxes(file).then((a) {
      if (mounted) setState(() => _axesBy[file] = a);
    });
    return emptyFontMeta;
  }

  @override
  void dispose() {
    _range?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc;
    final text = doc.strings['v_text'] ?? '',
        styles = doc.strings['v_text_styles'] ?? '',
        file = doc.strings['v_file'] ?? '';
    final vertical = (doc.get('v_writing') ?? 0).round() == 1;
    final wrapping = (doc.get('v_wrap') ?? 0).round() != 0;
    final base = TextStyles.name(Grey.g95).copyWith(
      fontWeight: FontWeight.w400,
      fontFamily: file.isEmpty ? null : fontFileFamily(file),
      fontSize: 15,
      height: 1.3,
    );
    final layer = {for (final p in widget.card.params) p.id: p};
    return ValueListenableBuilder(
      valueListenable: wordsPicked,
      builder: (context, p, _) {
        final picked = pickedLetters(text, p);
        final all = (start: 0, count: text.runes.length);
        final letters = picked ?? all;
        // The letters' font: the file their ranges name, else the layer's; null where they differ.
        final font = fontFileOf(
          rangeValue(
            styles,
            letters.start,
            letters.count,
            'font-family',
            otherwise: "'$file'",
          ),
        );
        final shownFont = picked != null ? font : file;
        final meta = _metaOf(doc, shownFont ?? '');
        final axes = meta.axes;
        final range = _values(doc, styles, letters, picked != null, axes, font);
        final layerTiles = [
          ?layer['size'],
          ?layer['letter_spacing'],
          ?layer['line_spacing'],
          ?layer['italic'],
          if (wrapping) ?layer['wrap_at'],
        ];
        final own = [
          if (picked != null) ...[
            _size,
            const Parameter(
              id: 'fill',
              label: 'Fill',
              look: ParameterLook.color,
            ),
            if (layer['letter_spacing'] case final t?)
              _like(t, def: doc.get('v_letter_spacing') ?? 0),
          ],
          _baseline,
          for (final a in axes) _axis(a),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TextWell(
              doc: doc,
              layer: layer,
              text: text,
              styles: styles,
              base: base,
              vertical: vertical,
              picked: picked,
              onDone: (said) => _typed(doc, text, said),
              onPick: (v) {
                _typing(doc, text, v.text);
                wordsPicked.value =
                    v.selection.isValid && !v.selection.isCollapsed
                    ? (
                        text: v.text,
                        start: v.selection.start,
                        end: v.selection.end,
                      )
                    : null;
              },
            ),
            if (layer.containsKey('file')) ...[
              SizedBox(height: Shape.s(6)),
              InspectorScope(
                doc: picked != null ? range : doc,
                tick: x.tick,
                child: _FontRow(
                  value: shownFont == null
                      ? 'Mixed'
                      : (shownFont.isEmpty ? 'Default' : shownFont),
                  scoped: picked != null,
                ),
              ),
            ],
            if (picked == null && layer.containsKey('font_features'))
              TextFeaturesStrip(doc: doc, supported: meta.features),
            SizedBox(height: Shape.s(2)),
            if (picked == null)
              _ScopedGrid(
                tick: x.tick,
                items: [
                  for (final param in layerTiles) (doc, param),
                  for (final param in own) (range, param),
                ],
              )
            else if (own.isNotEmpty)
              InspectorScope(
                doc: range,
                tick: x.tick,
                child: ParameterGrid(own),
              ),
          ],
        );
      },
    );
  }

  /// The values of [letters] as text_styles sets them: Size as a share of the layer's, Fill, Tracking, Baseline and
  /// the font's axes. A change to one writes it to text_styles for those letters; a drag writes each step, and the layer's
  /// values are in the drag with it, so the stage follows and the drag is one undo step.
  InspectorValues _values(
    InspectorValues doc,
    String styles,
    _Letters letters,
    bool picked,
    List<FontAxis> axes,
    String? font,
  ) {
    final made =
        '$styles|${letters.start}|${letters.count}|$picked|$font|${axes.length}';
    if (_range != null && made == _made) return _range!;
    _range?.dispose();
    _made = made;
    String? at(String property, String? otherwise) => rangeValue(
      styles,
      letters.start,
      letters.count,
      property,
      otherwise: otherwise,
    );
    double? number(String? css, double Function(double) scale) =>
        _number(css).let(scale);
    final axesOf = [
      for (var i = letters.start; i < letters.start + letters.count; i++)
        _variations(
          rangeValue(styles, i, 1, 'font-variation-settings', otherwise: '') ??
              '',
        ),
    ];
    final range = _RangeValues(doc)..actions = doc.actions;
    range.numbers
      ..['v_size'] = number(at('font-size', '100%'), (v) => v) ?? double.nan
      ..['v_letter_spacing'] =
          number(at('letter-spacing', null), (v) => v * 1000) ??
          (doc.get('v_letter_spacing') ?? 0)
      ..['v_baseline'] =
          number(at('baseline-shift', '0em'), (v) => v) ?? double.nan;
    for (final a in axes) {
      final each = {for (final m in axesOf) m[a.tag] ?? a.def};
      range.numbers['v_axis_${a.tag}'] = each.length == 1
          ? each.first
          : double.nan;
    }
    range.numbers.removeWhere((_, v) => v.isNaN); // Mixed.
    if (font != null) range.strings['v_file'] = font;
    switch (at('color', 'fill')) {
      case 'fill':
        if (doc.strings['v_fill'] case final f?) {
          range.strings['v_fill'] = f.startsWith('#') ? f : '#$f';
        }
      case final c?:
        range.strings['v_fill'] = c;
    }
    final shown = Map.of(range.numbers);
    range.addListener(() {
      var next = styles;
      for (final e in range.numbers.entries) {
        if (shown[e.key] == e.value) continue;
        final v = e.value;
        next = switch (e.key) {
          'v_size' => styleRange(
            next,
            letters.start,
            letters.count,
            'font-size',
            '${_css(v)}%',
          ),
          'v_letter_spacing' => styleRange(
            next,
            letters.start,
            letters.count,
            'letter-spacing',
            '${_css(v / 1000)}em',
          ),
          'v_baseline' => styleRange(
            next,
            letters.start,
            letters.count,
            'baseline-shift',
            '${_css(v)}em',
          ),
          _ => next,
        };
      }
      final changed = {
        for (final a in axes)
          if (range.numbers['v_axis_${a.tag}'] case final v?
              when v != shown['v_axis_${a.tag}'])
            a.tag: v,
      };
      if (changed.isNotEmpty) {
        final each = [
          for (final m in axesOf) {...m, ...changed},
        ];
        next = styleRange(
          next,
          letters.start,
          letters.count,
          'font-variation-settings',
          null,
        );
        for (var from = 0, i = 1; i <= each.length; i++) {
          if (i < each.length && _same(each[i], each[from])) continue;
          next = styleRange(
            next,
            letters.start + from,
            i - from,
            'font-variation-settings',
            [for (final e in each[from].entries) "'${e.key}' ${_css(e.value)}"]
                .join(', '),
          );
          from = i;
        }
      }
      if (next != styles) doc.str('v_text_styles', next);
    });
    return _range = range;
  }

  String? _before;
  String _sent = '';

  void _typing(InspectorValues doc, String text, String now) {
    final was = _before == null ? text : _sent;
    if (now == was) return;
    if (_before == null) {
      _before = text;
      doc.beginGesture();
    }
    _retype(doc, was, now);
    _sent = now;
  }

  void _typed(InspectorValues doc, String text, String? said) {
    final before = _before;
    if (before == null) {
      if (said != null) _retype(doc, text, said);
      return;
    }
    _before = null;
    final last = said ?? before;
    if (last != _sent) _retype(doc, _sent, last);
    doc.endGesture();
  }

  void _retype(InspectorValues doc, String was, String said) {
    final a = was.runes.toList(), b = said.runes.toList();
    var head = 0;
    while (head < a.length && head < b.length && a[head] == b[head]) {
      head++;
    }
    var tail = 0;
    while (tail < a.length - head &&
        tail < b.length - head &&
        a[a.length - 1 - tail] == b[b.length - 1 - tail]) {
      tail++;
    }
    final styles = doc.strings['v_text_styles'] ?? '';
    if (styles.isNotEmpty) {
      doc.strings['v_text_styles'] = shiftRanges(
        styles,
        head,
        a.length - head - tail,
        b.length - head - tail,
      );
    }
    doc.str('v_text', said);
  }
}

/// Recessed text well combining the editable styled text box, selection scope
/// indicator, vertical-writing guide, and in-well typesetting pills.
class _TextWell extends StatelessWidget {
  const _TextWell({
    required this.doc,
    required this.layer,
    required this.text,
    required this.styles,
    required this.base,
    required this.vertical,
    required this.picked,
    required this.onDone,
    required this.onPick,
  });

  final InspectorValues doc;
  final Map<String, Parameter> layer;
  final String text;
  final String styles;
  final TextStyle base;
  final bool vertical;
  final _Letters? picked;
  final void Function(String?) onDone;
  final void Function(TextEditingValue) onPick;

  @override
  Widget build(BuildContext context) {
    final hasBar =
        layer.containsKey('align') ||
        layer.containsKey('writing') ||
        layer.containsKey('metrics') ||
        layer.containsKey('kinsoku') ||
        layer.containsKey('hanging') ||
        layer.containsKey('wrap');
    return Container(
      padding: EdgeInsets.fromLTRB(
        Shape.s(8),
        Shape.s(7),
        Shape.s(8),
        hasBar ? Shape.s(6) : Shape.s(8),
      ),
      decoration: BoxDecoration(
        color: InspectorSkin.well,
        borderRadius: Shape.round(6),
        border: Border.all(
          color: picked != null
              ? Accent.fill.withValues(alpha: 0.45)
              : Grey.g20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TypedField(
                  key: const ValueKey('text:box'),
                  text: text,
                  standing: true,
                  escapes: true,
                  style: base,
                  cursor: Grey.g95,
                  backgroundCursor: Grey.g20,
                  selection: Role.selected.withValues(alpha: .4),
                  styled: (t, style) => _spans(t, styles, style),
                  onDone: onDone,
                  onPick: onPick,
                ),
              ),
              if (picked != null)
                Padding(
                  padding: EdgeInsets.only(left: Shape.s(6)),
                  child: Container(
                    key: const ValueKey('text:scope'),
                    padding: EdgeInsets.symmetric(
                      horizontal: Shape.s(5),
                      vertical: Shape.s(2),
                    ),
                    decoration: BoxDecoration(
                      color: Accent.fill.withValues(alpha: 0.16),
                      borderRadius: Shape.round(4),
                      border: Border.all(
                        color: Accent.fill.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      '${picked!.count} ch',
                      style: TextStyles.micro(Accent.fill),
                    ),
                  ),
                )
              else if (vertical)
                Padding(
                  padding: EdgeInsets.only(left: Shape.s(6)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Shape.s(4),
                      vertical: Shape.s(2),
                    ),
                    decoration: BoxDecoration(
                      color: Grey.g10,
                      borderRadius: Shape.round(4),
                    ),
                    child: Text('縦', style: TextStyles.micro(Grey.g63)),
                  ),
                ),
            ],
          ),
          if (hasBar) TextTypesetBar(doc: doc, layer: layer),
        ],
      ),
    );
  }
}

/// Slim 30px Font link row replacing the tall 42px tile while preserving LinkLine routing.
class _FontRow extends StatelessWidget {
  const _FontRow({required this.value, required this.scoped});

  final String value;
  final bool scoped;

  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(30),
    padding: EdgeInsets.symmetric(horizontal: InspectorSkin.tilePad),
    decoration: BoxDecoration(
      color: InspectorSkin.well,
      borderRadius: Shape.round(6),
    ),
    child: Row(
      children: [
        Text(
          scoped ? 'Range font' : 'Font',
          style: TextStyles.micro(scoped ? Accent.fill : Grey.g63),
        ),
        SizedBox(width: Shape.s(8)),
        Expanded(
          child: LinkLine(to: LinkTo.fonts, value: value, id: 'v_file'),
        ),
      ],
    ),
  );
}

/// Lays out layer-scoped and range-scoped tiles in one continuous grid so
/// Slant, Baseline and variable-font axes share rows cleanly without orphan gaps.
class _ScopedGrid extends StatelessWidget {
  const _ScopedGrid({required this.items, required this.tick});

  final List<(InspectorValues, Parameter)> items;
  final int tick;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (_, box) {
        final g = InspectorSkin.tileGap;
        final cols = math.max(
          1,
          ((box.maxWidth + g) / (InspectorSkin.tileMin + g)).floor(),
        );
        final rows = <List<(InspectorValues, Parameter)>>[];
        for (var i = 0; i < items.length; i += cols) {
          rows.add(items.sublist(i, math.min(i + cols, items.length)));
        }
        return Padding(
          padding: EdgeInsets.only(top: Shape.s(4)),
          child: Column(
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) SizedBox(height: g),
                Row(
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) SizedBox(width: g),
                      Expanded(
                        child: InspectorScope(
                          doc: rows[r][c].$1,
                          tick: tick,
                          child: ParameterTile(rows[r][c].$2),
                        ),
                      ),
                    ],
                    if (rows[r].length < cols) ...[
                      SizedBox(width: g),
                      Spacer(flex: cols - rows[r].length),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RangeValues extends InspectorValues {
  _RangeValues(this.whole) : super(whole.kind);
  final InspectorValues whole;

  @override
  void beginGesture() {
    whole.beginGesture();
    super.beginGesture();
  }

  @override
  void endGesture() {
    super.endGesture();
    whole.endGesture();
  }
}

InlineSpan _spans(String text, String styles, TextStyle base) {
  final ranges = readRanges(styles);
  if (ranges.isEmpty) return TextSpan(text: text, style: base);
  final runes = text.runes.toList(), runs = <TextSpan>[];
  Map<String, String> setsAt(int i) => {
    for (final r in ranges)
      if (i >= r.start && i < r.start + r.count) ...r.sets,
  };
  var from = 0;
  for (var i = 1; i <= runes.length; i++) {
    final sets = setsAt(from);
    if (i < runes.length && _same(setsAt(i), sets)) continue;
    runs.add(
      TextSpan(
        text: String.fromCharCodes(runes, from, i),
        style: _style(base, sets),
      ),
    );
    from = i;
  }
  return TextSpan(style: base, children: runs);
}

double? _number(String? css) => css == null
    ? null
    : double.tryParse(css.replaceAll(RegExp(r'[^-0-9.]'), ''));

bool _same<V>(Map<String, V> a, Map<String, V> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

TextStyle _style(TextStyle base, Map<String, String> sets) {
  final size =
      (base.fontSize ?? 15) * ((_number(sets['font-size']) ?? 100) / 100);
  final font = fontFileOf(sets['font-family']);
  return base.copyWith(
    fontFamily: font == null ? null : fontFileFamily(font),
    fontFamilyFallback: font == null || base.fontFamily == null
        ? null
        : [base.fontFamily!],
    fontSize: size,
    color: colorOfHex(sets['color'] ?? ''),
    letterSpacing: _number(sets['letter-spacing']).let((em) => em * size),
    fontVariations: [
      for (final e in _variations(
        sets['font-variation-settings'] ?? '',
      ).entries)
        FontVariation(e.key, e.value),
    ],
  );
}

Map<String, double> _variations(String css) => {
  for (final m in RegExp(r"""['"](\w{4})['"]\s+(-?[0-9.]+)""").allMatches(css))
    m[1]!: double.parse(m[2]!),
};

String _css(double v) => v == v.roundToDouble()
    ? '${v.round()}'
    : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

const _size = Parameter(
  id: 'size',
  label: 'Size',
  look: ParameterLook.scrub,
  unit: '%',
  def: 100,
  min: 25,
  max: 400,
  open: true,
);

const _baseline = Parameter(
  id: 'baseline',
  label: 'Baseline',
  look: ParameterLook.bipolar,
  unit: 'em',
  dec: 2,
  min: -1,
  max: 1,
  open: true,
);

Parameter _like(Parameter p, {required double def}) => Parameter(
  id: p.id,
  label: p.label,
  look: p.look,
  unit: p.unit,
  dec: p.dec,
  min: p.min,
  max: p.max,
  def: def,
  open: true,
);

Parameter _axis(FontAxis a) => Parameter(
  id: 'axis_${a.tag}',
  label: a.name,
  look: ParameterLook.bar,
  min: a.min,
  max: a.max,
  def: a.def,
  dec: a.max - a.min > 10 ? 0 : 2,
);

extension<T extends Object> on T? {
  R? let<R>(R Function(T) f) => this == null ? null : f(this as T);
}
