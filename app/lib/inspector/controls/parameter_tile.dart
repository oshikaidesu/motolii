// One parameter as a block: the name on top, the number large under it, a picture of the value in the top-right corner.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/chooser.dart';
import 'package:motolii/inspector/controls/angle_dial.dart';
import 'package:motolii/inspector/controls/gauge.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/link_line.dart';
import 'package:motolii/inspector/controls/parameter_grid.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_words.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart';
import 'package:motolii/widgets/switch_track.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';

/// One parameter as a block: the name on top, the number large under it, a picture of the value in the top-right corner.
///
/// Every block still shows the number and takes typing, scrubbing and the sideways slide. The picture is added, never a replacement.
/// Numbers always scrub sideways. A picture may handle the pointer its own way: a dial turns, a pad moves both ways.
class ParameterTile extends StatelessWidget {
  const ParameterTile(this.p, {super.key});
  final Parameter p;

  String get id => 'v_${p.id}';

  Widget _num(
    BuildContext context, {
    String? sub,
    String? caption,
    Widget? glyph,
    bool owns = false,
    bool tall = false,
  }) {
    final fid = sub == null ? id : '$id.$sub';
    return RowInfo(
      keys: InspectorScope.of(context).doc.keys[id] ?? KeyframeState.off,
      child: InspectorNumberField(
        p,
        id: fid,
        caption: caption ?? p.label,
        glyph: glyph,
        glyphOwnsPointer: owns,
        glyphTall: tall,
      ),
    );
  }

  /// How strongly the parameter changes the result (`Parameter.weight`, 0 to 10), as a step from 0 to 3.
  ///
  /// Each step above 0 tints the block with its own colour, so strength reads as a gradation of colour, not as yes or no,
  /// and the block stays quiet enough that the rest is still read. The tint follows GitHub's dark-page labels (Primer):
  /// the background is the colour at 0.18 alpha and the text is the colour itself.
  static int step(double? w) =>
      w == null || w < 4 ? 0 : (w < 6 ? 1 : (w < 8 ? 2 : 3));

  /// The tint of each step above 0: 青磁 (seiji), 撫子 (nadeshiko) and 浅黄 (usuki) from nipponcolors.com.
  /// Each has a contrast of at least 6:1 against `InspectorSkin.well`. It is not final so a picture test can try others.
  static var steps = const [
    Color(0xFF69B0AC),
    Color(0xFFDC9FB4),
    Color(0xFFFAD689),
  ];

  /// A filter that draws the block as a duotone: `InspectorSkin.well` maps to the tinted background, `Grey.g95` to [to], and greys between.
  static ColorFilter duotone(Color to) {
    final lo = InspectorSkin.well,
        hi = Grey.g95,
        ground = Color.alphaBlend(to.withValues(alpha: .18), lo);
    List<double> row(
      int k,
      double low,
      double high,
      double under,
      double word,
    ) {
      final a = (word - under) / (high - low);
      return [
        for (var j = 0; j < 5; j++)
          j == k ? a : (j == 4 ? (under - a * low) * 255 : 0),
      ];
    }

    return ColorFilter.matrix([
      ...row(0, lo.r, hi.r, ground.r, to.r),
      ...row(1, lo.g, hi.g, ground.g, to.g),
      ...row(2, lo.b, hi.b, ground.b, to.b),
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) => switch (step(p.weight)) {
    0 => _body(context),
    final s => ColorFiltered(
      colorFilter: duotone(steps[s - 1]),
      child: _body(context),
    ),
  };

  Widget _body(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc, v = doc.get(id);
    final gauge = SizedBox.square(
      dimension: InspectorSkin.glyph,
      child: FittedBox(child: Gauge(v, p)),
    );
    // Same layout as a number block: name at the top left, the control along the bottom, the picture at the top right.
    Widget shell(
      Widget bottom, {
      VoidCallback? onTap,
      Widget? glyph,
      bool tall = false,
    }) => Pressable(
      onTap: onTap,
      builder: (_, h) => Container(
        height: tall
            ? InspectorSkin.tile * 2 + InspectorSkin.tileGap
            : InspectorSkin.tile,
        decoration: BoxDecoration(
          color: h && onTap != null ? Grey.g20 : InspectorSkin.well,
          borderRadius: BorderRadius.all(Shape.r(6)),
        ),
        child: Stack(
          children: [
            if (glyph != null)
              Positioned(
                right: InspectorSkin.tilePad - 3,
                top: 4,
                width: InspectorSkin.glyph,
                height: InspectorSkin.glyph,
                child: Center(child: glyph),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                InspectorSkin.tilePad,
                Shape.s(4),
                glyph != null
                    ? InspectorSkin.glyph + InspectorSkin.tilePad
                    : InspectorSkin.tilePad,
                Shape.s(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.micro(Grey.g63).copyWith(height: 1.1),
                  ),
                  bottom,
                ],
              ),
            ),
          ],
        ),
      ),
    );
    switch (p.look) {
      case ParameterLook.toggle:
        final b = (v ?? 0) > 0;
        return shell(
          onTap: () => doc.set(id, b ? 0 : 1),
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(3)),
            child: Row(
              // Tests find it by the parameter id.
              key: ValueKey('toggle:$id'),
              children: [
                PopSwitch(on: b),
                SizedBox(width: Shape.s(6)),
                Text(b ? 'On' : 'Off', style: TextStyles.label(Grey.g76)),
              ],
            ),
          ),
        );
      case ParameterLook.choice:
        return shell(
          SizedBox(
            height: Shape.z(22),
            child: p.options.length <= 4
                ? Segmented(
                    // Tests find it by the parameter id, as they do the menu used for more options.
                    key: ValueKey('choice:$id'),
                    items: p.options,
                    index: (v ?? 0).round().clamp(0, p.options.length - 1),
                    onChanged: (i) => doc.set(id, i.toDouble()),
                  )
                : Chooser(id: id, options: p.options),
          ),
        );
      case ParameterLook.color when p.unit == 'words':
        // Free text, possibly several lines. It is committed when the field loses focus and Esc restores it (like Cavalry's string attribute).
        return shell(ParameterWords(id: id), tall: true);
      case ParameterLook.color when p.unit == 'file':
        // A file chosen from a shelf, such as a text layer's font from the Fonts shelf, as a colour is chosen from the Colors shelf.
        return shell(
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(3)),
            child: LinkLine(
              to: LinkTo.fonts,
              value: doc.strings[id] ?? '—',
              id: id,
            ),
          ),
        );
      case ParameterLook.color when p.unit == 'numbers':
        // A list of numbers, such as a bar chart's heights, edited as bars the user drags up and down. Committed on release.
        return shell(_Heights(id: id));
      case ParameterLook.color:
        final all = (doc.strings[id] ?? '—')
            .split(' ')
            .where((c) => hexControls(c) != null)
            .toList();
        return shell(
          glyph: Swatch(doc.strings[id], ramp: all.length > 1 ? all : null),
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(3)),
            // With several colours, the line shows how many and the swatch strip shows which.
            child: LinkLine(
              to: LinkTo.colors,
              value: all.length > 1 ? '${all.length}' : doc.strings[id] ?? '—',
              id: id,
            ),
          ),
        );
      case ParameterLook.angle:
        return _num(
          context,
          glyph: AngleDial(id: id, p: p),
          owns: true,
        );
      case ParameterLook.percent ||
          ParameterLook.vertical ||
          ParameterLook.horizontal ||
          ParameterLook.bipolar ||
          ParameterLook.bar ||
          ParameterLook.scrub:
        return _num(context, glyph: gauge);
      case ParameterLook.seed:
        return _num(
          context,
          glyph: SizedBox.square(
            dimension: InspectorSkin.glyph,
            child: FittedBox(
              child: Dice(id: id, p: p),
            ),
          ),
          owns: true,
        );
      case ParameterLook.stepper:
        return _num(
          context,
          glyph: Steps(id: id, p: p),
          owns: true,
          tall: true,
        );
      case ParameterLook.point || ParameterLook.size:
        final point = p.look == ParameterLook.point;
        return Row(
          children: [
            _PadGlyph(id: id, p: p, size: !point),
            SizedBox(width: InspectorSkin.tileGap),
            Expanded(
              child: _num(
                context,
                sub: 'x',
                caption: '${p.label} ${point ? 'X' : 'W'}',
              ),
            ),
            SizedBox(width: InspectorSkin.tileGap),
            Expanded(
              child: _num(context, sub: 'y', caption: point ? 'Y' : 'H'),
            ),
          ],
        );
    }
  }
}

/// A handle for a 2D value that the user drags like a trackpad. Sideways changes X (or width), up and down changes Y (or height).
///
/// The picture shows the current value. One drag is one undo step. For a point, Y follows the canvas (down increases it);
/// for a size, up increases the height.
class _PadGlyph extends StatefulWidget {
  const _PadGlyph({required this.id, required this.p, required this.size});
  final String id;
  final Parameter p;
  final bool size;
  @override
  State<_PadGlyph> createState() => _PadGlyphState();
}

class _PadGlyphState extends State<_PadGlyph> {
  bool _drag = false, _hot = false;
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc, p = widget.p;
    final ix = '${widget.id}.x', iy = '${widget.id}.y';
    double step(double v, double d) => double.parse(
      p
          .scrubbed(v + d * p.perPx, v, past: goingPast(context, doc))
          .toStringAsFixed(math.max(p.dec, 2)),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: Listener(
        onPointerDown: (_) {
          doc.beginGesture();
          setState(() => _drag = true);
        },
        onPointerMove: (e) {
          if (!_drag) return;
          doc.setMany({
            ix: step(doc.get(ix) ?? 0, e.delta.dx),
            iy: step(doc.get(iy) ?? 0, widget.size ? -e.delta.dy : e.delta.dy),
          });
        },
        onPointerUp: (_) {
          if (_drag) doc.endGesture();
          setState(() => _drag = false);
        },
        onPointerCancel: (_) {
          if (_drag) doc.endGesture();
          setState(() => _drag = false);
        },
        child: Container(
          width: InspectorSkin.tile,
          height: InspectorSkin.tile,
          decoration: BoxDecoration(
            color: _drag || _hot ? Grey.g20 : InspectorSkin.well,
            borderRadius: BorderRadius.all(Shape.r(6)),
          ),
          child: FittedBox(
            child: Gauge(null, p, x: doc.get(ix), y: doc.get(iy)),
          ),
        ),
      ),
    );
  }
}

/// A list of numbers drawn as bars. The user drags a bar up or down, and the new list is committed when the drag ends.
class _Heights extends StatefulWidget {
  const _Heights({required this.id});
  final String id;
  @override
  State<_Heights> createState() => _HeightsState();
}

class _HeightsState extends State<_Heights> {
  /// The numbers as edited during a drag. Null when no drag is in progress.
  List<double>? _held;
  double _top = 1;

  List<double> _said(InspectorValues doc) {
    final w = [
      for (final s in (doc.strings[widget.id] ?? '').split(' '))
        ?double.tryParse(s),
    ];
    // With no value yet, start from eight equal bars to drag.
    return w.isEmpty ? List.filled(8, 1) : w;
  }

  void _at(Offset p, Size box) {
    final v = _held!,
        i = (p.dx / box.width * v.length).floor().clamp(0, v.length - 1);
    setState(
      () => v[i] =
          (((1 - p.dy / box.height) * _top) * 10).roundToDouble().clamp(
            0,
            _top * 10,
          ) /
          10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc, v = _held ?? _said(doc);
    return SizedBox(
      height: Shape.z(24),
      child: LayoutBuilder(
        builder: (_, box) {
          final size = Size(box.maxWidth, 24);
          void start(Offset at) {
            _held = [..._said(doc)];
            _top = math.max(1, _held!.reduce(math.max) * 1.25);
            _at(at, size);
          }

          void end() {
            doc.str(
              widget.id,
              [
                for (final x in _held!)
                  x == x.roundToDouble() ? '${x.round()}' : '$x',
              ].join(' '),
            );
            setState(() => _held = null);
          }

          // Only vertical drags are claimed, so the panel can still scroll. A tap also sets a bar.
          return GestureDetector(
            supportedDevices: pressingDevices,
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (d) => start(d.localPosition),
            onVerticalDragUpdate: (d) => _at(d.localPosition, size),
            onVerticalDragEnd: (_) => end(),
            onTapUp: (d) {
              start(d.localPosition);
              end();
            },
            child: CustomPaint(
              size: size,
              painter: _BarsPainter(
                v,
                _held == null ? math.max(1, v.reduce(math.max) * 1.25) : _top,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.v, this.top);
  final List<double> v;
  final double top;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width / v.length, paint = Paint()..color = Grey.g76;
    for (var i = 0; i < v.length; i++) {
      final h = (v[i] / top).clamp(0.0, 1.0) * s.height;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * w + w * .15, s.height - h, w * .7, h),
          Shape.r(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter o) => o.v != v || o.top != top;
}
