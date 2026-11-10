// The workspace timeline's drawing: ruler, track rows, playhead, overview strip and the kind chip.
// Every painter takes plain values and repaints only when one of them changes; nothing here ticks.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/foundation.dart' show listEquals, ValueListenable;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// One row as drawn: a snapshot of the layer plus how the panel shows it.
@immutable
class TimelineRow {
  const TimelineRow({
    required this.name,
    required this.kind,
    required this.inF,
    required this.outF,
    required this.keys,
    required this.picked,
    this.selected = false,
    this.dim = false,
    this.locked = false,
    this.clipped = false,
    this.wave,
    this.frames,
    this.form,
    this.fill,
    this.outline = false,
    this.tone,
    this.mix,
    this.stretches = const [],
    this.lane,
    this.laneWays,
    this.laneOn,
    this.whole,
  });

  final (int, int)? whole; // The whole length of a video as it lies, cut or not: the pale slip-edit bar of After Effects.
  final List<Stretch> stretches; // The easing of each stretch between keyframes, drawn between them.

  /// A property's own lane in place of a bar, as Ableton's automation lane.
  ///
  /// Holds each keyframe's frame and where its value stands between the lowest and highest value of the property's
  /// keyframes (0 to 1). Null for a layer's row.
  final List<(int, double)>? lane;
  final List<List<double>>? laneWays; // The easing curve from each keyframe to the next: 0 at the keyframe, 1 at the next.
  final int? laneOn; // The index of the stretch selected by clicking its line.
  final Color?
  tone; // The label colour. Null uses the colour of the layer's kind.
  final List<Color>? mix; // For a relation, the label colours of its layers; the bar is a gradient of them.
  final String name;
  final List<double>? wave; // How loud the sound is at each frame of the bar, in dB. Null if there is no sound.
  final List<ui.Image>? frames; // One image per stretch of a video's bar. Null if not a video or not read yet.
  final String? form; // A shape's form as named by the engine (rect, circle, star...), drawn as a small icon at the row's left.
  final Color? fill;
  final bool
  outline; // True if the shape has no fill; [fill] is then the stroke colour.
  final LayerKind kind;
  final int inF, outF;
  final List<int> keys;
  final Set<int> picked;

  /// [clipped] means the layer is cut to the layer under it; a mark before its name shows this, as in Alight Motion.
  final bool selected, dim, locked, clipped;
  @override
  bool operator ==(Object other) =>
      other is TimelineRow &&
      other.name == name &&
      other.kind == kind &&
      other.tone == tone &&
      listEquals(other.mix, mix) &&
      other.inF == inF &&
      other.outF == outF &&
      listEquals(other.keys, keys) &&
      setEquals(other.picked, picked) &&
      other.selected == selected &&
      other.dim == dim &&
      other.locked == locked &&
      other.clipped == clipped &&
      other.whole == whole &&
      identical(other.wave, wave) &&
      identical(
        other.frames,
        frames,
      ) && // Read once per change: the same list until the project changes.
      other.form == form &&
      other.fill == fill &&
      other.outline == outline &&
      listEquals(other.lane, lane) &&
      other.laneOn == laneOn &&
      other.stretches.length == stretches.length &&
      [
        for (var i = 0; i < stretches.length; i++)
          other.stretches[i].from == stretches[i].from &&
              other.stretches[i].to == stretches[i].to &&
              other.stretches[i].way == stretches[i].way,
      ].every((same) => same);
  @override
  int get hashCode => Object.hash(
    name,
    kind,
    inF,
    outF,
    Object.hashAll(keys),
    Object.hashAllUnordered(picked),
    selected,
    dim,
    locked,
  );
}

/// The width of a marker's flag on the ruler, which holds its name. Used both to draw the flag and to hit-test it.
double markerFlagWidth(String name) =>
    lineText(
      name,
      TextStyles.micro(Grey.g13).copyWith(fontWeight: FontWeight.w700),
    ).width +
    8;

/// The width of the flag of a marker at [x]: its name's width, cut short where the next marker begins.
///
/// Logic Pro likewise shows a marker's name only as far as the following marker. [xs] holds the x of every marker.
double markerFlagRoom(String name, double x, Iterable<double> xs) {
  final next = xs
      .where((o) => o > x)
      .fold<double?>(null, (a, o) => a == null || o < a ? o : a);
  final w = markerFlagWidth(name);
  return next == null ? w : math.max(6, math.min(w, next - x - 1));
}

// ---------------------------------------------------------------- tracks

/// Paints the playhead: a thin line with a small head.
class TimelinePlayheadPainter extends CustomPainter {
  const TimelinePlayheadPainter({
    required this.view,
    required this.frame,
    required this.headTop,
    this.moment,
  }) : super(repaint: moment);
  final TimelineView view;
  final int frame;
  final double headTop;
  final ValueListenable<int>? moment; // The current frame, read at paint time, so moving the playhead repaints without rebuilding.

  @override
  void paint(Canvas c, Size s) {
    final frame = moment?.value ?? this.frame;
    final x = view.x(frame).roundToDouble();
    if (x < -40 || x > s.width + 40) return;
    final p = Paint()..color = WindowTokens.playhead;
    // A small head with no number on it, like the playhead of Premiere Pro, After Effects, Ableton and Alight Motion.
    // The frame is shown in the header's time. A head that carried the frame number hid marker names under it.
    // Blender and Cavalry number their playheads, but they put markers on a row of their own.
    final w = Shape.z(9), cx = (x + .5).clamp(w / 2, s.width - w / 2);
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, headTop + 8),
        width: w,
        height: Shape.z(15),
      ),
      Shape.r(4),
    );
    c.drawRect(Rect.fromLTWH(x, headTop + 8, 1, s.height - headTop - 8), p);
    p.color = WindowTokens.accent;
    c.drawRRect(pill, p);
    c.drawPath(
      Path()
        ..moveTo(x + .5 - 4, pill.bottom)
        ..lineTo(x + 4.5, pill.bottom)
        ..lineTo(x + .5, pill.bottom + 4)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(TimelinePlayheadPainter o) =>
      o.view != view ||
      o.frame != frame ||
      o.headTop != headTop ||
      o.moment != moment;
}

// ---------------------------------------------------------------- overview (the horizontal scroll strip)

/// Paints the overview strip: the whole project in miniature with the visible range and the playhead.
class TimelineOverviewPainter extends CustomPainter {
  const TimelineOverviewPainter({
    required this.from,
    required this.to,
    required this.frame,
    required this.hot,
  });
  final double from, to;
  final int frame;
  final bool hot;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint(), w = s.width - 8;
    double x(double f) => 4 + f / WorkspaceController.duration * w;
    c.drawRect(Offset.zero & s, p..color = WindowTokens.body);
    c.drawRRect(
      RRect.fromLTRBR(4, 3, s.width - 4, s.height - 3, Shape.r(3)),
      p..color = Grey.g13,
    );
    c.drawRRect(
      RRect.fromLTRBR(
        x(from),
        3,
        math.max(x(to), x(from) + 12),
        s.height - 3,
        Shape.r(3),
      ),
      p..color = hot ? Grey.g44 : Grey.g26,
    );
    c.drawRect(
      Rect.fromLTWH(x(frame.toDouble()).roundToDouble(), 2, 2, s.height - 4),
      p..color = WindowTokens.playhead,
    );
  }

  @override
  bool shouldRepaint(TimelineOverviewPainter o) =>
      o.from != from || o.to != to || o.frame != frame || o.hot != hot;
}

// ---------------------------------------------------------------- kind chip

/// A row's small thumbnail, as Alight Motion shows at the left of each row
/// (screenshots 95 and 106 in docs/design/alight_motion_ui.md).
///
/// An image or video layer shows its image, a shape shows its form in its own fill, and other kinds show the mark of
/// their kind. Alight Motion's camera and audio are marks too. Its screenshots show no text thumbnail, so text keeps its mark.
class TimelineThumbnail extends StatelessWidget {
  const TimelineThumbnail(this.row, {super.key});
  final TimelineRow row;
  @override
  Widget build(BuildContext context) {
    final r = row;
    if (r.frames case final f? when f.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.all(Shape.r(3)),
        child: SizedBox.square(
          dimension: TimelineMetrics.chip,
          child: RawImage(
            image: f.first,
            fit: BoxFit.cover,
            opacity: AlwaysStoppedAnimation(r.dim ? .35 : 1),
          ),
        ),
      );
    }
    if (r.form case final form?
        when r.kind == LayerKind.shape && form != 'null') {
      return Container(
        width: TimelineMetrics.chip,
        height: TimelineMetrics.chip,
        decoration: BoxDecoration(
          color: Grey.g20,
          borderRadius: BorderRadius.all(Shape.r(3)),
        ),
        child: CustomPaint(
          painter: _FormPainter(
            form,
            (r.fill ?? layerKindColor(r.kind)).withValues(
              alpha: r.dim ? .35 : 1,
            ),
            outline: r.outline,
          ),
        ),
      );
    }
    return layerKindChip(r.kind, dim: r.dim, tone: r.tone);
  }
}

class _FormPainter extends CustomPainter {
  const _FormPainter(this.form, this.ink, {this.outline = false});
  final String form;
  final Color ink;
  final bool outline;
  @override
  void paint(Canvas c, Size s) {
    final b = (Offset.zero & s).deflate(s.width * .16),
        st = Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
    final f = outline ? st : (Paint()..color = ink);
    Path round(int n, double inner) => Path()
      ..addPolygon([
        for (var i = 0; i < n * (inner < 1 ? 2 : 1); i++)
          b.center +
              Offset.fromDirection(
                -math.pi / 2 + i * math.pi * 2 / (n * (inner < 1 ? 2 : 1)),
                b.width / 2 * (inner < 1 && i.isOdd ? inner : 1),
              ),
      ], true);
    switch (form) {
      case 'rect' || 'solid':
        c.drawRect(b, f);
      case 'squircle' || 'chamfer':
        c.drawRRect(
          RRect.fromRectAndRadius(b, Radius.circular(b.width * .3)),
          f,
        );
      case 'polygon':
        c.drawPath(round(6, 1), f);
      case 'star':
        c.drawPath(round(5, .45), f);
      case 'line':
        c.drawLine(b.bottomLeft, b.topRight, st);
      case 'ring':
        c.drawOval(b.deflate(1), st);
      default: // Circle, and any form without a small mark of its own: a round shape in its fill.
        c.drawOval(b, f);
    }
  }

  @override
  bool shouldRepaint(_FormPainter o) =>
      o.form != form || o.ink != ink || o.outline != outline;
}

/// A layer's kind: a small square of its colour with the kind's mark drawn in dark ink.
Widget layerKindChip(LayerKind kind, {bool dim = false, Color? tone}) => Badge(
  dim ? Grey.g26 : tone ?? layerKindColor(kind),
  size: TimelineMetrics.chip,
  radius: Shape.r(3),
  mark: _KindPainter(kind, dim ? Grey.g56 : WindowTokens.onAccent),
);

class _KindPainter extends CustomPainter {
  const _KindPainter(this.kind, this.ink);
  final LayerKind kind;
  final Color ink;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width,
        f = Paint()..color = ink,
        st = Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;
    Offset o(double x, double y) => Offset(x * w, y * w);
    switch (kind) {
      case LayerKind.shape:
        c.drawCircle(o(.5, .5), w * .27, f);
      case LayerKind.text:
        c.drawRect(Rect.fromLTRB(w * .24, w * .22, w * .76, w * .34), f);
        c.drawRect(Rect.fromLTRB(w * .43, w * .22, w * .57, w * .8), f);
      case LayerKind.image:
        c.drawPath(
          Path()
            ..moveTo(w * .18, w * .76)
            ..lineTo(w * .42, w * .4)
            ..lineTo(w * .58, w * .6)
            ..lineTo(w * .66, w * .5)
            ..lineTo(w * .84, w * .76)
            ..close(),
          f,
        );
        c.drawCircle(o(.68, .28), w * .09, f);
      case LayerKind.camera:
        c.drawRRect(
          RRect.fromLTRBR(w * .16, w * .32, w * .64, w * .7, Shape.r(1.5)),
          f,
        );
        c.drawPath(
          Path()
            ..moveTo(w * .66, w * .51)
            ..lineTo(w * .86, w * .34)
            ..lineTo(w * .86, w * .68)
            ..close(),
          f,
        );
      case LayerKind.group:
        c.drawRect(Rect.fromLTRB(w * .2, w * .2, w * .62, w * .62), st);
        c.drawRect(Rect.fromLTRB(w * .4, w * .4, w * .8, w * .8), f);
      case LayerKind.particles:
        for (final (x, y, r) in const [
          (.3, .32, .1),
          (.68, .3, .07),
          (.5, .56, .12),
          (.26, .74, .07),
          (.74, .72, .09),
        ]) {
          c.drawCircle(o(x, y), w * r, f);
        }
      case LayerKind.audio:
        for (final (x, h) in const [
          (.24, .2),
          (.38, .4),
          (.52, .28),
          (.66, .44),
          (.8, .16),
        ]) {
          c.drawLine(o(x, .5 - h / 2 - .04), o(x, .5 + h / 2 + .04), st);
        }
    }
  }

  @override
  bool shouldRepaint(_KindPainter o) => o.kind != kind || o.ink != ink;
}
