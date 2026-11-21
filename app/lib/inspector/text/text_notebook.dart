// Ruled notebook text editor for the Text card:
// replaces a toolbar of boxed buttons with the paper itself — horizontal ruled
// lines under the real text, subtle genkouyoushi grid cells when Fixed-width
// metrics are active, a ruler strip at the top for direction/alignment/paper
// metrics, a draggable right margin rail for Wrap/Wrap at, and a clickable
// hanging punctuation mark right across the margin rail.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/text/text_ranges.dart'
    show TextCharClass, detectedCharClasses, styledClasses;
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Line height in CSS pixels used for both the real preview text and the ruled
/// notebook lines underneath so each line sits squarely on its rule.
const double notebookFontSize = 14.0;
const double notebookLineHeight = 1.5;
const double notebookRowStep = notebookFontSize * notebookLineHeight; // 21.0 px

/// Ruled notebook editor hosting the real layer text and borderless paper
/// affordances for discrete typesetting settings.
class TextNotebook extends StatefulWidget {
  const TextNotebook({
    required this.doc,
    required this.layer,
    required this.text,
    required this.styles,
    required this.base,
    required this.pickedCount,
    required this.activeClass,
    required this.onSelectClass,
    required this.styled,
    required this.onDone,
    required this.onPick,
    super.key,
  });

  final InspectorValues doc;
  final Map<String, Parameter> layer;
  final String text;
  final String styles;
  final TextStyle base;
  final int? pickedCount;
  final String? activeClass;
  final ValueChanged<String?> onSelectClass;
  final InlineSpan Function(String text, TextStyle style) styled;
  final void Function(String?) onDone;
  final void Function(TextEditingValue) onPick;

  @override
  State<TextNotebook> createState() => _TextNotebookState();
}

class _TextNotebookState extends State<TextNotebook> {
  static const _wrapCycle = [0, 2, 1, 3, 4];

  bool _draggingMargin = false;
  double _dragStartX = 0;
  double _dragStartWrap = 12.0;

  ({double min, double max, double def}) _wrapBounds() {
    final p = widget.layer['wrap_at'];
    final rawMin = p?.min;
    final rawMax = p?.max;
    final min = (rawMin != null && rawMin > 0) ? rawMin : 1.0;
    final max = (rawMax != null && rawMax > min) ? rawMax : 40.0;
    final def = (p?.def ?? 12.0).clamp(min, max);
    return (min: min, max: max, def: def);
  }

  double _marginX(double width, bool wrapOn, double wrapAt) {
    final maxX = width - 22.0;
    if (!wrapOn) return maxX;
    final b = _wrapBounds();
    final minX = math.max(96.0, width * 0.44);
    final t = ((wrapAt - b.min) / math.max(1.0, b.max - b.min)).clamp(0.0, 1.0);
    return minX + t * math.max(0.0, maxX - minX);
  }

  void _startMarginDrag(DragStartDetails d) {
    if (!widget.layer.containsKey('wrap_at')) return;
    final b = _wrapBounds();
    _draggingMargin = true;
    _dragStartX = d.localPosition.dx;
    _dragStartWrap = (widget.doc.get('v_wrap_at') ?? b.def).clamp(b.min, b.max);
    widget.doc.beginGesture();
    if ((widget.doc.get('v_wrap') ?? 0).round() == 0 &&
        widget.layer.containsKey('wrap')) {
      widget.doc.set('v_wrap', 2);
    }
    setState(() {});
  }

  void _updateMarginDrag(DragUpdateDetails d, double width) {
    if (!_draggingMargin) return;
    final b = _wrapBounds();
    final minX = math.max(96.0, width * 0.44);
    final maxX = width - 22.0;
    final span = math.max(1.0, maxX - minX);
    final dx = d.localPosition.dx - _dragStartX;
    final next = (_dragStartWrap + (dx / span) * (b.max - b.min)).clamp(
      b.min,
      b.max,
    );
    widget.doc.setMany({'v_wrap_at': next});
  }

  void _endMarginDrag() {
    if (!_draggingMargin) return;
    _draggingMargin = false;
    widget.doc.endGesture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final layer = widget.layer;
    final scoped = widget.pickedCount != null || widget.activeClass != null;
    final vertical =
        layer.containsKey('writing') &&
        (doc.get('v_writing') ?? 0).round() == 1;
    final align = doc.get('v_align') ?? 0.5;
    final alignIdx = align < 0.25 ? 0 : (align > 0.75 ? 2 : 1);
    final textAlign = switch (alignIdx) {
      0 => TextAlign.left,
      2 => TextAlign.right,
      _ => TextAlign.center,
    };
    final metrics = (doc.get('v_metrics') ?? 0).round().clamp(0, 2);
    final kinsoku = (doc.get('v_kinsoku') ?? 0).round().clamp(0, 3);
    final hanging = (doc.get('v_hanging') ?? 0) > 0.5;
    final wrap = (doc.get('v_wrap') ?? 0).round().clamp(0, 5);
    final wrapOn = wrap != 0;
    final wb = _wrapBounds();
    final wrapAt = (doc.get('v_wrap_at') ?? wb.def).clamp(wb.min, wb.max);

    final hasRuler =
        layer.containsKey('writing') ||
        layer.containsKey('align') ||
        layer.containsKey('metrics') ||
        layer.containsKey('kinsoku') ||
        layer.containsKey('wrap') ||
        scoped;

    return ClipRRect(
      borderRadius: Shape.round(6),
      child: Container(
        decoration: BoxDecoration(
          color: InspectorSkin.well,
          borderRadius: Shape.round(6),
          border: Border.all(
            color: scoped ? Accent.fill.withValues(alpha: 0.45) : Grey.g20,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasRuler)
              _NotebookRuler(
                doc: doc,
                layer: layer,
                vertical: vertical,
                alignIdx: alignIdx,
                metrics: metrics,
                kinsoku: kinsoku,
                wrap: wrap,
                wrapCycle: _wrapCycle,
                pickedCount: widget.pickedCount,
              ),
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final marginX = _marginX(w, wrapOn, wrapAt);
                final rightPad = math.max(22.0, w - marginX + 6.0);
                final hasMargin =
                    layer.containsKey('wrap') || layer.containsKey('hanging');

                return Stack(
                  children: [
                    // Ruled notebook lines, optional genkouyoushi cells (Fixed), and right margin rail.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _NotebookPaperPainter(
                            rowStep: notebookRowStep,
                            topInset: Shape.s(6),
                            metrics: metrics,
                            marginX: hasMargin ? marginX : null,
                            wrapOn: wrapOn,
                            kinsoku: kinsoku,
                            draggingMargin: _draggingMargin,
                          ),
                        ),
                      ),
                    ),
                    // Real editable horizontal text resting directly on the ruled lines.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Shape.s(10),
                        Shape.s(6),
                        hasMargin ? rightPad : Shape.s(10),
                        Shape.s(7),
                      ),
                      child: ClipRect(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: notebookRowStep * 2,
                            maxHeight: notebookRowStep * 4,
                          ),
                          child: TypedField(
                            key: const ValueKey('text:box'),
                            text: widget.text,
                            standing: true,
                            escapes: true,
                            align: layer.containsKey('align')
                                ? textAlign
                                : TextAlign.start,
                            style: widget.base,
                            cursor: Grey.g95,
                            backgroundCursor: Grey.g20,
                            selection: Role.selected.withValues(alpha: .4),
                            styled: widget.styled,
                            onDone: widget.onDone,
                            onPick: widget.onPick,
                          ),
                        ),
                      ),
                    ),
                    // Direct drag hit strip on the margin rail for Wrap / Wrap at.
                    if (layer.containsKey('wrap'))
                      Positioned(
                        left: (marginX - 7).clamp(0.0, math.max(0.0, w - 14)),
                        top: 0,
                        bottom: 0,
                        width: 14,
                        child: maybeTip(
                          context,
                          wrapOn
                              ? 'Drag margin to adjust Wrap at — tap to cycle wrap mode'
                              : 'Drag left to wrap text — tap to toggle Wrap',
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragStart: _startMarginDrag,
                              onHorizontalDragUpdate: (d) =>
                                  _updateMarginDrag(d, w),
                              onHorizontalDragEnd: (_) => _endMarginDrag(),
                              onHorizontalDragCancel: _endMarginDrag,
                            ),
                          ),
                        ),
                      ),
                    // Hanging punctuation mark seated right across the margin rail.
                    if (layer.containsKey('hanging') && !scoped)
                      Positioned(
                        left: (hanging ? marginX + 1 : marginX - 15).clamp(
                          0.0,
                          math.max(0.0, w - 18),
                        ),
                        top: Shape.s(6) + notebookRowStep - 15,
                        child: maybeTip(
                          context,
                          hanging
                              ? 'Hanging punctuation ON (、。，． hang past margin)'
                              : 'Hanging punctuation OFF — click to hang 、。，． past margin',
                          Pressable(
                            key: const ValueKey('text:hanging'),
                            onTap: () => doc.set('v_hanging', hanging ? 0 : 1),
                            builder: (_, hot) => SizedBox(
                              width: 16,
                              height: 16,
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(10, 10),
                                  painter: Draw(
                                    (c, s) => _drawPeriodMark(
                                      c,
                                      s,
                                      hanging
                                          ? Accent.fill
                                          : (hot ? Grey.g91 : Grey.g56),
                                      filled: hot,
                                    ),
                                    (hanging, hot),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Borderless composite character-class footer: auto-detected from
            // the scripts actually present in the text (only shown when 2+
            // classes mix or a class rule is already configured).
            if (widget.pickedCount == null)
              if (detectedCharClasses(
                    widget.text,
                    widget.styles,
                    detect: doc.actions.textClasses,
                  )
                  case final classes when classes.isNotEmpty)
                _ClassScopeFooter(
                  classes: classes,
                  activeClass: widget.activeClass,
                  customized: styledClasses(widget.styles),
                  onSelect: widget.onSelectClass,
                ),
          ],
        ),
      ),
    );
  }
}

/// Quiet borderless footer along the notebook's bottom edge for composite
/// character-class scoping, populated dynamically from the scripts in the text.
class _ClassScopeFooter extends StatelessWidget {
  const _ClassScopeFooter({
    required this.classes,
    required this.activeClass,
    required this.customized,
    required this.onSelect,
  });

  final List<TextCharClass> classes;
  final String? activeClass;
  final Set<String> customized;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(String? id, String label, String tip) {
      final selected = activeClass == id;
      final hasRule = id != null && customized.contains(id);
      return maybeTip(
        context,
        tip,
        Pressable(
          key: ValueKey('text:class:${id ?? 'all'}'),
          onTap: () => onSelect(selected && id != null ? null : id),
          builder: (_, hot) {
            final col = selected
                ? Accent.fill
                : (hot ? Grey.g95 : (hasRule ? Grey.g76 : Grey.g56));
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Shape.s(4),
                vertical: Shape.s(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyles.micro(col)),
                  if (hasRule)
                    Padding(
                      padding: EdgeInsets.only(left: Shape.s(2)),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Accent.fill,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: Shape.z(20),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(5)),
      decoration: BoxDecoration(
        color: Grey.g10.withValues(alpha: 0.45),
        border: Border(top: BorderSide(color: Grey.g20)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            item(null, 'All', 'Edit whole layer'),
            for (final cls in classes)
              item(cls.id, cls.label, 'Composite rule: ${cls.tip}'),
          ],
        ),
      ),
    );
  }
}

/// Borderless 20px top ruler strip on the notebook: writing direction at left,
/// clickable Left/Center/Right alignment marks across the center, and paper
/// metrics / wrap / kinsoku marks along the right without any boxed buttons.
class _NotebookRuler extends StatelessWidget {
  const _NotebookRuler({
    required this.doc,
    required this.layer,
    required this.vertical,
    required this.alignIdx,
    required this.metrics,
    required this.kinsoku,
    required this.wrap,
    required this.wrapCycle,
    required this.pickedCount,
  });

  final InspectorValues doc;
  final Map<String, Parameter> layer;
  final bool vertical;
  final int alignIdx;
  final int metrics;
  final int kinsoku;
  final int wrap;
  final List<int> wrapCycle;
  final int? pickedCount;

  @override
  Widget build(BuildContext context) {
    final scoped = pickedCount != null;
    return Container(
      height: Shape.z(22),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
      decoration: BoxDecoration(
        color: Grey.g10.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: Grey.g20)),
      ),
      child: Row(
        children: [
          if (layer.containsKey('writing') && !scoped)
            _RulerMark(
              key: const ValueKey('text:writing'),
              tip: vertical
                  ? 'Vertical-rl writing — click for horizontal'
                  : 'Horizontal writing — click for vertical-rl',
              active: vertical,
              label: vertical ? 'Vert' : 'Horiz',
              icon: (c, s, col) => _writingArrow(c, s, col, vertical),
              onTap: () => doc.set('v_writing', vertical ? 0 : 1),
            ),
          if (layer.containsKey('align') && !scoped) ...[
            SizedBox(width: Shape.s(6)),
            _AlignRuler(
              alignIdx: alignIdx,
              vertical: vertical,
              onSelect: (i) => doc.set('v_align', const [0.0, 0.5, 1.0][i]),
            ),
          ],
          const Spacer(),
          if (scoped)
            Container(
              key: const ValueKey('text:scope'),
              padding: EdgeInsets.symmetric(
                horizontal: Shape.s(5),
                vertical: Shape.s(1),
              ),
              decoration: BoxDecoration(
                color: Accent.fill.withValues(alpha: 0.16),
                borderRadius: Shape.round(3),
              ),
              child: Text(
                '$pickedCount ch',
                style: TextStyles.micro(Accent.fill),
              ),
            )
          else ...[
            if (layer.containsKey('metrics'))
              _RulerMark(
                key: const ValueKey('text:metrics'),
                tip: const [
                  'Fixed width (full-width monospace grid)',
                  'Proportional metrics (palt + kern)',
                  'Half-width punctuation (halt)',
                ][metrics],
                active: metrics != 0,
                label: const ['Fixed', 'palt', 'halt'][metrics],
                icon: (c, s, col) => _paperIcon(c, s, col, metrics),
                onTap: () =>
                    doc.set('v_metrics', ((metrics + 1) % 3).toDouble()),
              ),
            if (layer.containsKey('wrap')) ...[
              SizedBox(width: Shape.s(7)),
              _RulerMark(
                key: const ValueKey('text:wrap'),
                tip: wrap == 0
                    ? 'No wrap — click or drag margin rail'
                    : 'Wrap: ${const ['None', 'Char', 'Word', 'Smart', 'Clip', 'Col'][wrap]}',
                active: wrap != 0,
                label: const [
                  '↵',
                  'Char',
                  'Word',
                  'Smart',
                  'Clip',
                  'Col',
                ][wrap],
                icon: (c, s, col) => _marginMarkIcon(c, s, col, wrap != 0),
                onTap: () {
                  final at = wrapCycle.indexOf(wrap);
                  final next = wrapCycle[(at + 1) % wrapCycle.length];
                  doc.set('v_wrap', next.toDouble());
                },
              ),
            ],
            if (layer.containsKey('kinsoku')) ...[
              SizedBox(width: Shape.s(7)),
              _RulerMark(
                key: const ValueKey('text:kinsoku'),
                tip: const [
                  'Line break (kinsoku): Normal',
                  'Line break (kinsoku): Strict',
                  'Line break (kinsoku): Loose',
                  'Line break (kinsoku): None',
                ][kinsoku],
                active: kinsoku == 1 || kinsoku == 2,
                label: const ['Auto', 'Strict', 'Loose', 'Off'][kinsoku],
                onTap: () =>
                    doc.set('v_kinsoku', ((kinsoku + 1) % 4).toDouble()),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Borderless interactive ruler mark (text + optional tiny vector glyph).
class _RulerMark extends StatelessWidget {
  const _RulerMark({
    required this.tip,
    required this.active,
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String tip;
  final bool active;
  final String label;
  final VoidCallback onTap;
  final void Function(Canvas, Size, Color)? icon;

  @override
  Widget build(BuildContext context) => maybeTip(
    context,
    tip,
    Pressable(
      onTap: onTap,
      builder: (_, hot) {
        final col = active ? Accent.fill : (hot ? Grey.g95 : Grey.g56);
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(2),
            vertical: Shape.s(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                CustomPaint(
                  size: const Size(9, 9),
                  painter: Draw((c, s) => icon!(c, s, col), (
                    active,
                    hot,
                    label,
                  )),
                ),
                SizedBox(width: Shape.s(3)),
              ],
              Text(label, style: TextStyles.micro(col)),
            ],
          ),
        );
      },
    ),
  );
}

/// Three direct ruler positions (left / center / right) — tap where you expect
/// the lines to align instead of cycling a button.
class _AlignRuler extends StatelessWidget {
  const _AlignRuler({
    required this.alignIdx,
    required this.vertical,
    required this.onSelect,
  });

  final int alignIdx;
  final bool vertical;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('text:align'),
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        maybeTip(
          context,
          vertical
              ? const ['Align top', 'Align middle', 'Align bottom'][i]
              : const ['Align left', 'Align center', 'Align right'][i],
          Pressable(
            key: ValueKey('text:align:$i'),
            onTap: () => onSelect(i),
            builder: (_, hot) {
              final on = i == alignIdx;
              final col = on ? Accent.fill : (hot ? Grey.g91 : Grey.g44);
              return SizedBox(
                width: Shape.z(14),
                height: Shape.z(16),
                child: Center(
                  child: CustomPaint(
                    size: const Size(8, 8),
                    painter: Draw((c, s) => _alignTick(c, s, col, i, on), (
                      on,
                      hot,
                      i,
                    )),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}

/// Draws ruled horizontal lines aligned to the text rows, optional genkouyoushi
/// vertical grid for Fixed metrics, and the right-hand wrap margin rail.
class _NotebookPaperPainter extends CustomPainter {
  const _NotebookPaperPainter({
    required this.rowStep,
    required this.topInset,
    required this.metrics,
    required this.marginX,
    required this.wrapOn,
    required this.kinsoku,
    required this.draggingMargin,
  });

  final double rowStep;
  final double topInset;
  final int metrics;
  final double? marginX;
  final bool wrapOn;
  final int kinsoku;
  final bool draggingMargin;

  @override
  void paint(Canvas c, Size s) {
    final rulePaint = Paint()
      ..color = Grey.g26.withValues(alpha: 0.55)
      ..strokeWidth = 0.75;

    // Horizontal notebook lines seated under each text line.
    for (var y = topInset + rowStep - 1.5; y < s.height - 2; y += rowStep) {
      c.drawLine(Offset(6, y), Offset(s.width - 6, y), rulePaint);
    }

    // Genkouyoushi (manuscript paper) subtle vertical cells when Fixed-width.
    if (metrics == 0) {
      final cellPaint = Paint()
        ..color = Grey.g26.withValues(alpha: 0.28)
        ..strokeWidth = 0.6;
      final limit = marginX ?? (s.width - 8);
      for (
        var x = 10.0 + notebookFontSize;
        x < limit - 4;
        x += notebookFontSize
      ) {
        c.drawLine(Offset(x, topInset), Offset(x, s.height - 4), cellPaint);
      }
    }

    // Right margin rail (solid when Wrap is ON, faint dashed line when OFF).
    if (marginX case final mx?) {
      final railCol = draggingMargin
          ? Accent.fill
          : (wrapOn
                ? Accent.fill.withValues(alpha: 0.65)
                : Grey.g38.withValues(alpha: 0.45));
      final p = Paint()
        ..color = railCol
        ..strokeWidth = draggingMargin ? 1.4 : (wrapOn ? 1.0 : 0.8);
      if (wrapOn || draggingMargin) {
        c.drawLine(Offset(mx, 0), Offset(mx, s.height), p);
      } else {
        for (var y = 4.0; y < s.height - 4; y += 5.0) {
          c.drawLine(
            Offset(mx, y),
            Offset(mx, math.min(y + 2.5, s.height - 4)),
            p,
          );
        }
      }
      // Subtle kinsoku guard bar near the top of the margin rail.
      if (kinsoku == 1) {
        c.drawLine(
          Offset(mx - 2.5, 4),
          Offset(mx - 2.5, 13),
          Paint()
            ..color = Accent.fill.withValues(alpha: 0.7)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NotebookPaperPainter o) =>
      rowStep != o.rowStep ||
      topInset != o.topInset ||
      metrics != o.metrics ||
      marginX != o.marginX ||
      wrapOn != o.wrapOn ||
      kinsoku != o.kinsoku ||
      draggingMargin != o.draggingMargin;
}

void _drawPeriodMark(Canvas c, Size s, Color col, {required bool filled}) {
  final center = Offset(s.width * 0.5, s.height * 0.5);
  if (filled) {
    c.drawCircle(center, 4.2, Paint()..color = col.withValues(alpha: 0.16));
  }
  c.drawCircle(
    center,
    2.5,
    Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35,
  );
}

void _writingArrow(Canvas c, Size s, Color col, bool vertical) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round;
  if (!vertical) {
    c
      ..drawLine(
        Offset(1, s.height * 0.5),
        Offset(s.width - 1.2, s.height * 0.5),
        p,
      )
      ..drawLine(
        Offset(s.width - 3.2, s.height * 0.25),
        Offset(s.width - 1, s.height * 0.5),
        p,
      )
      ..drawLine(
        Offset(s.width - 3.2, s.height * 0.75),
        Offset(s.width - 1, s.height * 0.5),
        p,
      );
  } else {
    c
      ..drawLine(
        Offset(s.width * 0.5, 1),
        Offset(s.width * 0.5, s.height - 1.2),
        p,
      )
      ..drawLine(
        Offset(s.width * 0.25, s.height - 3.2),
        Offset(s.width * 0.5, s.height - 1),
        p,
      )
      ..drawLine(
        Offset(s.width * 0.75, s.height - 3.2),
        Offset(s.width * 0.5, s.height - 1),
        p,
      );
  }
}

void _alignTick(Canvas c, Size s, Color col, int idx, bool on) {
  final p = Paint()
    ..color = col
    ..strokeWidth = on ? 1.3 : 1.0
    ..strokeCap = StrokeCap.round;
  if (on) {
    // Small downward tab triangle on the ruler pointing at the chosen edge.
    final path = Path()
      ..moveTo(s.width * 0.2, 1.5)
      ..lineTo(s.width * 0.8, 1.5)
      ..lineTo(s.width * 0.5, s.height - 1.5)
      ..close();
    c.drawPath(path, Paint()..color = col);
    return;
  }
  // Subtle alignment bar preview for inactive ruler stops.
  final x = idx == 0 ? 1.0 : (idx == 1 ? s.width * 0.25 : s.width * 0.45);
  c
    ..drawLine(Offset(1, 2.2), Offset(s.width - 1, 2.2), p)
    ..drawLine(
      Offset(x, s.height - 2.2),
      Offset(x + s.width * 0.45, s.height - 2.2),
      p,
    );
}

void _paperIcon(Canvas c, Size s, Color col, int mode) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  if (mode == 0) {
    c
      ..drawRect(Rect.fromLTWH(0.8, 1.2, 3.5, s.height - 2.4), p)
      ..drawRect(Rect.fromLTWH(4.8, 1.2, 3.5, s.height - 2.4), p);
  } else {
    c
      ..drawLine(
        Offset(0.8, s.height * 0.3),
        Offset(s.width - 0.8, s.height * 0.3),
        p,
      )
      ..drawLine(
        Offset(0.8, s.height * 0.72),
        Offset(s.width - 0.8, s.height * 0.72),
        p,
      );
  }
}

void _marginMarkIcon(Canvas c, Size s, Color col, bool on) {
  final p = Paint()
    ..color = col
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(s.width - 1.5, 1), Offset(s.width - 1.5, s.height - 1), p);
  if (on) {
    c
      ..drawLine(
        Offset(1, s.height * 0.35),
        Offset(s.width - 3.2, s.height * 0.35),
        p,
      )
      ..drawLine(
        Offset(1, s.height * 0.7),
        Offset(s.width * 0.5, s.height * 0.7),
        p,
      );
  }
}
