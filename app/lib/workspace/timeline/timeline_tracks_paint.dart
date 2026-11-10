// Painting for the timeline's tracks: each row's bar (fill, keyframes, easing curves, video frames, sound wave)
// and the value line of an open property lane.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/timeline_painters.dart' show tpFine, tpMajor;
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

/// The bar's fill: the layer kind's hue, a step quieter when not selected. A hidden or soloed-out layer is grey.
Color wtBarFill(WtRow r) => Forms.worn.trackFill(r.tone ?? wsTone(r.kind), dim: r.dim, selected: r.selected);

/// Adds an easing curve to [p] from x [xa] to [xb], sampled finely enough for the pixels on screen.
///
/// Sampling at 192 steps is more than a short stretch has pixels for, and a long one still looks like a curve.
/// Skia flattens curves into line segments as well.
void _wayLine(Path p, List<double> way, double xa, double xb, double width, double Function(double) y) {
  final n = way.length - 1, wide = xb - xa;
  if (wide <= 0) return;
  final every = math.max(1, (n * 1.5 / wide).floor());
  final from = ((-xa / wide * n).floor() - every).clamp(0, n), to = (((width - xa) / wide * n).ceil() + every).clamp(0, n);
  for (var i = from + every; i < to; i += every) {
    p.lineTo(xa + wide * i / n, y(way[i]));
  }
  p.lineTo(xa + wide * to / n, y(way[to]));
}

void _vLines(Canvas c, WtView v, int fps, double w, double top, double bottom, {required Color major, required Color fine, WsBeats? beats}) {
  final mj = tpMajor(v.ppf, fps), fn = tpFine(v.ppf, fps, mj), p = Paint();
  if (beats != null) {
    // Draw the grid by beat rather than by second while the lines can be told apart; Live's grid also widens as it is zoomed out.
    for (final (f, bar) in beats.between(v.scroll, v.scroll + w / v.ppf)) {
      if (bar || beats.every * v.ppf >= 8) c.drawRect(Rect.fromLTWH(v.x(f).roundToDouble(), top, 1, bottom - top), p..color = bar ? major : fine);
    }
    return;
  }
  final f0 = (v.scroll / fn).floor() * fn;
  for (var f = f0; f <= Ws.duration; f += fn) {
    final x = v.x(f).roundToDouble();
    if (x > w) break;
    if (x < 0) continue;
    c.drawRect(Rect.fromLTWH(x, top, 1, bottom - top), p..color = f % mj == 0 ? major : fine);
  }
}

class WtTracksPainter extends CustomPainter {
  const WtTracksPainter({required this.rows, required this.view, required this.fps, required this.vscroll, this.restAt});
  final List<WtRow> rows;
  final WtView view;
  final int fps;
  final double vscroll;

  /// The frame where the drag snapped, drawn as a line like Alight Motion's SnapLine, or null.
  final int? restAt;

  @override
  void paint(Canvas c, Size s) {
    c.clipRect(Offset.zero & s);
    final p = Paint(), end = view.x(Ws.duration);
    c.drawRect(Offset.zero & s, p..color = WsT.body);
    for (var i = 0; i < rows.length; i++) {
      final top = i * WtM.row - vscroll;
      if (top > s.height || top + WtM.row < 0) continue;
      c.drawRect(Rect.fromLTWH(0, top, s.width, WtM.row - 1), p..color = Forms.worn.trackBand(i, rows[i].selected));
      c.drawRect(Rect.fromLTWH(0, top + WtM.row - 1, s.width, 1), p..color = Grey.rowLine);
    }
    if (end < s.width) c.drawRect(Rect.fromLTRB(end, 0, s.width, s.height), p..color = WsT.body);
    _vLines(c, view, fps, math.min(s.width, end), 0, s.height, major: Grey.g20, fine: Grey.g15);
    for (var i = 0; i < rows.length; i++) {
      final top = i * WtM.row - vscroll;
      if (top > s.height || top + WtM.row < 0) continue;
      _row(c, s, rows[i], top + WtM.row / 2 - .5);
    }
    if (restAt case final f?) c.drawRect(Rect.fromLTWH(view.x(f).roundToDouble(), 0, 1, s.height), p..color = WsT.accent);
  }

  void _row(Canvas c, Size s, WtRow r, double cy) {
    // A lane with no points is a row that only shows what it targets, so nothing is drawn.
    if (r.lane case final pts?) return pts.isEmpty ? null : _lane(c, s, r, pts, cy);
    final p = Paint(), x0 = view.x(r.inF), x1 = math.max(view.x(r.outF), x0 + 4), h = Forms.worn.trackBar(selected: r.selected);
    if (r.whole case (final a, final b)?) {
      c.drawRect(Rect.fromLTRB(view.x(a), cy - h / 2, view.x(b), cy + h / 2), p..color = wtBarFill(r).withValues(alpha: .18));
    }
    if (x1 < 0 || x0 > s.width) return;
    final bar = Rect.fromLTRB(x0, cy - h / 2, x1, cy + h / 2), rr = RRect.fromRectAndRadius(bar, Radius.circular(Forms.worn.trackRadius));
    final fill = wtBarFill(r), ink = r.dim ? Grey.g56 : WsT.onAccent, grip = Color.lerp(fill, Grey.g00, .28)!;
    final mix = r.mix;
    if (mix != null && mix.length > 1 && !r.dim) {
      // A behaviour bar blends the colours of the layers it affects.
      c.drawRRect(
        rr,
        Paint()..shader = LinearGradient(colors: [for (final m in mix) r.selected ? Color.lerp(m, const Color(0xFFFFFFFF), .18)! : m]).createShader(bar),
      );
    } else {
      c.drawRRect(rr, p..color = fill);
    }
    c.save();
    c.clipRRect(rr);
    // The trim handles at both ends are wide and have a light notch.
    c.drawRect(Rect.fromLTWH(x0, bar.top, 5, bar.height), p..color = grip);
    c.drawRect(Rect.fromLTWH(x1 - 5, bar.top, 5, bar.height), p..color = grip);
    final notch = ink.withAlpha(r.selected ? 200 : 120);
    c.drawRect(Rect.fromLTWH(x0 + 2, bar.top + 4, 1.5, bar.height - 8), p..color = notch);
    c.drawRect(Rect.fromLTWH(x1 - 3.5, bar.top + 4, 1.5, bar.height - 8), p..color = notch);
    if (r.frames case final f? when f.length == 1) {
      // A single image is repeated along the bar at its own aspect ratio, as in Alight Motion.
      final im = f.single, step = math.max(4.0, bar.height * im.width / math.max(1, im.height));
      for (var x = bar.left + 5; x < bar.right - 5; x += step) {
        paintImage(
          canvas: c,
          rect: Rect.fromLTWH(x, bar.top, step, bar.height),
          image: im,
          fit: BoxFit.cover,
          opacity: r.dim ? .35 : .8,
          filterQuality: FilterQuality.low,
        );
      }
    } else if (r.frames case final f? when f.isNotEmpty) {
      // A video shows a strip of frames, each filling its part of the bar with its centre kept, as in Alight Motion.
      final step = (bar.width - 10) / f.length;
      for (final (i, im) in f.indexed) {
        final at = Rect.fromLTWH(bar.left + 5 + i * step, bar.top, step, bar.height);
        paintImage(canvas: c, rect: at, image: im, fit: BoxFit.cover, opacity: r.dim ? .35 : .8, filterQuality: FilterQuality.low);
      }
    }
    if (r.wave case final w?) _wave(c, bar, ink, fill, r.inF, w);
    if (r.clipped) {
      // The arrow marks a layer clipped to the layer below.
      final at = Offset(math.max(x0 + 8, 6.0), cy - 4),
          arrow = Paint()
            ..color = ink
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
      c.drawLine(at, at + const Offset(7, 7), arrow);
      c.drawPath(
        Path()
          ..moveTo(at.dx + 7, at.dy + 3)
          ..lineTo(at.dx + 7, at.dy + 7)
          ..lineTo(at.dx + 3, at.dy + 7),
        arrow,
      );
    }
    final nameX = math.max(x0 + 8, 6.0) + (r.clipped ? 12 : 0);
    final t = lineText(r.name, T.name(ink).copyWith(fontWeight: FontWeight.w700));
    if (nameX + 20 < x1) {
      if (r.wave != null || r.frames != null) {
        c.drawRRect(
          RRect.fromLTRBR(nameX - 4, cy - 6.5, nameX + t.width + 4, cy + 6.5, Shape.r(3)),
          p..color = fill,
        ); // Backing for the name so it stays readable over the waveform or frames.
      }
      c.save();
      c.clipRect(Rect.fromLTRB(nameX, bar.top, x1 - 6, bar.bottom));
      t.paint(c, Offset(nameX, cy - t.height / 2));
      c.restore();
    }
    t.dispose();
    if (r.locked) {
      for (var x = x0 - bar.height; x < x1; x += 6) {
        c.drawLine(
          Offset(x, bar.bottom),
          Offset(x + bar.height, bar.top),
          Paint()
            ..color = grip
            ..strokeWidth = 1,
        );
      }
    }
    c.restore();
    if (r.selected && !r.dim) {
      c.drawRRect(
        rr.deflate(.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Grey.g100,
      );
    }
    for (final st in r.stretches) {
      // The easing between each keyframe and the next, drawn as a thin line inside the bar, as Ableton draws automation.
      final xa = view.x(st.from), xb = view.x(st.to);
      if (xb - xa < 6 || xb < 0 || xa > s.width) continue;
      final h = bar.height * .62, base = cy + h / 2;
      final line = Path()..moveTo(xa, base - st.shape.first.clamp(-.5, 1.5) * h);
      _wayLine(line, st.shape, xa, xb, s.width, (v) => base - v.clamp(-.5, 1.5) * h);
      c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true
          ..color = Color.lerp(fill, Grey.g100, r.dim ? .25 : .6)!,
      );
    }
    for (final k in r.keys) {
      final x = view.x(k);
      if (x < -8 || x > s.width + 8) continue;
      final on = r.picked.contains(k);
      final rad = on ? WtM.keyPicked : WtM.key;
      final d = Path()
        ..moveTo(x, cy - rad)
        ..lineTo(x + rad, cy)
        ..lineTo(x, cy + rad)
        ..lineTo(x - rad, cy)
        ..close();
      if (on) {
        c.drawPath(d, p..color = WsT.keyDot);
        c.drawPath(
          d,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeJoin = StrokeJoin.miter
            ..color = WsT.onAccent,
        );
      } else {
        c.drawPath(d, p..color = r.dim ? Grey.g44 : WsT.onAccent);
        c.drawPath(
          d,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = r.dim ? Grey.g26 : Color.lerp(fill, Grey.g100, .55)!,
        );
      }
    }
  }

  /// Draws a property lane, like an envelope in an Ableton Live lane (Live 12 manual 25.5).
  ///
  /// Keyframes are breakpoints at their values, lowest at the bottom, joined by each keyframe's easing curve.
  /// Nothing is drawn before the first or after the last keyframe, because with many lanes a full-width line says nothing.
  /// The line is a lighter shade of the bar's colour, like the bar's own easing lines.
  void _lane(Canvas c, Size s, WtRow r, List<(int, double)> pts, double cy) {
    final top = cy - WtM.row / 2 + 4, h = WtM.row - 9, col = Color.lerp(wtBarFill(r), Grey.g100, r.dim ? .25 : .6)!;
    Offset at((int, double) q) => Offset(view.x(q.$1), top + (1 - q.$2) * h);
    final line = Path()..moveTo(at(pts.first).dx, at(pts.first).dy);
    for (var i = 0; i < pts.length; i++) {
      final a = at(pts[i]), way = i + 1 < pts.length ? r.laneWays?.elementAtOrNull(i) : null;
      line.lineTo(a.dx, a.dy);
      if (way == null) continue;
      final b = at(pts[i + 1]);
      // Overshoot is clamped to stay within the lane.
      _wayLine(line, way, a.dx, b.dx, s.width, (v) => (a.dy + (b.dy - a.dy) * v).clamp(top - 3, top + h + 3));
    }
    if (r.laneOn case final i? when i + 1 < pts.length) {
      c.drawRect(
        Rect.fromLTRB(at(pts[i]).dx, cy - WtM.row / 2, at(pts[i + 1]).dx, cy + WtM.row / 2),
        Paint()..color = WsT.accent.withValues(alpha: .18),
      ); // Highlights the segment open in the curve editor, like Theatre.js's connector.
    }
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = col,
    );
    for (final q in pts) {
      c.drawCircle(at(q), WtM.key * .75, Paint()..color = col);
    }
  }

  /// Draws the layer's waveform from the engine's decibel values: -60 dB to full scale across the bar's height, using the loudest of each two points.
  void _wave(Canvas c, Rect bar, Color ink, Color fill, int inF, List<double> db) {
    final p = Paint()..color = Color.lerp(fill, ink, .7)!;
    final h = bar.height - 4, cy = bar.center.dy;
    for (var x = math.max(bar.left + 4, 0.0); x < bar.right - 4; x += 2) {
      final a0 = view.frameAt(x).floor() - inF, a1 = view.frameAt(x + 2).ceil() - inF;
      var loud = -100.0;
      for (var k = math.max(a0, 0); k <= a1 && k < db.length; k++) {
        if (db[k] > loud) loud = db[k];
      }
      final a = ((loud + 60) / 60).clamp(0.0, 1.0);
      if (a > 0) c.drawRect(Rect.fromCenter(center: Offset(x.roundToDouble(), cy), width: 1, height: (a * h).roundToDouble().clamp(1, h)), p);
    }
  }

  @override
  bool shouldRepaint(WtTracksPainter o) => o.view != view || o.fps != fps || o.vscroll != vscroll || o.restAt != restAt || !listEquals(o.rows, rows);
}

// ---------------------------------------------------------------- playhead
