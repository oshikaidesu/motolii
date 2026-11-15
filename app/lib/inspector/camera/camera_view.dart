// The Camera card's picture: a small orientation gimbal showing which way the
// camera looks (pan + tilt) and how it is rolled.  Where the camera is and its
// numbers live on the Transform card; the lens values stay as blocks on this
// card.  This picture only reads the three rotation values.  Drag to orbit the
// view; double-tap to reset.  Follows the orbit pattern of AnchorBox.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/tokens.dart';

// Only the rotation values drive the picture.
const _watched = {'v_rotate_x', 'v_rotate_y', 'v_rotate'};

/// The Camera card's picture: a live gimbal of where the camera points.
/// Drag to orbit; double-tap to reset the view.
class CameraBody extends StatelessWidget {
  const CameraBody(this.card, {super.key});
  final CardDeclaration card;

  /// The picture reads rotation but replaces no block: every lens value on the
  /// card still shows as its own number below.
  static const drawn = <String>{};

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return ListenableBuilder(
      listenable: Listenable.merge([for (final id in _watched) doc.watch(id)]),
      builder: (context, _) => _Gimbal(
        rotateX: doc.get('v_rotate_x') ?? 0.0,
        rotateY: doc.get('v_rotate_y') ?? 0.0,
        rotate: doc.get('v_rotate') ?? 0.0,
      ),
    );
  }
}

// ── stateful shell ──────────────────────────────────────────────────────────

class _Gimbal extends StatefulWidget {
  const _Gimbal({
    required this.rotateX,
    required this.rotateY,
    required this.rotate,
  });
  final double rotateX, rotateY, rotate;

  @override
  State<_Gimbal> createState() => _GimbalState();
}

class _GimbalState extends State<_Gimbal> {
  // Initial viewpoint: front-right, slightly above.
  double _yaw = 0.7, _pitch = 0.5;
  bool _dragging = false;

  static double get height => Shape.z(104);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (_, box) {
        return GestureDetector(
          onDoubleTap: () => setState(() {
            _yaw = 0.7;
            _pitch = 0.5;
          }),
          child: Listener(
            onPointerDown: (e) {
              if (e.buttons != kPrimaryButton) return;
              setState(() => _dragging = true);
            },
            onPointerMove: (e) {
              if (!_dragging) return;
              setState(() {
                _yaw += e.delta.dx * .013;
                _pitch = (_pitch + e.delta.dy * .013).clamp(-1.4, 1.4);
              });
            },
            onPointerUp: (_) => setState(() => _dragging = false),
            onPointerCancel: (_) => setState(() => _dragging = false),
            child: MouseRegion(
              cursor: _dragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              child: CustomPaint(
                size: Size(box.maxWidth, height),
                painter: _GimbalPaint(
                  yaw: _yaw,
                  pitch: _pitch,
                  rotateX: widget.rotateX,
                  rotateY: widget.rotateY,
                  rotate: widget.rotate,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ── painter ─────────────────────────────────────────────────────────────────

class _GimbalPaint extends CustomPainter {
  const _GimbalPaint({
    required this.yaw,
    required this.pitch,
    required this.rotateX,
    required this.rotateY,
    required this.rotate,
  });

  final double yaw, pitch;
  final double rotateX, rotateY, rotate;

  Paint _line(Color col, [double w = 1.0]) => Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color col) => Paint()..color = col;

  @override
  void paint(Canvas canvas, Size s) {
    final scale = math.min(s.height, s.width) * 0.33;
    final centre = s.center(Offset.zero);
    Offset p(double x, double y, double z) {
      final rx = x * math.cos(yaw) + z * math.sin(yaw);
      final rz = -x * math.sin(yaw) + z * math.cos(yaw);
      final ry = y * math.cos(pitch) - rz * math.sin(pitch);
      return centre + Offset(rx, ry) * scale;
    }

    // Horizontal reference ring on the ground plane, so the orbit reads as 3-D.
    const n = 48;
    final ring = <Offset>[
      for (int i = 0; i <= n; i++)
        p(math.cos(i / n * 2 * math.pi), 0, math.sin(i / n * 2 * math.pi)),
    ];
    final ringPath = Path()..addPolygon(ring, false);
    canvas.drawPath(ringPath, _line(Grey.g20));
    // The two ground axes and the world up, as a faint frame.
    canvas.drawLine(p(-1, 0, 0), p(1, 0, 0), _line(Grey.g20));
    canvas.drawLine(p(0, 0, -1), p(0, 0, 1), _line(Grey.g20));
    canvas.drawLine(p(0, 0, 0), p(0, -1, 0), _line(Grey.g26));

    // Camera orientation: pan (Y) then tilt (X) then roll (Z).
    final panR = rotateY * math.pi / 180;
    final tiltR = rotateX * math.pi / 180;
    final rollR = rotate * math.pi / 180;
    final fwd = _rot3(0, 0, -1, panR, tiltR, 0);
    final upV = _rot3(0, 1, 0, panR, tiltR, rollR);
    final rt = _cross(fwd, upV);

    final o = p(0, 0, 0);

    // Camera body: a small square facing forward, tilted by roll.
    final u = p(upV.$1 * .26, upV.$2 * .26, upV.$3 * .26) - o;
    final r = p(rt.$1 * .34, rt.$2 * .34, rt.$3 * .34) - o;
    final body = Path()
      ..addPolygon([o - u + r, o + u + r, o + u - r, o - u - r], true);
    canvas.drawPath(body, _fill(Grey.g20));
    canvas.drawPath(body, _line(Grey.g76, 1.4));
    // A tick on the top edge marks "up", so roll is readable.
    canvas.drawLine(o, o + u * 1.5, _line(Grey.g56, 1.2));

    // Forward arrow: the hero — which way the lens looks.
    final tip = p(fwd.$1 * 1.15, fwd.$2 * 1.15, fwd.$3 * 1.15);
    canvas.drawLine(o, tip, _line(Accent.fill, 2.0));
    // Arrowhead, built from the camera's own right and up so it faces the view.
    final back = p(fwd.$1 * .92, fwd.$2 * .92, fwd.$3 * .92);
    final headR =
        (p(fwd.$1 + rt.$1 * .16, fwd.$2 + rt.$2 * .16, fwd.$3 + rt.$3 * .16) -
        p(fwd.$1, fwd.$2, fwd.$3));
    final headU =
        (p(
          fwd.$1 + upV.$1 * .16,
          fwd.$2 + upV.$2 * .16,
          fwd.$3 + upV.$3 * .16,
        ) -
        p(fwd.$1, fwd.$2, fwd.$3));
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + headR.dx + headU.dx, back.dy + headR.dy + headU.dy)
      ..lineTo(back.dx - headR.dx - headU.dx, back.dy - headR.dy - headU.dy)
      ..close();
    canvas.drawPath(head, _fill(Accent.fill));

    // Lens dot where the arrow leaves the body.
    final lens = p(fwd.$1 * .3, fwd.$2 * .3, fwd.$3 * .3);
    canvas.drawCircle(lens, 2.4, _fill(Grey.g13));
    canvas.drawCircle(lens, 2.4, _line(Grey.g76, 1.2));
  }

  // Rotate (x,y,z) by pan around Y, tilt around X, roll around Z.
  (double, double, double) _rot3(
    double x,
    double y,
    double z,
    double panR,
    double tiltR,
    double rollR,
  ) {
    var rx = x * math.cos(panR) + z * math.sin(panR);
    var ry = y;
    var rz = -x * math.sin(panR) + z * math.cos(panR);
    final ty = ry * math.cos(tiltR) - rz * math.sin(tiltR);
    final tz = ry * math.sin(tiltR) + rz * math.cos(tiltR);
    ry = ty;
    rz = tz;
    final lx = rx * math.cos(rollR) - ry * math.sin(rollR);
    final ly = rx * math.sin(rollR) + ry * math.cos(rollR);
    return (lx, ly, rz);
  }

  (double, double, double) _cross(
    (double, double, double) a,
    (double, double, double) b,
  ) => (
    a.$2 * b.$3 - a.$3 * b.$2,
    a.$3 * b.$1 - a.$1 * b.$3,
    a.$1 * b.$2 - a.$2 * b.$1,
  );

  @override
  bool shouldRepaint(_GimbalPaint o) =>
      o.yaw != yaw ||
      o.pitch != pitch ||
      o.rotateX != rotateX ||
      o.rotateY != rotateY ||
      o.rotate != rotate;
}
