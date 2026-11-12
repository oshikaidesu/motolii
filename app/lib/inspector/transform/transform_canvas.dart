// The Transform preview: the layer as a blue box in the composition, its handles pulled to edit the Transform rows.
// Restored from 52289b693~1 (inspector_direct_transform_canvas.dart); the undo button and the depth slab left out.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/transform/transform_layout.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/number_field_state.dart' show dragRate;

/// The value id of the part hovered or held on the preview, or of the row hovered under it, so both light together.
final transformHot = ValueNotifier<String?>(null);

class TransformCanvas extends StatefulWidget {
  const TransformCanvas({
    super.key,
    required this.params,
    required this.deep,
    required this.linked,
  });

  /// The card's parameters by value id; a dragged value goes only as far as a typed one may.
  final Map<String, Parameter> params;

  /// Whether the layer is in 2.5D or 3D, where Z and the tilts can be pulled.
  final bool deep;

  /// Whether a corner scales both sides by one factor.
  final bool linked;
  @override
  State<TransformCanvas> createState() => _TransformCanvasState();
}

class _TransformCanvasState extends State<TransformCanvas> {
  final _focus = FocusNode(debugLabel: 'transform-preview');
  TransformLayout? _start;
  InspectorValues? _doc;
  Map<String, double>? _before;
  (TransformZone, int)? _grab, _hover;
  Offset _down = Offset.zero, _last = Offset.zero;
  TransformHome? _home;
  String? _homeOf;

  void _setHover((TransformZone, int)? zone) {
    if (zone?.$1 == _hover?.$1 && zone?.$2 == _hover?.$2) return;
    setState(() => _hover = zone);
    transformHot.value = (_grab ?? zone)?.$1.id;
  }

  void _finish({bool cancel = false}) {
    final doc = _doc;
    if (_grab == null || doc == null) return;
    if (cancel && _before != null) doc.setMany(_before!);
    doc.endGesture();
    setState(() {
      _grab = null;
      _start = null;
    });
  }

  @override
  void dispose() {
    if (_grab != null) _finish(cancel: true);
    _focus.dispose();
    super.dispose();
  }

  void _drag(Offset p) {
    final g = _start, grab = _grab, doc = _doc;
    if (g == null || grab == null || doc == null) return;
    final next = g.drag(
      grab.$1,
      grab.$2,
      down: _down,
      last: _last,
      now: p,
      current: doc.numbers,
      rate: dragRate(),
      linked: widget.linked,
    );
    doc.setMany({
      for (final e in next.entries)
        e.key: widget.params[e.key]?.typed(e.value) ?? e.value,
    });
    _last = p;
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return ListenableBuilder(
      // Drawn again when one of its values is told anew: a hand on the stage, a moment of playback.
      listenable: Listenable.merge([
        for (final id in TransformLayout.watched) doc.watch(id),
        transformHot,
        doc,
      ]),
      builder: (context, _) => _drawing(doc),
    );
  }

  Widget _drawing(InspectorValues doc) => Padding(
    padding: EdgeInsets.only(top: Shape.s(4)),
    child: SizedBox(
      height: Shape.z(PreviewSize.height),
      child: LayoutBuilder(
        builder: (context, box) {
          final values = {
            for (final id in TransformLayout.watched) id: doc.get(id) ?? 0,
          };
          if (_homeOf != doc.name) {
            _home = null;
            _homeOf = doc.name;
          }
          TransformLayout at(TransformHome home) => TransformLayout(
            box.biggest,
            values,
            deep: widget.deep,
            home: home,
          );
          var g = at(_home ??= TransformHome.of(values));
          // Gone out of the frame: back in the middle.
          if (_grab == null && g.away) g = at(_home = TransformHome.of(values));
          final own = _grab ?? _hover;
          final hot =
              own?.$1 ??
              TransformZone.values
                  .where((z) => z.id == transformHot.value)
                  .firstOrNull;
          return Semantics(
            label: 'Transform preview: drag the box to move, a handle to scale, the knob to rotate, the ring to move the anchor',
            child: Focus(
              focusNode: _focus,
              onKeyEvent: (_, e) {
                if (e is KeyDownEvent &&
                    e.logicalKey == LogicalKeyboardKey.escape &&
                    _grab != null) {
                  _finish(cancel: true);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MouseRegion(
                cursor: own == null
                    ? SystemMouseCursors.basic
                    : (_grab != null
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab),
                onHover: (e) => _setHover(g.pick(e.localPosition)),
                onExit: (_) => _setHover(null),
                child: Listener(
                  onPointerDown: (e) {
                    if (e.buttons != kPrimaryButton) return;
                    final grab = g.pick(e.localPosition);
                    if (grab == null) return;
                    _focus.requestFocus();
                    _before = Map.of(values);
                    _doc = doc..beginGesture();
                    _start = g;
                    _grab = grab;
                    _down = _last = e.localPosition;
                    transformHot.value = grab.$1.id;
                  },
                  onPointerMove: (e) => _drag(e.localPosition),
                  onPointerUp: (_) => _finish(),
                  onPointerCancel: (_) => _finish(cancel: true),
                  child: CustomPaint(
                    key: const ValueKey('transform-preview'),
                    size: box.biggest,
                    painter: _PreviewPaint(
                      g,
                      hot: hot,
                      hotIndex: own?.$2,
                      linked: widget.linked,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _PreviewPaint extends CustomPainter {
  const _PreviewPaint(
    this.g, {
    required this.hot,
    required this.hotIndex,
    required this.linked,
  });
  final TransformLayout g;
  final TransformZone? hot;
  final int? hotIndex;
  final bool linked;

  Paint line(Color color, [double width = 1]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  Paint fill(Color color) => Paint()..color = color;

  /// A part's colour; the others fade while one is hot, so the grabbed part stands alone.
  Color ink(TransformZone zone) => hot == null || hot == zone
      ? zone.color
      : zone.color.withValues(alpha: .3);

  /// A rotation knob's colour: the Z knob wears Rotation's, the tilts their axis colour.
  Color tiltInk(int axis) {
    final base = [TransformZone.rotate.color, axisX, axisY][axis];
    if (hot == null) return base;
    final on =
        hot == TransformZone.rotate && (hotIndex == null || hotIndex == axis);
    return on ? base : base.withValues(alpha: .3);
  }

  void arrowHead(Canvas c, Offset tip, Offset from, Color color) {
    final back = (from - tip) / math.max(.001, (from - tip).distance);
    c.drawLine(tip, tip + turned(back, .6) * 4, line(color));
    c.drawLine(tip, tip + turned(back, -.6) * 4, line(color));
  }

  static const _outline = [
    Offset(-1, -1),
    Offset(.45, -1),
    Offset(1, -.45),
    Offset(1, 1),
    Offset(-1, 1),
  ];

  void object(Canvas c) {
    final front = Path()
      ..addPolygon([
        for (final p in _outline)
          g.world(Offset(p.dx * g.half.dx, p.dy * g.half.dy)),
      ], true);
    final body = ink(TransformZone.move);
    c.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          colors: [body, Color.lerp(body, const Color(0xFF8FE3FF), .55)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(front.getBounds()),
    );
    // The corner cut off where the layer's up and right are, in the window's accent, so a turn or a flip reads at once.
    c.drawPath(
      Path()..addPolygon([
        for (final p in const [Offset(.45, -1), Offset(1, -1), Offset(1, -.45)])
          g.world(Offset(p.dx * g.half.dx, p.dy * g.half.dy)),
      ], true),
      fill(Accent.fill),
    );
    if (hot != TransformZone.move) return;
    final reach = math.min(g.half.dx.abs(), g.half.dy.abs()) * .7;
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      final from = g.center + d * (reach * .6), tip = g.center + d * reach;
      c.drawLine(from, tip, line(Grey.g100, 1.5));
      arrowHead(c, tip, from, Grey.g100);
    }
  }

  /// The Z rail: a large square at the near end, a small one at the far end, the knob between.
  void rail(Canvas c, Size size) {
    final x = g.railX,
        top = size.height / 2 - g.railHalf,
        bottom = size.height / 2 + g.railHalf;
    c.drawLine(Offset(x, top + 6), Offset(x, bottom - 4), line(Grey.g26, 2));
    c.drawLine(
      Offset(x - 3, size.height / 2),
      Offset(x + 3, size.height / 2),
      line(Grey.g38),
    );
    final end = line(g.deep ? Grey.g56 : Grey.g26);
    c.drawRect(
      Rect.fromCenter(center: Offset(x, top), width: 8, height: 8),
      end,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(x, bottom), width: 3, height: 3),
      end,
    );
    if (!g.deep) return; // In 2D there is no depth to pull; the rail only shows where it would be.
    final lift = ink(TransformZone.lift);
    c.drawLine(Offset(x, size.height / 2), g.liftKnob, line(lift, 2));
    c.drawCircle(g.liftKnob, hot == TransformZone.lift ? 6 : 5, fill(lift));
  }

  void tilt(Canvas c, int axis) {
    final color = tiltInk(axis), k = g.tiltKnob(axis);
    c.drawLine(g.tiltBase(axis), k, line(color, 1.5));
    final on = hot == TransformZone.rotate && hotIndex == axis;
    final r = Rect.fromCenter(
      center: k,
      width: axis == 1 ? 7 : (on ? 13 : 11),
      height: axis == 1 ? (on ? 13 : 11) : 7,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3.5)),
      fill(color),
    );
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.drawRect(Offset.zero & size, fill(Grey.g07));
    final f = g.frame;
    c.drawRect(f, line(Grey.g38));
    c.drawLine(f.topCenter, f.bottomCenter, line(Grey.g15));
    c.drawLine(f.centerLeft, f.centerRight, line(Grey.g15));
    final guide = ink(TransformZone.move)
        .withValues(alpha: hot == TransformZone.move ? .8 : .28);
    c.drawLine(Offset(g.pivot.dx, f.top), g.pivot, line(guide));
    c.drawLine(Offset(f.left, g.pivot.dy), g.pivot, line(guide));
    rail(c, size);
    object(c);

    final scale = ink(TransformZone.scale),
        scaleHot = hot == TransformZone.scale;
    c.drawPath(
      Path()..addPolygon(g.corners, true),
      line(scale.withValues(alpha: scaleHot ? 1 : .45)),
    );
    if (linked && scaleHot) {
      c.drawLine(g.corners[0], g.corners[2], line(scale.withValues(alpha: .5)));
    }
    for (final (i, p) in g.handles.indexed) {
      final side =
          (i < 4 ? PreviewSize.handle : PreviewSize.handle - 2) +
          (scaleHot ? 2 : 0);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: side, height: side),
          const Radius.circular(1.5),
        ),
        fill(scale),
      );
    }
    if (g.deep) {
      tilt(c, 1);
      tilt(c, 2);
    }

    final rotate = tiltInk(0);
    c.drawLine(g.stemBase, g.knob, line(rotate, 1.5));
    c.drawCircle(
      g.knob,
      PreviewSize.knob +
          (hot == TransformZone.rotate && hotIndex == 0 ? 1.5 : 0),
      fill(rotate),
    );
    const sweep = math.pi * 1.2;
    final start = g.angle - math.pi / 2 + .5, endA = start + sweep;
    c.drawArc(
      Rect.fromCircle(center: g.knob, radius: PreviewSize.turnArc),
      start,
      sweep,
      false,
      line(rotate, 1.5),
    );
    final tip =
        g.knob + Offset(math.cos(endA), math.sin(endA)) * PreviewSize.turnArc;
    arrowHead(
      c,
      tip,
      tip - Offset(-math.sin(endA), math.cos(endA)) * 4,
      rotate,
    );

    final pivot = ink(TransformZone.pivot),
        p = g.pivot,
        r = hot == TransformZone.pivot ? 6.0 : 4.5;
    c.drawCircle(p, r + 1.5, fill(Grey.g07));
    c.drawCircle(p, r, line(pivot, 2));
    c.drawCircle(p, 1.5, fill(pivot));
    if (hot == TransformZone.rotate && (hotIndex ?? 0) == 0) {
      c.drawCircle(
        p,
        (g.knob - p).distance,
        line(rotate.withValues(alpha: .35)),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_PreviewPaint old) =>
      !mapEquals(old.g.values, g.values) ||
      old.g.size != g.size ||
      old.g.deep != g.deep ||
      old.hot != hot ||
      old.hotIndex != hotIndex ||
      old.linked != linked;
}
