// The Fill card's inside: live fill & stacked-stroke preview instrument,
// compact fill/gradient controls, and a slim unified stroke stack.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/link_line.dart' show LinkTo;
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/fill/fill_preview.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/tip.dart' show Tip;

/// The Fill card's inside (see host_cards.dart).
/// Gradient sub-settings come from the engine's fold (`Parameter.fold ==
/// gradient.label`) and show inline whenever a gradient is active. Both the
/// primary stroke and absorbed extra Stroke cards render as one slim list.
class FillBody extends StatelessWidget {
  const FillBody(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {
    'fill',
    'fill_media',
    'gradient',
    'gradient_angle',
    'gradient_scale',
    'gradient_spread',
    'stroke',
    'stroke_width',
    'stroke_align',
  };

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final byId = {for (final p in card.params) p.id: p};
    final fillP = byId['fill'];
    final mediaP = byId['fill_media'];
    final gradP = byId['gradient'];
    final strokeP = byId['stroke'];
    final strokeWidthP = byId['stroke_width'];
    final strokeAlignP = byId['stroke_align'];

    // Engine's fold is the source of truth for gradient sub-parameters.
    // Discrete choices (gradient type / spread) live inside FillPreview's
    // pills; only continuous, keyframeable sliders stay below as tiles.
    final gradLabel = gradP?.label;
    final gradContinuous = [
      for (final p in card.params)
        if (gradLabel != null &&
            p.fold == gradLabel &&
            p.look != ParameterLook.choice)
          p,
    ];
    final spreadP = byId['gradient_spread'];

    final extraStrokes = [
      for (final c in doc.cards)
        if (c.name == 'Stroke') c,
    ];

    final listenables = <Listenable>[
      doc,
      doc.watch('v_gradient'),
      doc.watch('v_gradient_angle'),
      doc.watch('v_gradient_scale'),
      doc.watch('v_gradient_spread'),
      doc.watch('v_stroke_width'),
      doc.watch('v_stroke_align'),
      for (final sc in extraStrokes)
        for (final p in sc.params)
          if (p.id.endsWith(':stroke_width') || p.id.endsWith(':stroke_align'))
            doc.watch('v_${p.id}'),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final fillWord = doc.strings['v_fill'] ?? '';
        final mediaWord = doc.strings['v_fill_media'] ?? '';
        final colors = parseFillColors(fillWord);
        final gradVal = (doc.get('v_gradient') ?? 0).round();
        final gradWord = gradP?.options.elementAtOrNull(gradVal)?.toLowerCase();
        final isRadial = gradWord == 'radial';

        final primaryStrokeColors = parseFillColors(doc.strings['v_stroke']);
        final previewStrokes = <FillPreviewStroke>[
          if (strokeWidthP != null)
            (
              colors: primaryStrokeColors.isNotEmpty
                  ? primaryStrokeColors
                  : [Grey.g91],
              width: doc.get('v_stroke_width') ?? strokeWidthP.def,
              align: _alignOf(strokeAlignP, doc),
            ),
          for (final sc in extraStrokes) ?_extraStrokeOf(sc, doc),
        ];

        final hasStrokeGradient = previewStrokes.any(
          (s) => s.colors.length > 1,
        );
        final hasGradient =
            gradVal > 0 || colors.length > 1 || hasStrokeGradient;

        final spreadVal = (doc.get('v_gradient_spread') ?? 0).round();

        final hasAlignControl =
            strokeAlignP != null ||
            extraStrokes.any(
              (sc) => sc.params.any((p) => p.id.endsWith(':stroke_align')),
            );
        final hasExtraDetails = extraStrokes.any(
          (sc) => sc.params.any(
            (p) =>
                !p.id.endsWith(':stroke') &&
                !p.id.endsWith(':stroke_width') &&
                !p.id.endsWith(':stroke_align'),
          ),
        );
        final hasRemovable =
            extraStrokes.isNotEmpty && doc.actions.onCardRemove != null;

        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FillPreview(
                colors: colors,
                media: mediaWord,
                hasGradient: hasGradient,
                gradIndex: gradVal,
                gradOptions: gradP?.options ?? const [],
                radial: isRadial,
                angle: doc.get('v_gradient_angle') ?? 0,
                scale: doc.get('v_gradient_scale') ?? 1,
                spreadIndex: spreadVal,
                spreadOptions: spreadP?.options ?? const [],
                strokes: previewStrokes,
                angleParam: byId['gradient_angle'],
                scaleParam: byId['gradient_scale'],
              ),
              if (fillP != null || mediaP != null) ...[
                SizedBox(height: Shape.s(6)),
                _FillRow(
                  doc: doc,
                  colors: colors,
                  fillRaw: fillWord,
                  hasMediaParam: mediaP != null,
                  mediaRaw: mediaWord,
                ),
              ],
              if (hasGradient && gradContinuous.isNotEmpty) ...[
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    for (var i = 0; i < gradContinuous.length; i++) ...[
                      if (i > 0) SizedBox(width: InspectorSkin.tileGap),
                      Expanded(child: ParameterTile(gradContinuous[i])),
                    ],
                  ],
                ),
              ],
              if (strokeP != null ||
                  strokeWidthP != null ||
                  extraStrokes.isNotEmpty ||
                  doc.actions.onAddStroke != null) ...[
                SizedBox(height: Shape.s(6)),
                if (strokeP != null && strokeWidthP != null)
                  _StrokeLine(
                    doc: doc,
                    colorId: 'v_stroke',
                    widthId: 'v_stroke_width',
                    widthParam: strokeWidthP,
                    alignId: strokeAlignP == null ? null : 'v_stroke_align',
                    alignParam: strokeAlignP,
                    label: 'Stroke',
                    details: const [],
                    reserveAlignSlot: hasAlignControl,
                    reserveDetailsSlot: hasExtraDetails,
                    reserveRemoveSlot: hasRemovable,
                    onRemove: null,
                  ),
                for (final sc in extraStrokes)
                  _ExtraStrokeLine(
                    sc,
                    doc: doc,
                    reserveAlignSlot: hasAlignControl,
                    reserveDetailsSlot: hasExtraDetails,
                    reserveRemoveSlot: hasRemovable,
                  ),
                if (doc.actions.onAddStroke case final add?)
                  _AddStrokeButton(onTap: add),
              ],
            ],
          ),
        );
      },
    );
  }

  static int _alignOf(Parameter? alignP, InspectorValues doc) {
    if (alignP == null || alignP.options.isEmpty) return 0;
    final idx = (doc.get('v_${alignP.id}') ?? alignP.def).round();
    final word = alignP.options.elementAtOrNull(idx)?.toLowerCase();
    return switch (word) {
      'inside' => -1,
      'outside' => 1,
      _ => 0,
    };
  }

  static FillPreviewStroke? _extraStrokeOf(
    CardDeclaration sc,
    InspectorValues doc,
  ) {
    Parameter? colorP, widthP, alignP;
    for (final p in sc.params) {
      if (p.id.endsWith(':stroke')) colorP = p;
      if (p.id.endsWith(':stroke_width')) widthP = p;
      if (p.id.endsWith(':stroke_align')) alignP = p;
    }
    if (widthP == null) return null;
    final parsed = colorP == null
        ? const <Color>[]
        : parseFillColors(doc.strings['v_${colorP.id}']);
    return (
      colors: parsed.isNotEmpty ? parsed : [Grey.g91],
      width: doc.get('v_${widthP.id}') ?? widthP.def,
      align: _alignOf(alignP, doc),
    );
  }
}

List<String> _rampHexOf(String raw) => [
  for (final tok in raw.trim().split(RegExp(r'\s+')))
    if (tok.isNotEmpty)
      if (hexControls(
            tok.startsWith('#')
                ? tok.split('@').first
                : '#${tok.split('@').first}',
          ) !=
          null)
        tok.startsWith('#') ? tok.split('@').first : '#${tok.split('@').first}',
];

/// Compact 32px row for the Fill color/ramp and optional Media link.
class _FillRow extends StatelessWidget {
  const _FillRow({
    required this.doc,
    required this.colors,
    required this.fillRaw,
    required this.hasMediaParam,
    required this.mediaRaw,
  });

  final InspectorValues doc;
  final List<Color> colors;
  final String fillRaw;
  final bool hasMediaParam;
  final String mediaRaw;

  void _route(String id, LinkTo to) {
    doc.strings['route.at'] = id;
    doc.str('route', to.route);
  }

  @override
  Widget build(BuildContext context) {
    final rampHex = _rampHexOf(fillRaw);
    final summary = colors.length > 1
        ? '${colors.length} colors'
        : (rampHex.isNotEmpty ? rampHex.first.toUpperCase() : '—');
    return Row(
      children: [
        Expanded(
          child: Pressable(
            key: const ValueKey('link:colors:v_fill'),
            onTap: () => _route('v_fill', LinkTo.colors),
            builder: (_, hot) => Container(
              height: Shape.z(32),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
              decoration: BoxDecoration(
                color: hot ? Grey.g15 : Grey.g10,
                borderRadius: Shape.round(6),
              ),
              child: Row(
                children: [
                  Swatch(
                    rampHex.isNotEmpty ? rampHex.first : null,
                    ramp: rampHex.length > 1 ? rampHex : null,
                  ),
                  SizedBox(width: Shape.s(8)),
                  Text('Fill', style: TextStyles.label(Grey.g56)),
                  SizedBox(width: Shape.s(8)),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.value(hot ? Grey.g95 : Grey.g91),
                    ),
                  ),
                  Text(
                    'Colors ↗',
                    style: TextStyles.micro(hot ? Grey.g91 : Grey.g44),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasMediaParam) ...[
          SizedBox(width: InspectorSkin.tileGap),
          Pressable(
            key: const ValueKey('link:media:v_fill_media'),
            onTap: () => _route('v_fill_media', LinkTo.media),
            builder: (_, hot) => Container(
              height: Shape.z(32),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
              decoration: BoxDecoration(
                color: hot ? Grey.g15 : Grey.g10,
                borderRadius: Shape.round(6),
              ),
              alignment: Alignment.center,
              child: Text(
                mediaRaw.isEmpty ? 'Media' : mediaRaw.split('/').last,
                style: TextStyles.micro(
                  mediaRaw.isEmpty
                      ? (hot ? Grey.g76 : Grey.g44)
                      : (hot ? Grey.g95 : Grey.g91),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Wrapper that maps an absorbed `Stroke` CardDeclaration onto [_StrokeLine].
class _ExtraStrokeLine extends StatelessWidget {
  const _ExtraStrokeLine(
    this.card, {
    required this.doc,
    required this.reserveAlignSlot,
    required this.reserveDetailsSlot,
    required this.reserveRemoveSlot,
  });
  final CardDeclaration card;
  final InspectorValues doc;
  final bool reserveAlignSlot;
  final bool reserveDetailsSlot;
  final bool reserveRemoveSlot;

  @override
  Widget build(BuildContext context) {
    Parameter? colorP, widthP, alignP;
    final details = <Parameter>[];
    for (final p in card.params) {
      if (p.id.endsWith(':stroke')) {
        colorP = p;
      } else if (p.id.endsWith(':stroke_width')) {
        widthP = p;
      } else if (p.id.endsWith(':stroke_align')) {
        alignP = p;
      } else {
        details.add(p);
      }
    }
    if (colorP == null || widthP == null) {
      return ParameterGrid(card.params);
    }
    final remove = doc.actions.onCardRemove;
    return _StrokeLine(
      doc: doc,
      colorId: 'v_${colorP.id}',
      widthId: 'v_${widthP.id}',
      widthParam: widthP,
      alignId: alignP == null ? null : 'v_${alignP.id}',
      alignParam: alignP,
      label: 'Stroke',
      details: details,
      reserveAlignSlot: reserveAlignSlot,
      reserveDetailsSlot: reserveDetailsSlot,
      reserveRemoveSlot: reserveRemoveSlot,
      onRemove: remove == null
          ? null
          : () => remove(card.name, [for (final p in card.params) p.id]),
    );
  }
}

/// Slim 32px stroke row matching PathsStackItem's density: color/gradient
/// swatch + summary + compact width field + inline align toggle (center /
/// inside / outside) + optional expandable detail grid + thin vector ×.
class _StrokeLine extends StatefulWidget {
  const _StrokeLine({
    required this.doc,
    required this.colorId,
    required this.widthId,
    required this.widthParam,
    required this.alignId,
    required this.alignParam,
    required this.label,
    required this.details,
    required this.reserveAlignSlot,
    required this.reserveDetailsSlot,
    required this.reserveRemoveSlot,
    required this.onRemove,
  });

  final InspectorValues doc;
  final String colorId;
  final String widthId;
  final Parameter widthParam;
  final String? alignId;
  final Parameter? alignParam;
  final String label;
  final List<Parameter> details;
  final bool reserveAlignSlot;
  final bool reserveDetailsSlot;
  final bool reserveRemoveSlot;
  final VoidCallback? onRemove;

  @override
  State<_StrokeLine> createState() => _StrokeLineState();
}

class _StrokeLineState extends State<_StrokeLine> {
  bool _open = false;

  void _openColor() {
    widget.doc.strings['route.at'] = widget.colorId;
    widget.doc.str('route', LinkTo.colors.route);
  }

  void _cycleAlign(int currentIdx, int count) {
    final id = widget.alignId;
    if (id == null || count < 2) return;
    final next = (currentIdx + 1) % count;
    widget.doc
      ..beginGesture()
      ..set(id, next.toDouble())
      ..endGesture();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.doc.strings[widget.colorId] ?? '';
    final rampHex = _rampHexOf(raw);
    final summary = rampHex.length > 1
        ? '${rampHex.length} colors'
        : (rampHex.isNotEmpty ? rampHex.first.toUpperCase() : '—');

    final alignP = widget.alignParam;
    final alignOpts = alignP?.options ?? const <String>[];
    final alignIdx = alignP != null && alignOpts.isNotEmpty
        ? (widget.doc.get(widget.alignId!) ?? alignP.def).round().clamp(
            0,
            alignOpts.length - 1,
          )
        : 0;
    final alignWord = alignOpts.elementAtOrNull(alignIdx)?.toLowerCase() ?? '';
    final alignCode = switch (alignWord) {
      'inside' => -1,
      'outside' => 1,
      _ => 0,
    };
    final alignTip = switch (alignCode) {
      -1 => 'Stroke align: Inside',
      1 => 'Stroke align: Outside',
      _ => 'Stroke align: Center (both)',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: Shape.z(32),
          margin: EdgeInsets.only(bottom: Shape.s(2)),
          padding: EdgeInsets.only(left: Shape.s(8), right: Shape.s(4)),
          decoration: BoxDecoration(
            color: Grey.g10,
            borderRadius: Shape.round(6),
          ),
          child: Row(
            children: [
              Pressable(
                key: ValueKey('link:colors:${widget.colorId}'),
                onTap: _openColor,
                builder: (_, hot) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Swatch(
                      rampHex.isNotEmpty ? rampHex.first : null,
                      ramp: rampHex.length > 1 ? rampHex : null,
                    ),
                    SizedBox(width: Shape.s(6)),
                    SizedBox(
                      width: Shape.z(60),
                      child: Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.value(hot ? Grey.g95 : Grey.g76),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Shape.s(4)),
              Expanded(
                child: RowInfo(
                  keys: widget.doc.keys[widget.widthId] ?? KeyframeState.off,
                  child: InspectorNumberField(
                    widget.widthParam,
                    key: ValueKey('fill:${widget.widthId}'),
                    id: widget.widthId,
                    caption: widget.label,
                    compact: true,
                  ),
                ),
              ),
              if (alignP != null && alignOpts.length >= 2)
                _maybeTip(
                  context,
                  alignTip,
                  Pressable(
                    key: ValueKey('stroke-align:${widget.alignId}'),
                    onTap: () => _cycleAlign(alignIdx, alignOpts.length),
                    builder: (_, hot) => SizedBox(
                      width: Shape.z(24),
                      height: Shape.z(24),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(14, 14),
                          painter: Draw(
                            (c, s) => _drawStrokeAlignGlyph(
                              c,
                              s,
                              hot
                                  ? Grey.g95
                                  : (alignCode == 0 ? Grey.g56 : Grey.g91),
                              alignCode,
                            ),
                            (hot, alignCode),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (widget.reserveAlignSlot)
                SizedBox(width: Shape.z(24)),
              if (widget.details.isNotEmpty)
                Pressable(
                  key: ValueKey('stroke-more:${widget.widthId}'),
                  onTap: () => setState(() => _open = !_open),
                  builder: (_, hot) => SizedBox(
                    width: Shape.z(22),
                    height: Shape.z(24),
                    child: Center(
                      child: Text(
                        '⋯',
                        style: TextStyles.label(
                          _open || hot ? Grey.g91 : Grey.g44,
                        ),
                      ),
                    ),
                  ),
                )
              else if (widget.reserveDetailsSlot)
                SizedBox(width: Shape.z(22)),
              if (widget.onRemove case final remove?)
                Pressable(
                  key: ValueKey('stroke-remove:${widget.widthId}'),
                  onTap: remove,
                  builder: (_, hot) => SizedBox(
                    width: Shape.z(22),
                    height: Shape.z(24),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(8, 8),
                        painter: Draw(
                          (c, s) =>
                              _drawThinCross(c, s, hot ? Grey.g91 : Grey.g44),
                          hot,
                        ),
                      ),
                    ),
                  ),
                )
              else if (widget.reserveRemoveSlot)
                SizedBox(width: Shape.z(22)),
            ],
          ),
        ),
        if (_open && widget.details.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: Shape.s(8), bottom: Shape.s(4)),
            child: ParameterGrid(widget.details),
          ),
      ],
    );
  }
}

Widget _maybeTip(BuildContext context, String text, Widget child) =>
    Overlay.maybeOf(context) != null ? Tip(text, child: child) : child;

void _drawStrokeAlignGlyph(Canvas c, Size s, Color color, int align) {
  // Reference shape body (subtle filled square) so inside / center / outside
  // read unmistakably at 14px.
  final body = Rect.fromLTWH(3.5, 3.5, s.width - 7, s.height - 7);
  final fillPaint = Paint()..color = color.withValues(alpha: 0.22);
  final refStroke = Paint()
    ..color = color.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9;
  final strokePaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  if (align > 0) {
    // Outside: bright stroke outside the shaded shape body with a clear gap.
    c
      ..drawRect(body, fillPaint)
      ..drawRect(body.inflate(2.2), strokePaint);
  } else if (align < 0) {
    // Inside: outer boundary is thin; bright stroke sits inside the body.
    c
      ..drawRect(body.inflate(1.8), refStroke)
      ..drawRect(body.deflate(0.3), strokePaint);
  } else {
    // Center (both): bright stroke straddles the boundary with a center hairline.
    final mid = body.inflate(0.8);
    c
      ..drawRect(mid, fillPaint)
      ..drawRect(
        mid,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      )
      ..drawRect(
        mid,
        Paint()
          ..color = Grey.g10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
  }
}

void _drawThinCross(Canvas c, Size s, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(1, 1), Offset(s.width - 1, s.height - 1), p)
    ..drawLine(Offset(s.width - 1, 1), Offset(1, s.height - 1), p);
}

class _AddStrokeButton extends StatelessWidget {
  const _AddStrokeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Shape.s(2)),
    child: Pressable(
      key: const ValueKey('add-stroke'),
      onTap: onTap,
      builder: (_, hot) => Container(
        height: Shape.z(28),
        decoration: BoxDecoration(
          color: hot ? Grey.g15 : null,
          borderRadius: Shape.round(6),
          border: Border.all(
            color: Grey.g20,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '+ Stroke',
          style: TextStyles.label(hot ? Grey.g76 : Grey.g44),
        ),
      ),
    ),
  );
}
