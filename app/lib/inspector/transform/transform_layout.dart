// Where the Transform preview draws a layer and what a drag on it changes. Restored from 52289b693~1
// (inspector_direct_transform_layout.dart), the depth slab left out: no Transform value is a thickness.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/theme.dart';

/// What a point of the preview grabs. Each part edits one Transform row and wears that row's colour on both.
/// The colours are the skin's handle roles (`shelves/skins/*/theme.xml`).
enum TransformZone {
  move('v_x', 'HandleMove', Color(0xFF3D6BFF)),
  scale('v_scale_x', 'HandleScale', Color(0xFFB3C66B)),
  rotate('v_rotate', 'HandleRotate', Color(0xFFFF6A2B)),
  pivot('v_anchor_x', 'HandlePivot', Color(0xFFB57CFF)),
  lift('v_z', 'HandleLift', Color(0xFF8FB0FF));

  const TransformZone(this.id, this.role, this.usual);

  /// The first value the part edits; its row lights while the part is hovered or held.
  final String id;
  final String role;
  final Color usual;
  Color get color => ColorTheme.of(role, usual);
}

/// The axis colours, Blender's names for them.
Color get axisX => ColorTheme.of('AxisX', const Color(0xFFE974AB));
Color get axisY => ColorTheme.of('AxisY', const Color(0xFF7DD5B1));
Color get axisZ => ColorTheme.of('AxisZ', const Color(0xFF4781E5));

/// Sizes of the preview's parts, in logical pixels.
abstract final class PreviewSize {
  static const height = 108.0, objectWidth = 64.0, objectHeight = 40.0;
  static const handle = 7.0, stem = 20.0, knob = 6.0, turnArc = 11.0;
  static const tiltStem = 16.0, rail = 12.0, zReach = 1000.0;
}

Offset turned(Offset p, double angle) => Offset(
  p.dx * math.cos(angle) - p.dy * math.sin(angle),
  p.dx * math.sin(angle) + p.dy * math.cos(angle),
);

/// Where a layer stood and how large it was when its preview was opened, or last brought back to the middle.
class TransformHome {
  TransformHome.of(Map<String, double> v)
    : at = Offset(v['v_x'] ?? 0, v['v_y'] ?? 0),
      z = v['v_z'] ?? 0,
      size = math.max(
        1,
        math.max((v['v_scale_x'] ?? 100).abs(), (v['v_scale_y'] ?? 100).abs()),
      );
  final Offset at;
  final double z;

  /// In the scale's hundredths: the larger side is drawn at the usual size.
  final double size;
}

/// The preview of [values] on a canvas of [size], seen from the front.
///
/// The layer is drawn from its [home]: in the middle and at the usual size there, so what moved or grew since shows as far
/// as it went. Its turn and the ratio of its sides are its own. Outside 2D a nearer layer is drawn larger.
class TransformLayout {
  TransformLayout(
    this.size,
    this.values, {
    required this.deep,
    required this.home,
  });
  final Size size;
  final Map<String, double> values;
  final bool deep;
  final TransformHome home;

  /// Every value the preview edits.
  static const watched = [
    'v_x', 'v_y', 'v_z', 'v_scale_x', 'v_scale_y', 'v_rotate', //
    'v_rotate_x', 'v_rotate_y', 'v_anchor_x', 'v_anchor_y',
  ];

  double value(String id) => values[id] ?? 0;
  double get angle => value('v_rotate') * math.pi / 180;
  double get tiltX => value('v_rotate_x') * math.pi / 180;
  double get tiltY => value('v_rotate_y') * math.pi / 180;
  double get z => value('v_z');

  /// The composition, 16:9, as large as fits.
  Rect get frame {
    final w = math.min(size.width - 24, (size.height - 24) * 16 / 9);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: w * 9 / 16,
    );
  }

  double get perPixel => frame.width / 1920;

  // A composition-wide camera distance, so Z -1000 reads clearly larger without leaving the frame.
  static const _camera = 2400.0;
  double depthScale(double zc) =>
      deep ? _camera / math.max(300, _camera + zc) : 1;
  Offset _project(Offset flat, double zc) =>
      frame.center + (flat - frame.center) * depthScale(zc);

  Offset get half => Offset(
    PreviewSize.objectWidth / 2 * value('v_scale_x') / home.size,
    PreviewSize.objectHeight / 2 * value('v_scale_y') / home.size,
  );
  Offset get anchor => Offset(
    (value('v_anchor_x') / 50 - 1) * half.dx,
    (value('v_anchor_y') / 50 - 1) * half.dy,
  );
  Offset get flatPivot =>
      frame.center + (Offset(value('v_x'), value('v_y')) - home.at) * perPixel;
  Offset get pivot => _project(flatPivot, z - home.z);

  /// Whether the layer has left the frame; its home is then taken again where it is now.
  bool get away =>
      corners.any((p) => !frame.inflate(PreviewSize.handle).contains(p));

  /// A point of the layer around its centre, pushed [back] away from the viewer.
  Offset world(Offset p, [double back = 0]) {
    var (x, y, d) = (p.dx - anchor.dx, p.dy - anchor.dy, back);
    (y, d) = (
      y * math.cos(tiltX) - d * math.sin(tiltX),
      y * math.sin(tiltX) + d * math.cos(tiltX),
    );
    (x, d) = (
      x * math.cos(tiltY) + d * math.sin(tiltY),
      -x * math.sin(tiltY) + d * math.cos(tiltY),
    );
    return _project(
      flatPivot + turned(Offset(x, y), angle),
      z - home.z + d / perPixel,
    );
  }

  Offset get center => world(Offset.zero);
  Offset local(Offset p) =>
      turned((p - pivot) / depthScale(z - home.z), -angle) + anchor;

  static const _handlePoints = [
    Offset(-1, -1), Offset(1, -1), Offset(1, 1), Offset(-1, 1), //
    Offset(-1, 0), Offset(1, 0), Offset(0, -1), Offset(0, 1),
  ];
  List<Offset> get handles => [
    for (final p in _handlePoints)
      world(Offset(p.dx * half.dx, p.dy * half.dy)),
  ];
  List<Offset> get corners => handles.take(4).toList();
  Offset get stemBase => world(Offset(0, -half.dy.abs()));
  Offset get knob => world(Offset(0, -half.dy.abs() - PreviewSize.stem));

  /// The tilt knobs: below the layer tilts it about X, left of it about Y.
  Offset tiltBase(int axis) => axis == 1
      ? world(Offset(0, half.dy.abs()))
      : world(Offset(-half.dx.abs(), 0));
  Offset tiltKnob(int axis) => axis == 1
      ? world(Offset(0, half.dy.abs() + PreviewSize.tiltStem))
      : world(Offset(-half.dx.abs() - PreviewSize.tiltStem, 0));

  /// The Z rail on the right: near (negative Z) at the top, far at the bottom.
  double get railX => size.width - PreviewSize.rail;
  double get railHalf => size.height / 2 - 16;
  Offset get liftKnob => Offset(
    railX,
    size.height / 2 + (z / PreviewSize.zReach).clamp(-1, 1) * railHalf,
  );

  bool body(Offset p) => (Path()..addPolygon(corners, true)).contains(p);

  /// The part under [p], with the handle's index for scale and rotation, front to back.
  (TransformZone, int)? pick(Offset p) {
    if ((p - knob).distance <= 8) return (TransformZone.rotate, 0);
    // A 2D layer has no depth to pull: its order in the stack says what is in front.
    if (deep && (p - liftKnob).distance <= 8) return (TransformZone.lift, 0);
    if (deep) {
      for (final axis in const [1, 2]) {
        if ((p - tiltKnob(axis)).distance <= 7) {
          return (TransformZone.rotate, axis);
        }
      }
    }
    if ((p - pivot).distance <= 7) return (TransformZone.pivot, 0);
    for (final (i, h) in handles.indexed) {
      if ((p - h).distance <= 7) return (TransformZone.scale, i);
    }
    if (body(p)) return (TransformZone.move, 0);
    return null;
  }

  /// The values a drag of [zone] from [last] to [now] gives; [down] is where the drag began on this layout.
  /// [rate] is the fine or coarse modifier's factor. [linked] scales both sides by one factor.
  Map<String, double> drag(
    TransformZone zone,
    int index, {
    required Offset down,
    required Offset last,
    required Offset now,
    required Map<String, double> current,
    required double rate,
    required bool linked,
  }) {
    double cur(String id) => current[id] ?? 0;
    final step = now - last;
    switch (zone) {
      case TransformZone.move:
        final d = step / (perPixel * depthScale(z - home.z)) * rate;
        return {'v_x': cur('v_x') + d.dx, 'v_y': cur('v_y') + d.dy};
      case TransformZone.lift:
        return {
          'v_z': cur('v_z') + step.dy / railHalf * PreviewSize.zReach * rate,
        };
      case TransformZone.rotate when index == 1:
        return {'v_rotate_x': cur('v_rotate_x') - step.dy * .8 * rate};
      case TransformZone.rotate when index == 2:
        return {'v_rotate_y': cur('v_rotate_y') + step.dx * .8 * rate};
      case TransformZone.rotate:
        final a = (now - pivot).direction - (last - pivot).direction;
        return {
          'v_rotate':
              cur('v_rotate') +
              math.atan2(math.sin(a), math.cos(a)) * 180 / math.pi * rate,
        };
      case TransformZone.scale:
        final from = turned(down - pivot, -angle),
            to = turned(now - pivot, -angle);
        double ratio(double a, double b) => b.abs() < 1 ? 1 : a / b;
        var fx = index < 6 ? ratio(to.dx, from.dx) : 1.0;
        var fy = index < 4 || index >= 6 ? ratio(to.dy, from.dy) : 1.0;
        if (linked) {
          fx = fy = index < 4
              ? to.distance / math.max(1, from.distance)
              : (index < 6 ? fx : fy);
        }
        // Past the pivot a side flips, as a negative scale does in After Effects; the modifier only slows the change.
        double eased(double f) => f.sign * math.pow(f.abs(), rate);
        return {
          'v_scale_x': value('v_scale_x') * eased(fx),
          'v_scale_y': value('v_scale_y') * eased(fy),
        };
      case TransformZone.pivot:
        // The anchor is a share of the layer's box, and may lie outside it, as After Effects' Anchor Point may.
        final d = local(now) - local(last);
        return {
          'v_anchor_x': cur('v_anchor_x') + d.dx / (2 * half.dx) * 100 * rate,
          'v_anchor_y': cur('v_anchor_y') + d.dy / (2 * half.dy) * 100 * rate,
        };
    }
  }
}
