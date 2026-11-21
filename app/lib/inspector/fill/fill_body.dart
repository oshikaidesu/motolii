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
      for (final sc in extraStrokes)
        for (final p in sc.params)
          if (p.id.endsWith(':stroke_width')) doc.watch('v_${p.id}'),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final fillWord = doc.strings['v_fill'] ?? '';
        final mediaWord = doc.strings['v_fill_media'] ?? '';
        final colors = parseFillColors(fillWord);
        final gradVal = (doc.get('v_gradient') ?? 0).round();
        final gradWord = gradP?.options.elementAtOrNull(gradVal)?.toLowerCase();
        final hasGradient = gradVal > 0 || colors.length > 1;
        final isRadial = gradWord == 'radial';

        final previewStrokes = <FillPreviewStroke>[
          if (strokeWidthP != null)
            (
              color:
                  parseFillColors(doc.strings['v_stroke']).firstOrNull ??
                  Grey.g91,
              width: doc.get('v_stroke_width') ?? strokeWidthP.def,
            ),
          for (final sc in extraStrokes) ?_extraStrokeOf(sc, doc),
        ];

        final spreadVal = (doc.get('v_gradient_spread') ?? 0).round();

        final hasExtraDetails = extraStrokes.any((sc) => sc.params.length > 2);
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
                    label: 'Stroke',
                    details: const [],
                    reserveDetailsSlot: hasExtraDetails,
                    reserveRemoveSlot: hasRemovable,
                    onRemove: null,
                  ),
                for (final sc in extraStrokes)
                  _ExtraStrokeLine(
                    sc,
                    doc: doc,
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

  static FillPreviewStroke? _extraStrokeOf(
    CardDeclaration sc,
    InspectorValues doc,
  ) {
    Parameter? colorP, widthP;
    for (final p in sc.params) {
      if (p.id.endsWith(':stroke')) colorP = p;
      if (p.id.endsWith(':stroke_width')) widthP = p;
    }
    if (widthP == null) return null;
    final hex = colorP == null ? null : doc.strings['v_${colorP.id}'];
    return (
      color: parseFillColors(hex).firstOrNull ?? Grey.g91,
      width: doc.get('v_${widthP.id}') ?? widthP.def,
    );
  }
}

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
    final rampHex = [
      for (final tok in fillRaw.trim().split(RegExp(r'\s+')))
        if (hexControls(
              tok.startsWith('#')
                  ? tok.split('@').first
                  : '#${tok.split('@').first}',
            ) !=
            null)
          tok.startsWith('#')
              ? tok.split('@').first
              : '#${tok.split('@').first}',
    ];
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
    required this.reserveDetailsSlot,
    required this.reserveRemoveSlot,
  });
  final CardDeclaration card;
  final InspectorValues doc;
  final bool reserveDetailsSlot;
  final bool reserveRemoveSlot;

  @override
  Widget build(BuildContext context) {
    Parameter? colorP, widthP;
    final details = <Parameter>[];
    for (final p in card.params) {
      if (p.id.endsWith(':stroke')) {
        colorP = p;
      } else if (p.id.endsWith(':stroke_width')) {
        widthP = p;
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
      label: 'Stroke',
      details: details,
      reserveDetailsSlot: reserveDetailsSlot,
      reserveRemoveSlot: reserveRemoveSlot,
      onRemove: remove == null
          ? null
          : () => remove(card.name, [for (final p in card.params) p.id]),
    );
  }
}

/// Slim 32px stroke row matching PathsStackItem's density: swatch + hex +
/// compact width field + optional expandable detail grid + thin vector ×.
class _StrokeLine extends StatefulWidget {
  const _StrokeLine({
    required this.doc,
    required this.colorId,
    required this.widthId,
    required this.widthParam,
    required this.label,
    required this.details,
    required this.reserveDetailsSlot,
    required this.reserveRemoveSlot,
    required this.onRemove,
  });

  final InspectorValues doc;
  final String colorId;
  final String widthId;
  final Parameter widthParam;
  final String label;
  final List<Parameter> details;
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

  @override
  Widget build(BuildContext context) {
    final raw = widget.doc.strings[widget.colorId];
    final hex = raw == null || raw.isEmpty
        ? null
        : (raw.startsWith('#') ? raw : '#$raw');
    final hexText = hex != null && hexControls(hex) != null
        ? hex.toUpperCase()
        : '—';

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
                    Swatch(hex),
                    SizedBox(width: Shape.s(6)),
                    SizedBox(
                      width: Shape.z(64),
                      child: Text(
                        hexText,
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
