// The Blending card's inside: live blend-mode schematic with horizontal scrub
// and hover-preview dropdown, plus a dynamic Matte preview well (shown when
// clipped to the layer below) with Alpha/Luma & Invert glass pills and a live
// Feather readout.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/controls/well_pill.dart'
    show WellPill, maybeTip;
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/list_select.dart';
import 'package:motolii/widgets/paint_helpers.dart' show drawWell;

/// The Blending card's inside (see host_cards.dart).
class BlendPreview extends StatefulWidget {
  const BlendPreview(this.card, {super.key});
  final CardDeclaration card;

  static double get height => Shape.z(52);
  static double get matteHeight => Shape.z(52);

  @override
  State<BlendPreview> createState() => _BlendPreviewState();
}

class _BlendPreviewState extends State<BlendPreview> {
  // The mode hovered in the list, previewed live before committing.
  final _pending = ValueNotifier<int?>(null);
  bool _held = false;
  bool _moved = false;
  double _fromX = 0;
  int _fromI = 0;

  @override
  void dispose() {
    _pending.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = {for (final p in widget.card.params) p.id: p};
    final blend = params['blend'];
    final opts = blend?.options ?? const [];
    if (opts.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.watch('v_blend'),
        doc.watch('v_clip'),
        doc.watch('v_clip_matte'),
        doc.watch('v_clip_invert'),
        doc.watch('v_clip_feather'),
      ]),
      builder: (context, _) {
        final clipped = (doc.get('v_clip') ?? 0) > 0.5;
        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final h = BlendPreview.height, w = box.maxWidth;
                  final actualI = (doc.get('v_blend') ?? 0).round().clamp(
                    0,
                    opts.length - 1,
                  );
                  // The schematic box ends here; the mode-name trigger starts.
                  final textLeft = 8.0 + h * 1.6 + 12.0;

                  void scrub(double x) {
                    // Wraps around so every mode is reachable by dragging.
                    final raw = _fromI + ((x - _fromX) / 20).round();
                    final n = ((raw % opts.length) + opts.length) % opts.length;
                    if (n != (doc.get('v_blend') ?? 0).round()) {
                      doc.set('v_blend', n.toDouble());
                    }
                  }

                  return SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      children: [
                        // Layer 1: schematic canvas. Scrubbing cycles modes.
                        ValueListenableBuilder<int?>(
                          valueListenable: _pending,
                          builder: (_, pending, _) => Listener(
                            onPointerDown: (e) {
                              if (e.buttons != kPrimaryButton) return;
                              if (e.localPosition.dx >= textLeft) return;
                              _fromX = e.localPosition.dx;
                              _fromI = actualI;
                              _moved = false;
                              doc.beginGesture();
                              setState(() => _held = true);
                            },
                            onPointerMove: (e) {
                              if (!_held) return;
                              if ((e.localPosition.dx - _fromX).abs() > 4) {
                                _moved = true;
                              }
                              if (_moved) scrub(e.localPosition.dx);
                            },
                            onPointerUp: (_) => _let(),
                            onPointerCancel: (_) => _let(),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: CustomPaint(
                                key: const ValueKey('blend-preview'),
                                size: Size(w, h),
                                painter: _BlendPaint(
                                  word: opts[pending ?? actualI],
                                  lit: _held || pending != null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Layer 2: mode-name trigger with hover preview.
                        Positioned(
                          left: textLeft,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: ListSelect<int>(
                            value: actualI,
                            options: [
                              for (final (i, word) in opts.indexed)
                                (i, word.replaceAll('_', ' ')),
                            ],
                            itemHeight: 22,
                            maxItems: 10,
                            minWidth: 160,
                            wider: textLeft,
                            hover: _pending,
                            onChanged: (i) {
                              doc.beginGesture();
                              doc.set('v_blend', i.toDouble());
                              doc.endGesture();
                            },
                            builder: (_, st, _) => ValueListenableBuilder<int?>(
                              valueListenable: _pending,
                              builder: (_, pending, _) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Shape.s(8),
                                ),
                                decoration: BoxDecoration(
                                  color: st.isOpen || st.isHovered
                                      ? Grey.g10
                                      : null,
                                  borderRadius: BorderRadius.only(
                                    topRight: Shape.r(8),
                                    bottomRight: Shape.r(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opts[pending ?? actualI].replaceAll(
                                          '_',
                                          ' ',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.name(
                                          _held || pending != null
                                              ? Grey.g95
                                              : st.isOpen || st.isHovered
                                              ? Grey.g91
                                              : Grey.g76,
                                        ),
                                      ),
                                    ),
                                    DisclosureTriangle(
                                      open: true,
                                      hot: st.isOpen,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (clipped) _matteControls(doc, params),
            ],
          ),
        );
      },
    );
  }

  Widget _matteControls(InspectorValues doc, Map<String, Parameter> params) {
    final matteP = params['clip_matte'];
    final featherP = params['clip_feather'];
    final matteOpts = matteP?.options ?? const ['alpha', 'luma'];
    final matteI = (doc.get('v_clip_matte') ?? 0).round().clamp(
      0,
      matteOpts.length - 1,
    );
    final isLuma = matteOpts[matteI].toLowerCase() == 'luma';
    final inverted = (doc.get('v_clip_invert') ?? 0) > 0.5;
    final feather = doc.get('v_clip_feather') ?? (featherP?.def ?? 0);

    return Padding(
      padding: EdgeInsets.only(top: Shape.s(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MatteWell(
            doc: doc,
            matteOpts: matteOpts,
            matteIndex: matteI,
            isLuma: isLuma,
            inverted: inverted,
            feather: feather,
            featherParam: featherP,
          ),
          if (featherP != null) ...[
            SizedBox(height: Shape.s(4)),
            ParameterTile(featherP),
          ],
        ],
      ),
    );
  }

  void _let() {
    if (!_held) return;
    InspectorScope.of(context).doc.endGesture();
    setState(() => _held = false);
  }
}

/// Live Track Matte instrument: previews Alpha vs Luma cutout, Invert, and
/// Feather blur directly in a recessed well, with discrete modes anchored as
/// frosted glass pills. Dragging horizontally scrubs Feather.
class _MatteWell extends StatefulWidget {
  const _MatteWell({
    required this.doc,
    required this.matteOpts,
    required this.matteIndex,
    required this.isLuma,
    required this.inverted,
    required this.feather,
    required this.featherParam,
  });

  final InspectorValues doc;
  final List<String> matteOpts;
  final int matteIndex;
  final bool isLuma;
  final bool inverted;
  final double feather;
  final Parameter? featherParam;

  @override
  State<_MatteWell> createState() => _MatteWellState();
}

class _MatteWellState extends State<_MatteWell> {
  bool _dragging = false;
  double _fromX = 0;
  double _fromFeather = 0;

  void _cycleMatte() {
    if (widget.matteOpts.length < 2) return;
    final next = (widget.matteIndex + 1) % widget.matteOpts.length;
    widget.doc
      ..beginGesture()
      ..set('v_clip_matte', next.toDouble())
      ..endGesture();
  }

  void _toggleInvert() {
    widget.doc
      ..beginGesture()
      ..set('v_clip_invert', widget.inverted ? 0 : 1)
      ..endGesture();
  }

  void _endDrag() {
    if (!_dragging) return;
    widget.doc.endGesture();
    setState(() => _dragging = false);
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final matteLabel = _cap(widget.matteOpts[widget.matteIndex]);
    final canScrub = widget.featherParam != null;
    return SizedBox(
      height: BlendPreview.matteHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, BlendPreview.matteHeight);
          return Stack(
            children: [
              MouseRegion(
                cursor: canScrub
                    ? SystemMouseCursors.resizeLeftRight
                    : SystemMouseCursors.basic,
                child: Listener(
                  onPointerDown: (e) {
                    if (!canScrub || e.buttons != kPrimaryButton) return;
                    _fromX = e.localPosition.dx;
                    _fromFeather = widget.feather;
                    widget.doc.beginGesture();
                    setState(() => _dragging = true);
                  },
                  onPointerMove: (e) {
                    if (!_dragging) return;
                    final fp = widget.featherParam!;
                    final next =
                        (_fromFeather + (e.localPosition.dx - _fromX) * 0.4)
                            .clamp(fp.min ?? 0.0, fp.max ?? 500.0);
                    widget.doc.set('v_clip_feather', fp.typed(next));
                  },
                  onPointerUp: (_) => _endDrag(),
                  onPointerCancel: (_) => _endDrag(),
                  child: CustomPaint(
                    key: const ValueKey('matte-preview'),
                    size: size,
                    painter: _MattePaint(
                      isLuma: widget.isLuma,
                      inverted: widget.inverted,
                      feather: widget.feather,
                      lit: _dragging,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 13,
                bottom: 11,
                child: maybeTip(
                  context,
                  'Cut by $matteLabel',
                  WellPill(
                    key: const ValueKey('choice:clip_matte'),
                    label: matteLabel,
                    icon: (c, s, col) =>
                        _drawMatteGlyph(c, s, col, luma: widget.isLuma),
                    onTap: _cycleMatte,
                  ),
                ),
              ),
              Positioned(
                right: 13,
                bottom: 11,
                child: maybeTip(
                  context,
                  widget.inverted ? 'Invert matte: On' : 'Invert matte: Off',
                  WellPill(
                    key: const ValueKey('toggle:clip_invert'),
                    label: 'Invert',
                    active: widget.inverted,
                    icon: _drawInvertGlyph,
                    onTap: _toggleInvert,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _drawMatteGlyph(Canvas c, Size s, Color col, {required bool luma}) {
  final rect = Rect.fromLTWH(1, 1, s.width - 2, s.height - 2);
  if (luma) {
    // Half-filled luminance circle.
    final center = s.center(Offset.zero);
    final r = s.shortestSide * 0.4;
    c
      ..drawCircle(
        center,
        r,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      )
      ..drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        math.pi,
        true,
        Paint()..color = col,
      );
  } else {
    // 2x2 transparency checkerboard for alpha matte.
    final half = rect.width / 2;
    final p = Paint()..color = col;
    final dim = Paint()..color = col.withValues(alpha: 0.28);
    c
      ..drawRect(Rect.fromLTWH(rect.left, rect.top, half, half), p)
      ..drawRect(Rect.fromLTWH(rect.left + half, rect.top, half, half), dim)
      ..drawRect(Rect.fromLTWH(rect.left, rect.top + half, half, half), dim)
      ..drawRect(
        Rect.fromLTWH(rect.left + half, rect.top + half, half, half),
        p,
      );
  }
}

void _drawInvertGlyph(Canvas c, Size s, Color col) {
  final outer = Rect.fromLTWH(1, 1, s.width - 2, s.height - 2);
  final inner = Rect.fromLTWH(3.2, 3.2, s.width - 6.4, s.height - 6.4);
  c
    ..drawRect(
      outer,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    )
    ..drawRect(inner, Paint()..color = col);
}

class _MattePaint extends CustomPainter {
  const _MattePaint({
    required this.isLuma,
    required this.inverted,
    required this.feather,
    required this.lit,
  });

  final bool isLuma;
  final bool inverted;
  final double feather;
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    drawWell(c, s);
    final plate = Rect.fromLTWH(8, 6, s.width - 16, s.height - 12);
    final rrect = RRect.fromRectAndRadius(plate, const Radius.circular(5));

    c.save();
    c.clipRRect(rrect);

    // Checkerboard reveals transparent / masked-out regions.
    const cell = 5.5;
    c.drawRect(plate, Paint()..color = Grey.g10);
    final light = Paint()..color = Grey.g15;
    for (var y = plate.top, row = 0; y < plate.bottom; y += cell, row++) {
      for (var x = plate.left, col = 0; x < plate.right; x += cell, col++) {
        if ((row + col).isEven) {
          c.drawRect(Rect.fromLTWH(x, y, cell, cell), light);
        }
      }
    }

    // Layer artwork (same cool gradient family as the Blend schematic) masked
    // by the track matte below. saveLayer applies dstIn/dstOut across the full
    // plate so pixels outside the mask shape are cleared to reveal the checker.
    final blurSigma = (feather * 0.22).clamp(0.0, 9.0);
    c.saveLayer(plate, Paint());
    c.drawRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF59C3E8), Color(0xFF6B5CE7)],
        ).createShader(plate),
    );

    c.saveLayer(
      plate,
      Paint()..blendMode = inverted ? ui.BlendMode.dstOut : ui.BlendMode.dstIn,
    );
    final maskPaint = Paint();
    if (blurSigma > 0.1) {
      maskPaint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurSigma);
    }

    if (isLuma) {
      // Luma matte: smooth luminance gradient across the layer.
      final fadeSpan = (0.28 + (feather / 100).clamp(0.0, 0.5) * 0.4).clamp(
        0.2,
        0.8,
      );
      final lo = (0.5 - fadeSpan * 0.5).clamp(0.0, 1.0);
      final hi = (0.5 + fadeSpan * 0.5).clamp(0.0, 1.0);
      maskPaint.shader = ui.Gradient.linear(
        plate.centerLeft,
        plate.centerRight,
        const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        [lo, hi],
      );
      c.drawRect(plate, maskPaint);
    } else {
      // Alpha matte: crisp central disc silhouette softened by Feather.
      maskPaint.color = const Color(0xFFFFFFFF);
      c.drawCircle(plate.center, plate.height * 0.44, maskPaint);
    }
    c.restore();

    c.restore();

    // Subtle matte silhouette guide so Alpha shape remains legible even when
    // heavily feathered or inverted.
    if (!isLuma) {
      c.drawCircle(
        plate.center,
        plate.height * 0.44,
        Paint()
          ..color = Grey.g95.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    c.restore();

    c.drawRRect(
      rrect,
      Paint()
        ..color = lit ? Accent.fill : Grey.g26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MattePaint o) =>
      o.isLuma != isLuma ||
      o.inverted != inverted ||
      o.feather != feather ||
      o.lit != lit;
}

/// Flutter BlendMode for the 17 standard compositing modes. The remaining 8
/// modes use exact `blend_way.glsl` math below instead of approximations.
ui.BlendMode? _nativeBlendOf(String word) => switch (word) {
  'normal' => ui.BlendMode.srcOver,
  'add' => ui.BlendMode.plus,
  'multiply' => ui.BlendMode.multiply,
  'screen' => ui.BlendMode.screen,
  'darken' => ui.BlendMode.darken,
  'lighten' => ui.BlendMode.lighten,
  'overlay' => ui.BlendMode.overlay,
  'soft_light' => ui.BlendMode.softLight,
  'hard_light' => ui.BlendMode.hardLight,
  'color_dodge' => ui.BlendMode.colorDodge,
  'color_burn' => ui.BlendMode.colorBurn,
  'difference' => ui.BlendMode.difference,
  'exclusion' => ui.BlendMode.exclusion,
  'hue' => ui.BlendMode.hue,
  'saturation' => ui.BlendMode.saturation,
  'color' => ui.BlendMode.color,
  'luminosity' => ui.BlendMode.luminosity,
  _ => null,
};

// Exact sRGB formulas matching engine/materials/blend_way.glsl for the 8 modes
// Flutter's Canvas BlendMode does not expose natively.
double _wayDodge(double b, double s) => b < 1e-5
    ? 0.0
    : (s >= 1.0 ? 1.0 : math.min(1.0, b / math.max(1.0 - s, 1e-5)));

double _wayBurn(double b, double s) => b >= 0.99999
    ? 1.0
    : (s <= 0.0 ? 0.0 : 1.0 - math.min(1.0, (1.0 - b) / math.max(s, 1e-5)));

Color _exactBlendColor(String word, Color under, Color over) {
  final br = under.r, bg = under.g, bb = under.b;
  final sr = over.r, sg = over.g, sb = over.b;
  double ch(double b, double s) => switch (word) {
    'linear_burn' => (b + s - 1.0).clamp(0.0, 1.0),
    'linear_light' => (b + 2.0 * s - 1.0).clamp(0.0, 1.0),
    'vivid_light' =>
      (s <= 0.5 ? _wayBurn(b, 2.0 * s) : _wayDodge(b, 2.0 * s - 1.0)).clamp(
        0.0,
        1.0,
      ),
    'pin_light' =>
      (s <= 0.5 ? math.min(b, 2.0 * s) : math.max(b, 2.0 * s - 1.0)).clamp(
        0.0,
        1.0,
      ),
    'subtract' => (b - s).clamp(0.0, 1.0),
    'divide' => (s <= 0.0 ? 1.0 : b / math.max(s, 1e-5)).clamp(0.0, 1.0),
    _ => s,
  };
  if (word == 'darker_color' || word == 'lighter_color') {
    final lb = 0.3 * br + 0.59 * bg + 0.11 * bb;
    final ls = 0.3 * sr + 0.59 * sg + 0.11 * sb;
    final pickOver = word == 'darker_color' ? ls < lb : ls > lb;
    return pickOver ? over : under;
  }
  return Color.from(
    alpha: 1.0,
    red: ch(br, sr),
    green: ch(bg, sg),
    blue: ch(bb, sb),
  );
}

class _BlendPaint extends CustomPainter {
  _BlendPaint({required this.word, required this.lit});
  final String word;
  final bool lit;

  static const _bgLeft = Color(0xFFE8A13C);
  static const _bgRight = Color(0xFFD64B7A);
  static const _discTop = Color(0xFF59C3E8);
  static const _discBottom = Color(0xFF2E57E8);

  void _drawExactDisc(Canvas c, Rect box, Rect disc) {
    const n = 16;
    final positions = <Offset>[];
    final colors = <Color>[];
    final indices = <int>[];
    for (var row = 0; row <= n; row++) {
      final ty = row / n;
      final y = disc.top + disc.height * ty;
      final over = Color.lerp(_discTop, _discBottom, ty)!;
      for (var col = 0; col <= n; col++) {
        final tx = col / n;
        final x = disc.left + disc.width * tx;
        final bx = ((x - box.left) / box.width).clamp(0.0, 1.0);
        final under = Color.lerp(_bgLeft, _bgRight, bx)!;
        positions.add(Offset(x, y));
        colors.add(_exactBlendColor(word, under, over));
      }
    }
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final i = row * (n + 1) + col;
        indices.addAll([i, i + 1, i + n + 1, i + 1, i + n + 2, i + n + 1]);
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      colors: colors,
      indices: Uint16List.fromList(indices),
    );
    c.save();
    c.clipPath(Path()..addOval(disc));
    c.drawVertices(vertices, ui.BlendMode.srcOver, Paint());
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) {
    drawWell(c, s);
    // Schematic: warm gradient ground with a cool disc overlaid using the mode.
    final box = Rect.fromLTWH(8, 8, s.height * 1.6, s.height - 16);
    final r = RRect.fromRectAndRadius(box, const Radius.circular(6));
    c.save();
    c.clipRRect(r);
    c.saveLayer(box, Paint());
    c.drawRect(
      box,
      Paint()
        ..shader = const LinearGradient(colors: [_bgLeft, _bgRight])
            .createShader(box),
    );
    final disc = Rect.fromCircle(
      center: box.centerRight.translate(-box.height * 0.55, 0),
      radius: box.height * 0.42,
    );
    if (_nativeBlendOf(word) case final native?) {
      c.drawCircle(
        disc.center,
        disc.width / 2,
        Paint()
          ..blendMode = native
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_discTop, _discBottom],
          ).createShader(disc),
      );
    } else {
      _drawExactDisc(c, box, disc);
    }
    c.restore();
    c.restore();
    c.drawRRect(
      r,
      Paint()
        ..color = lit ? Accent.fill : Grey.g26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BlendPaint o) => o.word != word || o.lit != lit;
}
