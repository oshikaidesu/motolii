// Dedicated Text host card without duplicating Stage rendering:
// 1. Clipped horizontal text editor with in-well discrete typesetting pills
//    (Direction, Align, Metrics | Wrap, Kinsoku, Hanging)
// 2. Slim Font row + Transform-style 24px compact numeric rows for continuous
//    keyframeable typography parameters (Size, Slant, Baseline / Track, Line, Wrap at)
// 3. OpenType feature chip strip + variable-font axes
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/link_line.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart' show Swatch;
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/inspector/text/text_marks.dart';
import 'package:motolii/inspector/text/text_meta.dart';
import 'package:motolii/inspector/text/text_notebook.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/inspector/text/text_typeset_bar.dart';
import 'package:motolii/skin/hex_color.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/font_files.dart';
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/text_gestures.dart';

/// The Text card's inside (see host_cards.dart).
class TextBody extends StatefulWidget {
  const TextBody(this.card, {super.key});
  final CardDeclaration card;

  /// Parameters drawn directly by TextBody; remaining ones (such as Split)
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
  String? _activeClass;
  final _axesBy = <String, List<FontAxis>>{};
  final _metaBy = <String, FontMeta>{};

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
  void initState() {
    super.initState();
    fontFilesReady.addListener(_onFontReady);
  }

  void _onFontReady() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    fontFilesReady.removeListener(_onFontReady);
    _range?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc;
    final text = doc.strings['v_text'] ?? '',
        styles = doc.strings['v_text_styles'] ?? '',
        file = doc.strings['v_file'] ?? '';
    final wrapping = (doc.get('v_wrap') ?? 0).round() != 0;
    final loadedFamily = file.isEmpty ? null : fontFileFamily(file);
    final base = TextStyles.name(Grey.g95).copyWith(
      fontWeight: FontWeight.w400,
      fontFamily: loadedFamily,
      fontSize: notebookFontSize,
      height: notebookLineHeight,
    );
    final layer = {for (final p in widget.card.params) p.id: p};

    return ValueListenableBuilder(
      valueListenable: wordsPicked,
      builder: (context, p, _) {
        final picked = pickedLetters(text, p);
        final activeClass = picked != null ? null : _activeClass;
        final scoped = picked != null || activeClass != null;
        final all = (start: 0, count: text.runes.length);
        final letters = picked ?? all;
        final font = activeClass != null
            ? fontFileOf(
                classValue(
                  styles,
                  activeClass,
                  'font-family',
                  otherwise: "'$file'",
                ),
              )
            : fontFileOf(
                rangeValue(
                  styles,
                  letters.start,
                  letters.count,
                  'font-family',
                  otherwise: "'$file'",
                ),
              );
        final shownFont = scoped ? font : file;
        final meta = _metaOf(doc, shownFont ?? '');
        final axes = meta.axes;
        final range = _values(
          doc,
          styles,
          letters,
          activeClass,
          scoped,
          axes,
          font,
        );

        Widget numCell(
          InspectorValues target,
          Parameter param, {
          String? label,
          void Function(Canvas, Size, Color, double)? mark,
        }) => _CompactNumberCell(
          doc: target,
          tick: x.tick,
          param: param,
          label: label ?? param.label,
          mark: mark,
        );

        // Compact 24px rows for continuous keyframeable values.
        final glyphRow = !scoped
            ? <Widget>[
                if (layer['size'] case final s?)
                  numCell(doc, s, mark: drawTextSize),
                if (layer['italic'] case final s?)
                  numCell(doc, s, mark: drawTextSlant),
                numCell(
                  range,
                  _baseline,
                  label: 'Base',
                  mark: drawTextBaseline,
                ),
              ]
            : <Widget>[
                numCell(
                  range,
                  _size,
                  mark: (c, s, col, v) => drawTextSize(c, s, col, v / 1000),
                ),
                _CompactColorCell(doc: range, tick: x.tick),
                if (layer['letter_spacing'] case final t?)
                  numCell(
                    range,
                    _like(t, def: doc.get('v_letter_spacing') ?? 0),
                    label: 'Track',
                    mark: drawTextTracking,
                  ),
              ];

        final flowRow = !scoped
            ? <Widget>[
                if (layer['letter_spacing'] case final t?)
                  numCell(doc, t, label: 'Track', mark: drawTextTracking),
                if (layer['line_spacing'] case final l?)
                  numCell(doc, l, label: 'Line', mark: drawTextLineHeight),
                if (wrapping && layer['wrap_at'] != null)
                  numCell(doc, layer['wrap_at']!, mark: drawTextWrapWidth),
              ]
            : <Widget>[
                numCell(
                  range,
                  _baseline,
                  label: 'Base',
                  mark: drawTextBaseline,
                ),
              ];

        final axisCells = <Widget>[
          for (final a in axes)
            numCell(
              range,
              _axis(a),
              mark: (c, s, col, v) =>
                  drawTextAxis(c, s, col, a.tag, v, a.min, a.max),
            ),
        ];

        final fontLabel = picked != null
            ? 'Range font'
            : (activeClass != null
                  ? '${textCharClasses.firstWhere((c) => c.id == activeClass, orElse: () => (id: activeClass, label: activeClass, tip: activeClass)).label} font'
                  : 'Font');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Ruled notebook editor with borderless ruler, margin rail, and class scope footer.
            TextNotebook(
              doc: doc,
              layer: layer,
              text: text,
              styles: styles,
              base: base,
              pickedCount: picked?.count,
              activeClass: activeClass,
              onSelectClass: (cls) => setState(() => _activeClass = cls),
              styled: (t, style) =>
                  _spans(t, styles, style, highlightClass: activeClass),
              onDone: (said) => _typed(doc, text, said),
              onPick: (v) {
                _typing(doc, text, v.text);
                final hasSel = v.selection.isValid && !v.selection.isCollapsed;
                if (hasSel && _activeClass != null) {
                  setState(() => _activeClass = null);
                }
                wordsPicked.value = hasSel
                    ? (
                        text: v.text,
                        start: v.selection.start,
                        end: v.selection.end,
                      )
                    : null;
              },
            ),

            // 2. Slim Font row + 24px compact rows for continuous motion parameters.
            if (layer.containsKey('file')) ...[
              SizedBox(height: Shape.s(5)),
              InspectorScope(
                doc: scoped ? range : doc,
                tick: x.tick,
                child: _FontRow(
                  label: fontLabel,
                  value: shownFont == null
                      ? 'Mixed'
                      : (shownFont.isEmpty ? 'Default' : shownFont),
                  scoped: scoped,
                ),
              ),
            ],
            if (glyphRow.isNotEmpty) ...[
              SizedBox(height: InspectorSkin.tileGap),
              _CompactRow(glyphRow),
            ],
            if (flowRow.isNotEmpty) ...[
              SizedBox(height: InspectorSkin.tileGap),
              _CompactRow(flowRow),
            ],
            if (axisCells.isNotEmpty)
              for (var i = 0; i < axisCells.length; i += 3) ...[
                SizedBox(height: InspectorSkin.tileGap),
                _CompactRow(
                  axisCells.sublist(i, math.min(i + 3, axisCells.length)),
                ),
              ],
            if (!scoped && layer.containsKey('font_features'))
              TextFeaturesFold(
                doc: doc,
                supported: meta.features,
                fontFamily: loadedFamily,
              ),
          ],
        );
      },
    );
  }

  InspectorValues _values(
    InspectorValues doc,
    String styles,
    _Letters letters,
    String? activeClass,
    bool scoped,
    List<FontAxis> axes,
    String? font,
  ) {
    final made =
        '$styles|${letters.start}|${letters.count}|$activeClass|$scoped|$font|${axes.length}';
    if (_range != null && made == _made) return _range!;
    _range?.dispose();
    _made = made;
    String? at(String property, String? otherwise) => activeClass != null
        ? classValue(styles, activeClass, property, otherwise: otherwise)
        : rangeValue(
            styles,
            letters.start,
            letters.count,
            property,
            otherwise: otherwise,
          );
    double? number(String? css, double Function(double) scale) =>
        _number(css).let(scale);
    final axesOf = activeClass != null
        ? [
            _variations(
              classValue(
                    styles,
                    activeClass,
                    'font-variation-settings',
                    otherwise: '',
                  ) ??
                  '',
            ),
          ]
        : [
            for (var i = letters.start; i < letters.start + letters.count; i++)
              _variations(
                rangeValue(
                      styles,
                      i,
                      1,
                      'font-variation-settings',
                      otherwise: '',
                    ) ??
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
    range.numbers.removeWhere((_, v) => v.isNaN);
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
    final shownFont = range.strings['v_file'];
    final shownFill = range.strings['v_fill'];
    String writeProp(String current, String property, String? value) =>
        activeClass != null
        ? styleClass(current, activeClass, property, value)
        : styleRange(current, letters.start, letters.count, property, value);

    range.addListener(() {
      var next = styles;
      if (range.strings['v_file'] != shownFont &&
          range.strings['v_file'] != null) {
        final f = range.strings['v_file']!;
        next = writeProp(next, 'font-family', f.isEmpty ? null : "'$f'");
      }
      if (range.strings['v_fill'] != shownFill &&
          range.strings['v_fill'] != null) {
        next = writeProp(next, 'color', range.strings['v_fill']);
      }
      for (final e in range.numbers.entries) {
        if (shown[e.key] == e.value) continue;
        final v = e.value;
        next = switch (e.key) {
          'v_size' => writeProp(next, 'font-size', '${_css(v)}%'),
          'v_letter_spacing' => writeProp(
            next,
            'letter-spacing',
            '${_css(v / 1000)}em',
          ),
          'v_baseline' => writeProp(next, 'baseline-shift', '${_css(v)}em'),
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
        if (activeClass != null) {
          final merged = {...axesOf.first, ...changed};
          next = styleClass(
            next,
            activeClass,
            'font-variation-settings',
            [for (final e in merged.entries) "'${e.key}' ${_css(e.value)}"]
                .join(', '),
          );
        } else {
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
              [
                for (final e in each[from].entries)
                  "'${e.key}' ${_css(e.value)}",
              ].join(', '),
            );
            from = i;
          }
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

/// 24px compact scrubbable number cell matching Transform's compact rows, with
/// left-aligned micro label over the right-aligned number field so dragging
/// anywhere on the cell (including its label) scrubs the value.
class _CompactNumberCell extends StatelessWidget {
  const _CompactNumberCell({
    required this.doc,
    required this.tick,
    required this.param,
    required this.label,
    this.mark,
  });

  final InspectorValues doc;
  final int tick;
  final Parameter param;
  final String label;
  final void Function(Canvas, Size, Color, double)? mark;

  @override
  Widget build(BuildContext context) {
    final id = 'v_${param.id}';
    return InspectorScope(
      doc: doc,
      tick: tick,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          RowInfo(
            keys: doc.keys[id] ?? KeyframeState.off,
            child: InspectorNumberField(
              param,
              id: id,
              caption: '',
              compact: true,
            ),
          ),
          IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(left: Shape.s(5)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mark != null) ...[
                    ListenableBuilder(
                      listenable: doc.watch(id),
                      builder: (_, _) {
                        final v = doc.get(id) ?? param.def;
                        return CustomPaint(
                          size: const Size(10, 10),
                          painter: Draw((c, s) => mark!(c, s, Grey.g63, v), (
                            v,
                            label,
                          )),
                        );
                      },
                    ),
                    SizedBox(width: Shape.s(3)),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.micro(Grey.g56),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact 24px range color cell shown when letters are selected in the text box.
class _CompactColorCell extends StatelessWidget {
  const _CompactColorCell({required this.doc, required this.tick});

  final InspectorValues doc;
  final int tick;

  @override
  Widget build(BuildContext context) {
    final hex = doc.strings['v_fill'] ?? '—';
    return InspectorScope(
      doc: doc,
      tick: tick,
      child: Container(
        height: InspectorSkin.cell,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
        decoration: BoxDecoration(
          color: InspectorSkin.well,
          borderRadius: Shape.round(6),
        ),
        child: Row(
          children: [
            Swatch(hex),
            SizedBox(width: Shape.s(5)),
            Expanded(
              child: LinkLine(to: LinkTo.colors, value: hex, id: 'v_fill'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-column aligned row of 24px compact cells.
class _CompactRow extends StatelessWidget {
  const _CompactRow(this.cells);
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final g = InspectorSkin.tileGap;
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) SizedBox(width: g),
          Expanded(child: cells[i]),
        ],
        if (cells.length < 3) ...[
          SizedBox(width: g),
          Spacer(flex: 3 - cells.length),
        ],
      ],
    );
  }
}

/// Slim 28px Font link row.
class _FontRow extends StatelessWidget {
  const _FontRow({
    required this.label,
    required this.value,
    required this.scoped,
  });

  final String label;
  final String value;
  final bool scoped;

  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(28),
    padding: EdgeInsets.symmetric(horizontal: InspectorSkin.tilePad),
    decoration: BoxDecoration(
      color: InspectorSkin.well,
      borderRadius: Shape.round(6),
    ),
    child: Row(
      children: [
        Text(label, style: TextStyles.micro(scoped ? Accent.fill : Grey.g63)),
        SizedBox(width: Shape.s(8)),
        Expanded(
          child: LinkLine(to: LinkTo.fonts, value: value, id: 'v_file'),
        ),
      ],
    ),
  );
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

InlineSpan _spans(
  String text,
  String styles,
  TextStyle base, {
  String? highlightClass,
}) {
  final classes = readClassRules(styles);
  final ranges = readRanges(styles);
  if (classes.isEmpty && ranges.isEmpty && highlightClass == null) {
    return TextSpan(text: text, style: base);
  }
  final runes = text.runes.toList(), runs = <TextSpan>[];
  (Map<String, String>, bool) styleAt(int i) {
    final u = runes[i];
    final sets = <String, String>{};
    for (final c in classes) {
      if (charMatchesClass(u, c.name)) sets.addAll(c.sets);
    }
    for (final r in ranges) {
      if (i >= r.start && i < r.start + r.count) sets.addAll(r.sets);
    }
    final lit = highlightClass != null && charMatchesClass(u, highlightClass);
    return (sets, lit);
  }

  var from = 0;
  for (var i = 1; i <= runes.length; i++) {
    final (sets, lit) = styleAt(from);
    if (i < runes.length) {
      final (nextSets, nextLit) = styleAt(i);
      if (nextLit == lit && _same(nextSets, sets)) continue;
    }
    final s = _style(base, sets);
    runs.add(
      TextSpan(
        text: String.fromCharCodes(runes, from, i),
        style: lit
            ? s.copyWith(backgroundColor: Accent.fill.withValues(alpha: 0.18))
            : s,
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

/// Preview-safe bounds so extreme per-range font sizes or tracking never
/// overflow the inspector's text box into surrounding cards.
const double _previewMinSize = 9.0;
const double _previewMaxSize = 26.0;

TextStyle _style(TextStyle base, Map<String, String> sets) {
  final rawSize =
      (base.fontSize ?? 15) * ((_number(sets['font-size']) ?? 100) / 100);
  final size = rawSize.clamp(_previewMinSize, _previewMaxSize);
  final font = fontFileOf(sets['font-family']);
  return base.copyWith(
    fontFamily: font == null ? null : fontFileFamily(font),
    fontFamilyFallback: font == null || base.fontFamily == null
        ? null
        : [base.fontFamily!],
    fontSize: size,
    color: colorOfHex(sets['color'] ?? ''),
    letterSpacing: _number(sets['letter-spacing'])
        .let((em) => (em * size).clamp(-4.0, 12.0)),
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
