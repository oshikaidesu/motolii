// The Anchor fold of the Transform card: the layer as a box with 27 points to put the anchor on, and its X / Y / Z.
// Restored from 52289b693~1 (inspector_anchor.dart), drawn inside the card's standard Anchor fold.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/transform/transform_canvas.dart'
    show transformHot;
import 'package:motolii/inspector/transform/transform_layout.dart';
import 'package:motolii/inspector/transform/transform_rows.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

const _ids = ['v_anchor_x', 'v_anchor_y', 'v_anchor_z'];
const _spots = [
  'Top left',
  'Top',
  'Top right',
  'Left',
  'Centre',
  'Right',
  'Bottom left',
  'Bottom',
  'Bottom right',
];
const _depths = {-50: 'Front', 0: 'Middle', 50: 'Back'};

/// The anchor's place in words: one of the 27 points, or Custom between or outside them.
String anchorName(double x, double y, double z) {
  final onGrid =
      x % 50 == 0 &&
      y % 50 == 0 &&
      z % 50 == 0 &&
      x >= 0 &&
      x <= 100 &&
      y >= 0 &&
      y <= 100 &&
      z.abs() <= 50;
  return onGrid
      ? '${_spots[(y ~/ 50) * 3 + x ~/ 50]} · ${_depths[z.toInt()]}'
      : 'Custom';
}

/// What the Anchor fold holds: the box, the anchor's name, and its X / Y / Z under the axis heading.
class AnchorFold extends StatelessWidget {
  const AnchorFold(this.card, {super.key});
  final CardDeclaration card;

  /// The values drawn here.
  static const drawn = {'anchor_x', 'anchor_y', 'anchor_z'};

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = {for (final p in card.params) 'v_${p.id}': p};
    return ListenableBuilder(
      listenable: Listenable.merge([for (final id in _ids) doc.watch(id)]),
      builder: (context, _) {
        final at = (
          doc.get(_ids[0]) ?? 50,
          doc.get(_ids[1]) ?? 50,
          doc.get(_ids[2]) ?? 0,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnchorBox(at),
            Center(
              child: Text(
                anchorName(at.$1, at.$2, at.$3),
                key: const ValueKey('anchor:name'),
                style: TextStyles.label(Grey.g63),
              ),
            ),
            SizedBox(height: InspectorSkin.titleGap),
            const AxisHeader(),
            TransformRow(
              mark: (c, s) => _drawPad(
                c,
                s,
                transformHot.value == TransformZone.pivot.id
                    ? TransformZone.pivot.color
                    : Grey.g76,
              ),
              hot: TransformZone.pivot,
              label: 'Anchor',
              unit: params[_ids[0]]?.unit ?? '',
              cells: [
                for (final id in _ids)
                  if (params.containsKey(id)) axisField(params, doc, id),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The row mark: the layer as a small box with the anchor ring inside.
void _drawPad(Canvas c, Size s, Color ink) {
  final box = Rect.fromCenter(
    center: s.center(Offset.zero),
    width: 18,
    height: 13,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(box, const Radius.circular(2)),
    Paint()
      ..color = Grey.g44
      ..style = PaintingStyle.stroke,
  );
  c.drawCircle(
    box.center,
    3.2,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
  c.drawCircle(box.center, 1, Paint()..color = ink);
}

/// The box seen orthographically from a viewpoint the user turns; the first angle keeps all 27 points about 20 px apart.
class AnchorView {
  AnchorView(Size s, {this.yaw = firstYaw, this.pitch = firstPitch})
    : centre = s.center(Offset.zero);
  final Offset centre;
  final double yaw, pitch;
  static const unit = 29.0,
      firstYaw = 21 * math.pi / 180,
      firstPitch = 34 * math.pi / 180;
  static const steps = [0.0, 50.0, 100.0], depths = [50.0, 0.0, -50.0];

  (double, double, double) _view(double x, double y, double z) {
    final u = (x - 50) / 50, v = (y - 50) / 50, w = z / 50;
    final rx = u * math.cos(yaw) + w * math.sin(yaw),
        rz = -u * math.sin(yaw) + w * math.cos(yaw);
    return (
      rx,
      v * math.cos(pitch) - rz * math.sin(pitch),
      v * math.sin(pitch) + rz * math.cos(pitch),
    );
  }

  Offset at(double x, double y, double z) {
    final (sx, sy, _) = _view(x, y, z);
    return centre + Offset(sx, sy) * unit;
  }

  /// Larger is farther from the eye.
  double depth(double x, double y, double z) => _view(x, y, z).$3;

  /// Far to near, so nearer points paint over farther ones.
  List<(double, double, double)> get points => [
    for (final z in depths)
      for (final y in steps)
        for (final x in steps) (x, y, z),
  ]..sort((a, b) => depth(b.$1, b.$2, b.$3).compareTo(depth(a.$1, a.$2, a.$3)));

  /// The point within 8 px of [p], the nearest first.
  (double, double, double)? pick(Offset p) {
    (double, double, double)? best;
    var bestD = 8.0;
    for (final q in points) {
      final d = (at(q.$1, q.$2, q.$3) - p).distance;
      if (d <= bestD) (best, bestD) = (q, d);
    }
    return best;
  }
}

/// A click on a point puts the anchor there, one undo step. A drag anywhere turns the box to look and never edits;
/// a double click squares the view again.
class AnchorBox extends StatefulWidget {
  const AnchorBox(this.at, {super.key});

  /// Where the anchor is now: X and Y from 0 to 100 across the layer, Z from -50 (front) to 50 (back).
  final (double, double, double) at;
  static double get height => Shape.z(116.0);
  @override
  State<AnchorBox> createState() => _AnchorBoxState();
}

class _AnchorBoxState extends State<AnchorBox> {
  (double, double, double)? _near;
  double _yaw = AnchorView.firstYaw, _pitch = AnchorView.firstPitch;
  Offset? _down;
  bool _turning = false;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc, at = widget.at;
    return ValueListenableBuilder(
      valueListenable: transformHot,
      builder: (context, lit, _) => LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, AnchorBox.height);
          final g = AnchorView(size, yaw: _yaw, pitch: _pitch);
          final hot = lit == TransformZone.pivot.id;
          return Semantics(
            label: 'Anchor: ${anchorName(at.$1, at.$2, at.$3)}',
            child: MouseRegion(
              cursor: _turning
                  ? SystemMouseCursors.grabbing
                  : (_near != null
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.grab),
              onHover: (e) {
                final n = g.pick(e.localPosition);
                if (n != _near) setState(() => _near = n);
                if (!hot) transformHot.value = TransformZone.pivot.id;
              },
              onExit: (_) {
                setState(() => _near = null);
                if (hot) transformHot.value = null;
              },
              child: Listener(
                onPointerDown: (e) {
                  if (e.buttons != kPrimaryButton) return;
                  _down = e.localPosition;
                  _turning = false;
                },
                onPointerMove: (e) {
                  final d = _down;
                  if (d == null) return;
                  if (!_turning && (e.localPosition - d).distance < 4) return;
                  setState(() {
                    _turning = true;
                    _near = null;
                    _yaw += e.delta.dx * .012;
                    _pitch = (_pitch + e.delta.dy * .012).clamp(-1.45, 1.45);
                  });
                },
                onPointerUp: (e) {
                  final d = _down;
                  _down = null;
                  if (_turning) return setState(() => _turning = false);
                  final q = d == null ? null : g.pick(e.localPosition);
                  if (q == null) return;
                  doc
                    ..beginGesture()
                    ..setMany({_ids[0]: q.$1, _ids[1]: q.$2, _ids[2]: q.$3})
                    ..endGesture();
                },
                onPointerCancel: (_) {
                  _down = null;
                  if (_turning) setState(() => _turning = false);
                },
                child: GestureDetector(
                  onDoubleTap: () => setState(() {
                    _yaw = AnchorView.firstYaw;
                    _pitch = AnchorView.firstPitch;
                  }),
                  child: CustomPaint(
                    key: const ValueKey('anchor-box'),
                    size: size,
                    painter: _BoxPaint(g, at, _near, hot),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoxPaint extends CustomPainter {
  const _BoxPaint(this.g, this.at, this.near, this.hot);
  final AnchorView g;
  final (double, double, double) at;
  final (double, double, double)? near;
  final bool hot;

  @override
  void paint(Canvas c, Size s) {
    Offset p(double x, double y, double z) => g.at(x, y, z);
    Path plate(double z) => Path()
      ..addPolygon([
        p(0, 0, z),
        p(100, 0, z),
        p(100, 100, z),
        p(0, 100, z),
      ], true);
    Paint line(Color col, [double w = 1]) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    final pivot = TransformZone.pivot.color;

    // The edges shade by distance: the far ones recede.
    for (final a in const [0.0, 100.0]) {
      for (final b in const [0.0, 100.0]) {
        for (final (from, to, d) in [
          (p(0, a, b - 50), p(100, a, b - 50), g.depth(50, a, b - 50)),
          (p(a, 0, b - 50), p(a, 100, b - 50), g.depth(a, 50, b - 50)),
          (p(a, b, -50), p(a, b, 50), g.depth(a, b, 0)),
        ]) {
          c.drawLine(
            from,
            to,
            line(
              Color.lerp(Grey.g63, Grey.g26, ((d + 1.2) / 2.4).clamp(0, 1))!,
            ),
          );
        }
      }
    }

    // The plane the anchor lies in, and the line from it to the front face.
    if (at.$3 > -50) {
      final cut = plate(at.$3);
      c.drawPath(cut, Paint()..color = pivot.withValues(alpha: .16));
      c.drawPath(cut, line(pivot.withValues(alpha: .6)));
      final f = p(at.$1, at.$2, -50);
      c.drawLine(p(at.$1, at.$2, at.$3), f, line(pivot.withValues(alpha: .55)));
      c.drawCircle(f, 1.6, Paint()..color = pivot.withValues(alpha: .55));
    }

    // The front face is the layer, in the preview's colours.
    final front = plate(-50);
    c.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TransformZone.move.color.withValues(alpha: .34),
            TransformZone.lift.color.withValues(alpha: .16),
          ],
        ).createShader(front.getBounds()),
    );
    c.drawPath(front, line(TransformZone.lift.color.withValues(alpha: .7)));

    for (final q in g.points) {
      final isNear = q == near,
          k = ((g.depth(q.$1, q.$2, q.$3) + 1.2) / 2.4).clamp(0.0, 1.0);
      c.drawCircle(
        p(q.$1, q.$2, q.$3),
        (isNear ? 1.4 : 0) + 2.6 - k * 1.2,
        Paint()..color = isNear ? Grey.g95 : Color.lerp(Grey.g76, Grey.g38, k)!,
      );
    }

    final ink = hot ? pivot : Grey.g95, m = p(at.$1, at.$2, at.$3);
    c.drawCircle(m, 7, Paint()..color = Grey.g07);
    c.drawCircle(m, 7, line(ink, 1.6));
    c.drawCircle(m, 2, Paint()..color = ink);

    final tp = TextPainter(
      text: TextSpan(
        text: 'FRONT',
        style: TextStyles.micro(TransformZone.lift.color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final base = p(50, 100, -50), up = p(50, 0, -50);
    if ((base - up).distance > 1) {
      tp.paint(
        c,
        base +
            (base - up) / (base - up).distance * 10 -
            Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_BoxPaint o) =>
      o.at != at ||
      o.near != near ||
      o.hot != hot ||
      o.g.yaw != g.yaw ||
      o.g.pitch != g.pitch ||
      o.g.centre != g.centre;
}
