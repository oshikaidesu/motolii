// Typesetting controls grouped by scale for the Text card:
// - TextAxisBar: top-level writing direction and alignment inside the text well.
// - TextMetricsTile: 42px inline-spacing mode tile paired beside Tracking.
// - TextBoxBar: line-wrap and line-end rules (Kinsoku, Hanging punctuation).
// - TextFeaturesStrip: slim OpenType feature chip strip with custom tag input.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/well_pill.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_meta.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/number_field.dart' show blockValue;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Top-level spatial axis pills seated along the bottom of the text well:
/// writing direction (horizontal / vertical-rl) and block alignment.
class TextAxisBar extends StatelessWidget {
  const TextAxisBar({required this.doc, required this.layer, super.key});

  final InspectorValues doc;
  final Map<String, Parameter> layer;

  @override
  Widget build(BuildContext context) {
    final vertical =
        layer.containsKey('writing') &&
        (doc.get('v_writing') ?? 0).round() == 1;
    final align = doc.get('v_align') ?? 0.5;
    final alignIdx = align < 0.25 ? 0 : (align > 0.75 ? 2 : 1);
    final pills = <Widget>[
      if (layer.containsKey('writing'))
        maybeTip(
          context,
          vertical
              ? 'Vertical-rl OpenType typesetting (vert/vrt2)'
              : 'Horizontal typesetting — click for vertical-rl',
          WellPill(
            key: const ValueKey('text:writing'),
            label: vertical ? 'Vert' : 'Horiz',
            active: vertical,
            icon: (c, s, col) => _writingIcon(c, s, col, vertical),
            onTap: () => doc.set('v_writing', vertical ? 0 : 1),
          ),
        ),
      if (layer.containsKey('align'))
        maybeTip(
          context,
          vertical
              ? const ['Align top', 'Align middle', 'Align bottom'][alignIdx]
              : const ['Align left', 'Align center', 'Align right'][alignIdx],
          WellPill(
            key: const ValueKey('text:align'),
            label: vertical
                ? const ['Top', 'Mid', 'Bot'][alignIdx]
                : const ['Left', 'Center', 'Right'][alignIdx],
            icon: (c, s, col) => _alignIcon(c, s, col, alignIdx, vertical),
            onTap: () => doc.set('v_align', const [0.5, 1.0, 0.0][alignIdx]),
          ),
        ),
    ];
    if (pills.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(6)),
      child: Row(
        children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) SizedBox(width: Shape.s(4)),
            pills[i],
          ],
        ],
      ),
    );
  }
}

/// 42px tile for character-spacing metrics (`Fixed` / `palt` / `halt`), sized to
/// sit directly beside the Tracking and Line Height tiles.
class TextMetricsTile extends StatelessWidget {
  const TextMetricsTile({required this.doc, super.key});

  final InspectorValues doc;

  @override
  Widget build(BuildContext context) {
    final metrics = (doc.get('v_metrics') ?? 0).round().clamp(0, 2);
    final active = metrics != 0;
    return maybeTip(
      context,
      const [
        'Fixed width (Japanese monospace / 等幅)',
        'Proportional metrics (palt + kern / 文字詰め)',
        'Half-width punctuation (halt / 約物半角)',
      ][metrics],
      Pressable(
        key: const ValueKey('text:metrics'),
        onTap: () => doc.set('v_metrics', ((metrics + 1) % 3).toDouble()),
        builder: (_, hot) {
          final ink = active ? Accent.fill : (hot ? Grey.g95 : Grey.g91);
          final glyph = active ? Accent.fill : (hot ? Grey.g95 : Grey.g63);
          return Container(
            height: InspectorSkin.tile,
            padding: EdgeInsets.fromLTRB(
              InspectorSkin.tilePad,
              Shape.s(4),
              InspectorSkin.tilePad,
              Shape.s(4),
            ),
            decoration: BoxDecoration(
              color: hot ? Grey.g20 : InspectorSkin.well,
              borderRadius: Shape.round(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metrics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.micro(Grey.g63).copyWith(height: 1.1),
                ),
                Row(
                  children: [
                    CustomPaint(
                      size: const Size(11, 11),
                      painter: Draw(
                        (c, s) => _metricsIcon(c, s, glyph, metrics),
                        (hot, metrics),
                      ),
                    ),
                    SizedBox(width: Shape.s(5)),
                    Expanded(
                      child: Text(
                        const ['Fixed', 'palt', 'halt'][metrics],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: blockValue(ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Slim 1-row bar grouping box-edge rules: line wrapping, kinsoku line-breaking,
/// and hanging punctuation.
class TextBoxBar extends StatelessWidget {
  const TextBoxBar({required this.doc, required this.layer, super.key});

  final InspectorValues doc;
  final Map<String, Parameter> layer;

  static const _wrapCycle = [0, 2, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    final hasWrap = layer.containsKey('wrap');
    final hasKinsoku = layer.containsKey('kinsoku');
    final hasHanging = layer.containsKey('hanging');
    if (!hasWrap && !hasKinsoku && !hasHanging) {
      return const SizedBox.shrink();
    }
    final wrap = (doc.get('v_wrap') ?? 0).round().clamp(0, 5);
    final kinsoku = (doc.get('v_kinsoku') ?? 0).round().clamp(0, 3);
    final hanging = (doc.get('v_hanging') ?? 0) > 0.5;
    final hasEdge = hasKinsoku || hasHanging;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(6),
        vertical: Shape.s(5),
      ),
      decoration: BoxDecoration(
        color: InspectorSkin.well,
        borderRadius: Shape.round(6),
      ),
      child: Wrap(
        spacing: Shape.s(4),
        runSpacing: Shape.s(4),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasWrap)
            maybeTip(
              context,
              wrap == 0
                  ? 'No line wrap — click to wrap'
                  : 'Wrap mode: ${const ['None', 'Character', 'Word', 'Smart', 'Ellipsis', 'Vertical'][wrap]}',
              WellPill(
                key: const ValueKey('text:wrap'),
                label: const [
                  'Wrap',
                  'Char',
                  'Word',
                  'Smart',
                  'Clip',
                  'Col',
                ][wrap],
                active: wrap != 0,
                icon: (c, s, col) => _wrapIcon(c, s, col, wrap != 0),
                onTap: () {
                  final at = _wrapCycle.indexOf(wrap);
                  final next = _wrapCycle[(at + 1) % _wrapCycle.length];
                  doc.set('v_wrap', next.toDouble());
                },
              ),
            ),
          if (hasWrap && hasEdge)
            Container(
              width: 1,
              height: Shape.z(14),
              margin: EdgeInsets.symmetric(horizontal: Shape.s(2)),
              color: Grey.g26,
            ),
          if (hasKinsoku)
            maybeTip(
              context,
              const [
                'Kinsoku: Normal (標準禁則)',
                'Kinsoku: Strict (強い禁則)',
                'Kinsoku: Loose (緩い禁則)',
                'Kinsoku: None (禁則なし)',
              ][kinsoku],
              WellPill(
                key: const ValueKey('text:kinsoku'),
                label: const ['Auto', 'Strict', 'Loose', 'Off'][kinsoku],
                active: kinsoku == 1 || kinsoku == 2,
                icon: (c, s, col) => _kinsokuIcon(c, s, col, kinsoku),
                onTap: () =>
                    doc.set('v_kinsoku', ((kinsoku + 1) % 4).toDouble()),
              ),
            ),
          if (hasHanging)
            maybeTip(
              context,
              hanging
                  ? 'Hanging punctuation ON (ぶら下がり組版: 、。，．)'
                  : 'Hanging punctuation OFF — click to hang 、。，．',
              WellPill(
                key: const ValueKey('text:hanging'),
                label: 'Hang',
                active: hanging,
                icon: _hangingIcon,
                onTap: () => doc.set('v_hanging', hanging ? 0 : 1),
              ),
            ),
        ],
      ),
    );
  }
}

/// Slim chip strip for OpenType features (`v_font_features`): shows quick toggles
/// for features actually present in the font, preserves arbitrary user tokens,
/// and lets users add any raw OpenType tag via `+`.
class TextFeaturesStrip extends StatefulWidget {
  const TextFeaturesStrip({
    required this.doc,
    required this.supported,
    super.key,
  });

  final InspectorValues doc;
  final Set<String> supported;

  @override
  State<TextFeaturesStrip> createState() => _TextFeaturesStripState();
}

class _TextFeaturesStripState extends State<TextFeaturesStrip> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.doc.strings['v_font_features'] ?? '';
    final activeTokens = parseFeatureTokens(raw);
    final activeByTag = {for (final t in activeTokens) featureTagOf(t): t};
    final quick = [
      for (final tag in otFeatureDescriptions.keys)
        if (widget.supported.contains(tag)) tag,
    ];
    final custom = [
      for (final t in activeTokens)
        if (!quick.contains(featureTagOf(t))) t,
    ];
    if (quick.isEmpty && custom.isEmpty && !_adding) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: InspectorSkin.tileGap),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(7),
          vertical: Shape.s(5),
        ),
        decoration: BoxDecoration(
          color: InspectorSkin.well,
          borderRadius: Shape.round(6),
        ),
        child: Wrap(
          spacing: Shape.s(4),
          runSpacing: Shape.s(4),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('OT', style: TextStyles.micro(Grey.g56)),
            for (final tag in quick)
              _FeatureChip(
                key: ValueKey('text:ot:$tag'),
                label: activeByTag[tag] ?? tag,
                tip: otFeatureDescriptions[tag] ?? tag,
                active: activeByTag.containsKey(tag),
                onTap: () => widget.doc.str(
                  'v_font_features',
                  toggleFeatureToken(raw, tag),
                ),
              ),
            for (final tok in custom)
              _FeatureChip(
                key: ValueKey('text:ot:${featureTagOf(tok)}'),
                label: tok,
                tip: 'Remove $tok',
                active: true,
                onTap: () => widget.doc.str(
                  'v_font_features',
                  toggleFeatureToken(raw, featureTagOf(tok)),
                ),
              ),
            if (_adding)
              SizedBox(
                width: Shape.z(64),
                height: Shape.z(18),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
                  decoration: BoxDecoration(
                    color: Grey.g07,
                    borderRadius: Shape.round(4),
                    border: Border.all(
                      color: Accent.fill.withValues(alpha: 0.6),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TypedField(
                    key: const ValueKey('text:ot:input'),
                    text: '',
                    standing: true,
                    style: TextStyles.micro(Grey.g95),
                    cursor: Grey.g95,
                    backgroundCursor: Grey.g20,
                    selection: Role.selected.withValues(alpha: 0.4),
                    onDone: (said) {
                      if (said != null && said.trim().isNotEmpty) {
                        widget.doc.str(
                          'v_font_features',
                          addFeatureToken(raw, said),
                        );
                      }
                      if (mounted) setState(() => _adding = false);
                    },
                  ),
                ),
              )
            else
              maybeTip(
                context,
                'Add any OpenType tag (e.g. ss05, -kern, cv01=2)',
                Pressable(
                  key: const ValueKey('text:ot:add'),
                  onTap: () => setState(() => _adding = true),
                  builder: (_, hot) => Container(
                    height: Shape.z(18),
                    padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
                    decoration: BoxDecoration(
                      color: hot ? Grey.g20 : Grey.g13,
                      borderRadius: Shape.round(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: TextStyles.micro(hot ? Grey.g95 : Grey.g63),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.tip,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final String tip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => maybeTip(
    context,
    tip,
    Pressable(
      onTap: onTap,
      builder: (_, hot) {
        final ink = active ? Accent.fill : (hot ? Grey.g95 : Grey.g76);
        final bg = active
            ? Color.alphaBlend(
                Accent.fill.withValues(alpha: hot ? 0.22 : 0.14),
                Grey.g10,
              )
            : (hot ? Grey.g20 : Grey.g13);
        final border = active
            ? Accent.fill.withValues(alpha: 0.55)
            : Grey.g26.withValues(alpha: hot ? 0.8 : 0.4);
        return Container(
          height: Shape.z(18),
          padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Shape.round(4),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(label, style: TextStyles.micro(ink))],
          ),
        );
      },
    ),
  );
}

void _alignIcon(Canvas c, Size s, Color col, int idx, bool vertical) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  if (!vertical) {
    final lens = [s.width * 0.85, s.width * 0.55, s.width * 0.72];
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.2 + i * 0.3);
      final w = lens[i];
      final x = idx == 0
          ? 0.8
          : (idx == 1 ? (s.width - w) / 2 : s.width - 0.8 - w);
      c.drawLine(Offset(x, y), Offset(x + w, y), p);
    }
  } else {
    final lens = [s.height * 0.85, s.height * 0.55, s.height * 0.72];
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.8 - i * 0.3);
      final h = lens[i];
      final y = idx == 0
          ? 0.8
          : (idx == 1 ? (s.height - h) / 2 : s.height - 0.8 - h);
      c.drawLine(Offset(x, y), Offset(x, y + h), p);
    }
  }
}

void _writingIcon(Canvas c, Size s, Color col, bool vertical) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  if (!vertical) {
    c
      ..drawLine(
        Offset(1, s.height * 0.35),
        Offset(s.width - 1.5, s.height * 0.35),
        p,
      )
      ..drawLine(
        Offset(1, s.height * 0.7),
        Offset(s.width * 0.65, s.height * 0.7),
        p,
      )
      ..drawLine(
        Offset(s.width - 3.2, s.height * 0.15),
        Offset(s.width - 1.2, s.height * 0.35),
        p,
      )
      ..drawLine(
        Offset(s.width - 3.2, s.height * 0.55),
        Offset(s.width - 1.2, s.height * 0.35),
        p,
      );
  } else {
    c
      ..drawLine(
        Offset(s.width * 0.68, 1),
        Offset(s.width * 0.68, s.height - 1.5),
        p,
      )
      ..drawLine(
        Offset(s.width * 0.28, 1),
        Offset(s.width * 0.28, s.height * 0.65),
        p,
      )
      ..drawLine(
        Offset(s.width * 0.48, s.height - 3.2),
        Offset(s.width * 0.68, s.height - 1.2),
        p,
      )
      ..drawLine(
        Offset(s.width * 0.88, s.height - 3.2),
        Offset(s.width * 0.68, s.height - 1.2),
        p,
      );
  }
}

void _metricsIcon(Canvas c, Size s, Color col, int mode) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.15
    ..style = PaintingStyle.stroke;
  if (mode == 0) {
    c
      ..drawRect(Rect.fromLTWH(0.8, 2, 3.8, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(6.0, 2, 3.8, s.height - 4), p);
  } else if (mode == 1) {
    c
      ..drawRect(Rect.fromLTWH(1.5, 2, 3.6, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(5.6, 2, 2.3, s.height - 4), p);
  } else {
    c
      ..drawRect(Rect.fromLTWH(0.8, 2, 4.6, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(6.4, 2, 2.4, s.height - 4), p);
  }
}

void _kinsokuIcon(Canvas c, Size s, Color col, int mode) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  c.drawLine(
    Offset(s.width - 1.5, 1),
    Offset(s.width - 1.5, s.height - 1),
    Paint()
      ..color = col.withValues(alpha: mode == 3 ? 0.35 : 0.75)
      ..strokeWidth = 1.0,
  );
  final end = mode == 3 ? s.width - 0.5 : s.width - 3.2;
  c
    ..drawLine(Offset(1, s.height * 0.3), Offset(end, s.height * 0.3), p)
    ..drawLine(
      Offset(1, s.height * 0.7),
      Offset(s.width * 0.55, s.height * 0.7),
      p,
    );
}

void _hangingIcon(Canvas c, Size s, Color col) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(
      Offset(s.width - 3.2, 1),
      Offset(s.width - 3.2, s.height - 1),
      Paint()
        ..color = col.withValues(alpha: 0.65)
        ..strokeWidth = 1.0,
    )
    ..drawLine(
      Offset(1, s.height * 0.32),
      Offset(s.width - 4.4, s.height * 0.32),
      p,
    )
    ..drawLine(
      Offset(1, s.height * 0.7),
      Offset(s.width - 4.4, s.height * 0.7),
      p,
    )
    ..drawCircle(
      Offset(s.width - 1.3, s.height * 0.35),
      1.1,
      Paint()..color = col,
    );
}

void _wrapIcon(Canvas c, Size s, Color col, bool on) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  c.drawLine(
    Offset(1, s.height * 0.25),
    Offset(s.width - 1.5, s.height * 0.25),
    p,
  );
  if (on) {
    final path = Path()
      ..moveTo(s.width - 1.5, s.height * 0.25)
      ..quadraticBezierTo(
        s.width - 1.5,
        s.height * 0.72,
        s.width * 0.55,
        s.height * 0.72,
      )
      ..lineTo(2.2, s.height * 0.72);
    c
      ..drawPath(path, p)
      ..drawLine(Offset(3.8, s.height * 0.54), Offset(1.8, s.height * 0.72), p)
      ..drawLine(Offset(3.8, s.height * 0.90), Offset(1.8, s.height * 0.72), p);
  } else {
    c.drawLine(
      Offset(1, s.height * 0.7),
      Offset(s.width - 1.5, s.height * 0.7),
      p,
    );
  }
}
