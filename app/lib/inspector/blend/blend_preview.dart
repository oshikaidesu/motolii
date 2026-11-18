// The Blending card's inside: how the layer sits on what is below. A cool disc is laid over a warm ground with the
// chosen mode, so the mode's effect is seen. Clicking the mode name opens a list of all modes; hovering one shows it
// in the schematic before committing. Scrubbing left-right across the schematic cycles through modes and wraps around.
// The Clip to below tile stays below, so it may also be toggled there.
// The disc and the ground are a schematic, not the layer's own pixels, and the modes the canvas has no blend for
// (linear burn and light, vivid and pin light, darker and lighter colour, subtract, divide) are shown by their nearest
// neighbour. The layer's own render on the stage is the engine's, see engine/document/evaluate/material.h.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart'
    show NakedSelect, NakedSelectOption, OverlayPositionConfig;

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart' show PressOutside;
import 'package:motolii/widgets/controls.dart' show Pressable, Segmented;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/switch_track.dart';

/// The Blending card's inside (see host_cards.dart).
class BlendPreview extends StatefulWidget {
  const BlendPreview(this.card, {super.key});
  final CardDeclaration card;

  static double get height => Shape.z(52);

  @override
  State<BlendPreview> createState() => _BlendPreviewState();
}

class _BlendPreviewState extends State<BlendPreview> {
  // The mode the pointer is hovering in the list, shown in the schematic before the user commits.
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
      ]),
      builder: (context, _) {
        final clipped = (doc.get('v_clip') ?? 0) > 0.5;
        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    // Wraps around so every mode is reachable by dragging far enough.
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
                        // Layer 1: schematic canvas. Scrubbing it cycles through modes.
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
                        // Layer 2: mode-name trigger. Clicking opens the list; hovering a list item
                        // sets _pending, which layer 1 reads to preview the mode in the schematic.
                        Positioned(
                          left: textLeft,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: NakedSelect<int>(
                            value: actualI,
                            useRootOverlay: true,
                            closeOnClickOutside: false,
                            consumeOutsideTaps: false,
                            positioning: OverlayPositionConfig(
                              sideOffset: Shape.s(4),
                            ),
                            onChanged: (i) {
                              _pending.value = null;
                              if (i != null) {
                                doc.beginGesture();
                                doc.set('v_blend', i.toDouble());
                                doc.endGesture();
                              }
                            },
                            overlayBuilder: (context, info) => PressOutside(
                              group: info.tapRegionGroupId,
                              shut: () {
                                _pending.value = null;
                                MenuController.maybeOf(context)?.close();
                              },
                              child: MouseRegion(
                                onExit: (_) => _pending.value = null,
                                child: SizedBox(
                                  width: math.max(
                                    info.anchorRect.width + textLeft,
                                    160,
                                  ),
                                  child: _listWidget(actualI, opts),
                                ),
                              ),
                            ),
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
    final inverted = (doc.get('v_clip_invert') ?? 0) > 0.5;
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: Shape.z(26),
            child: Segmented(
              key: const ValueKey('choice:clip_matte'),
              items: matteOpts,
              index: matteI,
              onChanged: (i) {
                doc.beginGesture();
                doc.set('v_clip_matte', i.toDouble());
                doc.endGesture();
              },
            ),
          ),
          SizedBox(height: Shape.s(4)),
          Pressable(
            onTap: () {
              doc.beginGesture();
              doc.set('v_clip_invert', inverted ? 0 : 1);
              doc.endGesture();
            },
            builder: (_, _) => Padding(
              padding: EdgeInsets.only(bottom: Shape.s(3)),
              child: Row(
                children: [
                  PopSwitch(on: inverted),
                  SizedBox(width: Shape.s(6)),
                  Text(
                    inverted ? 'On' : 'Off',
                    style: TextStyles.label(Grey.g76),
                  ),
                ],
              ),
            ),
          ),
          if (featherP != null)
            InspectorNumberField(
              featherP,
              key: const ValueKey('feather:clip_feather'),
              id: 'v_clip_feather',
              caption: 'Feather',
            ),
        ],
      ),
    );
  }

  Widget _listWidget(int cur, List<String> opts) => Container(
    padding: EdgeInsets.all(Shape.s(3)),
    decoration: BoxDecoration(
      color: Grey.g15,
      borderRadius: Shape.round(8),
      border: Border.all(color: Grey.g26),
      boxShadow: WindowTokens.lift,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 10 * 22.0),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemExtent: 22.0,
        itemCount: opts.length,
        itemBuilder: (_, i) => NakedSelectOption<int>(
          value: i,
          builder: (_, st, _) {
            final sel = i == cur, on = st.isHovered || st.isFocused;
            return MouseRegion(
              // Enter sets the pending mode; exit clears it. The outer MouseRegion.onExit
              // handles leaving the whole list, so individual exits only clear if still theirs.
              onEnter: (_) => _pending.value = i,
              onExit: (_) {
                if (_pending.value == i) _pending.value = null;
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
                decoration: BoxDecoration(
                  color: on ? Grey.g26 : (sel ? Grey.g20 : null),
                  borderRadius: Shape.round(5),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opts[i].replaceAll('_', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.name(sel || on ? Grey.g95 : Grey.g76),
                      ),
                    ),
                    if (sel)
                      Container(
                        width: Shape.z(5),
                        height: Shape.z(5),
                        decoration: BoxDecoration(
                          color: Grey.g95,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  void _let() {
    if (!_held) return;
    InspectorScope.of(context).doc.endGesture();
    setState(() => _held = false);
  }
}

/// The Flutter blend for a Motolii mode, or its nearest neighbour where the canvas has none of its own.
ui.BlendMode _blendOf(String word) => switch (word) {
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
  'linear_burn' => ui.BlendMode.colorBurn,
  'linear_light' => ui.BlendMode.hardLight,
  'vivid_light' => ui.BlendMode.overlay,
  'pin_light' => ui.BlendMode.hardLight,
  'darker_color' => ui.BlendMode.darken,
  'lighter_color' => ui.BlendMode.lighten,
  'subtract' => ui.BlendMode.difference,
  'divide' => ui.BlendMode.colorDodge,
  _ => ui.BlendMode.srcOver,
};

class _BlendPaint extends CustomPainter {
  _BlendPaint({required this.word, required this.lit});
  final String word;
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)),
      Paint()..color = Grey.g07,
    );
    // Schematic: warm gradient ground with a cool disc overlaid using the chosen mode.
    final box = Rect.fromLTWH(8, 8, s.height * 1.6, s.height - 16);
    final r = RRect.fromRectAndRadius(box, const Radius.circular(6));
    c.save();
    c.clipRRect(r);
    c.saveLayer(box, Paint());
    c.drawRect(
      box,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE8A13C), Color(0xFFD64B7A)],
        ).createShader(box),
    );
    final disc = Rect.fromCircle(
      center: box.centerRight.translate(-box.height * 0.55, 0),
      radius: box.height * 0.42,
    );
    c.drawCircle(
      disc.center,
      disc.width / 2,
      Paint()
        ..blendMode = _blendOf(word)
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF59C3E8), Color(0xFF2E57E8)],
        ).createShader(disc),
    );
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
