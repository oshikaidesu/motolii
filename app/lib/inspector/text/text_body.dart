// The Text card's inside: the layer's text in a box, set in its font with its ranges' sizes and colors, and the
// character values under it. Letters selected in the box are what the values under it show and change, as in the
// Character panel of After Effects, Figma, Keynote and Word; with none selected they are the whole layer's.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/skin/hex_color.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/font_files.dart';
import 'package:motolii/widgets/text_gestures.dart';

/// The Text card's inside (see host_cards.dart).
class TextBody extends StatefulWidget {
  const TextBody(this.card, {super.key});
  final CardDeclaration card;

  /// The values the inside shows: the text and its ranges in the box, the font, size and tracking under it.
  static const drawn = {
    'text',
    'text_styles',
    'file',
    'size',
    'letter_spacing',
  };

  @override
  State<TextBody> createState() => _TextBodyState();
}

/// The characters selected in the box, counted in Unicode characters as text_styles counts them.
typedef _Letters = ({int start, int count});

class _TextBodyState extends State<TextBody> {
  // The values of the letters selected, or of all the letters for the values only a range has. Made again whenever
  // what it shows changes, which [_made] names.
  InspectorValues? _range;
  String? _made;
  List<FontAxis> _axes = const [];
  String? _axesOf;

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
    if (file != _axesOf) {
      _axesOf = file;
      _axes = const [];
      if (file.isNotEmpty) {
        fontFileAxes(file).then((a) {
          if (mounted && _axesOf == file) setState(() => _axes = a);
        });
      }
    }
    final base = TextStyles.name(Grey.g95).copyWith(
      fontWeight: FontWeight.w400,
      fontFamily: file.isEmpty ? null : fontFileFamily(file),
      fontSize: 15,
      height: 1.3,
    );
    final layer = {for (final p in widget.card.params) p.id: p};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(Shape.s(8)),
          decoration: BoxDecoration(
            color: InspectorSkin.well,
            borderRadius: BorderRadius.all(Shape.r(6)),
          ),
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
            onDone: (said) => said == null ? null : _retype(doc, text, said),
            onPick: (v) => wordsPicked.value =
                v.selection.isValid && !v.selection.isCollapsed
                ? (text: v.text, start: v.selection.start, end: v.selection.end)
                : null,
          ),
        ),
        SizedBox(height: Shape.s(6)),
        ValueListenableBuilder(
          valueListenable: wordsPicked,
          builder: (context, p, _) {
            final picked = p == null || p.text != text
                ? null
                : (
                    start: text.substring(0, p.start).runes.length,
                    count: text.substring(p.start, p.end).runes.length,
                  );
            final all = (start: 0, count: text.runes.length);
            final range = _values(doc, styles, picked ?? all, picked != null);
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
              for (final a in _axes) _axis(a),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ParameterGrid([
                  for (final id in [
                    'file',
                    if (picked == null) ...['size', 'letter_spacing'],
                  ])
                    ?layer[id],
                ]),
                InspectorScope(
                  doc: range,
                  tick: x.tick,
                  child: ParameterGrid(own),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// The values of [letters] as text_styles sets them: Size as a share of the layer's, Fill, Tracking, Baseline and
  /// the font's axes. A change to one writes it to text_styles for those letters; a drag writes once, when it ends.
  InspectorValues _values(
    InspectorValues doc,
    String styles,
    _Letters letters,
    bool picked,
  ) {
    final made =
        '$styles|${letters.start}|${letters.count}|$picked|${_axes.length}';
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
    double? number(String? css, double Function(double) scale) => css == null
        ? null
        : double.tryParse(css.replaceAll(RegExp(r'[^-0-9.]'), '')).let(scale);
    // Each letter's axes as its ranges set them; an axis is Mixed only where the letters differ on that axis.
    final axesOf = [
      for (var i = letters.start; i < letters.start + letters.count; i++)
        _variations(
          rangeValue(styles, i, 1, 'font-variation-settings', otherwise: '') ??
              '',
        ),
    ];
    final range = InspectorValues(doc.kind)..actions = doc.actions;
    range.numbers
      ..['v_size'] = number(at('font-size', '100%'), (v) => v) ?? double.nan
      ..['v_letter_spacing'] =
          number(at('letter-spacing', null), (v) => v * 1000) ??
          (doc.get('v_letter_spacing') ?? 0)
      ..['v_baseline'] =
          number(at('baseline-shift', '0em'), (v) => v) ?? double.nan;
    for (final a in _axes) {
      final each = {for (final m in axesOf) m[a.tag] ?? a.def};
      range.numbers['v_axis_${a.tag}'] = each.length == 1
          ? each.first
          : double.nan;
    }
    range.numbers.removeWhere((_, v) => v.isNaN); // Mixed.
    // Letters no range colors take the layer's fill.
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
      if (range.inGesture) return;
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
      // A changed axis is set on each letter, its other axes kept: the letters are written again as runs of equal axes.
      final changed = {
        for (final a in _axes)
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

  /// Writes the typed text, moving the ranges so each keeps its letters. One write, so one undo step.
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

/// The text set in runs of its ranges' sizes, colors, tracking and axes, as the stage sets them.
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

bool _same<V>(Map<String, V> a, Map<String, V> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

TextStyle _style(TextStyle base, Map<String, String> sets) {
  double? of(String? css) => css == null
      ? null
      : double.tryParse(css.replaceAll(RegExp(r'[^-0-9.]'), ''));
  final size = (base.fontSize ?? 15) * ((of(sets['font-size']) ?? 100) / 100);
  return base.copyWith(
    fontSize: size,
    color: colorOfHex(sets['color'] ?? ''),
    letterSpacing: of(sets['letter-spacing']).let((em) => em * size),
    fontVariations: [
      for (final e in _variations(
        sets['font-variation-settings'] ?? '',
      ).entries)
        FontVariation(e.key, e.value),
    ],
  );
}

/// CSS font-variation-settings, `'wght' 700, 'wdth' 100`, as numbers by axis tag.
Map<String, double> _variations(String css) => {
  for (final m in RegExp(r"""['"](\w{4})['"]\s+(-?[0-9.]+)""").allMatches(css))
    m[1]!: double.parse(m[2]!),
};

/// A number as CSS writes it: no trailing zeros.
String _css(double v) => v == v.roundToDouble()
    ? '${v.round()}'
    : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

/// Size of the letters as a share of the layer's Size: CSS font-size in percent. The slider shows 25–400 %; a typed
/// value goes past it.
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

/// After Effects' Baseline Shift, in ems: CSS baseline-shift. Up is positive, as in CSS.
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

/// [p] as a range value whose default is the layer's.
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

/// One axis of a variable font, its range the font's own (its fvar table).
Parameter _axis(FontAxis a) => Parameter(
  id: 'axis_${a.tag}',
  label: switch (a.tag) {
    'wght' => 'Weight',
    'wdth' => 'Width',
    'slnt' => 'Slant',
    'ital' => 'Italic',
    'opsz' => 'Optical Size',
    final t => t,
  },
  look: ParameterLook.bar,
  min: a.min,
  max: a.max,
  def: a.def,
  dec: a.max - a.min > 10 ? 0 : 2,
);

extension<T extends Object> on T? {
  R? let<R>(R Function(T) f) => this == null ? null : f(this as T);
}
