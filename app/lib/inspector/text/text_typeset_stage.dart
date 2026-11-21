// Interactive live typesetting instrument for the Text card:
// visually demonstrates Japanese/OpenType typesetting rules (em-box metrics,
// tracking, line height, slant, baseline, alignment, writing direction,
// wrap margin, kinsoku, and hanging punctuation) with pure vector geometry
// and direct drag manipulation.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/well_pill.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// Shared hover/drag highlight channel between [TextTypesetStage] and the
/// compact numeric rows beneath it (values: 'tracking', 'line', 'slant',
/// 'baseline', 'wrap', 'metrics', 'align', 'writing', 'kinsoku', 'hanging').
final textHot = ValueNotifier<String?>(null);

enum _DragKind { none, tracking, line, wrap }

/// Live visual typesetting canvas with direct drag for Tracking, Line Height,
/// and Wrap margin, plus in-well discrete mode pills along the bottom.
class TextTypesetStage extends StatefulWidget {
  const TextTypesetStage({required this.doc, required this.layer, super.key});

  final InspectorValues doc;
  final Map<String, Parameter> layer;

  @override
  State<TextTypesetStage> createState() => _TextTypesetStageState();
}

class _TextTypesetStageState extends State<TextTypesetStage> {
  static const _wrapCycle = [0, 2, 1, 3, 4];

  _DragKind _drag = _DragKind.none;
  Offset _start = Offset.zero;
  double _startVal = 0;

  bool get _vertical =>
      widget.layer.containsKey('writing') &&
      (widget.doc.get('v_writing') ?? 0).round() == 1;

  double _marginPos(Size s) {
    final wrapOn = (widget.doc.get('v_wrap') ?? 0).round() != 0;
    final wrapAt = (widget.doc.get('v_wrap_at') ?? 12.0).clamp(4.0, 40.0);
    final t = wrapOn ? ((wrapAt - 4.0) / 36.0).clamp(0.0, 1.0) : 0.78;
    if (!_vertical) {
      return s.width * (0.46 + t * 0.40);
    }
    return s.height * (0.52 + t * 0.34);
  }

  void _panStart(DragStartDetails d, Size s) {
    _start = d.localPosition;
    final m = _marginPos(s);
    final nearMargin = !_vertical
        ? (d.localPosition.dx - m).abs() <= 14
        : (d.localPosition.dy - m).abs() <= 14;
    if (nearMargin && widget.layer.containsKey('wrap_at')) {
      _drag = _DragKind.wrap;
      _startVal = widget.doc.get('v_wrap_at') ?? 12.0;
      widget.doc.beginGesture();
      if ((widget.doc.get('v_wrap') ?? 0).round() == 0 &&
          widget.layer.containsKey('wrap')) {
        widget.doc.set('v_wrap', 2);
      }
      textHot.value = 'wrap';
    } else {
      _drag = _DragKind.none;
    }
  }

  void _panUpdate(DragUpdateDetails d, Size s) {
    final delta = d.localPosition - _start;
    if (_drag == _DragKind.none) {
      if (delta.distance < 4) return;
      final horiz = delta.dx.abs() >= delta.dy.abs();
      final wantTracking = _vertical ? !horiz : horiz;
      if (wantTracking && widget.layer.containsKey('letter_spacing')) {
        _drag = _DragKind.tracking;
        _startVal = widget.doc.get('v_letter_spacing') ?? 0;
        widget.doc.beginGesture();
        textHot.value = 'tracking';
      } else if (!wantTracking && widget.layer.containsKey('line_spacing')) {
        _drag = _DragKind.line;
        _startVal = widget.doc.get('v_line_spacing') ?? 1.2;
        widget.doc.beginGesture();
        textHot.value = 'line';
      } else {
        return;
      }
    }
    switch (_drag) {
      case _DragKind.tracking:
        final px = _vertical ? delta.dy : delta.dx;
        final next = (_startVal + px * 2.5).clamp(-100.0, 500.0);
        widget.doc.setMany({'v_letter_spacing': next});
      case _DragKind.line:
        final px = _vertical ? -delta.dx : delta.dy;
        final next = (_startVal + px * 0.025).clamp(0.5, 3.0);
        widget.doc.setMany({'v_line_spacing': next});
      case _DragKind.wrap:
        final px = _vertical ? delta.dy : delta.dx;
        final span = _vertical ? s.height * 0.34 : s.width * 0.40;
        final next = (_startVal + (px / math.max(span, 1)) * 36.0).clamp(
          4.0,
          40.0,
        );
        widget.doc.setMany({'v_wrap_at': next});
      case _DragKind.none:
        break;
    }
  }

  void _panEnd() {
    if (_drag != _DragKind.none) {
      widget.doc.endGesture();
      _drag = _DragKind.none;
      textHot.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final layer = widget.layer;
    final vertical = _vertical;
    final align = doc.get('v_align') ?? 0.5;
    final alignIdx = align < 0.25 ? 0 : (align > 0.75 ? 2 : 1);
    final metrics = (doc.get('v_metrics') ?? 0).round().clamp(0, 2);
    final kinsoku = (doc.get('v_kinsoku') ?? 0).round().clamp(0, 3);
    final hanging = (doc.get('v_hanging') ?? 0) > 0.5;
    final wrap = (doc.get('v_wrap') ?? 0).round().clamp(0, 5);

    Widget pill(String zone, Widget child) => MouseRegion(
      onEnter: (_) => textHot.value = zone,
      onExit: (_) {
        if (textHot.value == zone) textHot.value = null;
      },
      child: child,
    );

    final pills = <Widget>[
      if (layer.containsKey('writing'))
        pill(
          'writing',
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
        ),
      if (layer.containsKey('align'))
        pill(
          'align',
          maybeTip(
            context,
            vertical
                ? const ['Align top', 'Align middle', 'Align bottom'][alignIdx]
                : const ['Align left', 'Align center', 'Align right'][alignIdx],
            WellPill(
              key: const ValueKey('text:align'),
              label: '',
              icon: (c, s, col) => _alignIcon(c, s, col, alignIdx, vertical),
              onTap: () => doc.set('v_align', const [0.5, 1.0, 0.0][alignIdx]),
            ),
          ),
        ),
      if (layer.containsKey('metrics'))
        pill(
          'metrics',
          maybeTip(
            context,
            const [
              'Fixed width (Japanese monospace / 等幅)',
              'Proportional metrics (palt + kern / 文字詰め)',
              'Half-width punctuation (halt / 約物半角)',
            ][metrics],
            WellPill(
              key: const ValueKey('text:metrics'),
              label: const ['Fixed', 'palt', 'halt'][metrics],
              active: metrics != 0,
              icon: (c, s, col) => _metricsIcon(c, s, col, metrics),
              onTap: () => doc.set('v_metrics', ((metrics + 1) % 3).toDouble()),
            ),
          ),
        ),
      if (layer.containsKey('wrap'))
        pill(
          'wrap',
          maybeTip(
            context,
            wrap == 0
                ? 'No line wrap — click or drag margin line'
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
        ),
      if (layer.containsKey('kinsoku'))
        pill(
          'kinsoku',
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
              onTap: () => doc.set('v_kinsoku', ((kinsoku + 1) % 4).toDouble()),
            ),
          ),
        ),
      if (layer.containsKey('hanging'))
        pill(
          'hanging',
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
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: InspectorSkin.well,
        borderRadius: Shape.round(6),
        border: Border.all(color: Grey.g20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: Shape.z(84),
            child: LayoutBuilder(
              builder: (_, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                return GestureDetector(
                  key: const ValueKey('text:stage'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _panStart(d, size),
                  onPanUpdate: (d) => _panUpdate(d, size),
                  onPanEnd: (_) => _panEnd(),
                  onPanCancel: _panEnd,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      textHot,
                      doc.watch('v_letter_spacing'),
                      doc.watch('v_line_spacing'),
                      doc.watch('v_italic'),
                      doc.watch('v_wrap_at'),
                    ]),
                    builder: (_, _) => CustomPaint(
                      size: size,
                      painter: _TypesetPainter(
                        vertical: vertical,
                        align: align,
                        metrics: metrics,
                        kinsoku: kinsoku,
                        hanging: hanging,
                        wrapOn: wrap != 0,
                        wrapAt: (doc.get('v_wrap_at') ?? 12.0).clamp(4.0, 40.0),
                        tracking: (doc.get('v_letter_spacing') ?? 0).clamp(
                          -100.0,
                          500.0,
                        ),
                        lineHeight: (doc.get('v_line_spacing') ?? 1.2).clamp(
                          0.5,
                          3.0,
                        ),
                        slant: (doc.get('v_italic') ?? 0).clamp(-30.0, 30.0),
                        hot: textHot.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (pills.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Shape.s(6),
                0,
                Shape.s(6),
                Shape.s(6),
              ),
              child: Wrap(
                spacing: Shape.s(4),
                runSpacing: Shape.s(4),
                children: pills,
              ),
            ),
        ],
      ),
    );
  }
}

enum _GlyphKind { kanji, kana, comma, period }

class _TypesetPainter extends CustomPainter {
  const _TypesetPainter({
    required this.vertical,
    required this.align,
    required this.metrics,
    required this.kinsoku,
    required this.hanging,
    required this.wrapOn,
    required this.wrapAt,
    required this.tracking,
    required this.lineHeight,
    required this.slant,
    required this.hot,
  });

  final bool vertical;
  final double align;
  final int metrics;
  final int kinsoku;
  final bool hanging;
  final bool wrapOn;
  final double wrapAt;
  final double tracking;
  final double lineHeight;
  final double slant;
  final String? hot;

  static const _stream1 = [
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.comma,
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.kanji,
  ];
  static const _line2 = [
    _GlyphKind.kana,
    _GlyphKind.kanji,
    _GlyphKind.kana,
    _GlyphKind.period,
  ];

  double _advance(_GlyphKind k, double em) {
    if (metrics == 0) return em;
    if (metrics == 1) {
      return switch (k) {
        _GlyphKind.kanji => em * 0.96,
        _GlyphKind.kana => em * 0.78,
        _GlyphKind.comma || _GlyphKind.period => em * 0.52,
      };
    }
    return switch (k) {
      _GlyphKind.comma || _GlyphKind.period => em * 0.52,
      _ => em,
    };
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.clipRect(Offset.zero & s);
    if (!vertical) {
      _paintHorizontal(c, s);
    } else {
      _paintVertical(c, s);
    }
    c.restore();
  }

  void _paintHorizontal(Canvas c, Size s) {
    const em = 16.0;
    final trackPx = (tracking / 1000.0) * em * 1.4;
    final step = (em + trackPx).clamp(8.0, 28.0);
    final gapExtra = step - em;
    final lead = (em * lineHeight).clamp(15.0, 34.0);

    final marginT = wrapOn ? ((wrapAt - 4.0) / 36.0).clamp(0.0, 1.0) : 0.78;
    final leftRail = 16.0;
    final rightRail = s.width * (0.46 + marginT * 0.40);
    final measure = math.max(60.0, rightRail - leftRail);

    // Subtle start rail (align visual anchor) and wrap margin rail.
    final alignHot = hot == 'align';
    final wrapHot = hot == 'wrap' || hot == 'kinsoku' || hot == 'hanging';
    final alignX = leftRail + align * measure;

    if (alignHot) {
      c.drawLine(
        Offset(alignX, 8),
        Offset(alignX, s.height - 8),
        Paint()
          ..color = Accent.fill.withValues(alpha: 0.7)
          ..strokeWidth = 1.2,
      );
    }

    // Draw right margin rail (solid when Wrap is ON, dashed when OFF).
    final railCol = wrapHot
        ? Accent.fill.withValues(alpha: 0.9)
        : (wrapOn
              ? Grey.g76.withValues(alpha: 0.65)
              : Grey.g56.withValues(alpha: 0.45));
    _drawRail(
      c,
      Offset(rightRail, 8),
      Offset(rightRail, s.height - 8),
      railCol,
      dashed: !wrapOn,
    );
    // Small drag handle tick on the margin rail.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rightRail, s.height * 0.5),
          width: 3,
          height: 14,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = railCol,
    );

    // Kinsoku guard accent near the margin rail.
    if (kinsoku != 3) {
      final guardCol = hot == 'kinsoku'
          ? Accent.fill
          : (kinsoku == 1
                ? Accent.fill.withValues(alpha: 0.65)
                : Grey.g56.withValues(alpha: 0.55));
      c.drawLine(
        Offset(rightRail - 3, 10),
        Offset(rightRail - 3, 20),
        Paint()
          ..color = guardCol
          ..strokeWidth = kinsoku == 1 ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Build line 1 so it fills up to the right margin rail; the trailing period
    // sits immediately outside the rail when Hanging is ON, or inside when OFF.
    final dotAdv = _advance(_GlyphKind.period, em);
    final budget = hanging
        ? measure
        : math.max(em, measure - dotAdv - gapExtra);
    final line1Body = <_GlyphKind>[];
    var w1 = 0.0;
    for (final k in _stream1) {
      final adv = _advance(k, em);
      final add = (line1Body.isEmpty ? 0.0 : gapExtra) + adv;
      if (line1Body.isNotEmpty && w1 + add > budget) break;
      line1Body.add(k);
      w1 += add;
    }

    double lineWidth(List<_GlyphKind> line) {
      var w = 0.0;
      for (var i = 0; i < line.length; i++) {
        if (i > 0) w += gapExtra;
        w += _advance(line[i], em);
      }
      return w;
    }

    final w2 = lineWidth(_line2);
    final blockH = em + lead;
    final topY = ((s.height - blockH) * 0.5).clamp(8.0, s.height - em - 8);
    final y1 = topY;
    final y2 = topY + lead;

    // Line 1 is a full wrapped line resting against the right margin; line 2 is
    // a short final line showing Left / Center / Right alignment.
    final x1 = leftRail + math.max(0.0, budget - w1);
    final x2 = leftRail + align * math.max(0.0, measure - w2);

    // Baseline guides.
    final baseCol = hot == 'baseline'
        ? Accent.fill.withValues(alpha: 0.85)
        : Grey.g38.withValues(alpha: 0.35);
    c
      ..drawLine(
        Offset(leftRail - 4, y1 + em * 0.86),
        Offset(rightRail + (hanging ? dotAdv + 6 : 4), y1 + em * 0.86),
        Paint()
          ..color = baseCol
          ..strokeWidth = hot == 'baseline' ? 1.2 : 0.75,
      )
      ..drawLine(
        Offset(leftRail - 4, y2 + em * 0.86),
        Offset(rightRail + 4, y2 + em * 0.86),
        Paint()
          ..color = baseCol
          ..strokeWidth = 0.75,
      );

    // Line-height vertical caliper between row 1 and row 2.
    if (hot == 'line') {
      final gx = leftRail - 8;
      final p = Paint()
        ..color = Accent.fill
        ..strokeWidth = 1.2;
      c
        ..drawLine(Offset(gx, y1 + em * 0.5), Offset(gx, y2 + em * 0.5), p)
        ..drawLine(
          Offset(gx - 2.5, y1 + em * 0.5),
          Offset(gx + 2.5, y1 + em * 0.5),
          p,
        )
        ..drawLine(
          Offset(gx - 2.5, y2 + em * 0.5),
          Offset(gx + 2.5, y2 + em * 0.5),
          p,
        );
    }

    // Draw line 1 body flush to the margin rail, followed by the trailing period.
    var cx = x1;
    for (var i = 0; i < line1Body.length; i++) {
      final k = line1Body[i];
      final adv = _advance(k, em);
      _drawGlyphCell(
        c,
        Rect.fromLTWH(cx, y1, adv, em),
        k,
        highlight: hot == 'metrics' && metrics != 0 && k != _GlyphKind.kanji,
      );
      if (hot == 'tracking' && i > 0) {
        final mid = cx - gapExtra * 0.5;
        c.drawLine(
          Offset(mid, y1 + 2),
          Offset(mid, y1 + em - 2),
          Paint()
            ..color = Accent.fill.withValues(alpha: 0.75)
            ..strokeWidth = 1.0,
        );
      }
      cx += adv + gapExtra;
    }
    final dotX = hanging ? rightRail + 2.0 : cx;
    _drawGlyphCell(
      c,
      Rect.fromLTWH(dotX, y1, dotAdv, em),
      _GlyphKind.period,
      highlight: hanging || (hot == 'metrics' && metrics != 0),
    );

    // Draw line 2 (if kinsoku == none, show a leading comma violating kinsoku subtly).
    var cx2 = x2;
    final second = kinsoku == 3
        ? [_GlyphKind.comma, ..._line2.take(3)]
        : _line2;
    for (var i = 0; i < second.length; i++) {
      final k = second[i];
      final adv = _advance(k, em);
      _drawGlyphCell(
        c,
        Rect.fromLTWH(cx2, y2, adv, em),
        k,
        dim: true,
        warn: kinsoku == 3 && i == 0,
      );
      cx2 += adv + gapExtra;
    }
  }

  void _paintVertical(Canvas c, Size s) {
    const em = 13.0;
    final trackPx = (tracking / 1000.0) * em * 1.2;
    final gapExtra = ((em + trackPx).clamp(7.0, 22.0)) - em;
    final colStep = (em * lineHeight * 1.15).clamp(16.0, 34.0);

    final marginT = wrapOn ? ((wrapAt - 4.0) / 36.0).clamp(0.0, 1.0) : 0.72;
    final topRail = 10.0;
    final bottomRail = s.height * (0.56 + marginT * 0.28);
    final measure = math.max(36.0, bottomRail - topRail);

    final wrapHot = hot == 'wrap' || hot == 'kinsoku' || hot == 'hanging';
    final railCol = wrapHot
        ? Accent.fill.withValues(alpha: 0.9)
        : (wrapOn
              ? Grey.g76.withValues(alpha: 0.65)
              : Grey.g56.withValues(alpha: 0.45));
    _drawRail(
      c,
      Offset(s.width * 0.24, bottomRail),
      Offset(s.width * 0.78, bottomRail),
      railCol,
      dashed: !wrapOn,
    );

    // Right-to-left column flow: column 1 on right, column 2 to its left.
    final col1X = s.width * 0.62;
    final col2X = col1X - colStep;

    // Direction arrow showing right-to-left column flow.
    final arrowY = 14.0;
    final arrowPaint = Paint()
      ..color = (hot == 'writing' ? Accent.fill : Grey.g56).withValues(
        alpha: 0.75,
      )
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    c
      ..drawLine(
        Offset(col1X + em + 10, arrowY),
        Offset(col1X + em + 10, arrowY + 18),
        arrowPaint,
      )
      ..drawLine(
        Offset(col1X + em + 7.5, arrowY + 15),
        Offset(col1X + em + 10, arrowY + 18),
        arrowPaint,
      )
      ..drawLine(
        Offset(col1X + em + 12.5, arrowY + 15),
        Offset(col1X + em + 10, arrowY + 18),
        arrowPaint,
      );

    // Column 1 (top to bottom) with hanging punctuation below bottomRail.
    final col1 = [
      _GlyphKind.kanji,
      _GlyphKind.kana,
      _GlyphKind.kanji,
      _GlyphKind.period,
    ];
    var cy = topRail + align * math.max(0.0, measure - em * 3);
    for (var i = 0; i < col1.length; i++) {
      final k = col1[i];
      final adv = _advance(k, em);
      final isHang = hanging && i == col1.length - 1;
      final drawY = isHang ? bottomRail + 2.0 : cy;
      _drawGlyphCell(
        c,
        Rect.fromLTWH(col1X, drawY, em, adv),
        k,
        highlight: isHang,
        verticalCell: true,
      );
      if (!isHang) cy += adv + gapExtra;
    }

    // Column 2 (shorter, to the left of column 1).
    final col2 = [_GlyphKind.kana, _GlyphKind.kanji, _GlyphKind.period];
    var cy2 = topRail + align * math.max(0.0, measure - em * 2.4);
    for (var i = 0; i < col2.length; i++) {
      final k = col2[i];
      final adv = _advance(k, em);
      _drawGlyphCell(
        c,
        Rect.fromLTWH(col2X, cy2, em, adv),
        k,
        dim: true,
        verticalCell: true,
      );
      cy2 += adv + gapExtra;
    }

    // Column-gap indicator when Line Height is hot.
    if (hot == 'line') {
      final p = Paint()
        ..color = Accent.fill
        ..strokeWidth = 1.2;
      c.drawLine(
        Offset(col2X + em, topRail + 6),
        Offset(col1X, topRail + 6),
        p,
      );
    }
  }

  void _drawGlyphCell(
    Canvas c,
    Rect r,
    _GlyphKind kind, {
    bool highlight = false,
    bool dim = false,
    bool warn = false,
    bool verticalCell = false,
  }) {
    // Em-box outline shows fixed vs proportional / half-width metrics immediately.
    final boxCol = highlight
        ? Accent.fill.withValues(alpha: 0.65)
        : (hot == 'metrics'
              ? Accent.fill.withValues(alpha: 0.45)
              : Grey.g38.withValues(alpha: dim ? 0.25 : 0.42));
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()
        ..color = boxCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 1.0 : 0.7,
    );

    final ink = warn
        ? Accent.fill
        : (highlight
              ? Accent.fill
              : (dim ? Grey.g76.withValues(alpha: 0.72) : Grey.g95));
    final skew = -math.tan(slant * math.pi / 180.0).clamp(-0.6, 0.6);

    c.save();
    c.translate(r.center.dx, r.center.dy);
    if (skew.abs() > 0.001) {
      c.transform(Matrix4.skewX(skew).storage);
    }
    final hw = r.width * 0.34;
    final hh = r.height * 0.34;
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case _GlyphKind.kanji:
        // Geometric kanji-like frame + cross strokes.
        c
          ..drawLine(Offset(-hw, -hh * 0.75), Offset(hw, -hh * 0.75), stroke)
          ..drawLine(Offset(0, -hh), Offset(0, hh), stroke)
          ..drawRect(
            Rect.fromLTRB(-hw * 0.8, -hh * 0.2, hw * 0.8, hh * 0.85),
            stroke,
          );
      case _GlyphKind.kana:
        // Flowing kana-like curve silhouette.
        final path = Path()
          ..moveTo(-hw * 0.7, -hh * 0.6)
          ..quadraticBezierTo(hw * 0.9, -hh * 0.5, 0, hh * 0.1)
          ..quadraticBezierTo(-hw * 0.8, hh * 0.7, hw * 0.75, hh * 0.75);
        c.drawPath(path, stroke);
      case _GlyphKind.comma:
        final px = verticalCell
            ? r.width * 0.22
            : (metrics == 0 ? -r.width * 0.22 : 0.0);
        final py = verticalCell ? -r.height * 0.15 : r.height * 0.22;
        c.drawLine(Offset(px, py - 1.5), Offset(px + 1.8, py + 1.5), stroke);
      case _GlyphKind.period:
        final px = verticalCell
            ? r.width * 0.22
            : (metrics == 0 ? -r.width * 0.22 : 0.0);
        final py = verticalCell ? -r.height * 0.15 : r.height * 0.22;
        c.drawCircle(Offset(px, py), 2.1, stroke..strokeWidth = 1.2);
    }
    c.restore();
  }

  void _drawRail(
    Canvas c,
    Offset a,
    Offset b,
    Color col, {
    required bool dashed,
  }) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.0;
    if (!dashed) {
      c.drawLine(a, b, p);
      return;
    }
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final u = d / len;
    for (var t = 0.0; t < len; t += 5.0) {
      c.drawLine(a + u * t, a + u * math.min(t + 2.5, len), p);
    }
  }

  @override
  bool shouldRepaint(_TypesetPainter o) =>
      vertical != o.vertical ||
      align != o.align ||
      metrics != o.metrics ||
      kinsoku != o.kinsoku ||
      hanging != o.hanging ||
      wrapOn != o.wrapOn ||
      wrapAt != o.wrapAt ||
      tracking != o.tracking ||
      lineHeight != o.lineHeight ||
      slant != o.slant ||
      hot != o.hot;
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
      ..drawRect(Rect.fromLTWH(0.8, 2, 3.6, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(5.6, 2, 3.6, s.height - 4), p);
  } else if (mode == 1) {
    c
      ..drawRect(Rect.fromLTWH(1.5, 2, 3.4, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(5.3, 2, 2.2, s.height - 4), p);
  } else {
    c
      ..drawRect(Rect.fromLTWH(0.8, 2, 4.4, s.height - 4), p)
      ..drawRect(Rect.fromLTWH(6.0, 2, 2.2, s.height - 4), p);
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
