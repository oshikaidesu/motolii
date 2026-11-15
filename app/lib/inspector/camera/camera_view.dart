// The Camera card's 3-D picture: FOV cone, focus plane, DOF band, position and
// rotation in one draggable orthographic view.  Follows the same pattern as
// AnchorBox (anchor_box.dart): a CustomPaint with a yaw/pitch orbit camera.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/tokens.dart';

// The parameter ids watched for the picture.  Position and rotation come from
// the card's own rows; the lens values come from the Lens card merged in.
const _watched = {
  'v_x',
  'v_y',
  'v_z',
  'v_rotate_x',
  'v_rotate_y',
  'v_rotate',
  'v_focal_length',
  'v_projection',
  'v_shift_x',
  'v_shift_y',
  'v_focus',
  'v_aperture',
};

/// The Camera card's picture: a live 3-D diagram of the camera.
/// Drag to orbit; double-tap to reset the view.
class CameraBody extends StatelessWidget {
  const CameraBody(this.card, {super.key});
  final CardDeclaration card;

  /// Values shown in the picture rather than as number blocks below it.
  static const drawn = {
    'x',
    'y',
    'z',
    'rotate_x',
    'rotate_y',
    'rotate',
    'focal_length',
    'projection',
    'shift_x',
    'shift_y',
    'focus',
    'aperture',
  };

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return ListenableBuilder(
      listenable: Listenable.merge([for (final id in _watched) doc.watch(id)]),
      builder: (context, _) => _CamBox(
        posX: doc.get('v_x') ?? 0.0,
        posY: doc.get('v_y') ?? 0.0,
        posZ: doc.get('v_z') ?? 0.0,
        rotateX: doc.get('v_rotate_x') ?? 0.0,
        rotateY: doc.get('v_rotate_y') ?? 0.0,
        rotate: doc.get('v_rotate') ?? 0.0,
        focalMm: doc.get('v_focal_length') ?? 45.0,
        ortho: (doc.get('v_projection') ?? 0) > 0.5,
        shiftX: doc.get('v_shift_x') ?? 0.0,
        shiftY: doc.get('v_shift_y') ?? 0.0,
        focusPx: doc.get('v_focus') ?? 0.0,
        aperture: doc.get('v_aperture') ?? 0.0,
      ),
    );
  }
}

// ── stateful shell ──────────────────────────────────────────────────────────

class _CamBox extends StatefulWidget {
  const _CamBox({
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.rotateX,
    required this.rotateY,
    required this.rotate,
    required this.focalMm,
    required this.ortho,
    required this.shiftX,
    required this.shiftY,
    required this.focusPx,
    required this.aperture,
  });
  final double posX, posY, posZ;
  final double rotateX, rotateY, rotate;
  final double focalMm, shiftX, shiftY, focusPx, aperture;
  final bool ortho;

  @override
  State<_CamBox> createState() => _CamBoxState();
}

class _CamBoxState extends State<_CamBox> {
  // Initial viewpoint: front-right, slightly above.
  double _yaw = 0.7, _pitch = 0.4;
  bool _dragging = false;

  static double get height => Shape.z(130);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (_, box) {
        final size = Size(box.maxWidth, height);
        return GestureDetector(
          onDoubleTap: () => setState(() {
            _yaw = 0.7;
            _pitch = 0.4;
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
                size: size,
                painter: _CamPaint(
                  yaw: _yaw,
                  pitch: _pitch,
                  posX: widget.posX,
                  posY: widget.posY,
                  posZ: widget.posZ,
                  rotateX: widget.rotateX,
                  rotateY: widget.rotateY,
                  rotate: widget.rotate,
                  focalMm: widget.focalMm,
                  ortho: widget.ortho,
                  shiftX: widget.shiftX,
                  shiftY: widget.shiftY,
                  focusPx: widget.focusPx,
                  aperture: widget.aperture,
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

class _CamPaint extends CustomPainter {
  const _CamPaint({
    required this.yaw,
    required this.pitch,
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.rotateX,
    required this.rotateY,
    required this.rotate,
    required this.focalMm,
    required this.ortho,
    required this.shiftX,
    required this.shiftY,
    required this.focusPx,
    required this.aperture,
  });

  final double yaw, pitch;
  final double posX, posY, posZ;
  final double rotateX, rotateY, rotate;
  final double focalMm, shiftX, shiftY, focusPx, aperture;
  final bool ortho;

  Paint _line(Color col, [double w = 1.0]) => Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  Paint _fill(Color col) => Paint()..color = col;

  @override
  void paint(Canvas canvas, Size s) {
    // FOV first — needed to fit the frustum in view.
    final tanV = math.tan(math.atan(12.0 / math.max(focalMm, 1.0)));
    final tanH = tanV * (16.0 / 9.0);

    final scale = math.min(s.height / 4.5, s.width / 7.0);
    final centre = s.center(Offset.zero);
    Offset p(double x, double y, double z) {
      final rx = x * math.cos(yaw) + z * math.sin(yaw);
      final rz = -x * math.sin(yaw) + z * math.cos(yaw);
      final ry = y * math.cos(pitch) - rz * math.sin(pitch);
      return centre + Offset(rx, ry) * scale;
    }

    // Ground grid on the XZ plane.
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        p(i.toDouble(), 0, -3),
        p(i.toDouble(), 0, 3),
        _line(Grey.g20),
      );
      canvas.drawLine(
        p(-3, 0, i.toDouble()),
        p(3, 0, i.toDouble()),
        _line(Grey.g20),
      );
    }

    // Camera orientation: pan (Y) then tilt (X) then roll (Z).
    final panR = rotateY * math.pi / 180;
    final tiltR = rotateX * math.pi / 180;
    final rollR = rotate * math.pi / 180;

    final fwd = _rot3(0, 0, -1, panR, tiltR, 0);
    final upV = _rot3(0, 1, 0, panR, tiltR, rollR);
    final rt = _cross(fwd, upV);

    // The diagram shows frustum shape, rotation, focus and DOF.
    // The camera body stays at the diagram centre regardless of world position.
    const cam = (0.0, 0.0, 0.0);

    // Clamp farD so the frustum corners stay inside the widget for any FOV.
    final farD = math
        .min(
          2.5,
          math.min(
            s.width * 0.38 / (tanH * scale),
            s.height * 0.44 / (tanV * scale),
          ),
        )
        .clamp(0.3, 2.5);
    final nearD = (farD * 0.1).clamp(0.05, 0.3);

    // Focus distance: canvas-px → scene units.
    final focusD = focusPx > 0
        ? (focusPx / 300.0).clamp(nearD + 0.02, farD + 0.3)
        : farD;

    // Depth-of-field half-width (thin-lens approximation).
    double dofHalf = 0;
    if (aperture > 0 && focusPx > 0) {
      const c = 4.0;
      final h = focalMm * focalMm / (aperture * c);
      final near = focusPx * (h - focalMm) / (h + focusPx - 2 * focalMm);
      dofHalf = (focusPx - near).abs() / 300.0;
      dofHalf = dofHalf.clamp(0, farD * 0.6);
    }

    // Lens shift in scene units.
    final sx = shiftX * tanH;
    final sy = -shiftY * tanV;

    List<Offset> plane(double d) {
      final hw = ortho ? tanH : tanH * d;
      final hv = ortho ? tanV : tanV * d;
      return [
        _camPt(p, cam, fwd, rt, upV, d, -hw + sx, -hv + sy),
        _camPt(p, cam, fwd, rt, upV, d, hw + sx, -hv + sy),
        _camPt(p, cam, fwd, rt, upV, d, hw + sx, hv + sy),
        _camPt(p, cam, fwd, rt, upV, d, -hw + sx, hv + sy),
      ];
    }

    final nearPts = plane(nearD);
    final farPts = plane(farD);
    final focPts = plane(focusD);

    final camPt = p(cam.$1, cam.$2, cam.$3);
    final accentCol = Accent.fill;
    final coneCol = Grey.g38;

    // Frustum rays (camera → far corners).
    for (final pt in farPts) {
      canvas.drawLine(camPt, pt, _line(coneCol.withValues(alpha: .55)));
    }

    // Near plane.
    _quad(canvas, nearPts, _line(coneCol.withValues(alpha: .4)));

    // DOF band.
    if (dofHalf > 0) {
      final dofNearPts = plane((focusD - dofHalf).clamp(nearD, farD));
      final dofFarPts = plane((focusD + dofHalf).clamp(nearD, farD + 0.3));
      _sideFill(
        canvas,
        dofNearPts,
        dofFarPts,
        _fill(accentCol.withValues(alpha: .10)),
      );
      _quad(canvas, dofNearPts, _line(Grey.g44, .8));
      _quad(canvas, dofFarPts, _line(Grey.g44, .8));
    }

    // Focus plane.
    _quadFill(canvas, focPts, _fill(accentCol.withValues(alpha: .18)));
    _quad(canvas, focPts, _line(accentCol, 1.3));

    // Far plane.
    _quad(canvas, farPts, _line(coneCol.withValues(alpha: .35)));

    // Camera body at the diagram centre, honoring roll.
    _drawBody(p, canvas, cam, fwd, rt, upV);
  }

  // 3-D point on the frustum at depth d, offset (u, v) in the focal plane.
  Offset _camPt(
    Offset Function(double, double, double) proj,
    (double, double, double) o,
    (double, double, double) f,
    (double, double, double) r,
    (double, double, double) u,
    double d,
    double uh,
    double vh,
  ) => proj(
    o.$1 + f.$1 * d + r.$1 * uh + u.$1 * vh,
    o.$2 + f.$2 * d + r.$2 * uh + u.$2 * vh,
    o.$3 + f.$3 * d + r.$3 * uh + u.$3 * vh,
  );

  // Draw a quad outline.
  void _quad(Canvas c, List<Offset> pts, Paint p) {
    for (int i = 0; i < 4; i++) {
      c.drawLine(pts[i], pts[(i + 1) % 4], p);
    }
  }

  // Fill a quad.
  void _quadFill(Canvas c, List<Offset> pts, Paint p) =>
      c.drawPath(Path()..addPolygon(pts, true), p);

  // Fill the four side faces between two parallel quads.
  void _sideFill(Canvas c, List<Offset> a, List<Offset> b, Paint p) {
    for (int i = 0; i < 4; i++) {
      c.drawPath(
        Path()..addPolygon([a[i], a[(i + 1) % 4], b[(i + 1) % 4], b[i]], true),
        p,
      );
    }
  }

  // Camera body icon: rectangle (body) + dot (lens front).
  void _drawBody(
    Offset Function(double, double, double) proj,
    Canvas c,
    (double, double, double) pos,
    (double, double, double) fwd,
    (double, double, double) rt,
    (double, double, double) upV,
  ) {
    final o = proj(pos.$1, pos.$2, pos.$3);
    final u =
        proj(
          pos.$1 + upV.$1 * .32,
          pos.$2 + upV.$2 * .32,
          pos.$3 + upV.$3 * .32,
        ) -
        o;
    final r =
        proj(pos.$1 + rt.$1 * .42, pos.$2 + rt.$2 * .42, pos.$3 + rt.$3 * .42) -
        o;
    final corners = [o - u + r, o + u + r, o + u - r, o - u - r];
    final body = Path()..addPolygon(corners, true);
    c.drawPath(body, _fill(Grey.g20));
    c.drawPath(body, _line(Grey.g76, 1.5));

    // Accent corner marks "up and right" so roll is readable.
    c.drawPath(
      Path()..addPolygon([o + u - r, o + u + r * .4, o - u * .4 + r], true),
      _fill(Accent.fill),
    );

    // Lens dot in front of the body.
    final lens = proj(
      pos.$1 + fwd.$1 * .35,
      pos.$2 + fwd.$2 * .35,
      pos.$3 + fwd.$3 * .35,
    );
    c.drawCircle(lens, 5.5, _fill(Grey.g13));
    c.drawCircle(lens, 5.5, _line(Grey.g76, 1.5));
    c.drawCircle(lens, 2.0, _fill(Grey.g76));
    c.drawLine(o, lens, _line(Grey.g44, 1));
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
    // Pan (Y-axis)
    var rx = x * math.cos(panR) + z * math.sin(panR);
    var ry = y;
    var rz = -x * math.sin(panR) + z * math.cos(panR);
    // Tilt (X-axis)
    final ty = ry * math.cos(tiltR) - rz * math.sin(tiltR);
    final tz = ry * math.sin(tiltR) + rz * math.cos(tiltR);
    ry = ty;
    rz = tz;
    // Roll (Z-axis)
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
  bool shouldRepaint(_CamPaint o) =>
      o.yaw != yaw ||
      o.pitch != pitch ||
      o.posX != posX ||
      o.posY != posY ||
      o.posZ != posZ ||
      o.rotateX != rotateX ||
      o.rotateY != rotateY ||
      o.rotate != rotate ||
      o.focalMm != focalMm ||
      o.ortho != ortho ||
      o.shiftX != shiftX ||
      o.shiftY != shiftY ||
      o.focusPx != focusPx ||
      o.aperture != aperture;
}
